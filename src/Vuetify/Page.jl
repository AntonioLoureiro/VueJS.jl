function htmlstring(page_inst::Page)
    includes=[]
    for d in page_inst.dependencies
        if d.kind=="js"
            push!(includes,HtmlElement("script",Dict("src"=>d.path),""))
        elseif d.kind=="css"
            push!(includes,HtmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>d.path)))
        end
    end

    head_dom=deepcopy(HEAD)
    append!(head_dom.value,includes)
    
    default_style="[v-cloak] {display: none}"
    push!(head_dom.value,HtmlElement("style",default_style))
    
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
            comp_script=[]
            push!(comp_script,"el: '#app'")
            push!(comp_script,"vuetify: vuetify")
            push!(comp_script,"components:components")
            push!(comp_script,"data: app_state")
            merge!(app_state,v.def_data)
            
            push!(comp_script, events_script(v))

            comp_script="var app = new Vue({"*join(comp_script,",")*"})"
            push!(scripts,comp_script)    
                   
            push!(components_dom,HtmlElement("v-content",HtmlElement("v-container",Dict("fluid"=>true),dom(v.grid))))
        else
            
            if v isa VueHolder
                vh_name=vue_escape(k)
                merge!(app_state,update_data!(v,nothing,vh_name))
                v=element_path(v,[vh_name])
            else
                merge!(app_state,VueJS.update_data!(v,nothing))         
                v=VueJS.element_path([v],[])[1]
            end
            
            comp_el=dom(v)
            comp_el.attrs["app"]=true
            push!(components_dom,comp_el)
        end
    end
    
    scripts=vcat("const app_state = $(vue_json(app_state))",scripts)
        
    body_dom=HtmlElement("body",
                        HtmlElement("div",Dict("id"=>"app","v-cloak"=>true),
                                 HtmlElement("v-app",components_dom)))
    
    htmlpage=HtmlElement("html",[head_dom,body_dom])
    styles=join([".$k {$v}" for (k,v) in page_inst.styles])
    return join([htmlstring(htmlpage), """<script>$(join(scripts,"\n"))</script>""","""<style>$styles</style>"""])
end