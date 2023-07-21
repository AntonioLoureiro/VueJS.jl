function htmlstring(page_inst::Page)
    includes=[]
    css_deps=[]
    for d in page_inst.dependencies
        if d.type == "js"
            push!(includes, head("script"=>Dict("src"=>d.path)))
        elseif d.type == "css"
            push!(includes, head("link"=>Dict("rel"=>"stylesheet", "type"=>"text/css", "href"=>d.path)))
        end
        push!(css_deps, d.css)
    end
    push!(css_deps, css_str(PAGE_OPTIONS.css))

    # Prepare HEAD
    head_items = HtmlElement[]
    if page_inst.title !== nothing push!(head_items, head("title"=>page_inst.title)) end
    [push!(head_items, meta) for meta in page_inst.meta]

    append!(head_items, includes)   

    push!(head_items, html("style", join(css_deps," ")))
    head_dom = html("head", head_items, Dict())

    # Prepare SCRIPTS
    scripts = deepcopy(page_inst.scripts)
    push!(scripts, "const vuetify = new Vuetify()")

    components_dom=[]

    is_sfc = haskey(page_inst.components, "_placeholder") && page_inst.components["_placeholder"] isa VueSFC
    if is_sfc

        # get page placeholder and props
        sfc_placeholder = page_inst.components["_placeholder"].name
        sfc_props = join([attr_render(k, v) for (k, v) in page_inst.components["_placeholder"].props])
        delete!(page_inst.components, "_placeholder")

        # prepare components instantiation
        sfc_component   = String[]
        sfc_route       = String[]
        for (k,comp) in page_inst.components
            push!(sfc_component, "Vue.component('$(k)', () => loadModule('$(comp.url)', options));")
            if !isnothing(comp.path)
                push!(sfc_route, "{ path: '$(comp.path)', component: () => loadModule('$(comp.url)', options) },")
            end
        end

        # prepare page instantiation
        sfc_loader = """
const { loadModule, vueVersion } = window['vue2-sfc-loader'];
const options = {
    moduleCache: {
        vue: Vue,
    },
    getFile(url) {
        return fetch(url).then(response => response.ok ? response.text() : Promise.reject(response));
    },
    addStyle(styleStr) {
        const style = document.createElement('style');
        style.textContent = styleStr;
        const ref = document.head.getElementsByTagName('style')[0] || null;
        document.head.insertBefore(style, ref);
    },
    log(type, ...args) {
        console.log(type, ...args);
    }
}

$(join(sfc_component, "\n"))

Vue.use(VueRouter)

const routes = [
$(join(sfc_route, "\n"))]

var app = new Vue({
    el: '#app',
    vuetify: vuetify,
    data: $(vue_json(page_inst.globals)),
    router: new VueRouter({
        routes
    }),
    template: '<$sfc_placeholder $sfc_props/>',
})
"""

        push!(scripts, sfc_loader)

    else

        # Add components to scripts
        components = Dict{String,String}()
        [merge!(components, d.components) for d in page_inst.dependencies if length(d.components) > 0]
        push!(scripts,"""const components = $(replace(JSON.json(components),"\""=>""))""")

        app_state=Dict{String,Any}()
        ## initialize globals
        app_state["globals"]=page_inst.globals

        ## Other components
        for (k,v) in page_inst.components
            if k=="v-main"
                ## component script
                update_data!(v,v.data)
                update_events!(v)
                merge!(app_state,v.def_data)
                
                comp_script=[]
                push!(comp_script,"el: '#app'")
                push!(comp_script,"vuetify: vuetify")
                push!(comp_script,"components:components")
                push!(comp_script,"data: app_state")
                push!(comp_script, v.scripts)
                
                comp_script="var app = new Vue({"*join(comp_script,",")*"})"
                push!(scripts,comp_script)
                opts=PAGE_OPTIONS
                opts.path="root"
                push!(components_dom,html("v-main",html("v-container",dom(v,opts=opts),Dict("fluid"=>true)),Dict()))
            else
                    
                opts=PAGE_OPTIONS
                if v isa VueHolder
                    vsid=vue_escape(k)
                    vs=VueStruct("",[VueStruct(vsid,[v])])
                    opts.path=vsid
                else
                    vs=VueStruct(vue_escape(k),[v])
                    opts.path=""
                end
                
                update_data!(vs,vs.data)
                update_events!(vs)
                merge!(app_state,vs.def_data)
                
                comp_el=VueJS.dom([vs],opts=opts)[1].value.value        
                comp_el.attrs["app"]=true
                push!(components_dom,comp_el)
            end
        end
        components_dom = html("v-app", components_dom)
    
        scripts=vcat("const app_state = $(vue_json(app_state))",scripts)
            
    end

    body_dom = html("body",[
                        html("div", components_dom, Dict("id"=>"app", "v-cloak"=>true)),
                        """<script>xhr=$(xhr_script)\n$(join(scripts,"\n"))</script>"""
                        ],Dict())

    htmlpage = html("html", [head_dom, body_dom], Dict())

    return htmlstring(htmlpage)
end
