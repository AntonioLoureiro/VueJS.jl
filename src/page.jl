"""
```julia
example = VueElement("teste", HtmlElement("v-text-field", Dict{String,Any}("label"=>"R1","value"=>"JValue"), 3, ""), "", Dict("value"=>"teste.value"), "value", Dict{String,Any}(), 3)
body=HtmlElement("body",
        HtmlElement("div",Dict("id"=>"app"),
            HtmlElement("v-app",
                HtmlElement("v-container",Dict("fluid"=>true),[example]))))

page_inst=Page(
        deepcopy(HEAD),
        [],
        [],
        body,
        "")

htmlpage=HtmlElement("html",[page_inst.head,page_inst.body])

@show htmlstring([htmlpage])
```

"""
mutable struct Page
    head::HtmlElement
    include_scripts::Array
    include_styles::Array
    vuestruct::VueStruct
    scripts::Vector{String}
end


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
function page(garr::Array; binds=Dict{String,String}(),data=Dict{String,Any}(),methods=Dict{String,Any}(),computed=Dict{String,Any}(),watched=Dict{String,Any}(), kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)

    scripts=haskey(args,"scripts") ? args["scripts"] : []
    comp=VueStruct("app",garr,data=data,binds=binds,methods=methods,computed=computed,watched=watched)
    
    return page(comp::VueStruct, kwargs...)
end

function page(comp::VueStruct,kwargs...)

    args=Dict(string(k)=>v for (k,v) in kwargs)
    scripts=haskey(args,"scripts") ? args["scripts"] : []
    
    page_inst=Page(
            deepcopy(HEAD),
            INCLUDE_SCRIPTS,
            INCLUDE_STYLES,
            comp,
            scripts)

    return page_inst
end

function htmlstring(page_inst::Page)
    
    include_scripts=map(x->HtmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->HtmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x)),page_inst.include_styles)

    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)
    
    nt=dom_scripts(page_inst.vuestruct::VueStruct)
    body_dom=nt.dom
    append!(page_inst.scripts,nt.scripts)
    
    htmlpage=HtmlElement("html",[page_inst.head,HtmlElement("body",body_dom)])

    return join([htmlstring(htmlpage), """<script>$(join(page_inst.scripts,"\n"))</script>"""],"")
end

function response(page::VueJS.Page)
    
    return HTTP.Response(200,htmlstring(page))
end
