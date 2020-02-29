mutable struct VueHolder

    tag::String
    attrs::Dict{String, Any} 
    elements::Array
    cols::Union{Nothing,Int64}
    render_func::Union{Nothing,Function}
    
    function VueHolder(tag::String,attrs::Dict,elements::Array,cols::Union{Nothing,Int64},render_func::Union{Nothing,Function})
        vueh=new(tag,attrs,elements,cols,render_func)
        
        if haskey(UPDATE_VALIDATION, tag)
            UPDATE_VALIDATION[tag](vueh)
        end
    
        return vueh
    end
    
end

function tabs(elements::Array,names::Array;cols=nothing,kwargs...)
    
   attrs=Dict{String,Any}("names"=>names)
    for (k,v) in kwargs
       attrs[string(k)]=v 
    end
   return VueJS.VueHolder("v-tabs",attrs,elements,cols,nothing)
    
end