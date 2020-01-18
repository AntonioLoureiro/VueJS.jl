function grid(arr::Array; rows=true)
    arr_dom=[]
    elements=[]
    def_data=Dict{String,Any}()
    scriptels=[]
    
#     arr_cols=WebTools.getcols(arr,rows)
    
#     tot=sum(arr_cols)
#     if tot>12
#         arr_cols=Int.(round.(arr_cols./tot*12,digits=0))
#         idx=findmax(arr_cols)[2]
#         arr_cols[idx]=arr_cols[idx]-1
#     end
    
    for (i,rorig) in enumerate(arr)
       
        r=deepcopy(rorig)
        if typeof(r)==VueElement
           domvalue=r.dom
           push!(elements,r.id=>r)
           
            #data
            if length(r.binds)!=0
                for (k,v) in r.binds
                    
                    if haskey(r.dom.attrs,k) 
                        datavalue=r.dom.attrs[k]
                        delete!(r.dom.attrs,k)
                    else
                        datavalue=""
                    end
                    def_data[v]=datavalue
                end
            end
        elseif typeof(r)==VueComponent
            domvalue=r.dom
            push!(elements,r.id=>r)
            push!(scriptels,r.script)
        elseif typeof(r)<:Array
            grid_nt=grid(r,rows=(rows ? false : true))
            domvalue=grid_nt.dom
            append!(elements,grid_nt.elements)
            append!(scriptels,grid_nt.scriptels)
            merge!(def_data,grid_nt.def_data)
            
        else
            error("$r with invalid type for Grid!")
        end
        
        grid_class=rows ? "v-row" : "v-col"
        new_el=htmlElement(grid_class,Dict(),domvalue)
        push!(arr_dom,new_el)
           
    end
    
    return (dom=arr_dom,elements=elements,def_data=def_data,scriptels=scriptels)

end
