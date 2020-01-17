module VueJS

using XMLDict,JSON

export htmlElement,el,vuetify,htmlString,VueElement,VueComponent


include("structs.jl")
include("base.jl")

### modules
include("vuetify.jl")

end # module
