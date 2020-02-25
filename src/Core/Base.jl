HEAD=HtmlElement("head",
    [
    HtmlElement("meta", Dict("charset"=>"UTF-8")),
    HtmlElement("meta", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
    ])

    #Production scripts INCLUDE_SCRIPTS=["https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.min.js","https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.js"]
    INCLUDE_SCRIPTS=["https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.js","https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.js","https://cdn.jsdelivr.net/npm/tiptap-vuetify"]
    INCLUDE_STYLES=["https://fonts.googleapis.com/css?family=Roboto:100,300,400,500,700,900","https://cdn.jsdelivr.net/npm/@mdi/font@4.x/css/materialdesignicons.min.css",
    "https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.css"]

    FRAMEWORK="vuetify"
    VIEWPORT="md"

const KNOWN_JS_EVENTS = ["click", "mouseover", "mouseenter", "change"]

const JS_FUNCTION_ATTRS=["rules", "filter","col_render"]

LIBRARY_RULES =
    Dict("maxchars"=> (x->return """ value => value.length <= $x || 'Max $x characters' """),
         "minchars"=> (x->return """ value => value.length > $x  || 'Min $x characters' """),
         "required"=> (x->return " value => !!value || 'Required' "),
         "min"=>(x->return " value => value >= $x || 'Minimum  value is $x' "),
         "max"=>(x->return " value => value <= $x || 'Maximum  value is $x' "),
         "type"=>(x->return "value => typeof(value) === '$x' || 'Please provide a $x'"),
         "in"=>(x->return """ value => $x.includes(value) || 'Value not in $x' """)
    )

const UPDATE_VALIDATION=Dict{String,Any}()

function includeJS!(a::Vector{String})
    global INCLUDE_SCRIPTS=a
    return nothing
end

function includeCSS!(a::Vector{String})
    global INCLUDE_STYLES=a
    return nothing
end
