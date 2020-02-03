using HTTP
using Sockets
using JSON
#include("../src/VueJS.jl")
using Revise
# include("../src/HtmlElement.jl")
# include("../src/VueElement.jl")
# include("../src/VueComponent.jl")
# include("../src/binding.jl")
# include("../src/data.jl")
# include("../src/base.jl")
# include("../src/grid.jl")
# include("../src/page.jl")
vinc = joinpath(@__DIR__, "..", "src")
push!(LOAD_PATH, vinc)
using VueJS


@el(r1,"v-text-field",value="JJJ",label="R1")
r2 = VueElement("r2", "v-text-field", label="label", value="testeBatata")
@el(r3,"v-slider",value=20,label="Slider 3")
@el(r4,"v-text-field",value="R4 Value",label="R4")
@el(r5,"v-slider",value=20,label="Slider")
@el(r6,"v-slider",value=20,label="Slider")
@el(r6,"v-input",placeholder="Dummy",label="Test")

@el(r7,"v-text-field",value="R7 Value",label="R7")

user = HtmlElement("input", Dict("class"=>"form-control","type"=>"text", "placeholder"=>"username"), "")

c1=VueStruct("c1",[r1,r2],data=Dict("vuet"=>"Cebola"),binds=Dict("r1.label"=>"r2.value"))
c2=VueStruct("c2",[r4,c1, VueElement(user.tag, user.tag)],data=Dict("vuet"=>"Cebola"));

 p1=page([[r1,r2,r3],[[c2,r7,r6]]],data=Dict("r1"=>"r1 data","r2"=>"r2 data","c2"=>Dict("r4"=>"R4 Dataaaaaa")),

    binds=Dict("r1.label"=>"r2.value","r1.value"=>"r3.value")

)

function index(req)
    return p1
end

router = HTTP.Router()
HTTP.@register(router, "GET", "/", index)

@async HTTP.serve(router, "127.0.0.1" , 8888)
