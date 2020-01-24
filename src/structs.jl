
mutable struct htmlElement
    
    tag::String
    attrs::Dict{String,Any}
    value
    
end

htmlString(s::String)=s
htmlString(n::Nothing)=nothing
htmlString(a::Vector)=join(htmlString.(a))

function htmlString(el::htmlElement)
    tag=el.tag
    attrs=join([typeof(v)==Bool ? " $k" : " "*k*"=\""*string(v)*"\"" for (k,v) in el.attrs])
    value=htmlString(el.value)
    
    if value==nothing
       return """<$tag$attrs/>"""
    else
        return """<$tag$attrs>$value</$tag>""" 
    end
    
end


mutable struct page
    
    head::htmlElement
    include_scripts::Array
    include_styles::Array
    body::htmlElement
    scripts::String
    
end

mutable struct VueElement
    
    id::String
    dom::htmlElement
    path::String
    binds::Vector{String}
    scriptels::Vector{String}
    value_attr::String
    cols::Int64
    
end
 

mutable struct VueComponent
    
     id::String
     grid::Array
     binds::Dict{String,String}
     scriptels::Vector{String}
     cols::Int64
     data::Dict{String,Any}
     def_data::Dict{String,Any}
     
end

