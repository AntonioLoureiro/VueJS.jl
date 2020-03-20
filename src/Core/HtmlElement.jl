"""
### Arguments

 * tag      :: String              :: Vuetify tag (e.g: "v-text-field")
 * attrs    :: Dict{String, Any}   :: HTML element attributes (e.g: Dict("placeholder"=>"username"))
 * cols     :: Union{Nothing, Int} :: Number of columns the element should occupy
 * value    :: Any                 :: Element content, will be assigned in between opening and closing tags. Defaults to nothing

### Examples

```julia
el      = HtmlElement("h4", Dict("class"=>"header"), 3, "A small tittle")
user    = HtmlElement("input", Dict("class"=>"form-control","type"=>"text", "placeholder"=>"username"), "")
headers = HtmlElement("head", [HtmlElement("meta", Dict("charset"=>"UTF-8")),
                               HtmlElement("meta", Dict("name"=>"author", "content"=>"Risk Assurance"))])

htmlstring(el)           :: `<h4 class='header'>A small tittle</h4>`
htmlstring(user)         :: `<input class='form-control' type="text" placeholder="username">`
htmlstring(headers)      :: `<head><meta charset="UTF-8"/><meta name="author" content="Risk Assurance"/></head>`

# @el(example,"v-text-field",value="JValue",label="R1")
example = VueElement("teste", HtmlElement("v-text-field", Dict{String,Any}("label"=>"R1","value"=>"JValue"), 3, ""), "", Dict("value"=>"teste.value"), "value", Dict{String,Any}(), 3)
body=HtmlElement("body",
        HtmlElement("div",Dict("id"=>"app"),
            HtmlElement("v-app",
                HtmlElement("v-container",Dict("fluid"=>true),[example]))))
```
"""
mutable struct HtmlElement
    tag::String
    attrs::Dict{String, Any}
    cols::Union{Nothing, Int64}
    value
end
#=
Shortcut constructs
=#
HtmlElement(tag::String, value::Union{String, Vector, HtmlElement}) = HtmlElement(tag, Dict(), nothing, value)
HtmlElement(tag::String, attrs::Dict, value::Union{String, Array, HtmlElement}) =
        HtmlElement(tag, attrs, nothing, value)
HtmlElement(tag::String, attrs::Dict) = HtmlElement(tag, attrs, nothing, nothing)

htmlstring(s::String)=s
htmlstring(n::Nothing)=nothing
htmlstring(a::Vector)=join(htmlstring.(a))

function attr_render(k,v)
    if (v isa Bool && v) || v isa Missing  #either true or explicitly missing
        return " $k"
    elseif v isa Bool && !v   #false
        return ""
    elseif startswith(k,":")
        return " $k=\"$(replace(vue_escape(string(v)),"\""=>"'"))\" "
    else
        return " $k=\"$(replace(string(v),"\""=>"'"))\" "
    end
end

function htmlstring(el::HtmlElement)
    tag=el.tag
    attrs=join([attr_render(k,v) for (k,v) in el.attrs])
    value=htmlstring(el.value)
    
    if value==nothing
       return """<$tag$attrs/>"""
    else
        return """<$tag$attrs>$value</$tag>"""
    end
end

function vue_json(v,f_mode)
    if f_mode
        return v
    else
        return JSON.json(v)
    end
end

vue_json(a::Array,f_mode)="[$(join(vue_json.(a,f_mode),","))]"

function vue_json(d::Dict,f_mode::Bool=false)
    els=[]
    for (k,v) in d
        if k in VueJS.JS_FUNCTION_ATTRS
            j="\"$k\": $(vue_json(v,true))"
        else
            j="\"$k\":"*vue_json(v,f_mode==false ? false : true)
        end
        push!(els,j)
    end
    return "{$(join(els,","))}"
end

vue_escape(s)=s
function vue_escape(s::String)
   s=lowercase(s) 
   s=replace(s," "=>"")
   s=replace(s,"-"=>"_")
   s=replace(s,"%"=>"_perc")
    
    return s
end
