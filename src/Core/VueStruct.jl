mutable struct VueStruct

    id::String
    grid::Union{Array,VueHolder}
    binds::Dict{String,Any}
    data::Union{Dict{String,Any},Vector{Dict{String,Any}}}
    def_data::Union{Dict{String,Any},Vector{Dict{String,Any}}}
    events::Dict{String, Any}
    scripts::String
    render_func::Union{Nothing,Function}
    attrs::Dict{String, Any}
    iterable::Bool
end

function VueStruct(
    id::String,
    garr::Union{Array,VueHolder};
    binds=Dict{String,Any}(),
    data=Dict{String,Any}(),
    value=Dict{String,Any}(),
    iterable=false,
    methods=Dict{String,Any}(),
    asynccomputed=Dict{String,Any}(),
    computed=Dict{String,Any}(),
    watch=Dict{String,Any}(),
    style=Dict{String,Any}(),
    class=Dict{String,Any}(),
    kwargs...)
    
    attrs=Dict{String,Any}()
    attrs["style"]=deepcopy(PAGE_OPTIONS.style)
    attrs["class"]=deepcopy(PAGE_OPTIONS.class)
    
    length(style)!=0 ? merge!(attrs["style"],style) : nothing
    length(class)!=0 ? merge!(attrs["class"],class) : nothing
    
    new_opts=deepcopy(PAGE_OPTIONS)
    merge!(new_opts.style,attrs["style"])
    merge!(new_opts.class,attrs["class"])
        
    update_style!(garr,new_opts)
    
    scope=[]
    garr=element_path(garr,scope)
    
    ## value is alias of data
    data==Dict() ? data=value : nothing
    if data isa Vector 
        iterable=true
        data=convert.(Dict{String,Any},data)
        def_data=[]
    else
        data=convert(Dict{String,Any},data)
        def_data=Dict{String,Any}()
    end

    events=Dict{String,Any}("methods"=>methods,"asynccomputed"=>asynccomputed,"computed"=>computed,"watch"=>watch)
    
    ## Kwargs only accepts lifecycle hooks
    for (k,v) in kwargs
        
        @assert string(k) in KNOWN_HOOKS "$k keyword not acceptable"
        @assert v isa String "value of $k should be a String"
        
        events[string(k)]=v
    end
    
    iterable==true ? def_data=Vector{Dict{String,Any}}() : nothing
        comp=VueStruct(id,garr,trf_binds(binds),data,def_data,events,"",nothing,attrs,iterable)
    element_binds!(comp,binds=comp.binds)
    
    return comp
end

macro st(varname,els,args...)
    @assert varname isa Symbol "1st arg should be Variable name"
    
    @assert els isa Expr "2nd arg should be Array of Elements"
          
    newargs=join([r for r in args],",")
    
    if length(newargs)==0
        newexpr=(Meta.parse("""VueJS.VueStruct("$(string(varname))",$(els))"""))
    else
        newexpr=(Meta.parse("""VueJS.VueStruct("$(string(varname))",$(els),$newargs)"""))
    end
    return quote
        $(esc(varname))=$(esc(newexpr))
    end
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

get_def_obj(o)=Dict()
function get_def_obj(vue::VueJS.VueElement)
    rd=Dict(vue.id=>Dict())
    value_attr=vue.value_attr
    for (k,v) in vue.binds
         nk=(value_attr!="value" && k==value_attr) ? "value" : k			
         rd[vue.id][nk]=get(vue.attrs,k,nothing)
    end
    
    return length(rd[vue.id])==0 ? Dict() : rd
end
    
get_def_obj(a::VueJS.VueHolder)=get_def_obj(a.elements)
function get_def_obj(a::Array)
    rd=Dict()
    for r in a
        merge!(rd,get_def_obj(r))
    end
    return rd
end

function get_def_obj(vs::VueStruct)
    rd=Dict(vs.id=>get_def_obj(vs.grid))

     if !vs.iterable
     fn_dict=Dict("submit"=>[],"submit_files"=>[])
     in_context_functions!(vs,fn_dict,vs.id,vs.def_data)
        if haskey(vs.def_data,"submit")
            rd[vs.id]["submit"]=vs.def_data["submit"]
        end
    end
    return rd
end

function needs_multipart(ve::VueJS.VueElement)
    if ve.tag=="v-file-input"
        return true
    else
        return false
    end
end
    
in_context_functions!(a,fn_dict::Dict,context::String,def_data::Dict)=nothing
in_context_functions!(a::VueJS.VueHolder,fn_dict::Dict,context::String,def_data::Dict)=map(x->in_context_functions!(x,fn_dict,context,def_data),a.elements)
function in_context_functions!(ve::VueJS.VueElement,fn_dict::Dict,context::String,def_data::Dict)
    if ve.value_attr!=nothing 
        if needs_multipart(ve)
            push!(fn_dict["submit"],"$(ve.id):[]")
            push!(fn_dict["submit_files"],"$context.$(ve.id).value")
            fn_dict["mp_mode"]=true
        else
            push!(fn_dict["submit"],"$(ve.id):this.$(ve.id).value")
        end
    end
end


export submit,add,remove

function in_context_functions!(vs::VueStruct,fn_dict_prev::Dict,context::String,def_data::Dict)
  
    fn_dict=Dict("submit"=>[],"submit_files"=>[],"mp_mode"=>false)
    
    if vs.iterable

        ## Upper Level update of elements
        map(x->in_context_functions!(vs.grid,fn_dict,"x",x),def_data[vs.id]["value"])
        push!(fn_dict_prev["submit"],"""$(vs.id):this.$(vs.id).value.map(function(x) { return {$(replace(join(fn_dict["submit"],","),"this."=>"x."))}})""")
                        
        def_data[vs.id]=convert(Dict{String,Any},def_data[vs.id])
        
        ### add fn
        def_data[vs.id]["empty_obj"]=VueJS.get_def_obj(vs)[vs.id]
        empty_obj_str=VueJS.vue_json(VueJS.get_def_obj(vs)[vs.id],false)
        def_data[vs.id]["add"]="""function(){this.value.push($empty_obj_str)}"""
        
        ### delete fn
        def_data[vs.id]["remove"]="""function(i){this.value.splice(i,1)}"""
        
    else
        
        ## update fn_dict updates also VueStructs
        in_context_functions!(vs.grid,fn_dict,context,def_data)
        
        if context!="app_state"
            push!(fn_dict_prev["submit"],"$(vs.id):this.$(vs.id).submit(url,null, method, async,true)")
        end
    
     ### Submit fn
     if fn_dict["mp_mode"]==false
         def_data["submit"]="""function(url, sub_content=null,method, async, no_post=false) {
            
        if (sub_content==null){
         content={$(join(fn_dict["submit"],","))};
            if (no_post) {
                return content
            } else {
                return xhr(JSON.stringify(content), url, method, async)
            }
            } else {
               if (typeof(sub_content) !== "object") {throw new Error("2nd arg should be object")}
               return xhr(JSON.stringify(sub_content), url, method, async)
            }}"""
    else
        files_obj=join(map(x->"{'$x':$x}",fn_dict["submit_files"]),",")
        json_obj="{"*join(fn_dict["submit"],",")*"}"
        def_data["submit"]="""function(url, sub_content=null,method, async, no_post=false) {
        if (sub_content==null){
            const content = new FormData();
            json_content=JSON.stringify($json_obj);
            const blob = new Blob([json_content], {type: 'application/json'});
            content.append("json", blob);
            const arr_files=[$files_obj];
            for (const i in arr_files) {
                for (const el in arr_files[i]){
                    for (const filei in arr_files[i][el]){
                    file_name=el+'.'+filei
                    content.append(file_name,arr_files[i][el][filei]);
                    }
                }
            }
                if (no_post) {
                     return $json_obj
                } else {
                    return xhr(content, url, method, async)
                }
        } else{ 
            if (typeof(sub_content) !== "object") {throw new Error("2nd arg should be object")}
            const content = new FormData();
            for (oi in sub_content){
                            if (Array.isArray(sub_content[oi])){
                    if(typeof(sub_content[oi][0])=="object"){
                        
                        for (const el in sub_content[oi]){
                                if(typeof(sub_content[oi][0].filename=="String")){
                                    file_name='app_state.'+oi+'.value.'+el
                                    content.append(file_name,sub_content[oi][el]);
                                }
                        } 
                    }}}
            
            json_content=JSON.stringify(sub_content);
            const blob = new Blob([json_content], {type: 'application/json'});
            content.append("json", blob);
            return xhr(content, url, method, async)
        }}"""   
            
    end
    
    vs.def_data=def_data
    end
    
    if fn_dict["mp_mode"] 
       fn_dict_prev["mp_mode"]=true
       append!(fn_dict_prev["submit_files"],fn_dict["submit_files"]) 
    end
    
    return nothing
end

function in_context_functions!(a::Vector,fn_dict::Dict,context::String,def_data::Dict)
    for r in a
        if r isa VueStruct
            if r.iterable
                in_context_functions!(r,fn_dict,context,def_data)
            else
                in_context_functions!(r,fn_dict,context*"."*r.id,def_data[r.id])
            end
        else
            in_context_functions!(r,fn_dict,context,def_data)
        end
    end
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
    
    ## Only put functions for main content
    if vs.id=="app"
        in_context_functions!(vs,Dict("submit"=>[],"submit_files"=>[],"mp_mode"=>false),"app_state",vs.def_data)
    end
    
    vs.scripts=events_script(convert(Vector{EventHandler},all_events))
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
