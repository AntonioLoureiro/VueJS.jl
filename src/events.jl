"""
"""
function EventHandlers(kind::String, d::Dict)
   hs=[]
   for (k,v) in d
     push!(hs,EventHandler(kind,k,[],v,""))
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

function function_script!(eh::EventHandler)

        str="""$(eh.id) :(function(event) {
        for (key of Object.keys(app_state)) {
        eval("var "+key+" = app_state."+key)
        };

        return  function(event) {
          $(eh.script)
        };
        })()
        """
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
