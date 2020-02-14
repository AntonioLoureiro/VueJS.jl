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
    child
end

dom(d)=d
dom(d::Dict)=JSON.json(d)
dom(a::Array)=dom.(a)
function dom(vuel::VueElement)
    
    child=nothing
    ## Value attr is nothing
    if vuel.value_attr==nothing
        if haskey(vuel.attrs,"value")
            child=vuel.attrs["value"]
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
   
   if vuel.child!=nothing
       child=vuel.child
   else
       child=child==nothing ? "" : child
   end
    
   return HtmlElement(vuel.tag, vuel.attrs, cols, update_dom(child))
end

update_dom(r)=dom(r)
function update_dom(r::VueElement)
    
    ## Bind el values
    for (k,v) in r.binds
        value=r.path=="" ? v : r.path*"."*v
        r.attrs[":$k"]=value

        ### Capture Event if tgt=src otherwise double count or if value is value attr
        if r.id*"."*k==v || r.id*".value"==v

            ## And only if value attr! Others do not change on input! I Think!
            if r.value_attr==k
                event=r.value_attr=="value" ? "@input" : "@change"
                if haskey(r.attrs,event)
                    r.attrs[event]=r.attrs[event]*"; "*"$value= \$event;"
                else
                    r.attrs[event]="$value= \$event"
                end
            end
        end
        ### delete attribute from dom
        if haskey(r.attrs,k)
            delete!(r.attrs,k)
        end
    end

    return dom(r)
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

    child=nothing
 
    vuel=VueElement(id,tag,attrs,"",Dict(), "value", Dict(), slots, cols,child)
    update_validate!(vuel)
    
       ## Slots
    if length(slots)!=0
        child=[]
        for (k,v) in slots
            push!(child,HtmlElement("template",Dict("v-slot:$k"=>true),dom(v)))
        end
    end

    return vuel
end

bind_child_v_for!(c)=nothing
bind_child_v_for!(c::Array)=bind_child_v_for!.(c)
function bind_child_v_for!(vuel::VueElement)
    
   vuel.binds[vuel.value_attr]="item."*vuel.id
    
end

function update_validate!(vuel::VueElement)

    ### Specific Validations and updates
    tag=vuel.tag
    if haskey(UPDATE_VALIDATION, tag)
        UPDATE_VALIDATION[tag](vuel)
    end

     for (k,v) in vuel.attrs
       ## Bindig of non html accepted values => Arrays/Dicts
        if !(v isa String || v isa Date || v isa Number)
          vuel.binds[k]=vuel.id.*"."*k
       end
       ## Bind item element
       if k=="v-for"
          bind_child_v_for!(vuel.child)
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
@el(r1,"v-slider",value=20,label="Slider 1")
@el(r4,"v-text-field",value="R4 Value",label="R4")
@el(r2,"v-slider",value=20,label="Slider 2")
@el(r6,"v-text-field",placeholder="Dummy data",label="Test")
@el(element,"v-text-field", full-width=true, label="Example", solo-inverted=true)
```
"""
macro el(varname,tag,args...)

    @assert typeof(varname)==Symbol "1st arg should be Variable name"
    @assert typeof(tag)==String "2nd arg should be tag name"

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
    newexpr=(Meta.parse("""VueElement("$(string(varname))","$(string(tag))",$newargs)"""))
    return quote
        $(esc(varname))=$(esc(newexpr))
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
