
function merge_def_data!(a::Dict,b::Dict)

    for (k,v) in b
       if typeof(v)<:Dict && haskey(a,k)
          merge_def_data!(a[k],b[k])
       elseif haskey(b,k)
          b[k]==nothing ? nothing : a[k]=b[k]
            if !haskey(a,k)
                a[k]=b[k]
            end
       end
    end
    
end


function update_data!(el::VueElement,datavalue)
   
    real_data=nothing
    def_data=Dict{String,Any}()
    for (k,v) in el.binds
        
        if haskey(el.dom.attrs,k)   
           real_data=deepcopy(el.dom.attrs[k])
        end
        
        if k==el.value_attr && datavalue!=nothing
           real_data=datavalue
        end
        
        def_data[k]=real_data
        
    end
    
    el.data=def_data
    return Dict(el.id=>def_data)
end

function update_data!(arr::Array,datavalue::Dict)
    
    def_data=Dict{String,Any}()
    for r in arr
        
        if typeof(r)==VueElement
            
            founddata=haskey(datavalue,r.id) ? datavalue[r.id] : nothing
            
        elseif typeof(r)==VueComponent
            
            founddata=haskey(datavalue,r.id) ? datavalue[r.id] : Dict{String,Any}()
            
        else
            founddata=datavalue
        end
                
        got_data=update_data!(r,founddata)
        merge!(def_data,got_data)
    end
    
    return def_data
end

function update_data!(el::VueComponent,datavalue=Dict{String,Any}())
    
    new_data=deepcopy(el.data)
    new_def_data=deepcopy(el.def_data)
    
    merge!(new_data,datavalue)
    updated_data=update_data!(el.grid,new_data)
    VueJS.merge_def_data!(new_def_data,updated_data)

    el.data=new_data
    el.def_data=new_def_data
    
    return Dict(el.id=>new_def_data)
end

