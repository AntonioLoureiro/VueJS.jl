mutable struct EventHandler

    kind::String
    id::String
    args::Vector{String}
    script::String
    function_script::String

end

mutable struct VueStruct

     id::String
     grid::Array
     binds::Dict{String,Any}
     cols::Union{Nothing,Int64}
     data::Dict{String,Any}
     def_data::Dict{String,Any}
     events::Vector{EventHandler}

end

function VueStruct(id::String,garr::Array;binds=Dict{String,Any}(),data=Dict{String,Any}(),methods=Dict{String,Any}(),computed=Dict{String,Any}(),watched=Dict{String,Any}(),kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    haskey(args,"cols") ? cols=args["cols"] : cols=nothing

    events=create_events((methods=methods,computed=computed,watched=watched))

    scope=[]
    garr=element_path(garr,scope)
    comp=VueStruct(id,garr,VueJS.trf_binds(binds),cols,data,Dict{String,Any}(),events)
    element_binds!(comp,binds=comp.binds)
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

        ## Array Elements/Components
        elseif r isa Array
            new_arr[i]=element_path(r,scope)
        end
    end
    return new_arr
end

function dom_scripts(el::VueStruct)

    scripts=[]
    push!(scripts,"const app_state = $(vue_json(el.def_data))")

    ## component script
    comp_script=[]
    push!(comp_script,"el: '#app'")
    push!(comp_script,"vuetify: new Vuetify()")
    push!(comp_script,"data: app_state")

    push!(comp_script, events_script(el))

    comp_script="var app = new Vue({"*join(comp_script,",")*"})"
    push!(scripts,comp_script)

    arr_dom=grid(el.grid)
    dom=HtmlElement("div",Dict("id"=>"app"),
             HtmlElement("v-app",
                 HtmlElement("v-container",Dict("fluid"=>true),arr_dom)))

    return (dom=dom,scripts=scripts)

end
