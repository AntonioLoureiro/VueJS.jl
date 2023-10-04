df=DataFrame()
df[!,:Class]=rand(["A","B","C"],10)
df[!,:Text]=rand(["ABC","DEF","GHI"],10)
df[!,:Value]=rand(10).*10000 .-5000

@css ".custom_css" Dict("background-color"=>"lightcyan","font-weight"=>"bold")
@el(st,"v-text-field",label="Search")
@el(d1,"v-data-table",items=df,binds=Dict("search"=>"st.value"),item-class="cond_form",cols=3)

@el(sel,"v-select",label="Filter Class",items=["","A","B","C"],change="filter_dt(d2,'Class',sel.value)")
@el(d2,"v-data-table",items=df,filter=Dict("Class"=>"=="),cols=3)

df[!,:Action]=df[!,:Text]
@el(alert,"v-alert",type="success",text=true,cols=3)
@el(btn,"v-btn",content="{{item.Text}}",binds=Dict("color"=>"item.Value<0 ? 'red' : 'blue'"),click="alert.content=item.text;alert.value=true")
@el(d3,"v-data-table",items=df,col_template=Dict("Action"=>btn),cols=3)

page([[[st,d1],spacer(),[sel,d2],spacer(),[spacer(rows=4),d3,alert]]],methods=Dict("cond_form"=>"""function(item){return item.col_value<0 ? 'custom_css' : ''}"""))