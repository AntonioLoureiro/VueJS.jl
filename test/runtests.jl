using Test, VueJS

@el(r1,"v-text-field",value="R1 Value",label="R1",disabled=false)
@el(r2,"v-text-field",value="R2 Value",label="R2")
c1=VueStruct("c1",[r1,r2],data=Dict("vuet"=>"Cebola"),binds=Dict("r1.label"=>"r2.value"))

## Tests
@test c1.binds==Dict("r1" => Dict("label"=>Dict("r2"=>"value")))
@test c1.grid[1].attrs==Dict("label"=>"R1","disabled" => false,"value"=> "R1 Value")
