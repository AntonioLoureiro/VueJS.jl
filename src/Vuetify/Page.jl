const SFC_LOADER = read(joinpath(@__DIR__, "Page_SFC.js"), String)
function htmlstring(page_inst::VueJS.Page)
    includes=[]
    css_deps=[]
    for d in page_inst.dependencies
        if d.type == "js"
            push!(includes, VueJS.head("script"=>Dict("src"=>d.path)))
        elseif d.type == "css"
            push!(includes, VueJS.head("link"=>Dict("rel"=>"stylesheet", "type"=>"text/css", "href"=>d.path)))
        end
        push!(css_deps, d.css)
    end
    push!(css_deps, VueJS.css_str(VueJS.PAGE_OPTIONS.css))

    # Prepare HEAD
    head_items = VueJS.HtmlElement[]
    if page_inst.title !== nothing push!(head_items, head("title"=>page_inst.title)) end
    [push!(head_items, meta) for meta in page_inst.meta]

    append!(head_items, includes)   

    push!(head_items, html("style", join(css_deps," ")))
    head_dom = html("head", head_items, Dict())

    scripts         = []
    components_dom  = []

    is_sfc = haskey(page_inst.components, "_placeholder") && page_inst.components["_placeholder"] isa VueSFC
    if is_sfc

        # get page placeholder and props
        sfc_placeholder = page_inst.components["_placeholder"].name
        sfc_props = join([attr_render(k, v) for (k, v) in page_inst.components["_placeholder"].props])
        delete!(page_inst.components, "_placeholder")

        # prepare components instantiation
        sfc_component_inst  = String[]
        sfc_component_dec   = String[]
        sfc_route           = String[]
        for (k,comp) in page_inst.components
            push!(sfc_component_inst, "const $k = Vue.defineAsyncComponent(() => loadModule('$(comp.url)', options));")
            push!(sfc_component_dec, "'$k': $k,")
            if !isnothing(comp.path)
                push!(sfc_route, "{ path: '$(comp.path)', component: $k },")
            end
        end

        # prepare page instantiation
        sfc_loader = replace(SFC_LOADER,
            "__SFC_COMPONENT_INST__"    => join(sfc_component_inst, "\n"),
            "__SFC_COMPONENT_DEC__"     => join(sfc_component_dec, "\n"),
            "__SFC_ROUTES__"            => join(sfc_route, "\n"),
            "__SFC_PLACEHOLDER__"       => sfc_placeholder,
            "__SFC_PROPS__"             => sfc_props,
        )

        push!(scripts, sfc_loader)

    else
        push!(scripts, "const vuetify = Vuetify.createVuetify()")

        # Add components to scripts
        components = Dict{String,String}()
        [merge!(components, d.components) for d in page_inst.dependencies if length(d.components) > 0]
        push!(scripts,"""const components = $(replace(VueJS.JSON.json(components),"\""=>""))""")

        app_state=Dict{String,Any}()
        ## initialize globals
        app_state["globals"]=page_inst.globals

        ## Other components
        for (k,v) in page_inst.components
            if k=="v-main"
                ## component script
                VueJS.update_data!(v,v.data)
                VueJS.update_events!(v, page_inst.scripts)
                merge!(app_state,v.def_data)
                
                comp_script=[]
                push!(comp_script,"template: '#app-template'")
                push!(comp_script,"components:components")
                push!(comp_script,"data(){return app_state}")
                push!(comp_script, v.scripts)
                
                comp_script="const app = Vue.createApp({"*join(comp_script,",")*"}).use(vuetify).mount('#app')"
                push!(scripts,comp_script)
                opts=VueJS.PAGE_OPTIONS
                opts.path="root"
                push!(components_dom,html("v-main",html("v-container",VueJS.dom(v,opts=opts),Dict("fluid"=>true)),Dict()))
            else
                  
                opts=VueJS.PAGE_OPTIONS
                vsid=VueJS.vue_escape(k)
                v isa VueJS.VueHolder ? opts.path=vsid : opts.path=""
                vs=VueStruct(VueJS.vue_escape(k),[v])
                
                found_data=convert(Dict{String,Any},VueJS.update_data!(vs,vs.data))
                vs.def_data=found_data
                VueJS.update_events!(vs)
                merge!(app_state,vs.def_data)
                                
                comp_el=VueJS.dom([vs],opts=opts)[1].value.value        
                comp_el.attrs["app"]=true
                push!(components_dom,comp_el)
            end
        end
        components_dom = html("v-app", components_dom)
    
        scripts=vcat("const app_state = $(VueJS.vue_json(app_state))",scripts)
            
    end
    body_dom=html("body",[html("script",components_dom,Dict("type"=>"text/x-template","id"=>"app-template","v-cloak"=>true)),html("div","",Dict("id"=>"app")),
                 """<script>xhr=$(VueJS.xhr_script)\n$(join(scripts,"\n"))</script>"""            
                ],Dict())

    htmlpage = html("!DOCTYPE html", [head_dom, body_dom], Dict())

    return htmlstring(htmlpage)
end