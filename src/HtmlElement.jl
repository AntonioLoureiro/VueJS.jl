"""
### Arguments

 * tag      :: String              :: HTML tag (e.g: "input")
 * attrs    :: Dict{String, Any}   :: HTML element attributes (e.g: Dict("placeholder"=>"username"))
 * value    :: Any                 :: Element content, will be assigned in between opening and closing tags

### Examples

```julia
el      = HtmlElement("h4", Dict("class"=>"header"), "A small tittle")
user    = HtmlElement("input", Dict("class"=>"form-control","type"=>"text", "placeholder"=>"username"), "")

str = htmlstring(el)    :: `<h4 class='header'>A small tittle</h4>`
inp = htmlstring(user)  :: `<input class='form-control' type="text" placeholder="username">`
```
"""
mutable struct HtmlElement
    tag::String
    attrs::Dict{String,Any}
    value
end

htmlstring(s::String)=s
htmlstring(n::Nothing)=nothing
htmlstring(a::Vector)=join(htmlstring.(a))

function htmlstring(el::HtmlElement)
    tag=el.tag
    attrs=join([typeof(v)==Bool ? " $k" : " "*k*"=\""*string(v)*"\"" for (k,v) in el.attrs])
    value=htmlstring(el.value)

    if value==nothing
       return """<$tag$attrs/>"""
    else
        return """<$tag$attrs>$value</$tag>"""
    end

end

mutable struct Page
    head::HtmlElement
    include_scripts::Array
    include_styles::Array
    body::HtmlElement
    scripts::String
end
