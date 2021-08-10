items=[Dict("icon"=>"mdi-apple","title"=>"Apple","href"=>"https://www.apple.com"),Dict("divider" => true), Dict("icon"=>"mdi-cart-outline","title"=>"Shopping","href"=>"https://www.amazon.com")]
@el(navel,"v-navigation-drawer",expand-on-hover=false,items=items)
@el(homeb,"v-btn",icon=true,value="<v-icon>mdi-home</v-icon>",click="open('/home')")
@el(searchb,"v-btn",icon=true,value="<v-icon>mdi-magnify</v-icon>",click="open('https://google.com')")
barel=bar([homeb,"APP",spacer(),searchb])
@el(icon_btn,"v-btn",content="Material Design Icons Page",click="open('https://materialdesignicons.com')")
page([icon_btn],navigation=navel,bar=barel)