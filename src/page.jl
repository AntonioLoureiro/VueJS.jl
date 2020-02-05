"""
Build HTML page, inclunding <head>, <body>, <scripts> and vuetify's initialization

Constructs a VueStruct from `garr`, `data`, `binds` and `methods` arguments.
Defines vue's `app` scripts.
(...)

### Arguments

 * garr             :: Array        :: `Grid array`, array of elements to be created and displayed
 * binds            :: Dict         :: Binds between ::VueElement's `value_attr`
 * methods          :: Dict         ::
 * kwargs           :: Any          :: Keyword arguments

### Examples
```julia

```
"""
function page(
    garr::Array;
    binds=Dict{String,String}(),
    methods=Dict{String,Any}(),
    kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    data=haskey(args,"data") ? args["data"] : Dict()
    comp=VueStruct("app",garr,data=data,binds=binds,methods=methods)

    scripts=[]
    push!(scripts,"const app_state = $(JSON.json(comp.def_data))")

    ## component script
    comp_script=[]
    push!(comp_script,"el: '#app'")
    push!(comp_script,"vuetify: new Vuetify()")
    push!(comp_script,"data: app_state")

    push!(comp_script, methods_script(comp))

    comp_script="var app = new Vue({"*join(comp_script,",")*"})"
    push!(scripts,comp_script)

    arr_dom=grid(comp.grid)
    body=HtmlElement("body",
            HtmlElement("div",Dict("id"=>"app"),
                HtmlElement("v-app",
                    HtmlElement("v-container",Dict("fluid"=>true),arr_dom))))

    page_inst=Page(
            deepcopy(HEAD),
            INCLUDE_SCRIPTS,
            INCLUDE_STYLES,
            body,
            join(scripts,"\n"))


    include_scripts=map(x->HtmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->HtmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x)),page_inst.include_styles)

    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)

    htmlpage=HtmlElement("html",[page_inst.head,page_inst.body])

    return join([htmlstring(htmlpage), "<script>$(page_inst.scripts)</script>"],"")
end
