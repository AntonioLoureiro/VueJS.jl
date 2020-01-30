mutable struct VueComponent
     id::String
     grid::Array
     binds::Dict{String,Any}
     scriptels::Vector{String}
     cols::Union{Nothing,Int64}
     data::Dict{String,Any}
     def_data::Dict{String,Any}
end

function VueComponent(
        id::String,
        garr::Array;
        binds=Dict{String,Any}(),
        data=Dict{String,Any}(),
        kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    scripts=haskey(args,"scripts") ? args["scripts"] : []
    haskey(args,"cols") ? cols=args["cols"] : cols=nothing

    scope=[]
    garr=element_path(garr,scope)
    comp=VueComponent(id,garr,trf_binds(binds),scripts,cols,data,Dict{String,Any}())
    element_binds!(comp, binds=comp.binds)
    update_data!(comp,data)

    return comp
end

function element_path(arr::Array,scope::Array)

    new_arr=deepcopy(arr)
    scope_str=join(scope,".")

    for (i, rorig) in enumerate(new_arr)
        r=deepcopy(rorig)
        ## Vue Element
        if r isa VueElement
            new_arr[i].path=scope_str
        ## Vue Component
    elseif r isa VueComponent
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
