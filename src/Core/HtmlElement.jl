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

function htmlstring(el::HtmlElement)
    tag=el.tag
    attrs=join([v isa Bool ? (v ? " $k" : "") : " $k=\"$(replace(string(v),"\""=>"'"))\" " for (k,v) in el.attrs])
    value=htmlstring(el.value)

    if value==nothing
       return """<$tag$attrs/>"""
    else
        return """<$tag$attrs>$value</$tag>"""
    end
end

function vue_json(d::Dict)
    els=[]

    for (k,v) in d
        if k in JS_FUNCTION_ATTRS
            if v isa Array
               els2=[]
               for r in v
                push!(els2,r)
               end
                j="\"$k\":[$(join(els2,","))]"
            else
                j="\"$k\":"*(v)
            end
        elseif v isa Dict
            j="\"$k\":"*vue_json(v)
        else
            j="\"$k\":"*JSON.json(v)
        end

        push!(els,j)
    end
    return "{$(join(els,","))}"
end
