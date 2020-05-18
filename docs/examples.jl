examples=["Elements_Basics"=>"""
@el(r1,"v-text-field",value="R1 Value",label="R1") # Default cols=2 using a 12 cols grid
@el(r2,"v-text-field",value="R2 Value",label="R2",disabled=true,cols=6)
@el(r3,"v-text-field",value="R3 Value",label="R3",disabled=false,cols=3)
tx=html("p","Text",Dict("align"=>"center")) # You can use normal html Elements with all the attributes, default cols=2
page([r1,r2,r3,tx])
""",
"Basic_Grid"=>"""
@el(r1,"v-text-field",value="R1 Value",label="R1",disabled=true)
@el(r2,"v-text-field",value="R2 Value",label="R2",disabled=false)
@el(r3,"v-text-field",value="R3 Value",label="R3",disabled=false)
@el(r4,"v-text-field",value="R4 Value",label="R4",disabled=false)
@el(r5,"v-select",items=["A","B"],label="R5")
@el(r6,"v-select",items=["A","B"],label="R6")
@el(r7,"v-slider",value=20,label="Slider 7")
page([r1,r2,[r3,r4,r5],r6,r7])
""",
"Basic_Binding"=>"""
@el(slider,"v-slider",value=20,label="Use Slider",cols=4)
@el(sel,"v-select",items=["red","green","blue"],label="Select Color",value="red")
@el(r1,"v-text-field",label="R1",binds=Dict("value"=>"slider.value","label"=>"r2.value")) ## Binding of element attributes to other elements attributes
@el(r2,"v-text-field",value="Label of R1, enter text",label="R2",rules=["v => v.length >= 8 || 'Min 8 characters'"])
@el(chip,"v-chip",text-color="white",binds=Dict("content"=>"slider.value","color"=>"sel.value"))
tx=html("h2","{{slider.value}}") ## You can use curly brace sintax to point plain html to element attributes
page([slider,sel,[r1,r2,chip,tx]])
""",
"Basic_Events"=>"""
@el(slider,"v-slider",value=200,min=0,max=1000,label="Use Slider",cols=4)
@el(chip,"v-chip",text-color="white",x-large=true,binds=Dict("content"=>"slider.value","color"=>"slider.value >500 ? 'red' : 'blue'"))
@el(chip2,"v-chip",text-color="white",color="green",content="HOVER",x-large=true,mouseover="slider.value=0;alert.content='RESET with Hover',alert.value=true")
@el(btn_add,"v-btn",content="ADD+10",text-color="white",click="slider.value+=10")
@el(btn_add_100,"v-btn",content="ADD+100",text-color="white",click="slider.value+=100")
@el(alert,"v-alert",content="RESET!",type="success",text=true,cols=12,timeout=5000)
@el(btn_toggle_reset,"v-btn",content="Reset",text-color="white",click="slider.value=0;alert.content='RESET with Click!',alert.value=true")
page([alert,slider,[btn_add,btn_add_100,btn_toggle_reset],[chip,chip2]])
"""
]