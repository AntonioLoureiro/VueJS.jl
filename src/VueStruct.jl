
mutable struct VueStruct

    id::String
    grid::Array
    binds::Dict{String,Any}
    cols::Union{Nothing,Int64}
    data::Dict{String,Any}
    def_data::Dict{String,Any}
    methods::Dict{String,Any}
    computed::Dict{String, Any}
    watched::Dict{String, Any}
end

function VueStruct(
    id::String,
    garr::Array;
    binds=Dict{String,Any}(),
    data=Dict{String,Any}(),
    methods=Dict{String,Any}(),
    computed=Dict{String, Any}(),
    watched=Dict{String, Any}(),
    kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    haskey(args,"cols") ? cols=args["cols"] : cols=nothing

    scope=[]
    garr=element_path(garr, scope)
    comp=VueStruct(id,garr,trf_binds(binds),cols,data,Dict{String,Any}(),methods, computed, watched)
    element_binds!(comp, binds=comp.binds)
    update_data!(comp,data)

    ## Cols
    m_cols=maximum(max_cols.(grid(garr)))
    m_cols>12 ? m_cols=12 : nothing
    if comp.cols==nothing
        comp.cols=m_cols
    end
    return comp
end

function element_path(arr::Array,scope::Array)

    new_arr=deepcopy(arr)
    scope_str=join(scope,".")

    for (i,rorig) in enumerate(new_arr)
        r=deepcopy(rorig)
        ## Vue Element
        if typeof(r) <: VueElement

            new_arr[i].path=scope_str

        ## VueStruct
        elseif r isa VueStruct

            scope2=deepcopy(scope)
            push!(scope2,r.id)
            scope2_str=join(scope2,".")
            new_arr[i].grid=element_path(r.grid,scope2)
            new_binds=Dict{String,Any}()
            for (k,v) in new_arr[i].binds
               for (ki,vi) in v
                    path=scope2_str=="" ? k : scope2_str*"."*k
                    values=Dict(path=>ki)
                    for (kij,vij) in vi
                        if haskey(new_binds,kij)
                            new_binds[kij][vij]=values
                        else
                            new_binds[kij]=Dict(vij=>values)
                        end
                    end
                end
            end
        new_arr[i].binds=new_binds

        ## Array Elements/Components
        elseif r isa Array
            new_arr[i]=element_path(r,scope)
        end
    end
    return new_arr
end
