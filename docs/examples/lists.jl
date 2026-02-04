# Empty items that will compose the list
items = []

push!(items,
    Dict("type"=>"subheader","title"=>"LIST"))
push!(items,
    Dict("title"=>"Title1",
         "subtitle"=>"SubTitle1",
         "append-icon"=>"mdi-clock",
         "href"=>"https://www.sapo.pt",
         "prepend-avatar"=>"https://cdn.vuetifyjs.com/images/lists/2.jpg"))
push!(items,
    Dict("title"=>"Title2",
         "subtitle"=>"SubTitle2",
         "append-icon"=>"mdi-pencil-outline",
         "href"=>"https://www.sapo.pt",
         "prepend-avatar"=>"https://cdn.vuetifyjs.com/images/lists/3.jpg"))
push!(items,
    Dict("type"=>"divider","inset"=>true))

## List with Item-props
@el(list1,"v-list", item-props=true,items=items, cols=2)

# Using this v-text-field as the field text to push to list
@el(el, "v-text-field",label="Title")

@el(b2,"v-btn",value="ADD",click="list1.value.push({title:el.value,subtitle:'sub',href:'https://www.google.pt'})")

page([[list1, spacer(), [el,b2]]])