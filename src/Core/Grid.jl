function max_cols(v::HtmlElement)

    if v.tag=="v-row"
        return v.value isa Array ? sum(map(x->max_cols(x),v.value)) : max_cols(v.value)
    elseif v.tag=="v-col"
        return v.value isa Array ? maximum(map(x->max_cols(x),v.value)) : max_cols(v.value)
    else
        return v.cols
    end
end


function grid(arr::Array;rows=true)

    arr_dom=[]
    i_rows=[]
    for (i,rorig) in enumerate(arr)

        r=deepcopy(rorig)

        ## update grid_data recursively
        append=false

            ## Vue Element
            if r isa VueElement
               domvalue=update_dom(r)
            ## VueStruct
            elseif r isa VueStruct
                append=true
                domvalue=grid(r.grid,rows=true)

            ## Array Elements/Components
            elseif r isa Array
                domvalue=grid(r,rows=(rows ? false : true))
            elseif r isa HtmlElement
                domvalue=r
            elseif r isa String
                domvalue=HtmlElement("div",Dict(),12,r)
            else
                error("$r with invalid type for Grid!")
            end

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
