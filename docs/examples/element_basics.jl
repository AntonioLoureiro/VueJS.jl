@el(r1,"v-text-field",value="R1 Value",label="R1") # Default cols=2 using a 12 cols grid
@el(r2,"v-text-field",value="R2 Value",label="R2",disabled=true,cols=6)
@el(r3,"v-text-field",value="R3 Value",label="R3",disabled=false,cols=3)
@el(r4,"v-text-field",value=100589.67,label="R4 (Number)",v-number=Dict("separator"=>" ","precision"=>2),cols=3) # Numbers handled through vue-number-format directive
tx=html("p","Text",Dict("align"=>"center"),cols=3) # You can use normal html Elements with all the attributes, default cols=2
page([r1,r2,r3,r4,tx])
