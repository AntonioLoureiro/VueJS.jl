module VueJS

using JSON

<<<<<<< HEAD
export htmlElement,htmlString,VueElement,VueStruct,grid,page,@el
=======
export HtmlElement,htmlstring,VueElement,VueStruct,grid,page,@el
>>>>>>> luis/master

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
