abstract type EventHandler end
    
mutable struct CustomEventHandler <:EventHandler

    kind::String
    id::String
    args::Vector{String}
    script::String
    path::String
    function_script::String

end

mutable struct StdEventHandler <:EventHandler

    kind::String
    id::String
    path::String
    function_script::String

end

mutable struct HookHandler <: EventHandler
    kind::String
    path::String
    function_script::String
end

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
    hooks::Vector{EventHandler}
    
end

function VueStruct(
    id::String,
    garr::Union{Array,VueHolder};
    binds=Dict{String,Any}(),
    data=Dict{String,Any}(),
    methods=Dict{String,Any}(),
    computed=Dict{String,Any}(),
    watched=Dict{String,Any}(),
    kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    haskey(args,"cols") ? cols=args["cols"] : cols=nothing

    events=create_events((methods=methods,computed=computed,watched=watched))
    styles=Dict()
    update_styles!(styles,garr)
    scope=[]
    garr=element_path(garr,scope)
    comp=VueStruct(id,garr,trf_binds(binds),cols,data,Dict{String,Any}(),events,nothing,styles, hooks)
    element_binds!(comp,binds=comp.binds)
    update_data!(comp,data)
    new_es=Vector{EventHandler}()
    update_events!(comp,new_es)
    std_events!(comp,new_es)
    sort!(new_es,by=x->length(x.path),rev=false)
    new_es=unique(x->x.id,new_es)
    comp.events=new_es
    function_script!.(comp.events)
    
    try
        hooks=create_hooks(garr)
        new_hs=Vector{HookHandler}()
        update_events!(comp,new_hs)
        sort!(new_hs,by=x->length(x.path),rev=false)
        comp.hooks=new_hs
    catch err
        
    end
        
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
            ## hack for v-for
            haskey(r.attrs,"v-for") ? new_arr[i].attrs["v-for"]=replace(new_arr[i].attrs["v-for"],"@path@"=>(scope_str=="" ? "" : "$scope_str.")) : nothing

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

update_events!(vs,new_es::Vector{T} where T<:EventHandler,scope="")=new_es=new_es
function update_events!(vs::Array,new_es::Vector{T} where T<:EventHandler, scope="")
    for r in vs
        if r isa VueStruct
        scope=(scope=="" ? r.id : scope*"."*r.id)
        end
        update_events!(r,new_es,scope)
    end
end
function update_events!(vs::VueStruct,new_es::Vector{EventHandler},scope="")
    events=deepcopy(vs.events)
    map(x->x.path=scope,events)
    append!(new_es,events)
    update_events!(vs.grid,new_es,scope)
end
function update_events!(vs::VueStruct,new_hs::Vector{HookHandler}, scope="")
    hooks=deepcopy(vs.hooks)
    map(x->x.path=scope,hooks)
    append!(new_hs,hooks)
    update_events!(vs.grid,new_hs,scope)
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
