@el(sel1,"v-select",items=["red","green","blue"],label="Main Color",value="red")
@el(sel2,"v-select",items=["red","green","blue"],label="Secondary Color",value="blue")
@el(slider,"v-slider",value=20,label="Use Slider",thumb-label="always",step=1,cols=4)
@el(r1,"v-text-field",label="R1",binds=Dict("value"=>"slider.value","label"=>"r2.value")) ## Binding of element attributes to other elements attributes
@el(r2,"v-text-field",value="Label of R1, enter text",label="R2",rules=[js"v => v.length >= 8 || 'Min 8 characters'"])
@el(chip,"v-chip",text-color="white",binds=Dict("content"=>"slider.value","color"=>"sel1.value"))
tx=html("h2","{{slider.value}}") ## You can use curly brace sintax to point plain html to element attributes
@el(slider2,"v-slider",value=20,label="Comparative Slider",thumb-label="always",step=1,cols=4)
@el(r3,"v-text-field",label="R3",value=40.0,v-number=Dict("separator"=>" ","precision"=>2)) # Numbers handled through vue-number-format directive
@el(chip2,"v-chip",text-color="white",cols=2,content="Comparative Chip",binds=Dict("color"=>"slider2.value>r3.value ? sel1.value : sel2.value"))
page([[sel1,sel2],slider,[r1,r2,chip,tx],slider2,[r3,chip2]])
