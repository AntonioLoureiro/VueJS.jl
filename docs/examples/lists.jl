# Empty items that will compose the list
items = []

push!(items,
    Dict("title"=>"Title1",
         "subtitle"=>"SubTitle1",
         "icon"=>"mdi-clock",
         "href"=>"https://www.sapo.pt",
         "avatar"=>"https://cdn.vuetifyjs.com/images/lists/2.jpg"))
push!(items,
    Dict("title"=>"Title2",
         "subtitle"=>"SubTitle2",
         "icon"=>"mdi-pencil-outline",
         "href"=>"https://www.sapo.pt",
         "avatar"=>"https://cdn.vuetifyjs.com/images/lists/3.jpg"))

@el(list1,"v-list", items=items, cols=2)

# Using this v-text-field as a template for dynamically created items for `list2`
@el(el, "v-text-field", binds=Dict("label"=>"item.label","value"=>"item.val"))
# keyword `item` is used to specify the template item
@el(list2,"v-list", items=[Dict("val"=>"Value1","label"=>"Label1"),Dict("val"=>"Value2","label"=>"Label2")],item=el,cols=3)
# A button that will add new items to `list2`
@el(b2,"v-btn",click="list2.value.push({val:'',label:'New item'})",value="ADD")

page([[list1, spacer(), [b2, list2]]])