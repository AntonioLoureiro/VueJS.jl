module VueJS

using JSON

export htmlElement,htmlString,VueElement,page,VueComponent,grid


include("structs.jl")
include("base.jl")
include("grid.jl")


    module vuetify

        using JSON,..VueJS

        export update_validate!,comp,page,VueElement,comp,page,@el

        ### modules
        include("vuetify.jl")


    end # module

end
