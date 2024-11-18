@el(el1,"v-text-field",label="Element 1",value="Default Value")
@el(el2,"v-select",value="A",items=["A","B"],update="el2.value=='B' ? el1.value='Triggered Value' : el1.value='Default Value'",label="Trigger",cols=1)
@el(el3,"v-select",value="blue",items=["blue","green","red"],label="Color",cols=1)
@el(el4,"v-checkbox",value=true,label="Visible",cols=1)
@el(el5,"v-chip",content="Conditional Chip",text-color="white",v-show="el4.value",binds=Dict("color"=>"el3.value"),cols=2)
@el(btn_add,"v-btn",content="ADD",click="vs.add()",outlined=true,color="indigo")
@el(btn_del,"v-btn",content="DELETE",click="vs.remove(index)",cols=1,outlined=true,color="indigo")

@st(vs,[card([[el1,el2,el3,el4,el5,btn_del]])],iterable=true,data=[Dict("el1"=>"Overrided Value","el3"=>"red"),Dict("el3"=>"blue"),Dict("el3"=>"green")])

page([btn_add,vs])