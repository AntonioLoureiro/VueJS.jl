
mutable struct HtmlElement
    tag::String
    attrs::Dict{String, Any}
    cols::Union{Nothing, Float64}
    value
end

html(tag::String,value::Union{String,HtmlElement,Array,Nothing},attrs::Dict=Dict();cols=2)=HtmlElement(tag,attrs,cols,value)


htmlstring(s::String)=s
htmlstring(n::Nothing)=nothing
htmlstring(a::Vector)=join(htmlstring.(a))

function attr_render(k,v)
    k=is_event(k) ? "@$k" : k
    if (v isa Bool && v) || v isa Missing  #either true or explicitly missing
        return " $k"
    elseif v isa Bool && !v   #false
        return ""
    elseif startswith(k,":")
        return " $k=\"$(replace(string(v),"\""=>"'"))\" "
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
        if k in JS_FUNCTION_ATTRS || k in CONTEXT_JS_FUNCTIONS
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
   s=replace(s,"keyup."=>"keyup")
    s=replace(s,"keydown."=>"keydown")
    return s
end


function keys_id_fix(s::String)
    s=replace(s,"keyup."=>"keyup")
    s=replace(s,"keydown."=>"keydown")
    return s
end