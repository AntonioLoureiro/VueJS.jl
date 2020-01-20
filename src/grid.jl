
function grid_data!(r,rows::Bool,grid_data::Dict,scope::Array)
    append=false
    ## Vue Element
        if typeof(r)==VueElement
           domvalue=r.dom
                      
            #data binding
            if length(r.binds)!=0
                for (k,v) in r.binds
                    
                    scope_str=length(scope)!=0 ? join(scope,".")*"." : ""
                    
                    r.dom.attrs[":$k"]=scope_str*v
                    r.dom.attrs["@input"]="$(scope_str*v) = \$event.target.$k"
    
                    if haskey(r.dom.attrs,k) 
                        datavalue=r.dom.attrs[k]
                        delete!(r.dom.attrs,k)
                    else
                        datavalue=""
                    end
                    grid_data["def_data"][v]=datavalue
                end
                
            end
            
        ## Vue Component
        elseif typeof(r)==VueJS.VueComponent
            push!(scope,r.id)
            grid_child=grid(r.grid,rows=true,scope=scope)
            domvalue=grid_child["arr_dom"]        
            append!(grid_data["scriptels"],grid_child["scriptels"])
            grid_data["def_data"][r.id]=grid_child["def_data"]
            append=true
        
        ## Array Elements/Components
        elseif typeof(r)<:Array
            grid_child=grid(r,rows=(rows ? false : true))
            domvalue=grid_child["arr_dom"]
            append!(grid_data["scriptels"],grid_child["scriptels"])
            merge!(grid_data["def_data"],grid_child["def_data"])
            
        else
            
            error("$r with invalid type for Grid!")
        end
        
    return (append,domvalue)
end


function update_def_data!(def_data::Dict,data::Dict)
    
    for (k,v) in def_data
        
        if typeof(v)<:Dict
            if haskey(data,k)
                update_def_data!(def_data[k],data[k])
            end
        else
            haskey(data,k) ? def_data[k]=data[k] : nothing
        end
        
    end
    
end

function grid(arr::Array; rows=true,scope=[])
    
    grid_data=Dict("arr_dom"=>[],"def_data"=>Dict{String,Any}(),"scriptels"=>[])
    
    i_rows=[]
    for (i,rorig) in enumerate(arr)
       
        r=deepcopy(rorig)
        
        ## update grid_data recursively
        (append,domvalue)=grid_data!(r,rows,grid_data,scope)  
     
        grid_class=rows ? "v-row" : "v-col"
        new_el=htmlElement(grid_class,Dict(),domvalue)
        
        if ((i!=1 && i_rows[i-1]) || (rows)) && append
        append!(grid_data["arr_dom"],domvalue)
        else
        push!(grid_data["arr_dom"],new_el)
        end
           
    push!(i_rows,rows)
    end
    
    return grid_data

end