using VueJS,HTTP,Sockets,JSON,DataFrames,Dates,Highlights

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
        ex_display="<div v-pre>"*String(take!(ioh))*"</div>"

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
    @el(dt_live,"v-data-table",items=df_examples,col_template=Dict("Link"=>bt),caption="Live Examples",dense=true,cols=3)

    df_components=DataFrame(Component=[],Library=[],Value_Attr=[],Doc=[])
    for (k,v) in VueJS.UPDATE_VALIDATION
        push!(df_components,(k,v.library,v.value_attr,v.doc))
    end
    @el(bt_doc,"v-btn",value="Doc",click="doc_el.value=item.doc;title_el.value=item.component;dial.active.value=true",small=true,outlined=true,color="indigo")
    @el(st,"v-text-field",label="Search")
    @el(dt_components,"v-data-table",items=df_components,col_template=Dict("Doc"=>bt_doc),caption="Components",binds=Dict("search"=>"st.value"),dense=true,items-per-page=50,cols=4)

    @el(doc_el,"v-text-field",value="",v-show="false")
    @el(title_el,"v-text-field",value="",v-show="false")
    @el(bt_close,"v-btn",value="Close",click="dial.active.value=false",small=true,outlined=true,color="indigo")

    dial=dialog("dial",[html("h2","",Dict("v-html"=>"title_el.value","align"=>"left"),cols=12),card([
                    html("div","",Dict("v-html"=>"doc_el.value","align"=>"left"),cols=12)],cols=12),bt_close],width=800)

    @el(nav,"v-navigation-drawer",items=[Dict("icon"=>"mdi-file-document-outline","title"=>"Base","href"=>"https://antonioloureiro.github.io/VueJS.jl/base.html"),
        Dict("icon"=>"mdi-table-settings","title"=>"Components","href"=>"https://antonioloureiro.github.io/VueJS.jl/components.html")])

    @el(homeb,"v-btn",icon=true,value="<v-icon>mdi-home</v-icon>",click="open('base.html')")
    barapp=bar([homeb]);
    
    pcomp=page([[[st,dt_components],spacer(),dt_live],dial,title_el,doc_el],navigation=nav,bar=barapp);
    
    iframe=html("iframe","",Dict("src"=>"https://antonioloureiro.github.io/VueJS.jl/Docs.html","width"=>"100%","height"=>"100%"),cols=12)
    pbase=page([iframe],navigation=nav,bar=barapp);
    
    io = open("public/base.html", "w")
    println(io, VueJS.htmlstring(pbase))
    close(io)
    
    io = open("public/components.html", "w")
    println(io, VueJS.htmlstring(pcomp))
    close(io)
    
    
end

docs()
