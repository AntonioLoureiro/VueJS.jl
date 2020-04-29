import Pkg; Pkg.add("Highlights")
push!(LOAD_PATH,"/workspace/VueJS.jl/src/")
using VueJS,HTTP,Sockets,JSON,DataFrames,Dates,Namtso,Highlights
include("docs_lib.jl")

docs()