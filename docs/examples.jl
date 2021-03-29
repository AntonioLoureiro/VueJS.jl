examples=["Elements Basics"=>"""
@el(r1,"v-text-field",value="R1 Value",label="R1") # Default cols=2 using a 12 cols grid
@el(r2,"v-text-field",value="R2 Value",label="R2",disabled=true,cols=6)
@el(r3,"v-text-field",value="R3 Value",label="R3",disabled=false,cols=3)
tx=html("p","Text",Dict("align"=>"center")) # You can use normal html Elements with all the attributes, default cols=2
page([r1,r2,r3,tx])
""",
"Basic Grid"=>"""
@el(r1,"v-text-field",value="R1 Value",label="R1",disabled=true)
@el(r2,"v-text-field",value="R2 Value",label="R2",disabled=false)
@el(r3,"v-text-field",value="R3 Value",label="R3",disabled=false)
@el(r4,"v-text-field",value="R4 Value",label="R4",disabled=false)
@el(r5,"v-select",items=["A","B"],label="R5")
@el(r6,"v-select",items=["A","B"],label="R6")
@el(r7,"v-slider",value=20,label="Slider 7")
page([r1,r2,[r3,r4,r5],r6,r7])
""",
"Basic Binding"=>"""
@el(slider,"v-slider",value=20,label="Use Slider",cols=4)
@el(sel,"v-select",items=["red","green","blue"],label="Select Color",value="red")
@el(r1,"v-text-field",label="R1",binds=Dict("value"=>"slider.value","label"=>"r2.value")) ## Binding of element attributes to other elements attributes
@el(r2,"v-text-field",value="Label of R1, enter text",label="R2",rules=["v => v.length >= 8 || 'Min 8 characters'"])
@el(chip,"v-chip",text-color="white",binds=Dict("content"=>"slider.value","color"=>"sel.value"))
tx=html("h2","{{slider.value}}") ## You can use curly brace sintax to point plain html to element attributes
page([slider,sel,[r1,r2,chip,tx]])
""",
"Basic Events"=>"""
@el(slider,"v-slider",value=200,min=0,max=1000,label="Use Slider",cols=4)
@el(chip,"v-chip",text-color="white",x-large=true,binds=Dict("content"=>"slider.value","color"=>"slider.value >500 ? 'red' : 'blue'"))
@el(chip2,"v-chip",text-color="white",color="green",content="<v-icon>mdi-mouse</v-icon>",x-large=true,mouseover="slider.value=0;alert.content='RESET with Hover';alert.value=true")
@el(btn_add,"v-btn",content="ADD+10",text-color="white",click="slider.value+=10")
@el(btn_add_100,"v-btn",content="ADD+100",text-color="white",click="slider.value+=100")
@el(alert,"v-alert",content="RESET!",type="success",text=true,cols=12,timeout=5000)
@el(btn_toggle_reset,"v-btn",content="Reset",text-color="white",click="slider.value=0;alert.content='RESET with Click!';alert.value=true")
@el(sel,"v-select",items=["https://google.com","https://weather.com"],label="Select WebSite")
@el(btn_open,"v-btn",content="OPEN",text-color="white",click="open(sel.value)")
page([alert,slider,[btn_add,btn_add_100,btn_toggle_reset],[chip,chip2],[sel,btn_open]])
""",
"Elements Special args Tooltip and Menu"=>"""
@el(ch1,"v-chip",content="Basic Tooltip",color="red",text-color="white",tooltip="<p>Lore Ipsilum</p><p><b>Lore Ipsilum</b></p>",cols=2)
@el(ttp,"v-tooltip",content="<p>Lore Ipsilum</p><p><b>Lore Ipsilum</b></p>",bottom=true,color="rgba(0, 0, 255, 0.5)")
@el(ch2,"v-chip",content="Advanced Tooltip",tooltip=ttp,color="red",text-color="white",cols=2)

items=[Dict("title"=>"Action 1","href"=>"https://www.google.com"),Dict("title"=>"Action 2","href"=>"https://www.amazon.com")]
@el(m1,"v-btn",menu=items,value="MENU 1")
@el(menu,"v-menu",items=items,dark=true)
@el(m2,"v-btn",menu=menu,value="MENU 2")

side_actions_def=[Dict("title"=>"Query1","val"=>Dict("query"=>"Query1","what"=>"www.google.com")), Dict("title"=>"Query2","val"=>Dict("query"=>"Query2","what"=>"www.google.com"))]
@el(actions_menu,"v-menu",items=side_actions_def)
@el(side_menu,"v-btn",content="<v-icon>mdi-dots-vertical</v-icon>",icon=true,menu=actions_menu,click="query_method(item.val.what,item.val.query)")
        
page([[ch1,ch2,m1,m2, side_menu]],methods=Dict("query_method"=>"function(what, query){open('http://'+what+'/search?q='+query,'_blank') }")) 
""",
"Vue Struct"=>"""
@el(el1,"v-text-field",label="Element 1",value="Default Value")
@el(el2,"v-select",value=false,items=[true,false],change="el2.value ? el1.value='Triggered Value' : el1.value='Default Value'",label="Trigger")
@el(el3,"v-select",value="blue",items=["blue","green","red"],label="Element 3")
@el(el4,"v-chip",content="Conditional Chip",text-color="white",binds=Dict("color"=>"el3.value"),cols=2)

@st(vs,[card([[el1,el2,el3,el4]])],data=Dict("el1"=>"Overrided Value in VS"))
page([el1,el2,el3,el4,vs],data=Dict("el1"=>"Overrided Value"))
""",
"Iterable Vue Struct"=>"""
@el(el1,"v-text-field",label="Element 1",value="Default Value")
@el(el2,"v-select",value=false,items=[true,false],change="el2.value ? el1.value='Triggered Value' : el1.value='Default Value'",label="Trigger")
@el(el3,"v-select",value="blue",items=["blue","green","red"],label="Element 3",cols=2)
@el(el4,"v-chip",content="Conditional Chip",text-color="white",binds=Dict("color"=>"el3.value"),cols=2)
@el(btn_add,"v-btn",content="ADD",click="vs.add()")
@el(btn_del,"v-btn",content="DELETE",click="vs.remove(index)",cols=1)

@st(vs,[card([[el1,el2,el3,el4,btn_del]])],iterable=true,data=[Dict("el1"=>"Overrided Value","el3"=>"red"),Dict("el3"=>"blue"),Dict("el3"=>"green")])

page([btn_add,vs])
""",
"Basic Datatables"=>"""
df=DataFrame()
df[!,:Class]=rand(["A","B","C"],10)
df[!,:Text]=rand(["ABC","DEF","GHI"],10)
df[!,:Value]=rand(10).*10000 .-5000

@el(st,"v-text-field",label="Search")
@el(d1,"v-data-table",items=df,binds=Dict("search"=>"st.value"),cols=3)

@el(sel,"v-select",label="Filter Class",items=["","A","B","C"],change="filter_dt(d2,'Class',sel.value)")
@el(d2,"v-data-table",items=df,filter=Dict("Class"=>"=="),cols=3)

df[!,:Action]=df[!,:Text]
@el(alert,"v-alert",type="success",text=true,cols=3)
@el(btn,"v-btn",content="{{item.Text}}",binds=Dict("color"=>"item.Value<0 ? 'red' : 'blue'"),click="alert.content=item.Text;alert.value=true")
@el(d3,"v-data-table",items=df,col_template=Dict("Action"=>btn),cols=3)

page([[[st,d1],spacer(),[sel,d2],spacer(),[spacer(rows=4),d3,alert]]])
""",
"Navigation and Bar"=>"""
items=[Dict("icon"=>"mdi-apple","title"=>"Apple","href"=>"https://www.apple.com"),Dict("divider" => true), Dict("icon"=>"mdi-cart-outline","title"=>"Shopping","href"=>"https://www.amazon.com")]
@el(navel,"v-navigation-drawer",expand-on-hover=false,items=items)
@el(homeb,"v-btn",icon=true,value="<v-icon>mdi-home</v-icon>",click="open('/home')")
@el(searchb,"v-btn",icon=true,value="<v-icon>mdi-magnify</v-icon>",click="open('https://google.com')")
barel=bar([homeb,"APP",spacer(),searchb])
@el(icon_btn,"v-btn",content="Material Design Icons Page",click="open('https://materialdesignicons.com')")
page([icon_btn],navigation=navel,bar=barel)
""",
"Lists"=>"""
items=[]
push!(items,Dict("title"=>"Title1","subtitle"=>"SubTitle1","icon"=>"mdi-clock","href"=>"https://www.sapo.pt","avatar"=>"https://cdn.vuetifyjs.com/images/lists/2.jpg"))
push!(items,Dict("title"=>"Title2","subtitle"=>"SubTitle2","icon"=>"mdi-pencil-outline","href"=>"https://www.sapo.pt","avatar"=>"https://cdn.vuetifyjs.com/images/lists/3.jpg"))
@el(list1,"v-list",items=items,cols=2)
@el(el,"v-text-field",binds=Dict("label"=>"item.label","value"=>"item.val"))
@el(list2,"v-list",items=[Dict("val"=>"Value1","label"=>"Label1"),Dict("val"=>"Value2","label"=>"Label2")],item=el,cols=3)
@el(b,"v-btn",click="list2.value.push({val:'',label:'New'})",value="ADD")
page([[list1,spacer(),[b,list2]]])
""",
"Computed, Async and Mounted"=>"""
@el(el1,"v-chip",text-color="white",binds=Dict("content"=>"comp2<1 ? 'A' : 'B'","color"=>"comp2<1 ? 'green' : 'blue'"),cols=2)
@el(el2,"v-text-field",label="Random Triggered",binds=Dict("value"=>"comp1"),cols=2)
@el(el3,"v-text-field",label="Submited Element x 2",binds=Dict("value"=>"comp3"),cols=2)
mounted="Vue.set(this.globals, 'heart_beat', 0);setInterval(function(){app_state.globals.heart_beat=Date.now()},1000)"
computed=Dict("comp1"=>"function(){this.globals.heart_beat; return Math.random()*1000}","comp2"=>"function(){return this.comp1 % 2}")
asynccomputed=Dict("comp3"=>"function(){return this.submit('https://httpbin.org/post',{a:this.comp1}).then(x=>JSON.parse(x.responseText).json.a*2)}")
page([el1,el2,el3],mounted=mounted,computed=computed,asynccomputed=asynccomputed)
"""
]
