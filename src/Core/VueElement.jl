"""
### Arguments

 * id           :: String           :: Element's identifier
 * tag          :: String           :: Vuetify tag, e.g. "v-dialog", "v-text-input", "v-btn", ...
 * attrs        :: Dict             ::
 * path         :: String           ::
 * binds        :: Dict             ::
 * value_attr   :: String           ::
 * data         :: Dict             ::
 * slots        :: Dict             :: VueJS slots, e.g. append, footer, header, label, prepend, ...
 * cols         :: Union{Nothing, Int64} :: Number of columns the element should occupy

### Examples

```julia

@el(r1,"v-text-field",value="JValue",label="R1")   :: r1 = VueElement{"r1", HtmlElement("v-textfield", Dict("value"=>"JValue","label"=>"R1")), ...}
@el(r3,"v-slider",value=20,label="Slider 3")
```

[See also: Vuejs components slots](https://vuejs.org/v2/guide/components-slots.html)
"""
mutable struct VueElement
    id::String
    tag::String
    attrs::Dict{String, Any}
    path::String
    binds::Dict{String,String}
    value_attr::Union{Nothing,String}
    data::Dict{String,Any}
    slots::Dict{String,T} where T<:Union{String,HtmlElement,Dict}
    cols::Union{Nothing,Int64}
    render_func::Union{Nothing,Function}
    style::Vector{String}
    template::Bool
    child
    events::Dict{String, Any}
end

"""
Defaults to binding on `value` attribute
"""
function VueElement(id::String, tag::String, attrs::Dict)

    if haskey(attrs,"slots")
        slots=attrs["slots"]
        delete!(attrs,"slots")
    else
        slots=Dict{String,String}()
    end

    if haskey(attrs,"cols")
        cols=attrs["cols"]
        delete!(attrs,"cols")
    else
       cols=nothing
    end

    events = get(attrs, "events", Dict{String, Vector}())
    delete!(attrs, "events")
    for (k,v) in attrs
        if k in vcat(KNOWN_HOOKS, KNOWN_EVT_PROPS)
            merge!(events, Dict(k=>v))
            delete!(attrs, k)
        end
    end

    vuel=VueElement(id,tag,attrs,"",Dict(), "value", Dict(), slots, cols,nothing,[],false,nothing,events)
    update_validate!(vuel)

    ## Slots
    if length(vuel.slots)!=0
        child=[]
        for (k,v) in vuel.slots
            push!(child,HtmlElement("template",Dict("v-slot:$k"=>true),dom(v)))
        end
        vuel.child=child
    end

    return vuel
end


function update_validate!(vuel::VueElement)

    ### Specific Validations and updates
    tag=vuel.tag
    if haskey(UPDATE_VALIDATION, tag)
        UPDATE_VALIDATION[tag](vuel)
    end

    ## Binding
    for (k,v) in vuel.attrs
       ## Bindig of non html accepted values => Arrays/Dicts or KNOWN_JS_EVENTS
       if !(v isa String || v isa Date || v isa Missing) || k in KNOWN_JS_EVENTS
          if k==vuel.value_attr
             vuel.binds[k]=vuel.id.*".value"
          else
             vuel.binds[k]=vuel.id.*"."*k
          end
       end
    end

    ## Decision was to tag as value even for the cases that it's not the value attr, better generalization and some attrs can not be used as JS vars e.g. text-input
    if vuel.value_attr!=nothing
        vuel.binds[vuel.value_attr]=vuel.id.*".value"
    end

    return nothing
end

"""
### Examples
```julia
@el(r1,"v-slider",value=20,label="Slider 1")
@el(r4,"v-text-field",value="R4 Value",label="R4")
@el(r2,"v-slider",value=20,label="Slider 2")
@el(r6,"v-text-field",placeholder="Dummy data",label="Test")
@el(element,"v-text-field", full-width=true, label="Example", solo-inverted=true)
```
"""
macro el(varname,tag,args...)

    @assert varname isa Symbol "1st arg should be Variable name"
    tag_type=typeof(tag)

    @assert tag_type in [String,Symbol] "2nd arg should be tag name or accepted Struct"

        newargs=[]
        for r in (args)
           @assert r.head==:(=) "You should input args with = indication e.g. a=1"
           @assert length(r.args)==2 "You should input args with = indication e.g. a=1"

            if typeof(r.args[1])==Expr
                arre=split(string(r),"=")
                lefte=arre[1]
                rigthe=string(r.args[2])
                lefte="\""*replace(lefte," "=>"")*"\"=>"
                lefte=replace(replace(lefte,"("=>""), ")"=>"") #handle cases where left side expr is similar to: a-multiple-hiphen-prop
                righte=replace(rigthe,"quote"=>"begin",count=1)
                push!(newargs,lefte*righte)
            else
                e=replace("\""*string(r)," ="=>"\" =>",count=1)
                push!(newargs,e)
            end
        end
        newargs="Dict($(join(newargs,",")))"

    ## Special Building Condition (EChart)
    if tag_type==Symbol

        newexpr=(Meta.parse("""VueJS.VueElement("$(string(varname))",$(tag),$newargs)"""))
        return quote
            $(esc(varname))=$(esc(newexpr))
        end

    ## Normal condition
    elseif tag_type==String

        newexpr=(Meta.parse("""VueJS.VueElement("$(string(varname))","$(string(tag))",$newargs)"""))
        return quote
            $(esc(varname))=$(esc(newexpr))
        end
    end
end

import Base.getindex
import Base.setindex!

function Base.getindex(el::HtmlElement, i::String)
    return Base.getindex(el.attrs, i)
end

function Base.getindex(v::VueElement, i::String)
    return Base.getindex(v.attrs, i)
end

function Base.setindex!(el::HtmlElement, v,i::String)
    Base.setindex!(el.attrs, v,i)
    return nothing
end

function Base.setindex!(vuel::VueElement,v, i::String)
    Base.setindex!(vuel.attrs, v,i)
    update_validate!(vuel)
    return nothing
end
