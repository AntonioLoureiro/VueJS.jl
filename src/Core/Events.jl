abstract type EventHandler end
abstract type EventHandlerWithID<:EventHandler end

abstract type EventHandlerIDWithPath<:EventHandlerWithID end

mutable struct MethodsEventHandler <:EventHandlerWithID

    id::String
    path::String
    script::String
end
function MethodsEventHandler(id::String, path::String, script::Tuple{String, Vector})
    args = join(last(script), ",")
    script = "function($args){$(first(script))}"
    return MethodsEventHandler(id, path, script)
end

mutable struct ComputedEventHandler <:EventHandlerIDWithPath

    id::String
    path::String
    script::String
	function ComputedEventHandler(id, path, script::String)
		if occursin("get", script) || occursin("set", script) &&
			(!startswith(script,"{") && !endswith(script, "}"))
	        script = "{$script}" #add braces for correct get, set structure
		end
		new(id, path, script)
	end
end
function ComputedEventHandler(id::String, path::String, script::Tuple{String, Dict})
    props = join(["$k : $v" for (k,v) in last(script)])
    script = first(script)
    if occursin("get", script) || occursin("set", script) #script has a get() set() structure
        script = props != "" ? "$script, $props" : "$script"
    end
    return ComputedEventHandler(id, path, script)
end

mutable struct WatchEventHandler <:EventHandlerIDWithPath

    id::String
    path::String
    script::String
end
function WatchEventHandler(id::String, path::String, script::Tuple{String, Vector, Dict})
    args = join(handler.script[2], ",")
    props = join["$k : $v" for (k,v) in last(script)]
    script = "function($args){$(first(script))}"
    script = (props != "" ? "handler : $script, $props" : script)
    return WatchEventHandler(id, path, script)
end

mutable struct HookEventHandler <:EventHandler

    kind::String
    path::String
    script::String
end

evt_map = Dict("computed"=>ComputedEventHandler, "methods"=>MethodsEventHandler, "watch"=>WatchEventHandler)

###############################################################
STANDARD_APP_EVENTS=Vector{EventHandler}()

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

#### Filter DataTable ####
filter_dt_script="""function(cont,col,value,oper){
      idx=cont.headers_idx[col]
      cont.headers[idx].filter_value=value
      oper!=undefined ? cont.headers[idx].filter_mode=oper : ""
    }"""
push!(STANDARD_APP_EVENTS,MethodsEventHandler("filter_dt","",filter_dt_script))

#get cookie value by cookie name
function_script="""
 function(cname) {
    var name = cname + "=";
    var decodedCookie = decodeURIComponent(document.cookie);
    var ca = decodedCookie.split(';');
    for(var i = 0; i <ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') {
          c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
          return c.substring(name.length, c.length);
        }
    }
    return "";
    }
"""
push!(STANDARD_APP_EVENTS,MethodsEventHandler("getcookie","",function_script))

#set a cookie
function_script = """
function(name, value, days) {
    var d = new Date;
    d.setTime(d.getTime() + 24*60*60*1000*days);
    maxage = days*86400;
    document.cookie = name + "=" + value + ";path=/;max-age="+maxage+";expires=" + d.toGMTString();
}
"""
push!(STANDARD_APP_EVENTS,MethodsEventHandler("setcookie","",function_script))
