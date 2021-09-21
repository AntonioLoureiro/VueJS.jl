@el(el1,"v-text-field",label="Element 1",value="Default Value")
@el(el2,"v-select",value=false,items=[true,false],change="el2.value ? el1.value='Triggered Value' : el1.value='Default Value'",label="Trigger")
@el(el3,"v-select",value="blue",items=["blue","green","red"],label="Element 3")
@el(el4,"v-chip",content="Conditional Chip",text-color="white",binds=Dict("color"=>"el3.value"),cols=2)

@st(vs,[card([[el1,el2,el3,el4]])],data=Dict("el1"=>"Overrided Value in VS"))
page([el1,el2,el3,el4,vs],data=Dict("el1"=>"Overrided Value"))
