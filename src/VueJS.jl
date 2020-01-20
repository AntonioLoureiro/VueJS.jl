module VueJS

using JSON

export htmlElement,htmlString,VueElement,page,VueComponent,grid,update_def_data!


include("structs.jl")
include("base.jl")
include("grid.jl")


    module vuetify

        using JSON,..VueJS

        export update_validate!,page,VueElement,VueComponent,page,@el

        ### modules
        include("vuetify.jl")


    end # module

end
