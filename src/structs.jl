mutable struct page
    
    head::Dict{String,Any}
    include_scripts::Array
    include_styles::Array
    body::Dict{String,Any}
    scripts::String
    
end

mutable struct VueElement
    
    tag::Symbol
    id::Symbol
    cols::Int64
    dom::Dict{String,Any}
    script::String
    
end


function el(tag::Symbol,id::Symbol;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    haskey(args,"cols") ? cols=args["cols"] : cols=3
    haskey(args,"value") ? value=args["value"] : value=nothing
    
    dataDict=Dict("data"=>Dict(string(id)=>value))
    script="""new Vue({
    el: '#$(id)',
    $(JSON.json(dataDict))
    })"""
    
    VueJS.VueElement(tag,id,cols,args,script)
    
end