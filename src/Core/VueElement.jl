"""
### Arguments

 * id           :: String           :: Element's identifier
 * tag          :: String           ::
 * attrs        :: Dict             ::
 * path         :: String           ::
 * binds        :: Dict             ::
 * value_attr   :: String           ::
 * data         :: Dict             ::
 * slots        :: Dict             :: 
 * cols         :: Union{Nothing, Int64} :: Number of columns the element should occupy

### Examples

```julia

@el(r1,"v-text-field",value="JValue",label="R1")   :: r1 = VueElement{"r1", HtmlElement("v-textfield", Dict("value"=>"JValue","label"=>"R1")), ...}
r2 = VueElement("r2", "v-text-field", label="label", value="testeBatata")
@el(r3,"v-slider",value=20,label="Slider 3")
```
"""
mutable struct VueElement
    id::String
    tag::String
    attrs::Dict{String, Any}
    path::String
    binds::Dict{String,String}
    value_attr::Union{Nothing,String}
    data::Dict{String,Any}
    slots::Dict{String,T} where T<:Union{String,HtmlElement}
    cols::Union{Nothing,Int64}
end

function dom(vuel::VueElement)
   
    if length(vuel.slots)==0
        value=""
    else
        value=[]
        for (k,v) in vuel.slots
            push!(value,HtmlElement("template",Dict("v-slot:$k"=>true),v))
        end
    end
    
    ## Value attr is nothing
    if vuel.value_attr==nothing
        if haskey(vuel.attrs,"value")
            value=vuel.attrs["value"]
            delete!(vuel.attrs,"value")
        end
    end
    
    ## cols
    if vuel.cols==nothing
        vuel.cols=3
        cols=3
    else
        cols=vuel.cols
    end
    
   return HtmlElement(vuel.tag, vuel.attrs, cols, value)
end

"""
Defaults to binding on `value` attribute

### Examples
```julia
el = VueElement("e1", "v-text-field", value="Empty", label="Description")
@show el
el = VueElement("e1", HtmlElement("v-text-field", Dict{String,Any}("label"=>"Description","value"=>"Empty"), 3, ""), "", Dict("value"=>"e1.value"), "value", Dict{String,Any}(), 3)
```
"""
function VueElement(id::String, tag::String; cols::Union{Nothing,Int64}=nothing, slots=Dict{String,String}(),kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    vuel=VueJS.VueElement(id,tag,args,"",Dict(), "value", Dict(), slots,cols)
    VueJS.update_validate!(vuel)

    return vuel
end

function update_validate!(vuel::VueElement)

    ### Specific Validations and updates
    tag=vuel.tag
    if haskey(UPDATE_VALIDATION, tag)
        UPDATE_VALIDATION[tag](vuel)
    end

     ## Bindig of non html accepted values => Arrays/Dicts
    for (k,v) in vuel.attrs
       if !(v isa String || v isa Date || v isa Number)
          vuel.binds[k]=vuel.id.*"."*k
       end
    end

    ## Decision was to tag as value even for the cases that it's not the value attr, better generalization and some attrs can not be used as JS vars e.g. text-input
    if vuel.value_attr!=nothing
        vuel.binds[vuel.value_attr]=vuel.id.*".value"
    end

    ## Events
    events=intersect(keys(vuel.attrs),KNOWN_JS_EVENTS)
    for e in events
        event_js=vuel.attrs[e]
        delete!(vuel.attrs,e)
        vuel.attrs["@$e"]=event_js isa Array ? join(event_js) : event_js
    end

    return nothing
end

"""
### Examples
```julia
@el(r3,"v-slider",value=20,label="Slider 3")
@el(r4,"v-text-field",value="R4 Value",label="R4")
@el(r5,"v-slider",value=20,label="Slider")
@el(r6,"v-slider",value=20,label="Slider")
@el(r6,"v-input",placeholder="Dummy data",label="Test")
```
"""
macro el(args...)

    @assert typeof(args[1])==Symbol "1st arg should be Variable name"
    @assert typeof(args[2])==String "2nd arg should be tag name"

    varname=(args[1])

    newargs=join(string.(args[3:end]),",")

    newexpr=(Meta.parse("""VueElement("$(string(args[1]))","$(string(args[2]))",$newargs)"""))
    return quote
        $(esc(varname))=$(esc(newexpr))
    end
end
