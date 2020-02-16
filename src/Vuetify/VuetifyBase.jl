UPDATE_VALIDATION["v-data-table"]=(x)->begin

    x.value_attr=nothing
    if haskey(x.attrs,"items")
        if x.attrs["items"] isa DataFrame
            df=x.attrs["items"]
            arr=[]
            for n in names(df)
               length(arr)==0 ? arr=map(x->Dict{String,Any}(lowercase(string(n))=>x),df[:,n]) : map((x,y)->y[lowercase(string(n))]=x,df[:,n],arr)
            end
            x.attrs["items"]=arr
            if !(haskey(x.attrs,"headers"))
                x.attrs["headers"]=[Dict("value"=>lowercase(n),"text"=>n) for n in string.(names(df))]
            end
            
            ### Formatting
            for (i,n) in enumerate(names(df))
                ### Numbers
                if eltype(df[!,i])<:Union{Missing,Number}
                    map(x->x["align"]="end",x.attrs["headers"])
                    
                    if !haskey(x.attrs,"col_render") || (haskey(x.attrs,"col_render") && !(haskey(x.attrs["col_render"],string(n))))
                        digits=maximum(skipmissing(df[:,n]))>=1000 ? 0 : 2
                        x.attrs["col_render"][string(n)]="x=> x.toLocaleString('pt',{minimumFractionDigits: $digits, maximumFractionDigits: $digits})"                       
                        
                    end
                    
                end
            end
        end
        
        ## Column rendering
		if haskey(x.attrs,"col_render")
			col_render=x.attrs["col_render"]
			@assert col_render isa Dict "col_render should be a Dict of cols and anonymous js function!"
			for (k,v) in col_render
				col=lowercase(k)                                        
				x.slots["item.$col='{item}'"]="""<div v-html="datatable_col_render(item.$col,@path@d1.col_render.$k)"></div>"""
			end
		end
        
    end
end

UPDATE_VALIDATION["v-switch"]=(x)->begin
    
    x.value_attr="input-value"
end

UPDATE_VALIDATION["v-btn"]=(x)->begin

    x.value_attr=nothing
end

UPDATE_VALIDATION["v-app-bar"]=(x)->begin

    x.value_attr=nothing
end

UPDATE_VALIDATION["v-select"]=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"
end

UPDATE_VALIDATION["v-list"]=(x)->begin
    
    @assert haskey(x.attrs,"items") "Vuetify List element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify List element with non Array arg items!"
    @assert haskey(x.attrs,"item") "Vuetify List element with no arg item!"
    
    x.value_attr="items"
    
    x.attrs["v-for"]="item in @path@$(x.id).value"
    x.attrs["v-bind:key"]="item.id"
    
    x.child=x.attrs["item"]
    delete!(x.attrs,"item")
    
end