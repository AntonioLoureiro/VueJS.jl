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
        
    @el(bt,"v-btn",value="Link",click="open(item.Link)")
    @el(dt_live,"v-data-table",items=df_examples,col_template=Dict("Link"=>bt),caption="Live Examples",dense=true,cols=3)

    ## Components
    df_components=DataFrame(Component=[],Library=[],Value_Attr=[],Doc=[])

    for (k,v) in VueJS.UPDATE_VALIDATION
        push!(df_components,(k,v.library,v.value_attr,v.doc))
    end
    @el(dt_components,"v-data-table",items=df_components,caption="Components",dense=true,cols=4)
    
    p1=page([[dt_components,spacer(),dt_live]])
    
    io = open("public/index.html", "w")
    println(io, VueJS.htmlstring(p1))
    close(io)
    
end

docs()
