
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


function revo_grid_data(df::DataFrame)
   
    columns=Vector{Dict{String,Any}}()
    columnTypes=Dict{String,Any}()
    (row_n,col_n)=size(df)
    rows=[Dict{String,Any}() for r in 1:row_n]
    
    for n in names(df)
        prop_id=VueJS.vue_escape(n)
        col_data=Dict("name"=>n,"prop"=>prop_id)
        arr_values=df[!,Symbol(n)]
        
        ### Numbers ###
        if eltype(arr_values)<:Union{Missing,Number}
            digits=maximum(skipmissing(arr_values))>=1000 ? 0 : 2
            eltype(arr_values)<:Union{Missing,Int} ? digits=0 : nothing
            dict_col_type=digits==0 ? Dict("numeric0"=>js"new NumberColumnType('0,0')") : Dict("numeric2"=>js"new NumberColumnType('0,0.00')")
            merge!(columnTypes,dict_col_type)
            col_data["columnType"]=[r for r in keys(dict_col_type)][1]     
        end
        
        push!(columns,col_data)
        map((x,y)->y[prop_id]=x,arr_values,rows)
    end
    return (rows=rows,columns=columns,columnTypes=columnTypes)
end

UPDATE_VALIDATION["revo-grid"]=(
doc="""
    Spreadsheet Element - Revogrid. See Documentation in <a href="https://revolist.github.io/revogrid/guide/""
    <code>
     columns= [Dict("name"=> "Birth",
               "prop"=> "birthdate",
               "columnType"=> "date",
               "size"=> 150),
          Dict("prop"=> "name",
               "columnType"=> "numeric",
               "name"=> "First"),
          Dict("prop"=> "details",
               "name"=> "Second")]
     rows= [Dict("birthdate"=> "2022-08-24",
            "name"=> 1000,
            "details"=> "Item 1"),
       Dict("birthdate"=> "2022-08-24",
            "name"=> 2000,
            "details"=> "Item 2")]
     @el(r1,"revo-grid",value=rows,columns=columns,range=true,cols=6)  
    </code>
    """,
library="revo-grid",
value_attr="source",
fn=(x)->begin
    haskey(x.attrs,"range") ? nothing : x.attrs["range"]=true
    @assert haskey(x.attrs,"value") "value attr is mandatory, it should be an array of Dicts or a DataFrame!"

    if x.attrs["value"] isa DataFrame
       ret_data=revo_grid_data(x.attrs["value"])
       x.attrs["value"]=ret_data.rows     
       x.attrs["columns"]=ret_data.columns
       ret_data.columnTypes==Dict() ? nothing : x.attrs["columnTypes"]=ret_data.columnTypes
    end
     
    haskey(x.attrs,"hide-attribution") ? nothing : x.attrs["hide-attribution"]=true
    
    @assert haskey(x.attrs,"columns") "columns attr is mandatory!"
end)
