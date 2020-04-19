
function child_path(a::Array,path::String)
    child_path.(a,path)
   return a
end

function child_path(s::String,path::String)
    if path==""
        return replace(s,"@path@"=>"")
    else
        return replace(s,"@path@"=>path*".")
    end
end

function child_path(h::HtmlElement,path::String)
    h.value=child_path(h.value,path)
    return h
end

is_event(k::String)=k in KNOWN_JS_EVENTS || startswith(k,"keyup") || startswith(k,"keydown")

function update_template(r::VueElement)

    ## Only change value attr
    if haskey(r.attrs,"value") && r.value_attr!=nothing && r.value_attr!="value"
        r.attrs[r.value_attr]=deepcopy(r.attrs["value"])
        delete!(r.attrs,"value")
    end
    new_d=Dict{String,Any}()

    ## Delete all binds
    r.binds=Dict()

    ## bind attrs(: notation) linked to item
    for (k,v) in r.attrs
       if is_event(k)
            new_d[k]=v
       elseif v isa AbstractString && occursin("item.",v)
            new_d[":$k"]=v
            event=r.value_attr=="value" ? "input" : "change"
            if haskey(r.attrs,event)
                r.attrs[event]="$v= \$event;"*r.attrs[event]*";"
            else
                r.attrs[event]="$v= \$event"
            end
       else
            new_d[k]=v
       end
    end

    r.attrs=new_d
    return r
end

function update_dom(r::VueElement)

    ## Update @path@ and Events
    for (k,v) in r.attrs
        if k in DIRECTIVES
            r.attrs[k]=replace(v,"@path@"=>(r.path=="" ? "" : "$(r.path)."))
        end
    end

    ## Bind element values to js (only if not template)
    if r.template==false
        for (k,v) in r.binds
            value=r.path=="" ? v : r.path*"."*v
            ## bind to target (small white list )
            if k in DIRECTIVES
                r.attrs[k]=value
            elseif is_event(k)
                r.attrs[k]=value*".call($(r.path))"
            else
                r.attrs[":$k"]=value
            end

            ### delete attribute from dom
            if haskey(r.attrs,k) && !(k in DIRECTIVES || k in KNOWN_JS_EVENTS)
                delete!(r.attrs,k)
            end
        end

        ### Capture Event if tgt=src otherwise double count or if value is value attr
        ## And only if value attr! Others do not change on input! I Think!
        if haskey(r.binds,r.value_attr)
            v=r.binds[r.value_attr]
            value=r.path=="" ? v : r.path*"."*v
            event=r.value_attr=="value" ? "input" : "change"
            if haskey(r.attrs,event)
                r.attrs[event]="$value= \$event;"*r.attrs[event]*";"
            else
                r.attrs[event]="$value= \$event"
            end
        end

    else
       r=update_template(r)
    end

    return r
end


dom_child(d;rows=true)=dom(d)
dom_child(d::HtmlElement;rows=true)=d
dom_child(d::String;rows=true)=d
dom_child(a::Array;rows=true)=dom_child.(a)
dom(d;opts=PAGE_OPTIONS)=d
dom(d::Dict;opts=PAGE_OPTIONS)=JSON.json(d)


function dom(vuel_orig::VueElement;opts=PAGE_OPTIONS,prevent_render_func=false)

    vuel=deepcopy(vuel_orig)
    if vuel.render_func!=nothing && prevent_render_func==false
       return vuel.render_func(vuel)
    end

    vuel=update_dom(vuel)

    child=nothing
    ## Value attr is nothing
    if vuel.value_attr==nothing
        if haskey(vuel.attrs,"content")
            child=vuel.attrs["content"]
            delete!(vuel.attrs,"content")
        end
    end

    ## styles
    if length(vuel.style)!=0
       vuel.attrs["class"]=vuel.id
    end

    ## cols
    if vuel.cols==nothing
        vuel.cols=1
    end

   if vuel.child!=nothing
       child=vuel.child
   else
       child=child==nothing ? "" : child
   end

    child_dom=dom_child(child)

    child_dom=child_path(child_dom,vuel.path)

   return HtmlElement(vuel.tag, vuel.attrs, vuel.cols, child_dom)
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
update_cols!(h::Array;context_cols=12,opts=PAGE_OPTIONS)=update_cols!.(h,context_cols=context_cols,opts=opts)
function update_cols!(h::VueJS.HtmlElement;context_cols=12,opts=PAGE_OPTIONS)

    if h.tag=="v-row"
        h.attrs=get(opts.attrs,h.tag,Dict())  
        update_cols!(h.value,context_cols=context_cols,opts=opts)
    elseif h.tag=="v-col"
        h.attrs=get(opts.attrs,h.tag,Dict())
        cols=VueJS.get_cols(h.value,rows=false)
        viewport=get(opts.attrs,"viewport","md")
        h.attrs[viewport]=Int(round(cols/context_cols*12))
        update_cols!(h.value,context_cols=cols,opts=opts)
    elseif h.value isa VueJS.HtmlElement || h.value isa Array
        update_cols!(h.value,context_cols=context_cols,opts=opts)
    end

    return nothing
end


dom(r::String;opts=PAGE_OPTIONS)=HtmlElement("div",Dict(),1,r)
dom(r::HtmlElement;opts=PAGE_OPTIONS)=r
function dom(r::VueStruct;opts=PAGE_OPTIONS)

    opts=deepcopy(opts)
    merge!(opts.attrs,r.attrs)
    
    if r.render_func!=nothing
        domvalue=r.render_func(r)
        
        if domvalue isa Array
        elseif r.cols!=nothing
            domvalue.cols=r.cols
        end
        
        return domvalue
    else
       return dom(r.grid,opts=opts)
    end
end

function dom(r::VueJS.VueHolder;opts=PAGE_OPTIONS)

    if r.render_func!=nothing
        domvalue=r.render_func(r)
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

function dom(arr::Array;opts=PAGE_OPTIONS)

    arr_dom=[]
    i_rows=[]
    for (i,rorig) in enumerate(arr)

        r=deepcopy(rorig)

        ## update grid_data recursively
        append=false
        new_opts=deepcopy(opts)
        r isa VueStruct ? append=true : nothing
        r isa VueStruct ? new_opts.rows=true : nothing
        r isa Array ? (opts.rows ? new_opts.rows=false : new_opts.rows=true) : nothing

        domvalue=dom(r,opts=new_opts)

        grid_class=opts.rows ? "v-row" : "v-col"
        
        ## Row with single element (1 column)
        domvalue=(opts.rows && typeof(r) in [VueHolder,VueElement,HtmlElement,String]) ? HtmlElement("v-col",Dict(),domvalue.cols,domvalue) : domvalue
        
        ### New Element with row/col
        new_el=HtmlElement(grid_class,Dict(),get_cols(domvalue),domvalue)

        if ((i!=1 && i_rows[i-1]) || (opts.rows)) && append
            append!(arr_dom,domvalue)
        else
            push!(arr_dom,new_el)
        end

    push!(i_rows,opts.rows)
    end
    update_cols!(arr_dom,opts=opts)
    return arr_dom

end
