Base.@kwdef mutable struct WebDependency
    name::String
    path::String
    version::String                 = ""
    type::String                    = extension(path)
    components::Dict{String,String} = Dict{String, String}()
    directives::Dict{String,String} = Dict{String, String}()    
    init_script::String             = ""
    css::String                     = ""
    sha::String                     = ""
    local_path::String              = ""
end
WebDependency(x::Dict) = WebDependency(get(x, "name", basename(x["url"])), 
                    x["url"], 
                    x["version"], 
                    get(x, "type", extension(basename(x["url"]))), 
                    get(x,"components",Dict()),
                    get(x,"directives",Dict()),
                    get(x,"init_script",""),
                    get(x,"css",""), 
                    "", 
                    get(x, "path", ""))
    
mutable struct Page
    dependencies::Vector{WebDependency}
    components::Dict{String,Any}
    scripts::Vector{String}
    cookiejar::Dict{String, Any}
    globals::Dict{String, Any}
    meta::Vector{HtmlElement}
    title::Union{String, Nothing}
end
Page(deps, comps, scripts) = return Page(deps, comps, scripts, Dict{String, Any}(), Dict{String, Any}(), META, nothing)

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
"""
function page(
    garr::Union{Array,VueHolder};
    binds=Dict{String,String}(),
    data=Dict{String,Any}(),
    methods=Dict{String,Any}(),
    asynccomputed=Dict{String,Any}(),
    computed=Dict{String,Any}(),
    watch=Dict{String,Any}(),
    style=Dict{String,Any}(),
    class=Dict{String,Any}(),
    scripts=[],
    cookies=Dict{String,Any}(),
    globals=Dict{String, Any}(),
    meta::Vector{HtmlElement}=META,
    title::Union{String, Nothing}=nothing,
    navigation::Union{VueElement,Nothing}=nothing,
    bar::Union{VueHolder,Nothing}=nothing,
    sysbar::Union{VueElement, Nothing}=nothing,
    footer::Union{VueElement, Nothing}=nothing,
    bottom::Union{VueElement, Nothing}=nothing,
    kwargs...)
    
    cont=VueStruct("app",garr,data=data,binds=binds,methods=methods,asynccomputed=asynccomputed,computed=computed,watch=watch,style=style,class=class;kwargs...)

    return page(cont, navigation=navigation, bar=bar, sysbar=sysbar, footer=footer, bottom=bottom, scripts=scripts, cookies=cookies, globals=globals, meta=meta, title=title)
end

function page(
        cont::VueStruct;
        scripts=[],
        cookies=Dict{String,Any}(),
        globals=Dict{String, Any}(),
        meta::Vector{HtmlElement}=META, 
        title::Union{String, Nothing}=nothing,   
        sysbar::Union{VueElement, Nothing}=nothing,
        bar::Union{VueHolder,Nothing}=nothing,
        navigation::Union{VueElement,Nothing}=nothing,
        footer::Union{VueElement, Nothing}=nothing,
        bottom::Union{VueElement, Nothing}=nothing)

    @assert cont.iterable==false "Cannot use a iterable VueStruct at top level, please put in inside an array (grid)"
    components=Dict{String,Any}("v-main"=>cont)

    if sysbar != nothing      components["v-system-bar"]        = sysbar     end
    if bar != nothing         components["v-app-bar"]           = bar        end
    if navigation != nothing  components["v-navigation-drawer"] = navigation end
    if footer != nothing      components["v-footer"]            = footer     end
    if bottom != nothing      components["v-bottom-navigation"] = bottom     end

    page_inst=Page(
            DEPENDENCIES,
            components,
            scripts,
            cookies,
            globals,
            meta,
            title)

    return page_inst
end

function response(page::Page)
    response = HTTP.Response(200, htmlstring(page))
    if length(page.cookiejar) > 0
        [HTTP.Messages.appendheader(response, SubString("Set-Cookie")=>SubString("$k=$v"))
            for (k,v) in page.cookiejar]
    end
    return response
end
