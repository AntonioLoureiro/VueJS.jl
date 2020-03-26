
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
    append!(hs, EventHandlers("watch", events.watched))
    return hs
end

js_closure = function(;scope::String="@scope@")
    script=""" for (key of Object.keys($scope)) {
    eval("var "+key+" = $scope."+key)
    };"""
    return script
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
            $(js_closure(scope=scope))
        return  function($args) {
          $(eh.script)
        };
        })()
        """

    eh.function_script=str

    return nothing
end

function events_script(vs::VueStruct)
    els=[]
    for e in ["methods","computed","watch"]
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

function std_events!(vs::VueStruct, new_es::Vector{EventHandler})

    #### xhr #####
    function_script = """xhr : function(contents, url=window.location.pathname, method="POST", async=true, success=null, error=null) {

    console.log(contents)
    var xhr = new XMLHttpRequest();
    if (!error) {
        xhr.onerror = function(){console.log('Error! Request failed with status ' + xhr.status + ' ' + xhr.responseText);}
    }
    else if (typeof(error) === 'function') {
        xhr.onerror = function(xhr) {error(xhr);}
    } else {
        xhr.onerror = function() {return error;}
    }
    xhr.onreadystatechange = function() {
        if (this.readyState == 4) {
            if (this.status == 200 && this.responseText) {
                if (success) {
                    return typeof(success) === 'function' ? success(xhr) : success
                } else {
                    console.log(this.responseText);
                }
            } else {
                xhr.onerror;
            }
        }
    }
    xhr.open(method, url, async);
    xhr.send(contents);
    }"""
    push!(new_es,StdEventHandler("methods","xhr","",function_script))

    #### Submit Method ####
    value_script=replace(JSON.json(get_json_attr(vs.def_data,"value")),"\""=>"")
    function_script="""submit : function(context, url, method, async, success, error) {
        var ret=$value_script
        $(js_closure(scope="app"))

        var search = function(obj, arr) {
            let result = {};
            for(key in obj) {
                if (arr.includes(key)) {
                    result[key] = obj[key];
                } else if (typeof(obj[key]) === 'object') {
                    Object.assign(result, search(obj[key], arr));
               	}
    	    }
            return result;
        }
        if (context && context.length) {
            ret = search(ret, context);
        }
        return xhr(JSON.stringify(ret), url, method, async, success, error)
    }"""
    push!(new_es,StdEventHandler("methods","submit","",function_script))

    ##### Open Method #####
    function_script="""open : function(url,name) {
        name = typeof name !== 'undefined' ? name : '_self';
        window.open(url,name);
        }"""

    push!(new_es,StdEventHandler("methods","open","",function_script))

    ## Datatable Col Format
    function_script="""datatable_col_format : function(item,format_script) {
        return format_script(item)
        }"""

    push!(new_es,StdEventHandler("methods","datatable_col_format","",function_script))
    
    ##### Run in closure #####
    function_script="""run_in_closure : (function(context, fn) {    
    path=context=='' ? 'app_state' : 'app_state.'+context
    for (key of Object.keys(eval(path))) {
        eval("var "+key+" = "+path+"."+key)
    }

    fnstr=fn.toString();
    fnstr=fnstr.replace('()=>','');
    eval(fnstr);
    })"""
    push!(new_es,StdEventHandler("methods","run_in_closure","",function_script))

   
    return nothing
end

"""
Wrapper around submit and xhr method(s)
Allows submissions to be defined at VueElement level as an action, `onclick`, `onchange`, etc
### Examples
```julia
@el(lun,"v-text-field",value="Luanda",label="Luanda",disabled=false)
@el(opo,"v-text-field",value="Oporto",label="Oporto")
@el(sub, "v-btn", value="Submit All", click=submit("api", context=[lun, opo],
    success=["this.window.alert('teste');","this.console.log('teste submissão');"],
    error=["this.console.log('teste erro');"]))
```
"""
function submit(
    url::String;
    method::String="POST",
    async::Bool=true,
    success::Vector=[],
    error::Vector=[],
    context::Vector=[])
    success = size(success, 1) > 0 ? """(function(xhr) {$(join(success,""))})""" : "null"
    error = size(error, 1) > 0 ? """(function(xhr) {$(join(error,""))})""" : "null"
    if context != []
        ids = [x.id for x in context] #Html or Vue Element `id`
        contents = replace(JSON.json(ids), "\""=>"'")
    else
        contents = "null"
    end
    return "submit($contents, '$url', '$method', $async, $success, $error)"
end
