#module VueJS

using JSON

export HtmlElement, htmlstring, VueElement, VueComponent, grid, page, @el

include("HtmlElement.jl")
include("VueElement.jl")
include("VueComponent.jl")
include("binding.jl")
include("data.jl")
include("base.jl")
include("grid.jl")
include("page.jl")


#end
