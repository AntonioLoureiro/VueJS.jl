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