
mutable struct VueElement
    id::String
    tag::String
    attrs::Dict{String, Any}
    no_dom_attrs::Dict{String, Any}
    path::String
    binds::Dict{String,String}
    value_attr::Union{Nothing,String}
    data::Dict{String,Any}
    slots::Dict{String,Any}
    cols::Union{Nothing,Float64}
    render_func::Union{Nothing,Function}
    events::Dict{String, Any}
    child
end


function create_vuel_update_attrs(id::String,tag::String,attrs::Dict)
    
    slots=get(attrs, "slots", Dict{String,Any}())
    haskey(attrs,"slots") ? delete!(attrs,"slots") : nothing
    
    cols=get(attrs, "cols", nothing)
    haskey(attrs,"cols") ? delete!(attrs,"cols") : nothing
    
    binds=get(attrs, "binds", Dict())
    haskey(attrs,"binds") ? delete!(attrs,"binds") : nothing
        
    events=Dict{String, Any}()
    for ev in KNOWN_HOOKS
        haskey(attrs,ev) ? events[ev]=attrs[ev] : nothing
    end
        
    ## Style Assert
    style=get(attrs,"style",Dict())
    @assert style isa Dict "style attr should be a Dict"
    length(style)!=0 ? style=convert(Dict{String,Any},style) : nothing

    ## V-Number
    v_number=get(attrs,"v-number",Dict())
    @assert v_number isa Dict "v-number should be a Dict"
    if length(v_number)!=0
       v_number=convert(Dict{String,Any},v_number)
       ## Number Defaults 
       haskey(v_number,"decimal") ? nothing : v_number["decimal"]="."
       haskey(v_number,"separator") ? nothing : v_number["separator"]=" "
       @assert v_number["separator"]!="." """Separator in V-Number should not be a "." (Bug in JS Library!)"""
       attrs["v-number"]=v_number
    end
    
    ## No Dom attrs
    no_dom_attrs=Dict{String, Any}()
    no_dom_attrs["storage"]=get(attrs, "storage", false)
    haskey(attrs,"storage") ? delete!(attrs,"storage") : nothing
    
    ## Tooltip
    tooltip=get(attrs, "tooltip", nothing)
    if tooltip!=nothing
        delete!(attrs,"tooltip")
        no_dom_attrs["tooltip"]=tooltip
    end
    
    ## Menu
    menu=get(attrs, "menu", nothing)
    if menu!=nothing
        @assert (menu isa VueJS.VueElement || menu isa Array) "Menu should be a VueElement Menu or Vector of items"
        if menu isa VueJS.VueElement
            items=get(menu.attrs, "items", [])
            attrs["items"]=items
            delete!(attrs,"menu")
            no_dom_attrs["menu"]=menu
        else
            attrs["items"]=menu
            delete!(attrs,"menu")
            no_dom_attrs["menu"]=menu
        end
    end
        
    return VueElement(id,tag,attrs,no_dom_attrs,"",binds, "value", Dict(), slots, cols,nothing,events,nothing)
    
end

is_valid_var(x::String)=all(c->islowercase(c) || c=='_' || isnumeric(c), x)

function VueElement(id::String, tag::String, attrs::Dict)
    @assert is_valid_var(id) "Element variable should be lowercase!"
    vuel=create_vuel_update_attrs(id,tag,attrs)
    vuel_value_attr=try VueJS.UPDATE_VALIDATION[vuel.tag].value_attr catch; "value "end
    
    if haskey(vuel.binds,"value") && vuel_value_attr!="value"
       vuel.binds[vuel_value_attr]=vuel.binds["value"]
       delete!(vuel.binds,"value")
    end
    
    VueJS.update_validate!(vuel) 
    
    ## Change/Update sufix value_attr Vue 3
    if vuel.value_attr!=nothing
        for (k,v) in vuel.attrs
            if k in ["change","update","input"]
               vuel.attrs[k*":"*vuel.value_attr]=v
               delete!(vuel.attrs,k) 
            end
        end
    end
    
    ## Slots
    if length(vuel.slots)!=0
        child=[]
        for (k,v) in vuel.slots
            push!(child,html("template",v,Dict("v-slot:$k"=>true)))
        end
        vuel.child=child
    end

    return vuel
end

function is_event(k::String)
    if k in KNOWN_JS_EVENTS
        return true
    elseif startswith(k,"keyup") || startswith(k,"keydown")
        return true
    else
        ret=false
        for r in KNOWN_JS_EVENTS_COLLON
            if startswith(k,r)
                ret=true
               break
            end
        end
        return ret
    end
end

function update_validate!(vuel::VueElement)

    ### Specific Validations and updates
    if haskey(UPDATE_VALIDATION, vuel.tag)
        UPDATE_VALIDATION[vuel.tag].fn(vuel)
        vuel.value_attr=deepcopy(UPDATE_VALIDATION[vuel.tag].value_attr)
    else
        error("Vue Element $(vuel.tag) is not implemented! Please submit a PR in VueJS Github repo!")
    end

    ## Binding
    for (k,v) in vuel.attrs   
       haskey(vuel.binds,k) ? continue : nothing
       ## Bindig of non html accepted values => Arrays/Dicts or KNOWN_JS_EVENTS
       if !(v isa String || v isa Date || v isa Missing)
          if k==vuel.value_attr
             vuel.binds[k]=vuel.id.*".value"
          else
             vuel.binds[k]=vuel.id.*"."*k
          end
       end
    end
    
    ## Decision was to tag as value even for the cases that it's not the value attr, better generalization and some attrs can not be used as JS vars e.g. text-input
    if vuel.value_attr!=nothing && !(haskey(vuel.binds,vuel.value_attr))
        vuel.binds[vuel.value_attr]=vuel.id.*".value"
    end

    ## Clean Auto Bind of non value value_attr
    if vuel.value_attr!="value" && vuel.value_attr!=nothing && haskey(vuel.binds,"value")
       delete!(vuel.binds,"value")
    end
    
    return nothing
end

function treat_kwargs(args) 
        newargs=[]
        for r in (args)
           @assert r.head==:(=) "You should input args with = indication e.g. a=1"
           @assert length(r.args)==2 "You should input args with = indication e.g. a=1"

            if typeof(r.args[1])==Expr
                str_expr=string(r)
                arre=split(str_expr,"=")
                lefte=arre[1]
                if occursin("-",lefte)  ### handle cases where left side expr is similar to: a-multiple-hiphen-prop
                    rigthe=string(r.args[2])
                    righte=replace(rigthe,"quote"=>"begin",count=1)
                    lefte="\""*replace(lefte," "=>"")*"\"=>"
                    lefte=replace(replace(lefte,"("=>""), ")"=>"") 
                    push!(newargs,lefte*righte)
                else  ### handle cases where left side expr is similar to: dot.key
                     str_expr=replace("\""*string(str_expr)," ="=>"\" =>",count=1)
                    push!(newargs,str_expr)
                end
            else
                e=replace("\""*string(r)," ="=>"\" =>",count=1)
                push!(newargs,e)
            end
        end
   return newargs
end

macro el(varname,tag,args...)

    @assert varname isa Symbol "1st arg should be Variable name"
    tag_type=typeof(tag)

    @assert tag_type in [String,Symbol] "2nd arg should be tag name or accepted Struct"
    newargs=treat_kwargs(args)
        
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
