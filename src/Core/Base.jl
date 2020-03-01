HEAD=HtmlElement("head",
    [
    HtmlElement("meta", Dict("charset"=>"UTF-8")),
    HtmlElement("meta", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
    ])


    #Production scripts INCLUDE_SCRIPTS=["https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.min.js","https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.js"]
DEPENDENCIES=[dependency("https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.js","js",Dict()),
                dependency("https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.js","js",Dict()),  
                dependency("https://fonts.googleapis.com/css?family=Roboto:100,300,400,500,700,900","css",Dict()),
                dependency("https://cdn.jsdelivr.net/npm/@mdi/font@4.x/css/materialdesignicons.min.css","css",Dict()),
                dependency("https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.css","css",Dict()),
                dependency("https://s3.eu-central-1.amazonaws.com/antonio.loureiro/JS/vue2editor.umd.min.js","js",Dict("VueEditor"=>"vue2editor.components.VueEditor")),
                dependency("https://s3.eu-central-1.amazonaws.com/antonio.loureiro/JS/vue2editor.umd.min.js.map","js",Dict()),
]

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

UPDATE_VALIDATION["vue-editor"]=(x)->begin

    x.cols=6
end

# function jsLibraries!(a::Vector{String})
#     global INCLUDE_SCRIPTS=a
#     return nothing
# end

# function includeJS!(s::String)
#     push!(INCLUDE_SCRIPTS,s)
#     return nothing
# end

# function cssLibraries!(a::Vector{String})
#     global INCLUDE_STYLES=a
#     return nothing
# end

# function includeCSS!(s::String)
#     push!(INCLUDE_STYLES,s)
#     return nothing
# end
