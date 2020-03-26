
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
       if !startswith(k,"@") && v isa AbstractString && occursin("item.",v)
            new_d[":$k"]=v
       else
            new_d["$k"]=v  
       end
    end
    
    r.attrs=new_d
    return r
end


function update_dom(r::VueElement)
    
    ## Update @path@
    for (k,v) in r.attrs
        if k in DIRECTIVES
            r.attrs[k]=replace(v,"@path@"=>(r.path=="" ? "" : "$(r.path)."))
        end
    end
    
    ### Dom Events =>@ ####
    events=intersect(keys(r.attrs),KNOWN_JS_EVENTS)
    for e in events
        event_js=r.attrs[e]
        delete!(r.attrs,e)
        r.attrs["@$e"]=event_js
    end

    
    ## Bind element values to js (only if not template)
    if r.template==false
        for (k,v) in r.binds
            value=r.path=="" ? v : r.path*"."*v
            ## bind to target (small white list )
            k in DIRECTIVES ? r.attrs[k]=value : r.attrs[":$k"]=value
            
            ### Capture Event if tgt=src otherwise double count or if value is value attr
            if r.id*"."*k==v || r.id*".value"==v

                ## And only if value attr! Others do not change on input! I Think!
                if r.value_attr==k
                    event=r.value_attr=="value" ? "@input" : "@change"
                    if haskey(r.attrs,event)
                        r.attrs[event]=r.attrs[event]*"; "*"$value= \$event;"
                    else
                        r.attrs[event]="$value= \$event"
                    end
                end
            end
            ### delete attribute from dom
            if haskey(r.attrs,k) && !(k in DIRECTIVES)
                delete!(r.attrs,k)
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
dom(d;opts=Opts())=d
dom(d::Dict;opts=Opts())=JSON.json(d)


function dom(vuel_orig::VueElement;opts=Opts(),prevent_render_func=false)
    
    vuel=deepcopy(vuel_orig)
    if vuel.render_func!=nothing && prevent_render_func==false
       return vuel.render_func(vuel)
    end
    
    ### Update Dom Events ## Scope Issue
    for (k,v) in vuel.attrs
        if k in KNOWN_JS_EVENTS
            new_js=v
            for o in opts.closure_funcs
                if new_js==o
                   new_js="app."*o
                else
                    new_js=replace(new_js,o*"("=>"app.$o(")
                end
            end
            new_js=""" run_in_closure("$(vuel.path)", ()=>$new_js) """
            vuel.attrs[k]=new_js
        end
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
        vuel.cols=3
        cols=3
    else
        cols=vuel.cols
    end
   
   if vuel.child!=nothing
       child=vuel.child
   else
       child=child==nothing ? "" : child
   end
    
    child_dom=dom_child(child)
    
    child_dom=child_path(child_dom,vuel.path)
    
   return HtmlElement(vuel.tag, vuel.attrs, cols, child_dom)
end


function max_cols(v::HtmlElement)

    if v.tag=="v-row"
        return v.value isa Array ? sum(map(x->max_cols(x),v.value)) : max_cols(v.value)
    elseif v.tag=="v-col"
        return v.value isa Array ? maximum(map(x->max_cols(x),v.value)) : max_cols(v.value)
    else
        return v.cols
    end
end

update_cols!(h::Array;context_cols=12)=update_cols!.(h;context_cols=context_cols)
function update_cols!(h::HtmlElement;context_cols=12)
    
    if h.tag=="v-row"
        update_cols!(h.value,context_cols=context_cols)
    elseif h.tag=="v-col"
        cols=h.value isa Array ? maximum(max_cols.(h.value)) : max_cols(h.value)
        h.attrs[VIEWPORT]=Int(round(cols/context_cols*12))
        update_cols!(h.value,context_cols=cols)
    end
    
    return nothing
end

dom(r::String;opts=Opts())=HtmlElement("div",Dict(),12,r)
dom(r::HtmlElement;opts=Opts())=r
function dom(r::VueStruct;opts=Opts())
    
    closure_funcs=filter(r->!(r in ["run_in_closure"]),map(id->id.id,filter(m->m.kind=="methods",r.events)))
    append!(closure_funcs,opts.closure_funcs)
    opts.closure_funcs=unique(closure_funcs)
    
    if r.render_func!=nothing
       return r.render_func(r)
    else
       return dom(r.grid,opts=opts)
    end
end

function dom(r::VueJS.VueHolder;opts=Opts())
    
    if r.render_func==nothing
        return HtmlElement(r.tag,r.attrs,r.cols,map(x->deepcopy(dom(x)),r.elements))
    else
        return r.render_func(r)
    end
end

function dom(arr::Array;opts=Opts())

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

        ## one row only must have a single col
        domvalue=(opts.rows && typeof(r) in [VueHolder,VueElement,HtmlElement,String]) ? HtmlElement("v-col",Dict(),domvalue.cols,domvalue) : domvalue
        
        ## New Element
        new_el=HtmlElement(grid_class,Dict(),domvalue isa Array ? maximum(max_cols.(domvalue)) : max_cols(domvalue),domvalue)
        
        if ((i!=1 && i_rows[i-1]) || (opts.rows)) && append
            append!(arr_dom,domvalue)
        else
            push!(arr_dom,new_el)
        end

    push!(i_rows,opts.rows)
    end
    update_cols!(arr_dom)
    return arr_dom

end
