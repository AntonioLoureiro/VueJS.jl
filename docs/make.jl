using Namtso, VueJS
using DataFrames, Dates, Highlights, HTTP, JSON, Sockets

include("base.jl")

function docs()
    
    df_examples=DataFrame(Name=[],Link=[])
    
    include("examples.jl")
    for (name, file) in examples

        filepath    = joinpath(EXAMPLES_DIR, file)
        ex_display  = deepcopy(Base.read(filepath, String))

        ioh=IOBuffer() 
        stylesheet(ioh, MIME("text/html"))
        ex_style=String(take!(ioh))
        ioh=IOBuffer() 
        highlight(ioh, MIME("text/html"), join(deepcopy(ex_display)), Lexers.JuliaLexer)
        ex_display="""<div style="padding-bottom:10px" v-pre>"""*String(take!(ioh))*"</div>"

        ex_page   = include(filepath)
        html_code = String(response(ex_page).body)
        
        html_code=replace(html_code,"</style>"=>"</style>"*ex_style)
        html_code=replace(html_code,"<v-container fluid>"=>"<v-container fluid>"*ex_display)

        io = open("$TARGET_DIR/$(name).html", "w")
        println(io, html_code)
        close(io)
 
        name_url = HTTP.escapeuri(name)
        push!(df_examples, (name, joinpath(BASE_PATH, "$(name_url).html")))
    end
    @css "code" Dict("background-color"=>"lightcyan")
    
    @el(bt,"v-btn",value="Link",click="open(item.Link)",small=true,outlined=true,color="indigo")
    @el(dt_live,"v-data-table",items=df_examples,col_template=Dict("Link"=>bt),caption="Live Examples",density="comfortable",items-per-page=50,cols=3.5)

    df_components=DataFrame(Component=[],Library=[],Value_Attr=[],Doc=[])
    for (k,v) in VueJS.UPDATE_VALIDATION
        push!(df_components,(k,v.library,v.value_attr,v.doc))
    end
    @el(bt_doc,"v-btn",value="Doc",click="doc_el.value=item.doc;title_el.value=item.component;dial.active.value=true",small=true,outlined=true,color="indigo")
    @el(st,"v-text-field",label="Search Components")
    @el(dt_components,"v-data-table",items=df_components,col_template=Dict("Doc"=>bt_doc),caption="Components",binds=Dict("search"=>"st.value"),density="comfortable",items-per-page=50,cols=4)

    @el(doc_el,"v-text-field",value="",v-show="false")
    @el(title_el,"v-text-field",value="",v-show="false")
    @el(bt_close,"v-btn",value="Close",click="dial.active.value=false",small=true,outlined=true,color="indigo")

    dial=dialog("dial",
                [html("div","""<h2 v-html="title_el.value" align="left"></h2>""",cols=12),
                card([html("div","""<div v-html="doc_el.value" align="left"></div>""",cols=12)],
                cols=12),
                bt_close],width=800)

    @el(homeb,"v-btn",icon=true,value="<v-icon>mdi-home</v-icon>",click="open('$INDEX_PATH')")
    barapp=bar([homeb,"VueJS Documentation"]);

    nav_items = [
        Dict("prepend-icon"=>"mdi-table-settings","title"=>"Components","href"=>"$INDEX_PATH"),
        Dict("type" => "divider")
    ]
    
    iframes = []
    for (name, details) in notebooks
        href = joinpath(NOTEBOOKS_PATH, details.html)
        push!(nav_items, Dict("icon"=>details.icon, "title"=>name, "href"=>joinpath(BASE_PATH, details.html),"prepend-icon"=>details.icon))
        push!(iframes,   html("iframe","", Dict("src"=>href,"height"=>1000,"width"=>"100%","frameborder"=>0),cols=12))
    end
    @el(nav, "v-navigation-drawer", expand-on-hover = false, items = nav_items)
    for iframe in iframes
        pbase = page([iframe],navigation=nav,bar=barapp);
        # extract filename from iframe.src and write page to public/
        io    = open("$TARGET_DIR/$(basename(iframe.attrs["src"]))", "w")
        println(io, VueJS.htmlstring(pbase))
        close(io)
    end
    
    pcomp=page([st,[dt_components,spacer(),dt_live],dial,title_el,doc_el],navigation=nav,bar=barapp);
        
    # write out entry page to index.html
    io = open(joinpath(TARGET_DIR, INDEX_PAGE), "w")
    println(io, VueJS.htmlstring(pcomp))
    close(io)
end


docs()
