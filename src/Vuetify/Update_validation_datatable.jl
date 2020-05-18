#### Filter DataTable to put in header ####
dt_filter_modes=Dict()
dt_filter_modes["range"]="""function(value, search, item){if (this.filter_value==null || this.filter_value==''){return true} else{return (value>=this.filter_value[0] && value<=this.filter_value[1])}}"""
dt_filter_modes[">="]="""function(value, search, item){if (this.filter_value==null || this.filter_value==''){return true} else{return value>=this.filter_value}}"""
dt_filter_modes[">"]="""function(value, search, item){if (this.filter_value==null || this.filter_value==''){return true} else{return value>this.filter_value}}"""
dt_filter_modes["<="]="""function(value, search, item){if (this.filter_value==null || this.filter_value==''){return true} else{return value<=this.filter_value}}"""
dt_filter_modes["<"]="""function(value, search, item){if (this.filter_value==null || this.filter_value==''){return true} else{return value<this.filter_value}}"""
dt_filter_modes["=="]="""function(value, search, item){if (this.filter_value==null || this.filter_value==''){return true} else{return value==this.filter_value}}"""

UPDATE_VALIDATION["v-data-table"]=(x)->begin
    col_pref="_"
    trf_col=x->!(string(x)[1] in JS_FIRST_VAR_CHARS) ? col_pref*VueJS.vue_escape(string(x)) : vue_escape(string(x))
    trf_dom=x->begin
    x.attrs=Dict(k=>VueJS.vue_escape(v) for (k,v) in x.attrs)
    x.value=x.value isa String ? VueJS.vue_escape(x.value) : x.value
    end
    
    haskey(x.attrs,"item-key") ? x.attrs["item-key"]=trf_col(x.attrs["item-key"]) : nothing
    x.value_attr="value"
    x.attrs["value"]=[]
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
                x.attrs["headers"]=[Dict{String,Any}("value"=>trf_col(n),"text"=>n,"value_orig"=>n) for n in string.(names(df))]
            end

            ### Default Formatting
            for (i,n) in enumerate(names(df))
                n=string(n)
                ### Numbers
                if eltype(df[!,i])<:Union{Missing,Number}
                    map(x->x["text"]==n ? x["align"]="end" : nothing ,x.attrs["headers"])

                    ## Default Renders
                    if !haskey(x.attrs,"col_format") || (haskey(x.attrs,"col_format") && !haskey(x.attrs["col_format"],n))
			if nrow(df) > 0
			    digits=maximum(skipmissing(df[:,Symbol(n)]))>=1000 ? 0 : 2
			    eltype(df[!,i])<:Union{Missing,Int} ? digits=0 : nothing
			    haskey(x.attrs,"col_format") ? nothing : x.attrs["col_format"]=Dict{String,Any}()
			    x.attrs["col_format"][n]="x=> x==null ? x : x.toLocaleString('pt',{minimumFractionDigits: $digits, maximumFractionDigits: $digits})"
			end
                    end
                end
            end
        end

        ####### normalize Headers if not internally built #########
        map(c->c["value"]=trf_col(c["value"]),x.attrs["headers"])
        

        #### Filter and create Headers Index #####
        x.attrs["headers_idx"]=Dict()
        filter_arg=get(x.attrs,"filter",Dict())
        haskey(x.attrs,"filter") ? delete!(x.attrs,"filter") : nothing
        @assert filter_arg isa Dict "Filter arg should be a Dict of Column Name and Filter Operator=> $(keys(dt_filter_modes))"
		x.attrs["headers"] = convert(Vector{Dict{String, Any}}, x.attrs["headers"])
        for (i,r) in enumerate(x.attrs["headers"])
            x.attrs["headers_idx"][r["value_orig"]]=i-1
            
            ### has filter indication in filter arg
            filt_oper=get(filter_arg,x.attrs["headers"][i]["value_orig"],nothing)
            
            if filt_oper!=nothing
                @assert filt_oper in keys(dt_filter_modes) "Filter arg should be a Dict of Column Name and Filter Operator=> $(keys(dt_filter_modes))"
                x.attrs["headers"][i]["filter_value"]=nothing
                x.attrs["headers"][i]["filter"]=dt_filter_modes[filt_oper]                
            end
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
				x.slots["item.$k='{item}'"]="""<div v-html="datatable_col_format(item.$k,$(x.id).col_format.$k)"></div>"""
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
                            new_d[":$kk"]=vv
                        else
                            new_d[kk]=vv
                        end
                    end
                    value_dom.attrs=new_d
                end
                                
                if v isa VueJS.VueElement
                    vd=deepcopy(v)
                    value_dom=VueJS.dom(vd,is_child=true)
                end
                value_dom!=nothing ? trf_dom(value_dom) : nothing
                value_dom!=nothing ? value_str=VueJS.htmlstring(value_dom) : nothing

                v isa String ? value_str=VueJS.vue_escape(v) : nothing

                x.slots["item.$k='{item}'"]=value_str

                x.attrs["headers"][col_idx[k]]["align"]="center"
			end
            delete!(x.attrs,"col_template")
        end

    end
end
