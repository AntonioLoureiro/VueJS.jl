"""
### Arguments

 * id           :: String           :: Element's identifier
 * dom          :: HtmlElement      ::
 * path         :: String           ::
 * binds        :: Dict             ::
 * value_attr   :: String           ::
 * data         :: Dict             ::
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
    dom::HtmlElement
    path::String
    binds::Dict{String,String}
    value_attr::Union{Nothing,String}
    data::Dict{String,Any}
    cols::Union{Nothing,Int64}
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
function VueElement(id::String, tag::String; kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    ## Args for Vue
    haskey(args, "cols")  ? cols = args["cols"] : cols=nothing

    vuel=VueElement(id, HtmlElement(tag, args, ""),"",Dict(), "value", Dict(), cols)
    update_validate!(vuel, args)

    return vuel
end

SPECIFIC_UPDATE_VALIDATION=Dict(

"v-data-table"=>(x)->begin

    if haskey(x.dom.attrs,"items")
        if x.dom.attrs["items"] isa DataFrame
            df=x.dom.attrs["items"]
            arr=[]
            for n in names(df)
               length(arr)==0 ? arr=map(x->Dict{String,Any}(string(n)=>x),df[!,n]) : map((x,y)->y[string(n)]=x,df[!,n],arr)
            end
            x.dom.attrs["items"]=arr
            if !(haskey(x.dom.attrs,"headers"))
                x.dom.attrs["headers"]=[Dict("value"=>n,"text"=>n) for n in string.(names(df))]
            end
        end
    end
        
end,

"v-switch"=>(x)->begin
    x.value_attr="input-value"
end,   
    
"v-btn"=>(x)->begin
    x.value_attr=nothing
end,
    
"v-select"=>(x)->begin
    @assert haskey(x.dom.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.dom.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"
end
    
)

function update_validate!(vuel::VueElement,args::Dict)
     
   
    ### Specific Validations and updates
    tag=vuel.dom.tag
    if haskey(SPECIFIC_UPDATE_VALIDATION,tag)
        SPECIFIC_UPDATE_VALIDATION[tag](vuel)
    end
    
     ## Bindig of non html accepted values => Arrays/Dicts
    for (k,v) in vuel.dom.attrs
       if !(v isa String || v isa Date || v isa Number)
          vuel.binds[k]=vuel.id.*"."*k
       end 
    end
    
    
    ## Default Binding value_attr
    if vuel.value_attr==nothing
        if haskey(vuel.dom.attrs,"value")
            vuel.dom.value=vuel.dom.attrs["value"]
            delete!(vuel.dom.attrs,"value")
        end
    else
        ## Decision was to tag as value even for the cases that it's not the value attr, better generalization and some attrs can not be used as JS vars e.g. text-input
        vuel.binds[vuel.value_attr]=vuel.id.*".value"
    end
    
    ## Events
    events=intersect(keys(vuel.dom.attrs),["click","mouseover"])
    for e in events
        event_js=vuel.dom.attrs[e]
        delete!(vuel.dom.attrs,e)
        vuel.dom.attrs["@$e"]=event_js isa Array ? join(event_js) : event_js
    end
   
    ## cols
    if vuel.cols==nothing
        vuel.cols=3
        vuel.dom.cols=3
    else
        vuel.dom.cols=vuel.cols
    end
    
    return nothing
end

function VueElement(id::String, tag::String; kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    ## Args for Vue
    haskey(args, "cols")  ? cols = args["cols"] : cols=nothing

    vuel=VueElement(id, HtmlElement(tag, args, ""),"",Dict(), "value", Dict(), cols)
    update_validate!(vuel, args)

    return vuel
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
