function htmlstring(page_inst::Page)

    include_scripts=map(x->HtmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->HtmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x)),page_inst.include_styles)

    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)
    scripts=deepcopy(page_inst.scripts)
    
    components_dom=[]
    app_state=Dict{String,Any}()
    ## Other components
    for (k,v) in page_inst.components
        if k=="v-content"
            ## component script
            comp_script=[]
            push!(comp_script,"el: '#app'")
            push!(comp_script,"vuetify: new Vuetify()")
            push!(comp_script,"data: app_state")
            merge!(app_state,v.def_data)
            
            push!(comp_script, events_script(v))

            comp_script="var app = new Vue({"*join(comp_script,",")*"})"
            push!(scripts,comp_script)    
                   
            push!(components_dom,HtmlElement("v-content",HtmlElement("v-container",Dict("fluid"=>true),grid(v.grid))))
        else
            haskey(v.attrs,"items") ? app_state[v.id]=Dict("value"=>v.attrs["items"]) : nothing
            v=VueJS.element_path([v],[])[1]
            
            if v.tag==k
                 comp_el=update_dom(v)
                 comp_el.attrs["app"]=true
                 push!(components_dom,comp_el)
            elseif k=="v-navigation-drawer"
                push!(components_dom,HtmlElement(k,Dict("app"=>true,"clipped"=>true,"width"=>200),update_dom(v)))
            else
                push!(components_dom,HtmlElement(k,Dict("app"=>true,"clipped"=>true),update_dom(v)))
            end
        end
    end
    
    scripts=vcat("const app_state = $(vue_json(app_state))",scripts)
        
    body_dom=HtmlElement("body",
                        HtmlElement("div",Dict("id"=>"app"),
                                 HtmlElement("v-app",components_dom)))
    
    htmlpage=HtmlElement("html",[page_inst.head,body_dom])

    return join([htmlstring(htmlpage), """<script>$(join(scripts,"\n"))</script>"""],"")
end