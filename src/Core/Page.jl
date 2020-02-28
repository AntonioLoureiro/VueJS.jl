struct WebDependency
    path::String
    kind::String
    components::Dict{String,String}
end

dependency(path::String,kind::String,components::Dict)=WebDependency(path,kind,components)

"""
```julia
@el(example,"v-text-field",value="Example Value",label="Example label",rules=["v => v.length >= 8 || 'Min 8 characters'"])
body=HtmlElement("body",
        HtmlElement("div",Dict("id"=>"app"),
            HtmlElement("v-app",
                HtmlElement("v-container",Dict("fluid"=>true),[example]))))


page_inst=Page(
        deepcopy(HEAD),
        [],
        INCLUDE_STYLES,
        body,
        "")

htmlpage=HtmlElement("html",[page_inst.head,page_inst.body])

@show htmlstring([htmlpage])
```

"""
mutable struct Page
    head::HtmlElement
    dependencies::Vector{WebDependency}
    components::Dict{String,Any}
    scripts::Vector{String}
end


"""
Build HTML page, inclunding <head>, <body>, <scripts> and vuetify's initialization

Constructs a VueStruct from `garr`, `data`, `binds` and `methods` arguments.
Defines vue's `app` scripts.
(...)

### Methods

Methods are functions associated with a Vue instance and are defined inside the `methods` property.
Methods accept parameters, which can be passed directly from elements in a template.
Methods will behave like regular Javascript and will only evaluate when explicity called. Also,
unlike `computed properties`, a method call will always re-execute the script.

[`VueJS Events and Event Handlers`](https://v1.vuejs.org/guide/events.html)

### Computed

These properties are useful for composing data from already existing sources, e.g., display a user full name
from two separate `firstName` and `lastName` fields.
These properties are reactive and bound to other properties and/or dom elements.
Computed properties are cached based on their reactive dependencies, meaning they will only re-evaluate
when any of its dependencies changes.

[`VueJS Computed properties`](https://vuejs.org/v2/guide/computed.html)

### Watcher

"Watchers are most useful when performing asynchronous operations in response to changing data"

[`VueJS Computed Properties and Watchers`](https://vuejs.org/v2/guide/computed.html)


### Arguments

 * garr             :: Array        :: `Grid array`, array of elements to be created and displayed
 * binds            :: Dict         ::
 * methods          :: Dict         :: Collection of functions to associate with a Vue instance
 * computed         :: Dict         :: Collection of computed properties
 * watched          :: Dict         :: Collection of watchers
 * kwargs           :: Any          :: Keyword arguments

### Examples
```julia

```
"""
function page(
    garr::Array;
    binds=Dict{String,String}(),
    data=Dict{String,Any}(),
    methods=Dict{String,Any}(),
    computed=Dict{String,Any}(),
    watched=Dict{String,Any}(),
    navigation::Union{VueElement,Nothing}=nothing,
    bar::Union{VueElement,Nothing}=nothing,
    sysbar::Union{VueElement, Nothing}=nothing,
    footer::Union{VueElement, Nothing}=nothing,
    bottom::Union{VueElement, Nothing}=nothing,
    kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    scripts=haskey(args,"scripts") ? args["scripts"] : []
    cont=VueStruct("app",garr,data=data,binds=binds,methods=methods,computed=computed,watched=watched)

    return page(cont::VueStruct, navigation=navigation, bar=bar, sysbar=sysbar, footer=footer, bottom=bottom, kwargs...)
end

function page(
        cont::VueStruct;
        sysbar::Union{VueElement, Nothing}=nothing,
        bar::Union{VueElement,Nothing}=nothing,
        navigation::Union{VueElement,Nothing}=nothing,
        footer::Union{VueElement, Nothing}=nothing,
        bottom::Union{VueElement, Nothing}=nothing,
        kwargs...)
    
    components=Dict{String,Any}("v-content"=>cont)

    args=Dict(string(k)=>v for (k,v) in kwargs)
    scripts=haskey(args,"scripts") ? args["scripts"] : []

    sysbar!=nothing ? components["v-system-bar"]=sysbar : nothing
    bar!=nothing ? components["v-app-bar"]=bar : nothing
    navigation!=nothing ? components["v-navigation-drawer"]=navigation : nothing
    footer!=nothing ? components["v-footer"]=footer : nothing
    bottom!=nothing ? components["v-bottom-navigation"] : nothing

    page_inst=Page(
            deepcopy(HEAD),
            DEPENDENCIES,
            components,
            scripts)

    return page_inst
end

function response(page::Page)

    return HTTP.Response(200,htmlstring(page))
end
