const KNOWN_HOOKS = [
    "beforeCreate",
    "created",
    "beforeMount",
    "mounted",
    "beforeUpdate",
    "updated",
    "beforeDestroy",
    "destroyed",
    "activated",
    "deactivated"]

function HookHandlers(kind::String, value::Union{Array, String})
    hs = []
    if value isa String
        push!(hs, HookHandler(kind, "", v))
    else
        for v in value
            push!(hs, HookHandler(kind, "", v))
        end
    end
    return hs
end

function create_hooks(elements)
    hs = []
    hooks = Dict() #Dict("mounted"=>["js1", "js2"])
    elements = !(elements isa Vector) ? [elements] : elements
    for el in elements
        el_hooks=intersect(keys(el.attrs), KNOWN_HOOKS)

        for hook in el_hooks
            js=el.attrs[hook] #Dict("created"=>"function()...") --> "function()..."

            js = js isa Vector ? js : [js]
            if haskey(hooks, hook)
                hooks[hook] = [hooks[hook]..., js...]
            else
                hooks[hook] = [js...]
            end
            delete!(el.attrs, hook)
        end
    end
    for (kind,value) in hooks
        hs = vcat(hs, HookHandlers(kind, value))
    end
    return hs
end
