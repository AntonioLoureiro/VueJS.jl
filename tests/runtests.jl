using HTTP
using Sockets
using JSON
include("../src/VueJS.jl")
using Revise
#using .VueJS
# include("../src/HtmlElement.jl")
# include("../src/VueElement.jl")
# include("../src/VueComponent.jl")
# include("../src/binding.jl")
# include("../src/data.jl")
# include("../src/base.jl")
# include("../src/grid.jl")
# include("../src/page.jl")


router = HTTP.Router()

dom = HtmlElement("tag", Dict("class"=>"test-class"), "valor")
input = HtmlElement("h4", Dict("type"=>"text", "placeholder"=>"luis"), "texto")

function index(req)
    myvue = VueElement("luis", "h4", value="outro")
    myinp = VueElement("inp", "input", placeholder="dummy data", type="text")
    comp = VueComponent("page1", [myvue, myinp])
    return page([myvue])
    #return JSON.json(Dict("welcome"=>"home"))
end

HTTP.@register(router, "GET", "/", index)

@async HTTP.serve(router, "127.0.0.1" , 9000)
