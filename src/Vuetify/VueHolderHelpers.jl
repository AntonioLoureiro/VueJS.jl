
spacer(;cols=1,rows=1)=VueJS.VueElement("","v-spacer",Dict("cols"=>cols,"content"=>join(fill("<br>",rows-1))))

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
    
    vh=VueHolder("v-app-bar",attrs,elements,nothing,nothing)
    
    vh.render_func=(x;opts=PAGE_OPTIONS)->HtmlElement(x.tag,x.attrs,12,map(e->deepcopy(dom(e)),x.elements))
    
   return vh
    
end

card(text::htmlTypes;cols=nothing,kwargs...)=card(text=[text],cols=cols;kwargs...) 
card(text::Vector;cols=nothing,kwargs...)=card(text=text,cols=cols;kwargs...) 
function card(;title=nothing,subtitle=nothing,text=nothing,actions::htmlTypes=nothing,cols=nothing,kwargs...)
    #elements=>title,subtitle,text,actions

    real_attrs=Dict(string(k)=>v for (k,v) in kwargs)
    ## Defaults and merge with real
    attrs=Dict()
    merge!(attrs,real_attrs)
    
    elements=[]
    names=[]
    for (k,v) in [title=>"v-card-title",subtitle=>"v-card-subtitle",text=>"v-card-text",actions=>"v-card-actions"]
       if k!=nothing
       assert_html_types(k)
       push!(elements,k)
       push!(names,v) 
       end
    end
    elements
    attrs["names"]=names
    
   return VueJS.VueHolder("v-card",attrs,elements,cols,nothing)
    
end

dialog(id::String,element;kwargs...)=dialog(id,[element];kwargs...)
function dialog(id::String,elements::Vector;kwargs...)
    
    real_attrs=Dict(string(k)=>v for (k,v) in kwargs)
        
    haskey(real_attrs,"active") ? (@assert real_attrs["active"] isa Bool "Value Attr in Dialog must be a Bool") : nothing
    haskey(real_attrs,"active") ? nothing : real_attrs["active"]=false
    
    ## Defaults and merge with real
    maxwidth = get(real_attrs, "maxwidth", 600)
    delete!(real_attrs, "maxwidth")
    dial_attrs=Dict("persistent"=>true,"max-width"=>string(maxwidth))
    merge!(dial_attrs,real_attrs)
    
    vs_dial=VueStruct(id,elements)
    vs_dial.def_data["active"]=Dict("value"=>dial_attrs["active"])    
    dial_attrs[":value"]=id*".active.value"
    
    vs_dial.render_func=(x;opts=PAGE_OPTIONS)->begin
        
        child_dom=VueJS.dom(x.grid,opts=opts)
        [HtmlElement("v-dialog",dial_attrs,12,HtmlElement("v-card",Dict(),12,HtmlElement("v-container",Dict(),12,child_dom)))]
    end
    
    return vs_dial
end
