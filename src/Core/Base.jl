HEAD=html("head",
    [
    html("meta","", Dict("charset"=>"UTF-8")),
    html("meta","", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
    ],Dict())


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
                WebDependency("https://cdn.jsdelivr.net/npm/vue-echarts@4.0.2","js",Dict("vuechart"=>"VueECharts")),
                WebDependency("https://unpkg.com/vue-async-computed@3.8.1","js",Dict())
                
            ]

FRAMEWORK="vuetify"

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
    attrs::Dict{String,Any}
    path::String
    vars_replace::Dict{String,String}
end
const PAGE_OPTIONS=Opts(true,Dict("viewport"=>"md","v-col"=>Dict("align"=>"center","align-content"=>"center","justify"=>"center")),"root",Dict())


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

const JS_VAR_CHARS=vcat(Char.(48:57),Char.(65:90),Char(95),Char.(97:122))

function trf_vue_expr(expr::String;opts=PAGE_OPTIONS)
    
    if opts.path==""
        return expr
    end
    
    expr=replace(expr,"\""=>"'")
    expr_arr=split(expr,"'")   
    expr_out=Vector{String}()
    expr_arr[1]=="" ? is_quoted=false : is_quoted=true
    expr_arr=filter(x->x!="",expr_arr)
    
   ## iterate blocks of code
   for s in expr_arr
        
        is_quoted=!is_quoted
        
        if is_quoted
            push!(expr_out,"'$s'")
        else
            
            ## Total Match (e.g. submit)
            if s in CONTEXT_JS_FUNCTIONS
                s=get(opts.vars_replace,s,s)*"()"
                push!(expr_out,s)
                continue
            end

            text_seg=Vector{Char}()
            lns=length(s)
            is_var_char=false
            prev_oper=' '
            ## Iterate Chars
            for (i,chr) in enumerate(s)
               
                new_var_char=chr in JS_VAR_CHARS
                
                if (i!=1 && new_var_char!=is_var_char)
                    strf=String(text_seg)
                    if prev_oper!='.'
                        strf=get(opts.vars_replace,strf,strf)
                    end
                    push!(expr_out,strf)
                    prev_oper=text_seg[end]
                    text_seg=Vector{Char}()
                    push!(text_seg,chr)
                else
                    push!(text_seg,chr)
                end
                
                is_var_char=new_var_char
            end
                if length(text_seg)!=0
                    strf=String(text_seg)
                    if prev_oper!='.'
                        strf=get(opts.vars_replace,strf,strf)
                    end
                    push!(expr_out,strf)
                end
        end
    end
   
    return join(expr_out)
end

