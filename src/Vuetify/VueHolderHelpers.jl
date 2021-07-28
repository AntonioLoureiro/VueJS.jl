
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
    
    attrs["names"]=names
    
   return VueJS.VueHolder("v-card",attrs,elements,cols,nothing)
    
end

dialog(id::String,element;kwargs...)=dialog(id,[element];kwargs...)
function dialog(id::String,elements::Vector; container::Bool=true, kwargs...)
    
    real_attrs=Dict(string(k)=>v for (k,v) in kwargs)
        
    haskey(real_attrs,"active") ? (@assert real_attrs["active"] isa Bool "Value Attr in Dialog must be a Bool") : nothing
    haskey(real_attrs,"active") ? nothing : real_attrs["active"]=false
    
    ## Defaults and merge with real
    dial_attrs=Dict("persistent"=>true,"max-width"=>"2400")
    merge!(dial_attrs,real_attrs)
    
    vs_dial=VueStruct(id,elements)
    merge!(vs_dial.attrs,Dict("v-dialog"=>dial_attrs))
    vs_dial.def_data["active"]=Dict("value"=>dial_attrs["active"])    
    dial_attrs[":value"]=id*".active.value"
    
    vs_dial.render_func=(x;opts=PAGE_OPTIONS)->begin
        
        child_dom=VueJS.dom(x.grid,opts=opts)
        container_dom(child, container::Bool) = container ? VueJS.HtmlElement("v-container",Dict(),12,child) : child
        [VueJS.HtmlElement("v-dialog",get(vs_dial.attrs,"v-dialog",Dict()),12,VueJS.HtmlElement("v-card",Dict(),12,container_dom(child_dom, container)))]
    end
    
    return vs_dial
end

macro dialog(varname,els,args...)
    @assert varname isa Symbol "1st arg should be Variable name"
    
    newargs=treat_kwargs(args)
    
    newargs="Dict($(join(newargs,",")))"
    
    if length(newargs)==0
        newexpr=(Meta.parse("""VueJS.dialog("$(string(varname))",$(els))"""))
    else
        newexpr=(Meta.parse("""VueJS.dialog("$(string(varname))",$(els),$newargs)"""))
    end
    return quote
        $(esc(varname))=$(esc(newexpr))
    end
end

dialog(id::String,element,d::Dict)=dialog(id,element;Dict(Symbol(k)=>v for (k,v) in d)...)

"""
    Toolbar(elements::Vector; kwargs...) :: VueHolder

Arguments

 * style          :: Dict         :: Dict of css style elements
 * nav            :: Bool         :: Whether to display in nav mode, absolute positioning on the edges of the container 
 * bottom         :: Bool         :: When in nav mode, whether to place it at the bottom
 * floating       :: Bool         :: Whether toolbar is a floating bar. This disables nav mode.
 * collapse       :: Bool        :: Whether it's a collpsed toolbar. 
 * width          :: String       :: Bar width, default is 100%. Usage of width is prefered over cols

"""
function toolbar(elements::Vector; style::Dict=Dict(), nav::Bool=true, bottom::Bool=false, width="100%", kwargs...) :: VueJS.VueHolder
    if isempty(elements) elements = Vector{VueJS.VueElement}() end
    
    #default attrs are to be merged with real attributes
    real_attrs=Dict(string(k)=>v for (k,v) in kwargs)
    attrs = Dict{String, Any}("color"=>"primary")

    collapse = get(real_attrs, "collapse", false)
    #check if user wants a floating toolbar
    floating = get(real_attrs, "floating", false)
    if floating === true
        nav = false
    end
    #style for usage as nav
    container_style = Dict{String, Any}("position"=>"absolute", "left"=>"0", "right"=>"0")
    bottom ? container_style["bottom"] = 0 : container_style["top"] = 0
    if !collapse container_style["padding"] = "0 12px" end
    
    cols = get(real_attrs, "cols",  nothing)
    delete!(real_attrs, "cols")
    if cols isa Nothing #cols take priority over 100% width definition
        collapse ? container_style["max_width"] = width : container_style["min-width"] = width
    else
        @warn "v-toolbar | width definition is preferred over cols"
        container_style["max-width"] = "$(cols/12 * 100)%"
    end
    merge!(attrs, real_attrs)
    attrs["style"] = nav ? merge(container_style, style) : style
    
    return VueJS.VueHolder("v-toolbar", attrs, elements, cols, nothing)
end

function toolbartitle(title::String; style::Dict=Dict(), cols=4, attrs...)
    attrs      = Dict{String, Any}(string(k)=>v for (k,v) in attrs)
    base_style = Dict("padding"=>"2% 0", "color"=>"white")
    attrs["style"] = join(["$k:$v;" for (k,v) in merge(base_style, style)], " ")
    return html("v-toolbar-title", title, attrs, cols=cols)
end

function expansion_panels(panels::Vector{VueJS.VueElement}; kwargs...) ::VueJS.VueHolder
    # Treat kwargs
    attrs = Dict(string(k)=>v for (k,v) in kwargs)
    ex_panels_cols = haskey(attrs, "cols") ? attrs["cols"] : 4
    
    # define render
    render_func = (x; opts = PAGE_OPTIONS) -> begin
        res   = ""
        [res *= VueJS.htmlstring(VueJS.dom(child)) for child in x.elements ] 
        return html("v-expansion-panels", res, x.attrs, cols = x.cols)
    end
    
    return VueJS.VueHolder("v-expansion-panels", attrs, panels, ex_panels_cols, render_func)
end
expansion_panels(panel::VueJS.VueElement; kwargs...) = expansion_panels([panel]; kwargs...)