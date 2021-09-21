@el(r1,"v-text-field",value="R1 Value",label="R1") # Default cols=2 using a 12 cols grid
@el(r2,"v-text-field",value="R2 Value",label="R2",disabled=true,cols=6)
@el(r3,"v-text-field",value="R3 Value",label="R3",disabled=false,cols=3)
tx=html("p","Text",Dict("align"=>"center")) # You can use normal html Elements with all the attributes, default cols=2
page([r1,r2,r3,tx])