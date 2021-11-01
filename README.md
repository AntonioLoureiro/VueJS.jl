# VueJS

## Documentation: [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://antonioloureiro.github.io/VueJS.jl/)

## Installation

The package can be installed with Julia's package manager,
either by using the Pkg REPL mode (press `]` to enter):
```
pkg> add VueJS
```
or by using Pkg functions
```julia
julia> using Pkg; Pkg.add("VueJS")
```

## Quick Start
See Documentation for additional examples

```julia
using HTTP,VueJS

function home(req::HTTP.Request)
    @el(slider,"v-slider",value=20,label="Use Slider",cols=4)
    @el(sel,"v-select",items=["red","green","blue"],label="Select Color",value="red")
    @el(chip,"v-chip",text-color="white",
        binds=Dict("content"=>"slider.value","color"=>"sel.value")) ## Binding See Documentation
        
    tx=html("h2","{{slider.value}}")
    
    return response(page([slider,sel,[chip,tx]]))
    
end

const ROUTER = HTTP.Router()
HTTP.@register(ROUTER, "GET", "/home", home)
HTTP.serve(ROUTER,"127.0.0.1", 80)
```
