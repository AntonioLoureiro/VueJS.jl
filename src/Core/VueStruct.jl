mutable struct VueStruct

    id::String
    grid::Union{Array,VueHolder}
    binds::Dict{String,Any}
    cols::Union{Nothing,Int64}
    data::Dict{String,Any}
    def_data::Dict{String,Any}
    events::Vector{EventHandler}
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
    comp=VueStruct(id,garr,trf_binds(binds),cols,data,Dict{String,Any}(),[],nothing,styles)
    element_binds!(comp,binds=comp.binds)
    update_data!(comp,data)
    update_events!(comp,methods=methods,computed=computed,watch=watch)
        
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
function get_events(vs::Array,scope="")
    evs=Vector{EventHandler}()
    for r in vs
        if r isa VueStruct
        scope=(scope=="" ? r.id : scope*"."*r.id)
        end
        append!(evs,get_events(r,scope))
    end
    return evs
end
function get_events(vs::VueStruct,scope="")
    events=deepcopy(vs.events)          
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
                    v2=strip(vv) in methods_ids ? strip(vv)*"()" : vv
                    d[k][kk]="function(){$data $v2}" 
                end
            end
        end
    end   
    d["submit"]="""function(url, method, async, success, error,no_post=false){
     content={$(join(s_f,","))};
     if (no_post){
        return content
    } else{   
     return app.xhr(content, url, method, async, success, error)}
    }"""
end

function update_events!(vs::VueStruct;methods=[],computed=[],watch=[])
    all_events=[]
    ### Standard Events
    append!(all_events,STANDARD_APP_EVENTS)
    
    ### Events Defined in current VueStruct
    append!(all_events, [MethodsEventHandler(k,"","function(){$v}") for (k,v) in methods])
    append!(all_events, [ComputedEventHandler(k,"","function(){$v}") for (k,v) in computed])
    append!(all_events, [WatchEventHandler(k,"","function(){$v}") for (k,v) in watch])
    
    ### Get all lower level events
    append!(all_events,get_events(vs.grid,""))
    
    evs_noid=filter(x->!(x isa EventHandlerWithID),all_events)
    evs_wids=filter(x->x isa EventHandlerWithID,all_events)
    evs_wids_nt=[(id=r.id,i=i,len=(r.path=="" ? 0 : count(".",r.path)+1)) for (i,r) in enumerate(evs_wids)]
    evs_dict=Dict()
    for r in evs_wids_nt
        if haskey(evs_dict,r.id)
           evs_dict[r.id].len>r.len ? evs_dict[r.id]=r : nothing
        else
           evs_dict[r.id]=r
        end
    end
    
    unique_evs=[evs_wids[v.i] for (k,v) in evs_dict]
    methods_ids=map(x->x.id,unique_evs)
    methods_code=join(map(x->"var $x = app.$x;",methods_ids))
    
    append!(unique_evs,evs_noid)
    vs.events=unique_evs
    
    boiler_this!(vs.def_data,methods_ids,methods_code)
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

events_script(a::Vector{MethodsEventHandler})="methods : {"*join(map(x->"$(x.id) : $(x.script)",a),",")*"}"
events_script(a::Vector{ComputedEventHandler})="computed : {"*join(map(x->"""$(x.path=="" ? x.id : x.path*"."*x.id) : $(x.script)""",a),",")*"}"
events_script(a::Vector{WatchEventHandler})="watch : {"*join(map(x->"""$(x.path=="" ? x.id : x.path*"."*x.id) : $(x.script)""",a),",")*"}"

function events_script(vs::VueStruct)
    
    els=[]
    
    for typ in [MethodsEventHandler,ComputedEventHandler,WatchEventHandler,HookEventHandler]
        ef=filter(x->x isa typ,vs.events)
        if length(ef)!=0
            ef=convert(Vector{typ},ef)
            push!(els,events_script(ef))
        end
    end
    return join(els,",")
end
