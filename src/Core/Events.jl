abstract type EventHandler end
abstract type EventHandlerWithID<:EventHandler end

abstract type EventHandlerIDWithPath<:EventHandlerWithID end

mutable struct MethodsEventHandler <:EventHandlerWithID

    id::String
    path::String
    script::String
end

mutable struct ComputedEventHandler <:EventHandlerIDWithPath

    id::String  
    path::String
    script::String
end

mutable struct WatchEventHandler <:EventHandlerIDWithPath

    id::String  
    path::String
    script::String
end

mutable struct HookEventHandler <:EventHandler
    
    kind::String
    path::String
    script::String
end

            
STANDARD_APP_EVENTS=Vector{EventHandler}()

#### get_attr ####
get_attr_script="""function (o,attr) {
    ret={}
    for (var k in o) {
        if (typeof(o[k]=="object")) {
			
			if(attr in o[k]){
				ret[k]=o[k][attr];
			} else 	{
            result=traverse(o[k],attr);
			ret[k]==undefined ? '' : ret[k]=result
			}
		}
    }
return ret
}"""
push!(STANDARD_APP_EVENTS,MethodsEventHandler("get_attr","",get_attr_script))

###### XHR #######
xhr_script = """function(contents, url=window.location.pathname, method="POST", async=true, success=null, error=null) {

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
push!(STANDARD_APP_EVENTS,MethodsEventHandler("xhr","",xhr_script))

##### Open Method #####
open_script=""" function(url,name) {
        name = typeof name !== 'undefined' ? name : '_self';
        window.open(url,name);
        }"""

push!(STANDARD_APP_EVENTS,MethodsEventHandler("open","",open_script))

## Datatable Col Format
col_format_script=""" function(item,format_script) {
    return format_script(item)
    }"""
push!(STANDARD_APP_EVENTS,MethodsEventHandler("datatable_col_format","",col_format_script))

#### Submit Method ####
submit_script="""function(context, url, method, async, success, error) {
        // var call_context should be created in run_in_closure
        var ret=get_attr(call_context,"value")

        return xhr(JSON.stringify(ret), url, method, async, success, error)
    }"""

push!(STANDARD_APP_EVENTS,MethodsEventHandler("submit","",submit_script))

#################################################################################################
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
