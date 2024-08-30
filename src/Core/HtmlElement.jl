
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
    @assert !isnothing(v) "Invalid attr value (nothing)"
    k=is_event(k) ? "@$k" : k
    if (v isa Bool && v) || v isa Missing  #either true or explicitly missing
        return " $k"
    elseif v isa Bool && !v   #false
        return ""
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

vue_json(v)=JSON.json(v)
vue_json(v::JSFunc)=v.content

vue_json(a::Array)="[$(join(vue_json.(a),","))]"

function vue_json(d::Dict)
    els=[]
    for (k,v) in d
        if k in CONTEXT_JS_FUNCTIONS
            j="\"$k\": $(v)"
        else
            j="\"$k\": $(vue_json(v))"
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

### Transform Col Name for dataframe ###
col_pref="col_"
trf_col=x->startswith(string(x),col_pref) ? string(x) : col_pref*VueJS.vue_escape(string(x))