HEAD=html("head",
    [
    html("meta","", Dict("charset"=>"UTF-8")),
    html("meta","", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
    ],Dict())

arr_deps=JSON.parse(read(joinpath(@__DIR__, "../WebDeps/deps.json"),String))

DEPENDENCIES=map(x->WebDependency(x["path"],x["version"],x["kind"],get(x,"components",Dict()),get(x,"css",""),"",""),arr_deps)


FRAMEWORK="vuetify"

const DIRECTIVES=["v-html","v-text","v-for","v-if","v-on","v-style","v-show"]

const KNOWN_JS_EVENTS = ["input","click", "mouseover", "mouseenter", "change"]
const CONTEXT_JS_FUNCTIONS=["submit","add","remove"]
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
    style::Dict{String,Any}
    class::Dict{String,Any}
    path::String
    vars_replace::Dict{String,String}
end
const PAGE_OPTIONS=Opts(true,Dict("viewport"=>"md","v-col"=>Dict("align"=>"center","align-content"=>"center","justify"=>"center")),Dict(),"root",Dict())


LIBRARY_RULES =
    Dict("maxchars"=> (x->return """ value => value.length <= $x || 'Max $x characters' """),
         "minchars"=> (x->return """ value => value.length > $x  || 'Min $x characters' """),
         "required"=> (x->return " value => !!value || 'Required' "),
         "min"=>(x->return " value => value >= $x || 'Minimum  value is $x' "),
         "max"=>(x->return " value => value <= $x || 'Maximum  value is $x' "),
         "type"=>(x->return "value => typeof(value) === '$x' || 'Please provide a $x'"),
         "in"=>(x->return """ value => $x.includes(value) || 'Value not in $x' """)
    )

struct VueElementSettings
    library::String
    doc::String
    value_attr::Union{Nothing,String}
    fn::Function    
end

function VueElementSettings(nt::NamedTuple)
    
    library=get(nt,:library,"vuetify")
    doc=get(nt,:doc,"")
    value_attr=get(nt,:value_attr,"value")
    fn=nt.fn
    
    return VueElementSettings(library,doc,value_attr,fn)
end

import Base.convert
Base.convert(::Type{VueElementSettings}, x::NamedTuple) = VueElementSettings(x)

const UPDATE_VALIDATION=Dict{String,VueElementSettings}()

function get_web_dependencies!(web_dependency_path::String,deps_url::String)

    isdir(web_dependency_path) ? nothing : mkdir(web_dependency_path)

    for d in DEPENDENCIES
        resp=""
        try
            resp=HTTP.get(d.path,require_ssl_verification = false)
        catch err;
            error("Error getting $(d.path) please try again!")    
        end
        
        str=String(resp.body)
        sha_str=bytes2hex(sha256(str))
        d.sha=sha_str
        filename=web_dependency_path*"/"*sha_str*"."*d.kind
        file_exists=isfile(filename)

        if !(file_exists)
            open(filename, "w") do io
                   write(io,str)
            end
       
        end
        d.local_path=deps_url*"/"*sha_str*"."*d.kind
    end

end

function library(s::String)
    kind=String(split(s,".")[end])
    return VueJS.WebDependency(s,kind,Dict(),"","")
end

function library(s::String,kind::String)
    return VueJS.WebDependency(s,kind,Dict(),"","")
end
function library(s::String,d::Dict)
    kind=String(split(s,".")[end])
    return VueJS.WebDependency(s,kind,Dict(),"","")
end
function library(s::String,kind::String,d::Dict)
    return VueJS.WebDependency(s,kind,Dict(),"","")
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

const JS_VAR_CHARS=vcat(Char.(48:57),Char.(65:90),Char(95),Char.(97:122))
const JS_FIRST_VAR_CHARS=vcat(Char.(65:90),Char(95),Char.(97:122))

function trf_vue_expr(expr::String;opts=PAGE_OPTIONS)
        
    if opts.path==""
        return expr
    end
    
    expr=replace(expr,"\""=>"'")
    expr_arr=split(expr,"'")   
    expr_out=Vector{String}()
    expr_arr[1]=="" ? is_quoted=false : is_quoted=true
        
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

