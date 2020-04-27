mutable struct VueStruct

    id::String
    grid::Union{Array,VueHolder}
    binds::Dict{String,Any}
    data::Dict{String,Any}
    def_data::Dict{String,Any}
    events::Dict{String, Any}
    scripts::String
    render_func::Union{Nothing,Function}
    styles::Dict{String,String}
    attrs::Dict{String, Any}
end

function VueStruct(
    id::String,
    garr::Union{Array,VueHolder};
    binds=Dict{String,Any}(),
    data=Dict{String,Any}(),
    methods=Dict{String,Any}(),
    asynccomputed=Dict{String,Any}(),
    computed=Dict{String,Any}(),
    watch=Dict{String,Any}(),
    attrs=Dict{String,Any}(),
    kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    styles=Dict()
    update_styles!(styles,garr)
    scope=[]
    garr=element_path(garr,scope)
    comp=VueStruct(id,garr,trf_binds(binds),data,Dict{String,Any}(),Dict("methods"=>methods,"asynccomputed"=>asynccomputed,"computed"=>computed,"watch"=>watch),"",nothing,styles,attrs)
    element_binds!(comp,binds=comp.binds)
    
    return comp
end

function element_path(v::VueHolder,scope::Array)
    v.elements=deepcopy(element_path(v.elements,scope))
    return v
end

function element_path(arr::Array,scope::Array)

    new_arr=deepcopy(arr)
    scope_str=join(scope,".")

    for (i,rorig) in enumerate(new_arr)
        r=deepcopy(rorig)
        ## Vue Element
        if typeof(r)==VueElement
            new_arr[i].path=scope_str

        ## VueStruct
        elseif r isa VueStruct

            scope2=deepcopy(scope)
            push!(scope2,r.id)
            scope2_str=join(scope2,".")
            new_arr[i].grid=element_path(r.grid,scope2)
            new_binds=Dict{String,Any}()
            for (k,v) in new_arr[i].binds
               for (kk,vv) in v
                    path=scope2_str=="" ? k : scope2_str*"."*k
                    values=Dict(path=>kk)
                    for (kkk,vvv) in vv
                        if haskey(new_binds,kkk)
                            new_binds[kkk][vvv]=values
                        else
                            new_binds[kkk]=Dict(vvv=>values)
                        end
                    end
                end
            end
        new_arr[i].binds=new_binds

        ## VueHolder
        elseif r isa VueHolder
            new_arr[i]=element_path(r,scope)
        ## Array Elements/Components
        elseif r isa Array
            new_arr[i]=element_path(r,scope)
        end
    end
    return new_arr
end

get_events(vs,scope="")=[]
get_events(vh::VueHolder,scope="")=get_events(vh.elements,scope)
function get_events(vue::VueElement, scope="")
    id=scope=="" ? vue.id : scope*".$(vue.id)"
    ### Standard Vue Element Events
    if get(vue.no_dom_attrs,"storage",false)
        storage_key="$(id).$(vue.value_attr)"
        vue.events["watch"]=Dict("$(vue.id).$(vue.value_attr)"=>"function(val){localStorage.setItem('$(storage_key)', val)}")
        vue.events["mounted"]="localStorage.getItem('$(storage_key)')==null ? '' : app_state.$(storage_key)=localStorage.getItem('$(storage_key)')"
    end
    
    return create_events(vue)
end

function get_events(vs::Array,scope="")
    evs=Vector{EventHandler}()
    for r in vs
        if r isa VueStruct
            append!(evs,get_events(r,(scope=="" ? r.id : scope*"."*r.id)))
        else
            append!(evs,get_events(r,scope))
        end
    end
    return evs
end

function get_events(vs::VueStruct,scope="")
    
    events=create_events(vs)
    map(x->x.path=scope,events)
    append!(events,get_events(vs.grid,scope))
    return events
end

export submit
function boiler_this!(d::Dict,methods_ids::Vector,methods_code::String;count=1,path="app_state")

    context=count==1 ? "app" : "this"
    vars=collect(keys(d))
    append!(vars,CONTEXT_JS_FUNCTIONS)
    data=join(map(x->"var $x = $context.$x;",vars))*methods_code
    s_f=[]
    for (k,v) in d
        if v isa Dict && sum(map(x->x isa Dict,collect(values(v))))==(length(values(v))-length(intersect(keys(v),CONTEXT_JS_FUNCTIONS)))
            ### Submit Function
            push!(s_f,"$k:$path.$k.submit(url, method, async,true)")
            boiler_this!(v,methods_ids,methods_code,count=count+=1,path=path*".$k")
        elseif v isa Dict
            ### Submit Function
            if haskey(v,"value")
                push!(s_f,"$k:$path.$k.value")
            end

            for (kk,vv) in v
                if kk in VueJS.KNOWN_JS_EVENTS && vv isa String
                    v2=deepcopy(strip(vv) in vcat(methods_ids,CONTEXT_JS_FUNCTIONS) ? strip(vv)*"()" : vv)
                    d[k][kk]="function(){$data $v2}" 
                end
                
            end
        end
    end
    d["submit"]="""function(url, method, async, no_post=false) {
     content={$(join(s_f,","))};
	    if (no_post) {
	        return content
	    } else {
     		return app.xhr(content, url, method, async)
		}
    }"""
end


function create_events(vs::Union{VueElement,VueStruct})
    
    vs isa VueElement ? path=vs.path=="" ? "" : vs.path : path=""
    
    all_events=[]
    append!(all_events, [MethodsEventHandler(k,path,v) for (k,v) in (haskey(vs.events,"methods") ? vs.events["methods"] : Dict())])
    append!(all_events, [ComputedEventHandler(k,path,v) for (k,v) in (haskey(vs.events,"computed") ? vs.events["computed"] : Dict())])
    append!(all_events, [AsyncComputedEventHandler(k,path,v) for (k,v) in (haskey(vs.events,"asynccomputed") ? vs.events["asynccomputed"] : Dict())])
    append!(all_events, [WatchEventHandler(k,path,v) for (k,v) in (haskey(vs.events,"watch") ? vs.events["watch"] : Dict())])
    
    for ev in KNOWN_HOOKS
        if haskey(vs.events,ev) 
            if vs isa VueElement
                vs.events[ev] isa Vector ? append!(all_events,HookEventHandler(ev,path,vs.events[ev])) : push!(all_events,HookEventHandler(ev,path,vs.events[ev]))
            else
                vs.events[ev] isa Vector ? append!(all_events,HookEventHandler(ev,"",vs.events[ev])) : push!(all_events,HookEventHandler(ev,"",vs.events[ev]))
            end
        end
    end
    
    return all_events
end


function update_events!(vs::VueStruct)
	all_events=[]
    #standard events
    append!(all_events, STANDARD_APP_EVENTS)

    ### Events Defined in current VueStruct
    append!(all_events,create_events(vs))
    
    ### Get all lower level events
    append!(all_events,get_events(vs.grid))

    #only expose methods and computed to boiler_this!
    methods_ids=map(x->x.id, filter(y->typeof(y) in [MethodsEventHandler,ComputedEventHandler,AsyncComputedEventHandler], all_events))
    methods_code=join(map(x->"var $x = app.$x;",methods_ids))

    boiler_this!(vs.def_data,methods_ids,methods_code)
    
    vs.scripts=events_script(convert(Vector{EventHandler},all_events))
    return nothing
end


update_styles!(st_dict::Dict,v)=nothing
update_styles!(st_dict::Dict,a::Array)=map(x->update_styles!(st_dict,x),a)
update_styles!(st_dict::Dict,v::VueHolder)=map(x->update_styles!(st_dict,x),v.elements)
function update_styles!(st_dict::Dict,vs::VueStruct)
   merge!(st_dict,vs.styles)
end

function update_styles!(st_dict::Dict,v::VueElement)
    length(v.style)!=0 ? st_dict[v.id]=join(v.style) : nothing
    return nothing
end

function events_script(handlers::Vector{MethodsEventHandler}) 
    evs_dict=Dict()
    for (i, handler) in enumerate(handlers)
        handler.path=="" ? nothing : handler.script=replace(handler.script,"this."=>"this.$(handler.path).")
        len = handler.path=="" ? 0 : (count(c->c=='.',handler.path)+1)
        nt = (id=handler.id, i=i, len=len)
        #ids between watchers and computed can overlap
        key = handler.id
        if haskey(evs_dict, key)
            existing = evs_dict[key]
            #keep event with minimal path length : top-level events have priority over low-level events
            if existing.len > len
                evs_dict[key] = nt
            end
        else
           evs_dict[key] = nt
        end
    end
    
    handlers_filt=[handlers[v.i] for (k,v) in evs_dict]
    
   return "methods : {"*join(map(x->"$(x.id) : $(x.script)", handlers_filt),",")*"}"
    
end

function events_script(handlers::Vector{ComputedEventHandler}) 
    
    for handler in handlers
        handler.path=="" ? nothing : handler.script=replace(handler.script,"this."=>"this.$(handler.path).")
    end
   return "computed : {"*join(map(x->"$(x.id) : $(x.script) ", handlers),",")*"}"
end

function events_script(handlers::Vector{AsyncComputedEventHandler}) 
    
    for handler in handlers
        handler.path=="" ? nothing : handler.script=replace(handler.script,"this."=>"this.$(handler.path).")
    end
   return "asyncComputed : {"*join(map(x->"$(x.id) : $(x.script) ", handlers),",")*"}"
end

function events_script(handlers::Vector{WatchEventHandler})
    for handler in handlers
        handler.id=handler.path=="" ? handler.id : handler.path*"."*handler.id
        handler.path=="" ? nothing : handler.script=replace(handler.script,"this."=>"this.$(handler.path).")
        if occursin(".",handler.id)
            handler.id="'$(handler.id)'"
        end
    end
    return "watch : {"*join(map(x->"$(x.id) : $(x.script)", handlers),",")*"}"
end

function events_script(handlers::Vector{HookEventHandler})
    hooks = Dict()
	sort!(handlers,by=x->length(x.path),rev=true)
    for handler in handlers
        kind = handler.kind
        !haskey(hooks, kind) ? hooks[kind] = [] : nothing #init this kind of hook
        handler.script = endswith(handler.script, ";") ? handler.script : handler.script * ";"
		push!(hooks[kind], handler.script)
    end
    out = []
    for kind in collect(keys(hooks))
        #remove duplicates
        scripts = join(unique!(hooks[kind]))
        push!(out, "$kind:function(){$scripts}")
    end
    
    return join(out, ",")
end

function events_script(events::Vector{EventHandler})
    els=[]
    for typ in [MethodsEventHandler,AsyncComputedEventHandler,ComputedEventHandler,WatchEventHandler,HookEventHandler]
        ef=filter(x->x isa typ,events)
        if length(ef)!=0
            push!(els,events_script(convert(Vector{typ},ef)))
        end
    end
    return join(els,",")
end

import Base.getindex
import Base.setindex!

function get_vue(a::Array, i::String)
    for r in a
       
        if r isa Array 
            retl=get_vue(r,i)
            if retl!=nothing
                return retl
            end
        elseif r isa VueJS.VueHolder
            retl=get_vue(r.elements,i)
            if retl!=nothing
                return retl
            end
        elseif r isa VueJS.VueElement || r isa VueStruct
            if r.id==i
                return r
            end
        end
    end
    
    return nothing
end

function Base.getindex(el::VueStruct, i::String)
    ret=get_vue(el.grid, i::String)
    if ret==nothing
        return error("KeyError: key \"$i\" not found")
    else
        return ret
    end
end


function set_vue(a::Array, v, i::String)
    for r in a
        if r isa Array 
            set_vue(r,v,i)
        elseif r isa VueJS.VueHolder
            set_vue(r.elements,v,i)
        elseif r isa VueJS.VueElement || r isa VueStruct
            if r.id==i
                Base.setindex!(r,v,i)
            end
        end
    end
    
    return error("KeyError: key \"$i\" not found")
end

function Base.setindex!(el::VueStruct,v, i::String)
    
    Base.setindex!(el.grid, v,i)
    return nothing
end
