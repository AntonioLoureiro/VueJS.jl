function is_own_attr(v::VueJS.VueElement,k::String)
    karr=split(k,'.')
    if length(karr)==2
        if karr[1]==v.id && haskey(v.attrs,karr[2])
            return true 
        else 
            return false
        end
    else
       return false 
    end
end

function update_dom(r::VueElement;opts=PAGE_OPTIONS,is_child=false)

    ## Is Child Explicit item. in child attrs
    if is_child
        ## Un Bind Things
        for (k,v) in r.binds
            if k==r.value_attr
                ka="value"
                value=get(r.attrs,ka,nothing)
            else
                value=get(r.attrs,k,nothing)
            end
            
            value==nothing ? value=v : nothing
            
            if value isa AbstractString && occursin("item.",value)
                r.attrs[":$k"]=trf_vue_expr(value,opts=opts)               
                if k==r.value_attr 
                    event=r.value_attr=="model-value" ? "update:$(r.value_attr)" : "update:$(r.value_attr)"
                    ev_expr=get(r.attrs,"type","")=="number" ? "$value= toNumber(\$event);" : "$value= \$event;"
                      if haskey(r.attrs,event)
                        r.attrs[event]=ev_expr*r.attrs[event]*";"
                    else
                        r.attrs[event]=ev_expr
                    end
                    delete!(r.attrs,ka)
                else     
                    delete!(r.attrs,k)
                end
            elseif value!=nothing
                r.attrs[k]=value
            else
                r.attrs[k]=""
            end
        end
        r.binds=Dict()
    end    
        
    ## cycle through attrs
    for (k,v) in r.attrs
        if k in DIRECTIVES
            r.attrs[k]=trf_vue_expr(v,opts=opts)
        elseif is_event(k) 
            value=keys_id_fix(v)
            r.attrs[k]=trf_vue_expr(value,opts=opts)
        end
    end
    
    ## cycle through binds
    for (k,v) in r.binds
        value=opts.path=="" ? v : opts.path*"."*v
        ## Expressions
        if k!=r.value_attr && !(is_own_attr(r,v))
            r.attrs[":$k"]=trf_vue_expr(v,opts=opts)
            delete!(r.attrs,k)
         
        ## Own attrs
        else
            r.attrs[":$k"]=vue_escape(value)
            delete!(r.attrs,k)
        end
    end

    ## Bind with Value Attr
    if haskey(r.binds,r.value_attr)
        v=r.binds[r.value_attr]
        value=opts.path=="" ? v : opts.path*"."*v
        event=r.value_attr=="model-value" ? "update:$(r.value_attr)" : "update:$(r.value_attr)"
        ev_expr=get(r.attrs,"type","")=="number" ? "$value= toNumber(\$event);" : "$value= \$event;"
        if haskey(r.attrs,event)
            r.attrs[event]=ev_expr*r.attrs[event]*";"
        else
            r.attrs[event]=ev_expr
        end
    end
    
    return r
end


dom(d;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)=d
dom(d::Dict;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)=JSON.json(d)
dom(r::String;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)=HtmlElement("div",Dict(),1,r)
function dom(r::HtmlElement;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)
   
    if r.value isa Vector
       r.value=map(x->dom(x,opts=opts),r.value) 
    else
        r.value=dom(r.value,opts=opts)
    end
    
    for (k,v) in r.attrs
        if k in DIRECTIVES
            r.attrs[k]=trf_vue_expr(v,opts=opts)            
        end
    end
    
    return r
end



function dom(vuel_orig::VueJS.VueElement;opts=VueJS.PAGE_OPTIONS,prevent_render_func=false,is_child=false)

    vuel=deepcopy(vuel_orig)
        
    if vuel.render_func!=nothing && prevent_render_func==false
       dom_ret=vuel.render_func(vuel,opts=opts)
    else
        vuel=VueJS.update_dom(vuel,opts=opts,is_child=is_child)

        child=nothing
        ## Value attr is nothing
        if vuel.value_attr==nothing
            if haskey(vuel.attrs,"content")
                child=vuel.attrs["content"]
                delete!(vuel.attrs,"content")
            end
            if haskey(vuel.attrs,":content")
                child="""{{$(vuel.attrs[":content"])}}"""
                delete!(vuel.attrs,":content")
            end
        end

        ## cols
        vuel.cols==nothing ? vuel.cols=1 : nothing
    
       if vuel.child!=nothing
           child=vuel.child
       else
           child=child==nothing ? "" : child
       end

       child_dom=child=="" ? "" : dom(child,opts=opts,is_child=true)
        
       dom_ret=VueJS.HtmlElement(vuel.tag, vuel.attrs, vuel.cols, child_dom)
        
    end
        
    ## Tooltip 
    tooltip=get(vuel.no_dom_attrs,"tooltip",nothing)
    if tooltip!=nothing
        tooltip_dom=dom(tooltip,opts=opts,is_child=true)
        if tooltip_dom isa HtmlElement
            tooltip_dom.tag=="v-tooltip" ? nothing : tooltip_dom=HtmlElement("v-tooltip", Dict(), tooltip_dom.cols, tooltip_dom)
            tooltip_dom.attrs["activator"]="parent"
        end
        if dom_ret.value==""
            dom_ret.value=tooltip_dom
        else
            dom_ret.value=[dom_ret.value,tooltip_dom]
        end
    end
    
    ## Menu 
    menu=get(vuel.no_dom_attrs,"menu",nothing)
    if menu!=nothing
            
        if menu isa Vector
            menu_items=deepcopy(menu)
            @el(menu,"v-menu",items=menu_items)
        end

       @assert menu.tag=="v-menu" "Menu value shall be a v-menu Element"
       delete!(menu.attrs,"items")
       menu_dom=dom(menu,opts=opts,is_child=true)
       items_path=vuel.attrs[":items"]
       menu_dom.value=html("v-list",html("v-list-item",html("v-list-item-title","{{item.title}}",Dict()),
                Dict("v-for"=>"(item, index) in $items_path",":key"=>"index",":value"=>"index")))
       if haskey(vuel.attrs,"click") 
            menu_dom.value.value.attrs["click"]=vuel.attrs["click"]
            delete!(vuel.attrs,"click")
       else
            menu_dom.value.value.attrs["click"]="open(item.href)"
       end
       delete!(vuel.attrs,":items")
      
       if menu isa VueJS.VueElement
            menu_dom.attrs["activator"]="parent"
       end
        
       dom_ret.value=dom_ret.value=="" ? menu_dom : [dom_ret.value,menu_dom]
        
    end
    
    return dom_ret
end

function get_cols(v::Array;rows=true)
    if rows
        return sum(map(x->get_cols(x,rows=rows),v))
    else
        return maximum(map(x->get_cols(x,rows=rows),v))
    end
end

function get_cols(v::VueJS.HtmlElement;rows=true)
    
    if v.tag=="v-row"
        return get_cols(v.value,rows=true)
    elseif v.tag=="v-col"
        return get_cols(v.value,rows=false)
    else
        return v.cols
    end
end


update_cols!(h::Nothing;context_cols=12,opts=PAGE_OPTIONS)=nothing
update_cols!(h::String;context_cols=12,opts=PAGE_OPTIONS)=nothing
update_cols!(h::Array;context_cols=12,opts=PAGE_OPTIONS)=update_cols!.(h,context_cols=context_cols,opts=opts)
function update_cols!(h::VueJS.HtmlElement;context_cols=12,opts=PAGE_OPTIONS)

    if h.tag=="v-row"
        h.attrs=get(opts.style,h.tag,Dict())
        class=get(opts.class,h.tag,Dict())
        class!=Dict() ? h.attrs["class"]=class : nothing
        update_cols!(h.value,context_cols=context_cols,opts=opts)
    elseif h.tag=="v-col"
        h.attrs=get(opts.style,h.tag,Dict())
        class=get(opts.class,h.tag,Dict())
        class!=Dict() ? h.attrs["class"]=class : nothing
        cols=VueJS.get_cols(h.value,rows=false)
        viewport=get(opts.style,"viewport","md")
        precise_cols=cols/(context_cols/12)
        cols_dec=precise_cols%1
        h.attrs[viewport]=Int(round(precise_cols))
        style=get(opts.style,h.tag,Dict())
        if cols_dec!=0
           perc_width=Int(round(precise_cols/12*100))
           if cols_dec>0.5 
               class!=Dict() ? nothing : h.attrs["class"]="flex-shrink-1"
               h.attrs["style"]="max-width: $(perc_width)%;"
            else
               class!=Dict() ? nothing : h.attrs["class"]="flex-grow-1"
               h.attrs["style"]="max-width: $(perc_width)%;"
            end 
        end
        update_cols!(h.value,context_cols=cols,opts=opts)
    elseif h.value isa VueJS.HtmlElement || h.value isa Array
        update_cols!(h.value,context_cols=context_cols,opts=opts)
    end

    return nothing
end


function dom(r::VueStruct;opts=PAGE_OPTIONS)
        
    opts=deepcopy(opts)
    merge!(opts.style,get(r.attrs,"style",Dict{Any,Any}()))
    merge!(opts.class,get(r.attrs,"class",Dict{Any,Any}()))
    
    ## Paths
    if r.iterable
        vs_path=opts.path in ["root",""] ? r.id : opts.path*"."*r.id

        opts.path=r.id*"_item"

        ks=collect(keys(get(update_data!(r,r.data),r.id,Dict())["value"][1]))
        opts.vars_replace=Dict(k=>"$(opts.path).$k" for k in vcat(ks,CONTEXT_JS_FUNCTIONS))
    else
        opts.path=opts.path=="root" ? "" : (opts.path=="" ? r.id : opts.path*"."*r.id)
        if opts.path!=""
            opts.vars_replace=Dict(k=>"$(opts.path).$k" for k in vcat(collect(keys(r.def_data)),CONTEXT_JS_FUNCTIONS))
        end
    end
    
    ## Render
    if r.render_func!=nothing
        domvalue=r.render_func(r,opts=opts)
    else
       domvalue=dom(r.grid,opts=opts)
    end
    
    if r.iterable
        iter_cols=get_cols(domvalue,rows=true) ## Iterable VS assumes row based
        domvalue=html("v-container",domvalue,cols=iter_cols,Dict("v-for"=>"($(opts.path),index) in $(vs_path).value","fluid"=>true))
    end
    
    return domvalue
end

function dom(r::VueJS.VueHolder;opts=PAGE_OPTIONS)
    
    opts.path=="root" ? opts.path="" : nothing
    
    if r.render_func!=nothing
        domvalue=r.render_func(r,opts=opts)
        if r.cols!=nothing
            domvalue.cols=r.cols
        elseif domvalue.cols==nothing
            domvalue.cols=get_cols(domvalue)
        end
        
        return domvalue
    else
        
        domvalue=deepcopy(dom(r.elements,opts=opts))
        
        if r.cols!=nothing
            cols=r.cols
        else
            cols=get_cols(domvalue)
        end
                
        return HtmlElement(r.tag,r.attrs,cols,domvalue)
    end
end

function dom(arr::Array;opts=PAGE_OPTIONS,is_child=false)
    
    opts.path=="root" ? opts.path="" : nothing
    
    if is_child
       return dom.(arr,opts=opts,is_child=is_child) 
    end
    
    arr_dom=[]
    i_rows=[]
    for (i,rorig) in enumerate(arr)

        r=deepcopy(rorig)

        ## update grid_data recursively
        append=false
        new_opts=deepcopy(opts)
        (r isa VueStruct && r.iterable==false) ? append=true : nothing
        r isa VueStruct ? new_opts.rows=true : nothing
        r isa Array ? (opts.rows ? new_opts.rows=false : new_opts.rows=true) : nothing

        domvalue=dom(r,opts=new_opts)

        grid_class=opts.rows ? "v-row" : "v-col"
        
        ## Row with single element (1 column)
        domvalue=(opts.rows && typeof(r) in [VueHolder,VueElement,HtmlElement,String]) ? HtmlElement("v-col",Dict(),domvalue.cols,domvalue) : domvalue
        
        ### New Element with row/col
        new_el=HtmlElement(grid_class,Dict(),get_cols(domvalue),domvalue)

        if ((i!=1 && i_rows[i-1]) || (opts.rows)) && append
            domvalue isa Vector ? append!(arr_dom, domvalue) : push!(arr_dom, domvalue)
        else
            push!(arr_dom,new_el)
        end

    push!(i_rows,opts.rows)
    end
    update_cols!(arr_dom,opts=opts)
    return arr_dom

end
