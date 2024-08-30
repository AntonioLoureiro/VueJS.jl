# VueJS

## Documentation: [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://antonioloureiro.github.io/VueJS.jl/)

## Introduction

VueJS.jl is a Julia package that facilitates the creation of reactive, interactive web applications by leveraging the Vue.js framework directly from Julia. It allows you to combine the flexibility and simplicity of Vue.js with the computational power of Julia, making it an excellent tool for building dynamic web applications with ease.
It uses [Vuetify](https://vuetifyjs.com/en/) as main Vue Framework, but also leverages on Echarts through Julia Namtso package and others.
The main philosofy is to pass through to the frameworks all of the introduced arguments with several automations and special cases.

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
See [Documentation](https://antonioloureiro.github.io/VueJS.jl/) **(that is dynamically created using VueJS!)** for additional examples.

```julia
using HTTP,VueJS,Sockets

function home(req::HTTP.Request)
    @el(slider,"v-slider",value=20,label="Use Slider",cols=4)
    @el(sel,"v-select",items=["red","green","blue"],label="Select Color",value="red")
    @el(chip,"v-chip",text-color="white",
        binds=Dict("content"=>"slider.value","color"=>"sel.value"))
        
    tx=html("h2","{{slider.value}}")
    
    return response(page([slider,sel,[chip,tx]]))
    
end

const ROUTER = HTTP.Router()
HTTP.@register!(ROUTER, "GET", "/home", home)
HTTP.serve(ROUTER,Sockets.getipaddr(), 80)
```
