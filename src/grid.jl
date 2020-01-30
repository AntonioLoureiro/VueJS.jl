
function grid(arr::Array;rows=true)

    arr_dom=[]

    i_rows=[]
    for (i,rorig) in enumerate(arr)

        r=deepcopy(rorig)

        ## update grid_data recursively
        append=false

        ## Vue Element
            if typeof(r)==VueElement

            ## Bind el values
                for (k,v) in r.binds
                    value=r.path=="" ? v : r.path*"."*v
                    r.dom.attrs[":$k"]=value
                    if haskey(r.dom.attrs,"@input")
                        r.dom.attrs["@input"]=r.dom.attrs["@input"]*"; "*"$value= \$event;"
                    else
                        r.dom.attrs["@input"]="$value= \$event"
                    end

                    if haskey(r.dom.attrs,k)
                        delete!(r.dom.attrs,k)
                    end

                end

               domvalue=r.dom

            ## Vue Component
            elseif typeof(r)==VueComponent
                append=true
                domvalue=grid(r.grid,rows=true)

            ## Array Elements/Components
            elseif typeof(r)<:Array
                domvalue=grid(r,rows=(rows ? false : true))

        else
            error("$r with invalid type for Grid!")
        end

        grid_rows="v-row"
        grid_cols="v-col"
        grid_class=rows ? grid_rows : grid_cols

        ## one row only must have a single col
        domvalue=(rows && typeof(r)==VueElement) ? HtmlElement(grid_cols,Dict(),domvalue) : domvalue
        new_el=HtmlElement(grid_class,Dict(),domvalue)
        if ((i!=1 && i_rows[i-1]) || (rows)) && append
        append!(arr_dom,domvalue)
        else
        push!(arr_dom,new_el)
        end

    push!(i_rows,rows)
    end
    return arr_dom

end
