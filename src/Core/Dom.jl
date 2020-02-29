
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

function update_dom(r::VueElement)
    
    ## Bind el values
    for (k,v) in r.binds
        value=r.path=="" ? v : r.path*"."*v
        r.attrs[":$k"]=value

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
        if haskey(r.attrs,k)
            delete!(r.attrs,k)
        end
    end

    return r
end


dom_child(d;rows=true)=dom(d)
dom_child(d::HtmlElement;rows=true)=d
dom_child(d::String;rows=true)=d
dom_child(a::Array;rows=true)=dom_child.(a)
dom(d;rows=true)=d
dom(d::Dict;rows=true)=JSON.json(d)


function dom(vuel::VueElement;rows=true)
    
    vuel=update_dom(vuel)
    
    child=nothing
    ## Value attr is nothing
    if vuel.value_attr==nothing
        if haskey(vuel.attrs,"value")
            child=vuel.attrs["value"]
            delete!(vuel.attrs,"value")
        end
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


bind_child_v_for!(c)=nothing
bind_child_v_for!(c::Array)=bind_child_v_for!.(c)
function bind_child_v_for!(vuel::VueElement)
    
   vuel.binds[vuel.value_attr]="item."*vuel.id
    
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


dom(r::String;rows=true)=HtmlElement("div",Dict(),12,r)
dom(r::HtmlElement;rows=true)=r
dom(r::VueHolder;rows=true)=dom(r.elements,rows=rows)
dom(r::VueStruct;rows=true)=dom(r.grid,rows=rows)

function dom(arr::Array;rows=true)

    arr_dom=[]
    i_rows=[]
    for (i,rorig) in enumerate(arr)

        r=deepcopy(rorig)

        ## update grid_data recursively
        append=false
        new_rows=deepcopy(rows)
        r isa VueStruct ? append=true : nothing
        r isa VueStruct ? new_rows=true : nothing
        r isa Array ? (rows ? new_rows=false : new_rows=true) : nothing
        
        domvalue=dom(r,rows=new_rows)
        
        grid_rows="v-row"
        grid_cols="v-col"
        grid_class=rows ? grid_rows : grid_cols

        ## one row only must have a single col
        domvalue=(rows && typeof(r) in [VueElement,String]) ? HtmlElement(grid_cols,Dict(),domvalue.cols,domvalue) : domvalue

        cols=domvalue isa Array ? maximum(max_cols.(domvalue)) : max_cols(domvalue)

        ## New Element
        cols_attrs=rows ? Dict() : Dict(VIEWPORT=>cols)
        new_el=HtmlElement(grid_class,cols_attrs,cols,domvalue)

        if ((i!=1 && i_rows[i-1]) || (rows)) && append
            append!(arr_dom,domvalue)
        else
            push!(arr_dom,new_el)
        end

    push!(i_rows,rows)
    end
    return arr_dom

end
