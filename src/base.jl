HEAD=HtmlElement("head",
    [
    HtmlElement("meta", Dict("charset"=>"UTF-8")),
    HtmlElement("meta", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
    ])

    INCLUDE_SCRIPTS=["https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.min.js","https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.js"]
    INCLUDE_STYLES=["https://fonts.googleapis.com/css?family=Roboto:100,300,400,500,700,900","https://cdn.jsdelivr.net/npm/@mdi/font@4.x/css/materialdesignicons.min.css",
    "https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.css"]

    FRAMEWORK="vuetify"
    VIEWPORT="md"

const KNOWN_JS_EVENTS = ["click", "mouseover", "mouseenter", "change"]

using Base

#=
HTMLElement interfaces
=#
Base.getproperty(el::HtmlElement, prop::String) = Base.getproperty(el, Symbol(prop))
function Base.getproperty(el::HtmlElement, prop::Symbol)
    return getfield(el, prop)
end
#=
VueElement interfaces
=#
function Base.getindex(v::VueElement, i::String)
    if i in string.(fieldnames(typeof(v.dom)))
        return getproperty(v.dom, Symbol(i))
    end
end
