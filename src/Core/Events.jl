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
