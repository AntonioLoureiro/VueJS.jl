module VueJS

using JSON,Dates,DataFrames

export HtmlElement,htmlstring,VueElement,VueStruct,grid,page,@el

include("HtmlElement.jl")
include("VueElement.jl")
include("VueStruct.jl")
include("binding.jl")
include("data.jl")
include("base.jl")
include("grid.jl")
include("methods.jl")
include("page.jl")


end
