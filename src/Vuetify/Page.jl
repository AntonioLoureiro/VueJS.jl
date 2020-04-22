function htmlstring(page_inst::Page)
    includes=[]
    for d in page_inst.dependencies
        if d.kind=="js"
            push!(includes,html("script","",Dict("src"=>d.path)))
        elseif d.kind=="css"
            push!(includes,html("link",nothing,Dict("rel"=>"stylesheet","type"=>"text/css","href"=>d.path)))
        end
    end

    head_dom=deepcopy(HEAD)
    append!(head_dom.value,includes)   
    
    push!(head_dom.value,html("style","[v-cloak] {display: none}"))
        
    scripts=deepcopy(page_inst.scripts)
    push!(scripts,"const vuetify = new Vuetify()")
    components=Dict{String,String}()
    for d in page_inst.dependencies
        length(d.components)!=0 ? merge!(components,d.components) : nothing
    end
    
    push!(scripts,"""const components = $(replace(JSON.json(components),"\""=>""))""")
    
    components_dom=[]
    app_state=Dict{String,Any}()
    ## Other components
    for (k,v) in page_inst.components
        if k=="v-content"
            ## component script
            update_data!(v,v.data)
            update_events!(v)
            comp_script=[]
            push!(comp_script,"el: '#app'")
            push!(comp_script,"vuetify: vuetify")
            push!(comp_script,"components:components")
            push!(comp_script,"data: app_state")
            push!(comp_script, v.scripts)
            merge!(app_state,v.def_data)

            comp_script="var app = new Vue({"*join(comp_script,",")*"})"
            push!(scripts,comp_script)    
            
            push!(components_dom,html("v-content",html("v-container",dom(v),Dict("fluid"=>true)),Dict()))
        else
            
            if v isa VueHolder
                vs=VueStruct("",[VueStruct(vue_escape(k),[v])])
            else
                vs=VueStruct(vue_escape(k),[v])
            end
            
            update_data!(vs,vs.data)
            update_events!(vs)
            comp_el=VueJS.dom([vs])[1].value.value            
            merge!(app_state,vs.def_data)
            comp_el.attrs["app"]=true
            push!(components_dom,comp_el)
        end
    end
    
    scripts=vcat("const app_state = $(vue_json(app_state))",scripts)
        
    styles=html("style",join([".$k {$v}" for (k,v) in page_inst.styles]),Dict("type"=>"text/css"))
    
    body_dom=html("body",[styles,
                        html("div",html("v-app",components_dom),Dict("id"=>"app","v-cloak"=>true))],Dict())
    
    htmlpage=html("html",[head_dom,body_dom],Dict())
    
    return join([htmlstring(htmlpage), """<script>$(join(scripts,"\n"))</script>"""])
end