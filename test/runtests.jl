using Test, VueJS,Namtso

@el(r1,"v-text-field",value="R1 Value",label="R1",disabled=false,prepend-icon="mdi-account",cols=2)
@el(r2,"v-text-field",value="R2 Value",label="R2")
@st(c1,[r1,r2],data=Dict("vuet"=>"Cebola"),binds=Dict("r1.label"=>"r2.value"))
@dialog(dial,[username,username2],persistent=false,max-width=800)


## Tests
@test r1.value_attr=="value"
@test c1.binds==Dict("r1" => Dict("label"=>Dict("r2"=>"value")))
@test c1.grid[1].attrs==Dict("label"=>"R1","disabled" => false,"value"=> "R1 Value")
@test dial.id="dial"
