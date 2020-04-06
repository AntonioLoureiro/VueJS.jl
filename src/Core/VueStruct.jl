mutable struct VueStruct

    id::String
    grid::Union{Array,VueHolder}
    binds::Dict{String,Any}
    cols::Union{Nothing,Int64}
    data::Dict{String,Any}
    def_data::Dict{String,Any}
    events::Dict{String, Any}
    scripts::String
    render_func::Union{Nothing,Function}
    styles::Dict{String,String}
    
end

function VueStruct(
    id::String,
    garr::Union{Array,VueHolder};
    binds=Dict{String,Any}(),
    data=Dict{String,Any}(),
    methods=Dict{String,Any}(),
    computed=Dict{String,Any}(),
    watch=Dict{String,Any}(),
    kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    haskey(args,"cols") ? cols=args["cols"] : cols=nothing

    styles=Dict()
    update_styles!(styles,garr)
    scope=[]
    garr=element_path(garr,scope)
    comp=VueStruct(id,garr,trf_binds(binds),cols,data,Dict{String,Any}(),Dict("methods"=>methods,"computed"=>computed,"watch"=>watch),"",nothing,styles)
    element_binds!(comp,binds=comp.binds)
    update_data!(comp,data)

    ## Cols
    m_cols=garr isa Array ? maximum(max_cols.(dom(garr))) : maximum(max_cols(dom(garr)))
    m_cols>12 ? m_cols=12 : nothing
    if comp.cols==nothing
        comp.cols=m_cols
    end
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
    
    events=create_events(vue)
    map(x->x.path=scope,events)
    #fix boilerplate @path@ from events generated in UPDATE_VALIDATE!
#     [x.script = replace(x.script,"@path@"=>(vue.path=="" ? "" : "$(vue.path).")) for x in evts]
    
    return events
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
            push!(s_f,"$k:$path.$k.submit(url, method, async, success, error,true)")
            boiler_this!(v,methods_ids,methods_code,count=count+=1,path=path*".$k")
        elseif v isa Dict
            ### Submit Function
            if haskey(v,"value")
                push!(s_f,"$k:$path.$k.value")
            end

            for (kk,vv) in v
                if kk in VueJS.KNOWN_JS_EVENTS && vv isa String
                    v2=deepcopy(strip(vv) in methods_ids ? strip(vv)*"()" : vv)
                    d[k][kk]="function(){$data $v2}" 
                end
                
            end
        end
    end
    d["submit"]="""function(url, method, async, success, error, no_post=false) {
     content={$(join(s_f,","))};
	    if (no_post) {
	        return content
	    } else {
     		return app.xhr(content, url, method, async, success, error)
		}
    }"""
end


function create_events(vs::Union{VueElement,VueStruct})
    all_events=[]
    append!(all_events, [MethodsEventHandler(k,"",v) for (k,v) in (haskey(vs.events,"methods") ? vs.events["methods"] : Dict())])
    append!(all_events, [ComputedEventHandler(k,"",v) for (k,v) in (haskey(vs.events,"computed") ? vs.events["computed"] : Dict())])
    append!(all_events, [WatchEventHandler(k,"",v) for (k,v) in (haskey(vs.events,"watch") ? vs.events["watch"] : Dict())])
    
    for ev in KNOWN_HOOKS
        append!(all_events, [HookEventHandler(k,ev,v) for (k,v) in (haskey(vs.events,ev) ? vs.events[ev] : Dict())])
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

	evs_noid=filter(x->!(x isa EventHandlerWithID),all_events)
    evs_wids=filter(x->x isa EventHandlerWithID,all_events)

    evs_dict=Dict()
    for (i, handler) in enumerate(evs_wids)
        len = handler.path=="" ? 0 : (count(c->c=='.',handler.path)+1)
        nt = (id=handler.id, i=i, len=len)
        #ids between watchers and computed can overlap, so include type in keys to distinguish
        key = (handler.id, typeof(handler))
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

	unique_evs=[evs_wids[v.i] for (k,v) in evs_dict]

    #only expose methods and computed to boiler_this!
    methods_ids=map(x->x.id, filter(y->typeof(y) in [MethodsEventHandler,ComputedEventHandler], unique_evs))
    methods_code=join(map(x->"var $x = app.$x;",methods_ids))

    unique_evs = convert(Vector{EventHandler}, unique_evs)
    append!(unique_evs,evs_noid)

#     ## check whether watch keys/ids refer to elements or other functions
#     for watcher in collect(filter(x->x isa WatchEventHandler, unique_evs))
#         if !(watcher.id in map(y->y.id, filter(x->typeof(x) in [MethodsEventHandler, ComputedEventHandler], unique_evs)))
#             #quote key/id if it refers to an element, important for nested elements
#             #https://vuejs.org/v2/api/#watch
#             watcher.id = "'$(watcher.id)'"
#         end
#     end
#     vs.events=unique_evs

    boiler_this!(vs.def_data,methods_ids,methods_code)
    vs.scripts=events_script(unique_evs)
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

events_script(handlers::Vector{MethodsEventHandler}) = "methods : {"*join(map(x->"$(x.id) : $(x.script)", handlers),",")*"}"
events_script(handlers::Vector{ComputedEventHandler}) = "computed : {"*join(map(x->"$(x.id) : $(x.script) ", handlers),",")*"}"

function events_script(handlers::Vector{WatchEventHandler})
    for handler in handlers
        if occursin("'", handler.id) #if quoted --> refers to an element
            id = replace(handler.id, "'"=>"")
            elpath = handler.path == "" ? id : "$(handler.path).$id"
			#=
			Check handler id to verify whether it's already correct or needs parsing
			##
			Users can define a watcher without specifying an element's full (future) path making it easier to both write and reuse watchers
			of a VueStruct.
			E.g:
			> watch=Dict("someElement.value"=>"function(val){console.log(this.someElement.value);}"))
			When doing this, it's important to refer to the element itself as `this.somElement` in the script body

			When `someElement` gets included in one or more inner VueStructs (e.g: another VueStruct with id `struct`),
			`someElement.value` needs to become `struct.someElement.value` and the script also needs to be parsed to
			replace occurrences of `this.someElement` with `this.struct.someElement`
			=#
			if handler.path != ""
				if !(id == "$(handler.path).$id") #unquoted id does not match expected id, user used the described shorthand version
					handler.id = "'$elpath'"
				end
			end
            handler.script = replace(handler.script, "this.$id"=>"this.$elpath")
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
        push!(out, """
            $kind()
            {
                $scripts
            }
            """)
    end
    return join(out, ",")
end
function events_script(events::Vector{EventHandler})
        
    els=[]

    for typ in [MethodsEventHandler,ComputedEventHandler,WatchEventHandler,HookEventHandler]
        ef=filter(x->x isa typ,events)
        if length(ef)!=0
            ef=convert(Vector{typ},ef)
            push!(els,events_script(ef))
        end
    end
    return join(els,",")
end
