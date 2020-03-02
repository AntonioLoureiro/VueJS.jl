
function tabs(ts::Array;cols=nothing,kwargs...)
   names=[]
   elements=[]
   for t in ts
        @assert t isa Pair "tabs should use Pair of String (name of Tab) and Elements"
        push!(names,t[1])
        push!(elements,t[2])
   end
   attrs=Dict{String,Any}("names"=>names)
    for (k,v) in kwargs
       attrs[string(k)]=v 
    end
   return VueHolder("v-tabs",attrs,elements,cols,nothing)
    
end

bar(;kwargs...)=bar([];kwargs...)
function bar(elements::Vector;kwargs...)
    elements=elements==[] ? Vector{VueElement}() : elements
    @assert elements isa Vector "Elements should be vector of VueElement's/HtmlElement/String!"
    
    real_attrs=Dict(string(k)=>v for (k,v) in kwargs)
        
    ## Defaults and merge with real
    attrs=Dict("color"=>"dark-v accent-4","dense"=>true,"dark"=>true,"clipped-left"=>true)
    merge!(attrs,real_attrs)
    
   return VueHolder("v-app-bar",attrs,elements,nothing,nothing)
    
end

htmlTypes=Union{Nothing,String,HtmlElement,VueElement,VueStruct,VueJS.VueHolder}
card(text::htmlTypes;cols=3,kwargs...)=card(text=text,cols=cols;kwargs...)    
function card(;title::htmlTypes=nothing,subtitle::htmlTypes=nothing,text::htmlTypes=nothing,actions::htmlTypes=nothing,cols=3,kwargs...)
    #elements=>title,subtitle,text,actions
    
    real_attrs=Dict(string(k)=>v for (k,v) in kwargs)
    ## Defaults and merge with real
    attrs=Dict()
    merge!(attrs,real_attrs)
    
    elements=[]
    names=[]
    for (k,v) in [title=>"v-card-title",subtitle=>"v-card-subtitle",text=>"v-card-text",actions=>"v-card-actions"]
       if k!=nothing
       push!(elements,k)
       push!(names,v) 
       end
    end
    elements
    attrs["names"]=names
    
   return VueJS.VueHolder("v-card",attrs,elements,cols,nothing)
    
end