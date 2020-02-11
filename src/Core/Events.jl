
function EventHandlers(kind::String, d::Dict)

    hs=[]
    for (k,v) in d
        if v isa NamedTuple
           kis = keys(v)
           @assert :args in kis && :script in kis "Building EventHandler from NamedTuple requires both `args` and `script` keys"
           @assert v.args isa Vector "Function `args` must be of Type Vector{String}. `$(v.args)` of type $(typeof(v.args)) provided."
           push!(hs, CustomEventHandler(kind, k, v.args, v.script, "", ""))
        elseif v isa String
           push!(hs,CustomEventHandler(kind,k,[],v,"",""))
        end
    end
    function_script!.(hs)
    return hs
end

function create_events(events::NamedTuple)
    hs=[]
    append!(hs, EventHandlers("methods", events.methods))
    append!(hs, EventHandlers("computed",events.computed))
    append!(hs, EventHandlers("watched", events.watched))
    return hs
end


function_script!(eh::EventHandler)=nothing

function function_script!(eh::CustomEventHandler)
        
        if eh.path==""
            scope="app_state"
        else
            scope="app_state."*eh.path
        end

        args = size(eh.args, 1) > 0 ? join(eh.args, ",") : "event"

        str="""$(eh.id) :(function($args) {
        for (key of Object.keys(@scope@)) {
        eval("var "+key+" = @scope@."+key)
        };

        return  function($args) {
          $(eh.script)
        };
        })()
        """

    str=replace(str,"@scope@"=>scope)

    eh.function_script=str

    return nothing
end

function events_script(vs::VueStruct)
    els=[]
    for e in ["methods","computed","watched"]
        ef=filter(x->x.kind==e,vs.events)
        if length(ef)!=0
            push!(els,"$e : {"*join(map(y->y.function_script,ef),",")*"}")
        end
    end
    return join(els,",")
end

function get_json_attr(d::Dict,a::String,path="app_state")
    out=Dict()
    for (k,v) in d
        if v isa Dict
            if haskey(v,a)
                out[k]=path*".$k.$a"
            else
                ret=get_json_attr(v,a,path*".$k")
                length(ret)!=0 ? out[k]=ret : nothing
            end
        end
    end
    return out
end

function std_events!(vs::VueStruct,new_es::Vector{EventHandler})
    
    value_script=replace(JSON.json(VueJS.get_json_attr(vs.def_data,"value")),"\""=>"")
    function_script="""submit : function(context) {
        var ret=$value_script
        console.log(ret)
        }"""
    
    push!(new_es,VueJS.StdEventHandler("methods","submit","",function_script))
    return nothing
end