@el(slider,"v-slider",value=20,label="Use Slider",step=1,cols=4)
@el(sel,"v-select",items=["red","green","blue"],label="Select Color",value="red")
@el(r1,"v-text-field",label="R1",binds=Dict("value"=>"slider.value","label"=>"r2.value")) ## Binding of element attributes to other elements attributes
@el(r2,"v-text-field",value="Label of R1, enter text",label="R2",rules=["v => v.length >= 8 || 'Min 8 characters'"])
@el(chip,"v-chip",text-color="white",binds=Dict("content"=>"slider.value","color"=>"sel.value"))
tx=html("h2","{{slider.value}}") ## You can use curly brace sintax to point plain html to element attributes
page([slider,sel,[r1,r2,chip,tx]])