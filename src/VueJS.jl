module VueJS

using JSON,Dates,DataFrames,HTTP

export HtmlElement,htmlstring,VueElement,VueStruct,grid,page,@el,response, submit,tabs,bar,card,libraries!

include("Core/HtmlElement.jl")
include("Core/VueElement.jl")
include("Core/VueHolder.jl")
include("Core/VueStruct.jl")
include("Core/Events.jl")
include("Core/Binding.jl")
include("Core/Data.jl")
include("Core/Dom.jl")
include("Core/Page.jl")
include("Core/Base.jl")
include("Vuetify/Vuetify.jl")

end