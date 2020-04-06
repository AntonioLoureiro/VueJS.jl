HEAD=HtmlElement("head",
    [
    HtmlElement("meta", Dict("charset"=>"UTF-8")),
    HtmlElement("meta", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
    ])


    #Production scripts INCLUDE_SCRIPTS=["https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.min.js","https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.js"]
DEPENDENCIES=[
                WebDependency("https://cdn.jsdelivr.net/npm/vue@2.x/dist/vue.js","js",Dict()),
                WebDependency("https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.js","js",Dict()),
                WebDependency("https://fonts.googleapis.com/css?family=Roboto:100,300,400,500,700,900","css",Dict()),
                WebDependency("https://cdn.jsdelivr.net/npm/@mdi/font@4.x/css/materialdesignicons.min.css","css",Dict()),
                WebDependency("https://cdn.jsdelivr.net/npm/vuetify@2.x/dist/vuetify.min.css","css",Dict()),
                WebDependency("https://cdnjs.cloudflare.com/ajax/libs/handsontable/6.2.2/handsontable.full.min.css","css",Dict()),
                WebDependency("https://s3.eu-central-1.amazonaws.com/antonio.loureiro/JS/vue2editor.umd.min.js","js",Dict("VueEditor"=>"vue2editor.components.VueEditor")),
                WebDependency("https://s3.eu-central-1.amazonaws.com/antonio.loureiro/JS/vue2editor.umd.min.js.map","js",Dict()),
                WebDependency("https://cdnjs.cloudflare.com/ajax/libs/handsontable/6.2.2/handsontable.full.min.js","js",Dict()),
                WebDependency("https://cdn.jsdelivr.net/npm/@handsontable/vue/dist/vue-handsontable.min.js","js",Dict("HotTable"=>"Handsontable.vue.HotTable")),
                WebDependency("https://cdn.jsdelivr.net/npm/echarts@4.1.0/dist/echarts.js","js",Dict()),
                WebDependency("https://cdn.jsdelivr.net/npm/vue-echarts@4.0.2","js",Dict("vuechart"=>"VueECharts"))
            ]

FRAMEWORK="vuetify"
VIEWPORT="md"

const DIRECTIVES=["v-html","v-text","v-for","v-if","v-on","v-style"]

const KNOWN_JS_EVENTS = ["input","click", "mouseover", "mouseenter", "change"]
const CONTEXT_JS_FUNCTIONS=["submit"]
const JS_FUNCTION_ATTRS=["rules", "filter","col_format","formatter"] ## Formatter is an Echarts Tag

const KNOWN_HOOKS = [
    "beforeCreate",
    "created",
    "beforeMount",
    "mounted",
    "beforeUpdate",
    "updated",
    "beforeDestroy",
    "destroyed",
    "activated",
    "deactivated"]

const KNOWN_EVT_PROPS = [
    "methods",
    "computed",
    "watch"
]

## Dom Render Opts
mutable struct Opts
    rows::Bool
    closure_funcs::Vector{String}
end
Opts()=Opts(true,[])


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

function library(s::String)
    kind=String(split(s,".")[end])
    return VueJS.WebDependency(s,kind,Dict())
end

function library(s::String,kind::String)
    return VueJS.WebDependency(s,kind,Dict())
end
function library(s::String,d::Dict)
    kind=String(split(s,".")[end])
    return VueJS.WebDependency(s,kind,Dict())
end
function library(s::String,kind::String,d::Dict)
    return VueJS.WebDependency(s,kind,Dict())
end

function libraries!(a::Vector)
    deps_arr=[]
    for r in a
        r isa String ? push!(deps_arr,library(r)) : nothing
        r isa Tuple ? push!(deps_arr,library(r...)) : nothing
    end

    global DEPENDENCIES=deps_arr
    return nothing
end


htmlTypes=Union{Nothing,String,HtmlElement,VueElement,VueStruct,VueJS.VueHolder}

function assert_html_types(v::Vector)
    for r in v
        if r isa Vector
           assert_html_types(r)
        else
            @assert r isa htmlTypes "$r is not an acceptable HtmlType"
        end
    end
end

function update_boolean_values(x)
    ##boolean props
    for (k,v) in x.attrs
        if v isa Bool
            x.attrs["v-bind:$k"]="$v"
            delete!(x.attrs, k)
        elseif v isa Missing
            x.attrs[k] = true #later `attr_render` call will remove the boolean value and keep only the key
        end
    end
end
