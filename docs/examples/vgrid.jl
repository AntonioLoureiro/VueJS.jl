columns= [Dict("name"=> "Class","prop"=> "class","columnType"=> "select","source"=>["A","B","C"]),
          Dict("name"=> "Text","prop"=> "text","size"=> 90),
          Dict("name"=> "Value","prop"=> "value","columnType"=> "numeric")]
rows= [Dict("class"=> "A","text"=> "DEF","value"=> 1050.34),
       Dict("class"=> "B","text"=> "ABC","value"=> 1298)]

df=DataFrame()
df[!,:Class]=rand(["A","B","C"],10)
df[!,:Text]=rand(["red","green","blue","grey","violet"],10)
df[!,:Date]=rand([Date(2020,1,1),Date(2020,3,23),Date(2023,8,6)],10)
df[!,:Value]=rand(10).*10000 .-5000
   
@el(r1,"revo-grid",value=rows,columns=columns,columnTypes=Dict("numeric"=>js"new NumberColumnType('0,0')","select"=> js"new SelectTypePlugin()"),cols=3) ## Classic Input
@el(r2,"revo-grid",value=df,cols=3) ## DataFrame Input
@el(r3,"revo-grid",value=df,cols=3) ## DataFrame Input

## Attribute Editing after initialization ##
ct=Dict("numeric"=>js"new NumberColumnType('0,0.00')","select"=> js"new SelectTypePlugin()","date"=> js"new DateTypePlugin()")
r3.attrs["columnTypes"]=ct
r3.attrs["columns"][4]["columnType"]="numeric"
r3.attrs["columns"][1]["columnType"]="select"
r3.attrs["columns"][2]["sortable"]=true
r3.attrs["columns"][2]["cellTemplate"]=js"(h, { model, prop }) => h('div', {class: {bubble: true},style:{backgroundColor: model[prop]}},model[prop] )"
r3.attrs["columns"][3]["columnType"]="date"
r3.attrs["columns"][1]["source"]=["A","B","C"]
r3.attrs["columns"][4]["cellProperties"]=js"({prop, model, data, column}) => {return model.value<0 ? {style: {color: 'red'}} : {style: {color: 'blue'}}}"

page([[r1,r2,r3]])