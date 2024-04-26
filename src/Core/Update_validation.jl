
UPDATE_VALIDATION["quill-editor"]=(
doc="""
    Rich Text Element. See Documentation in <a href="https://vueup.github.io/vue-quill/""
    <code>
     @el(q,"quill-editor",value="<b>Bold Text</b>",toolbar=["strike","bold", "italic", "underline","link","image"],cols=4) 
    </code>
    """,
library="quill-editor",
value_attr="content",
fn=(x)->begin
  haskey(x.attrs,"contentType") ? nothing : x.attrs["contentType"]="html"
end)

UPDATE_VALIDATION["revo-grid"]=(
doc="""
    Spreadsheet Element - Revogrid. See Documentation in <a href="https://revolist.github.io/revogrid/guide/""
    <code>
     columns= [Dict("name"=> "Birth",
               "prop"=> "birthdate",
               "columnType"=> "date",
               "size"=> 150),
          Dict("prop"=> "name",
               "name"=> "First"),
          Dict("prop"=> "details",
               "name"=> "Second")]
     rows= [Dict("birthdate"=> "2022-08-24",
            "name"=> "1",
            "details"=> "Item 1"),
       Dict("birthdate"=> "2022-08-24",
            "name"=> "2",
            "details"=> "Item 2")]
     @el(r1,"revo-grid",value=rows,columns=columns,range=true,cols=6)  
    </code>
    """,
library="revo-grid",
value_attr="source",
fn=(x)->begin
  #haskey(x.attrs,"contentType") ? nothing : x.attrs["contentType"]="html"
end)

UPDATE_VALIDATION["v-currency-field"]=(
doc="""Simple Element allows to input number values with flexile format. Default locale is pt-PT. See Documentation in <a href="https://phiny1.github.io/v-currency-field/config.html#component-props">Currency Field</a>
    <code>
    @el(price,"v-currency-field",value=10000,label="Price",cols=2,suffix="€",decimal-length=0)
    </code>    
    """,
library="currency-field",
value_attr="value",
fn=(x)->begin
   
    haskey(x.attrs,"reverse") ? nothing : x.attrs["reverse"]=true
    haskey(x.attrs,"locale") ? nothing : x.attrs["locale"]="pt-PT"
    haskey(x.attrs,"auto-decimal-mode") ? nothing : x.attrs["auto-decimal-mode"]=false
        
     
    if x.attrs["reverse"]==true
       prefix_int=get(x.attrs,"prefix",nothing)
       suffix_int=get(x.attrs,"suffix",nothing)
       
        prefix_int!=nothing ? (x.attrs["suffix"]=prefix_int;delete!(x.attrs,"prefix")) : nothing
        suffix_int!=nothing ? (x.attrs["prefix"]=suffix_int;delete!(x.attrs,"suffix")) : nothing
            
    end
end)