
function grid(arr::Array;binds=Dict{String,String}(),rows=true,scope=[],data=Dict(),def_data=Dict{Any,Any}())
    
    arr_dom=[]
    
    i_rows=[]
    for (i,rorig) in enumerate(arr)
       
        r=deepcopy(rorig)
        
        ## update grid_data recursively
        append=false
        
        ## Vue Element
            if typeof(r)==VueElement
                              
               domvalue=r.dom

            ## Vue Component
            elseif typeof(r)==VueJS.VueComponent
                push!(scope,r.id)
                append=true
                (domvalue,def_data_child)=grid(r.grid,rows=true,scope=scope,data=(haskey(data,r.id) ? data[r.id] : Dict()))
                def_data=convert(Dict{Any,Any},def_data)
                def_data[r.id]=def_data_child

            ## Array Elements/Components
            elseif typeof(r)<:Array
                def_data=convert(Dict{Any,Any},def_data)
                (domvalue,def_data)=grid(r,rows=(rows ? false : true),data=data,def_data=def_data)
                      
        else
            
            error("$r with invalid type for Grid!")
        end
   
        grid_rows="v-row"
        grid_cols="v-col"
        grid_class=rows ? grid_rows : grid_cols
        
        ## one row only must have a single col
        
        domvalue=(rows && typeof(r)==VueElement) ? htmlElement(grid_cols,Dict(),domvalue) : domvalue
        new_el=htmlElement(grid_class,Dict(),domvalue)
        
        if ((i!=1 && i_rows[i-1]) || (rows)) && append
        append!(arr_dom,domvalue)
        else
        push!(arr_dom,new_el)
        end
           
    push!(i_rows,rows)
    end

    def_data=convert(Dict{Any,Any},def_data)
    return (arr_dom,def_data)

end
