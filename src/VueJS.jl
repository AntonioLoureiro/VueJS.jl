module VueJS

using JSON

export htmlElement,htmlString,VueElement,VueComponent,grid,page,@el


include("htmlElement.jl")
include("VueElement.jl")
include("VueComponent.jl")
include("binding.jl")
include("data.jl")
include("base.jl")
include("grid.jl")
include("methods.jl")
include("page.jl")


end
