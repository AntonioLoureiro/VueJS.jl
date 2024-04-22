#### Filter DataTable to put in header ####
dt_filter_modes=Dict()
dt_filter_modes["range"]="""(item, filter) =>    {return item >= filter[0] && item <= filter[1] }"""
dt_filter_modes[">="]="""(item, filter) =>    {return item >= filter}"""
dt_filter_modes[">"]="""(item, filter) =>    {return item > filter}"""
dt_filter_modes["<="]="""(item, filter) =>    {return item <= filter}"""
dt_filter_modes["<"]="""(item, filter) =>    {return item < filter}"""
dt_filter_modes["=="]="""(item, filter) =>    {return item == filter}"""
dt_filter_modes["contains"]="""(item, filter) => {return String(item).toLowerCase().includes(String(filter).toLowerCase())}"""

dt_filter_dispatcher(mode::String; callback=dt_filter_modes[mode]) = """
    function(item,filter) {
        c = $callback;        
        if (filter == null || filter == '') { return true; }
        
        if (Array.isArray(filter) && '$mode'.toLowerCase() !== 'range') {
            return filter.some((x) => c(value, x));  
        }
        return c(item, filter)
    }
"""

VueJS.UPDATE_VALIDATION["v-data-table"]=(
doc="",
value_attr="model-value",
fn=(x)->begin
 
    trf_dom=x->begin
    x.attrs=Dict(k=>VueJS.vue_escape(v) for (k,v) in x.attrs)
    x.value=x.value isa String ? VueJS.vue_escape(x.value) : x.value
    end
    
    haskey(x.attrs,"item-key") ? x.attrs["item-key"]=trf_col(x.attrs["item-key"]) : nothing
    
    if haskey(x.attrs,"cell-props")
        x.binds["cell-props"]=x.attrs["cell-props"]
        delete!(x.attrs,"cell-props")
    end
    if haskey(x.attrs,"row-props")
        x.binds["row-props"]=x.attrs["row-props"]
        delete!(x.attrs,"row-props")
    end
    
    x.attrs["model-value"]=[]
    x.cols==nothing ? x.cols=4 : nothing

    ####### Has Items ###########
    if haskey(x.attrs,"items")
        if x.attrs["items"] isa DataFrame
            df=x.attrs["items"]
            arr=[]
            col_idx=Dict{String,Int64}()
            i=1
            for n in names(df)
                col_arr=df[:,n]
               if length(arr)==0
                    arr=map(x->Dict{String,Any}(trf_col(n)=>x),col_arr)
                else
                    map((x,y)->y[trf_col(n)]=x,col_arr,arr)
                end
                col_idx[trf_col(string(n))]=i
                i+=1
            end
            x.attrs["items"]=arr
            if !(haskey(x.attrs,"headers"))
                x.attrs["headers"]=[Dict{String,Any}("key"=>trf_col(n),"title"=>n,"key_orig"=>n) for n in string.(names(df))]
            else
                @assert all(y->"key" in keys(y), x.attrs["headers"]) "Headers declared without value"
                for (i,header) in enumerate(x.attrs["headers"])
                    val = header["key"]
                    title = get(header, "title", val)
                    x.attrs["headers"][i]["title"] = title
                    
                    x.attrs["headers"][i]["key"] = trf_col(val)
                    x.attrs["headers"][i]["key_orig"] = val
                end
            end

            ### Default Formatting
            for (i,n) in enumerate(names(df))
                n=string(n)
                ### Numbers
                if eltype(df[!,i])<:Union{Missing,Number}
                    map(x->x["title"]==n ? x["align"]="end" : nothing ,x.attrs["headers"])

                    ## Default Renders
                    if !haskey(x.attrs,"col_format") || (haskey(x.attrs,"col_format") && !haskey(x.attrs["col_format"],n))
                        if nrow(df) > 0
                            digits=maximum(skipmissing(df[:,Symbol(n)]))>=1000 ? 0 : 2
                            eltype(df[!,i])<:Union{Missing,Int} ? digits=0 : nothing
                            haskey(x.attrs,"col_format") ? nothing : x.attrs["col_format"]=Dict{String,Any}()
                            x.attrs["col_format"][n]=js"x=> x==null ? x : x.toLocaleString('pt',{minimumFractionDigits: $digits, maximumFractionDigits: $digits})"
                        end
                    end
                end
            end
        end

        ####### normalize Headers if not internally built #########
        map(c->c["key"]=trf_col(c["key"]),x.attrs["headers"])
        
        
        #### Filter #####
        if haskey(x.attrs,"filter")
            @assert get(x.attrs,"filter",Dict()) isa Dict "Filter arg should be a Dict of Column Name and Filter Operator=> $(keys(dt_filter_modes))"
            x.attrs["headers"] = convert(Vector{Dict{String, Any}}, x.attrs["headers"])
            x.attrs["custom-key-filter"]=Dict()
            for (k,v) in x.attrs["filter"]      
                new_col=trf_col(k)
                fn=dt_filter_dispatcher(v)
                x.attrs["custom-key-filter"][new_col]=js"""function (value,item,c){
                    
                var col_name='$new_col' 
                var fn=$fn    
                var filter_values=JSON.parse(item)
                var filter_value=filter_values[col_name];
               
                return  fn(c["columns"][col_name],filter_value)
                }
                """
            end          
            delete!(x.attrs,"filter")
                
            x.binds["search"]=x.id*".search"
            x.attrs["search"]="{}"
            x.attrs["custom-filter"]=js"""function (value,item,c){return true}"""
            x.binds["custom-filter"]=x.id*".custom_filter"    
            x.binds["custom-key-filter"]=x.id*".custom_key_filter"
        end


        ######### Col Format #########
        if haskey(x.attrs,"col_format")
            @assert x.attrs["col_format"] isa Dict "col_format should be a Dict of cols and anonymous js function!"
            new_col_format=Dict{String,Any}()
            for (k,v) in x.attrs["col_format"]
                new_col_format[trf_col(k)]=v
            end
            x.attrs["col_format"]=new_col_format
            
            for (k,v) in x.attrs["col_format"]
                x.slots["item.$k='{item}'"]=html("div","{{datatable_col_format(item.$k,$(x.id).col_format.$k)}}")
			end
        end

        ###### Col Template ##########
        if haskey(x.attrs,"col_template")
            @assert x.attrs["col_template"] isa Dict "col_template should be a Dict of cols and HtmlElement!"
            new_col_template=Dict{String,Any}()
            for (k,v) in x.attrs["col_template"]
                new_col_template[trf_col(k)]=v
            end
            x.attrs["col_template"]=new_col_template

            for (k,v) in x.attrs["col_template"]
                value_dom=nothing
                if v isa VueJS.HtmlElement
                    value_dom=v
                     new_d=Dict{String,Any}()
                    for (kk,vv) in value_dom.attrs
                        if vv isa AbstractString && occursin("item.",vv)
                            new_d[":$kk"]=VueJS.vue_escape(vv)
                        else
                            new_d[kk]=vv
                        end
                    end
                    value_dom.attrs=new_d
                end
                                
                if v isa VueJS.VueElement
                    vd=deepcopy(v)
                    value_dom=VueJS.dom(vd,is_child=true)
                                        
                    if value_dom.value isa VueJS.HtmlElement && value_dom.value.value isa AbstractString && occursin("item.",value_dom.value.value)
                       value_dom.value.value=VueJS.vue_escape(value_dom.value.value)
                    end
                    
                end
                value_dom!=nothing ? trf_dom(value_dom) : nothing
                value_dom!=nothing ? value_str=VueJS.htmlstring(value_dom) : nothing

                v isa String ? value_str=VueJS.vue_escape(v) : nothing
                
                value_str=replace(value_str,"item."=>"item.$(col_pref)")
                x.slots["item.$k='{item}'"]=value_str
					
                haskey(x.attrs["headers"][col_idx[k]], "align") ? nothing : x.attrs["headers"][col_idx[k]]["align"]="center"
	    end
            
	    delete!(x.attrs,"col_template")
        end

    end
end)
