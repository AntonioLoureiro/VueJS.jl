
mutable struct htmlElement
    
    tag::String
    attrs::Dict{String,Any}
    cols::Union{Nothing,Int64}
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
