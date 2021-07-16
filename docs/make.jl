using VueJS,HTTP,Sockets,JSON,DataFrames,Dates,Highlights,Namtso

function docs()
    
    df_examples=DataFrame(Name=[],Link=[])
    
    include("examples.jl")
    for e in examples

        name=e[1] 
        ex=split(e[2],"\n")
        filter!(x->x!="",ex) 
        ex_display=join(deepcopy(ex),"\n")
        ioh=IOBuffer() 
        stylesheet(ioh, MIME("text/html"))
        ex_style=String(take!(ioh))
        ioh=IOBuffer() 
        highlight(ioh, MIME("text/html"), join(deepcopy(ex_display)), Lexers.JuliaLexer)
        ex_display="""<div style="padding-bottom:10px" v-pre>"""*String(take!(ioh))*"</div>"

        ex[end]="global p="*ex[end]

        for r in ex
            eval(Meta.parse(r))
        end 
        html_code=String(response(p).body)
        
        html_code=replace(html_code,"</style>"=>"</style>"*ex_style)
        html_code=replace(html_code,"<v-container fluid>"=>"<v-container fluid>"*ex_display)
        io = open("public/$(name).html", "w")
        println(io, html_code)
        close(io)
        name_url=replace(name," "=>"%20")
        push!(df_examples,(name, """https://antonioloureiro.github.io/VueJS.jl/$(name_url).html"""))
        
    end
    
    @el(bt,"v-btn",value="Link",click="open(item.Link)",small=true,outlined=true,color="indigo")
    @el(dt_live,"v-data-table",items=df_examples,col_template=Dict("Link"=>bt),caption="Live Examples",dense=true,items-per-page=50,cols=3)

    df_components=DataFrame(Component=[],Library=[],Value_Attr=[],Doc=[])
    for (k,v) in VueJS.UPDATE_VALIDATION
        push!(df_components,(k,v.library,v.value_attr,v.doc))
    end
    @el(bt_doc,"v-btn",value="Doc",click="doc_el.value=item.doc;title_el.value=item.component;dial.active.value=true",small=true,outlined=true,color="indigo")
    @el(st,"v-text-field",label="Search Components")
    @el(dt_components,"v-data-table",items=df_components,col_template=Dict("Doc"=>bt_doc),caption="Components",binds=Dict("search"=>"st.value"),dense=true,items-per-page=50,cols=4)

    @el(doc_el,"v-text-field",value="",v-show="false")
    @el(title_el,"v-text-field",value="",v-show="false")
    @el(bt_close,"v-btn",value="Close",click="dial.active.value=false",small=true,outlined=true,color="indigo")

    dial=dialog("dial",[html("h2","",Dict("v-html"=>"title_el.value","align"=>"left"),cols=12),card([
                    html("div","",Dict("v-html"=>"doc_el.value","align"=>"left"),cols=12)],cols=12),bt_close],width=800)

    @el(nav,"v-navigation-drawer",expand-on-hover=false,items=[
        Dict("icon"=>"mdi-table-settings","title"=>"Components","href"=>"https://antonioloureiro.github.io/VueJS.jl/components.html"),
        Dict("divider" => true),
        Dict("icon"=>"mdi-file-document-outline","title"=>"Elements","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsElements.html"),
        Dict("icon"=>"mdi-palette-swatch-outline","title"=>"Styling","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsStyling.html"),
        Dict("icon"=>"mdi-account-group-outline","title"=>"Holders","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsHolders.html"),
        Dict("icon"=>"mdi-domain","title"=>"Structs","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsStructs.html"),
        Dict("icon"=>"mdi-laptop","title"=>"Methods","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsMethods.html"),
        Dict("icon"=>"mdi-calculator","title"=>"Computed","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsComputed.html"),
        Dict("icon"=>"mdi-hook","title"=>"Hooks","href"=>"https://antonioloureiro.github.io/VueJS.jl/DocsHooks.html"),
        ])

    @el(homeb,"v-btn",icon=true,value="<v-icon>mdi-home</v-icon>",click="open('components.html')")
    barapp=bar([homeb,"VueJS Documentation"]);
    
    
    for p in ["DocsElements","DocsStyling","DocsHolders","DocsStructs","DocsMethods","DocsComputed","DocsHooks"]
        iframe=html("iframe","",Dict("src"=>"https://antonioloureiro.github.io/VueJS.jl/docs/$p.html","height"=>1000,"width"=>"100%","frameborder"=>0),cols=12)
        pbase=page([iframe],navigation=nav,bar=barapp);
    
        io = open("public/$p.html", "w")
        println(io, VueJS.htmlstring(pbase))
        close(io)
    end
    
    pcomp=page([st,[dt_components,spacer(),dt_live],dial,title_el,doc_el],navigation=nav,bar=barapp);
        
    io = open("public/components.html", "w")
    println(io, VueJS.htmlstring(pcomp))
    close(io)
    
    
end

docs()
