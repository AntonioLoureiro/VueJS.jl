function docs()
    include("examples.jl")
    io_readme = open("/workspace/VueJS.jl/README.md", "w")
    println(io_readme,"# VueJS

### Example Pages:")
    
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
        io = open("/workspace/VueJS.jl/docs/$(name).html", "w")
        println(io, html_code)
        close(io)
        println(io_readme, """[$name](https://antonioloureiro.github.io/VueJS.jl/$(name).html)""")
        println(io_readme, """ 
            """)
    end
    close(io_readme)
end