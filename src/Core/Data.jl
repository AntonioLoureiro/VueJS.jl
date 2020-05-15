
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

update_data!(el,datavalue)=Dict()
function update_data!(el::VueHolder,datavalue,name::String)
     ret=Dict()   
     for e in el.elements
         merge!(ret,update_data!(e,datavalue))
    end
    return Dict(name=>ret)
end

function update_data!(el::VueElement,datavalue)

    def_data=Dict{String,Any}()
    for (k,v) in el.binds
        real_data=nothing
        new_k=vue_escape(deepcopy(k))
        
        ## get data from attr
        haskey(el.attrs,k) ? real_data=deepcopy(el.attrs[k]) : nothing
        
        if k==el.value_attr
            new_k="value"
            if datavalue!=nothing
               real_data=datavalue
            end
        end

        def_data[new_k]=real_data
    end
    el.data=def_data
    if el.id==""
        return Dict() 
    else
        return Dict(el.id=>def_data)
    end
end

function update_data!(arr::Array,datavalue::Dict)

    def_data=Dict{String,Any}()
    for r in arr
        if r isa VueElement
            founddata=haskey(datavalue,r.id) ? datavalue[r.id] : nothing
        elseif r isa VueStruct
            founddata=haskey(datavalue,r.id) ? datavalue[r.id] : Dict{String,Any}()
        else
            founddata=datavalue
        end

        if !(r isa String)
            got_data=update_data!(r,founddata)
            merge!(def_data,got_data)
        end
    end
    return def_data
end

function update_data!(el::VueStruct,datavalue::Union{Dict{String,T},Vector{Dict{String,T}}}) where T<:Any

    new_data=deepcopy(el.data)
    new_def_data=deepcopy(el.def_data)

    if el.iterable
        el=deepcopy(el)
        updated_data=Vector{Dict{String,Any}}()
        if length(new_data)==0 
            new_data=[Dict{String,Any}()]
            length(datavalue)==0 ? datavalue=[Dict{String,Any}()] : nothing
        end
                
        for (i,r) in enumerate(new_data)
            if length(datavalue)>=i
                merge!(new_data[i],datavalue[i])            
            end
            found_data=update_data!(el.grid,new_data[i])
            push!(updated_data,found_data)
        end
        
        if length(new_def_data)==length(updated_data)
            VueJS.merge_def_data!.(new_def_data,updated_data)
        else
            new_def_data=updated_data
        end
        
        el.data=new_data
        el.def_data=new_def_data
        
        return Dict(el.id=>new_def_data)
    else
        merge!(new_data,datavalue)
        updated_data=update_data!(el.grid,new_data)

        VueJS.merge_def_data!(new_def_data,updated_data)

        ## Delete empty elements
        for (k,v) in new_def_data
            v==Dict() ? delete!(new_def_data,k) : nothing
        end

        el.data=new_data
        el.def_data=new_def_data 
        
        return Dict(el.id=>new_def_data)
    end
end


update_data!(vueh::VueHolder,datavalue::Dict)=update_data!(vueh.elements,datavalue)