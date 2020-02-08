## Render VueStruct
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