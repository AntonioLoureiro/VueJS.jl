UPDATE_VALIDATION["v-data-table"]=(x)->begin
    trf_col=x->"c"*VueJS.vue_escape(string(x))
    trf_dom=x->begin
    x.attrs=Dict(k=>VueJS.vue_escape(v) for (k,v) in x.attrs)
    x.value=x.value isa String ? VueJS.vue_escape(x.value) : x.value
    end
    
    x.value_attr=nothing
    
    if haskey(x.attrs,"items")
        if x.attrs["items"] isa DataFrame
            df=x.attrs["items"]
            arr=[]
            for n in names(df)
                col_arr=df[:,n]
               if length(arr)==0
                    arr=map(x->Dict{String,Any}(trf_col(n)=>x),col_arr)
                else 
                    map((x,y)->y[trf_col(n)]=x,col_arr,arr)
                end
            end
            x.attrs["items"]=arr
            if !(haskey(x.attrs,"headers"))
                x.attrs["headers"]=[Dict{String,Any}("value"=>trf_col(n),"text"=>n) for n in string.(names(df))]
            end
            
            ### Default Formatting
            for (i,n) in enumerate(names(df))
                n=string(n)
                ### Numbers
                if eltype(df[!,i])<:Union{Missing,Number}
                    map(x->x["text"]==n ? x["align"]="end" : nothing ,x.attrs["headers"])
                    
                    ## Default Renders
                    if !haskey(x.attrs,"col_format") || (haskey(x.attrs,"col_format") && !haskey(x.attrs["col_format"],n))
                        digits=maximum(skipmissing(df[:,Symbol(n)]))>=1000 ? 0 : 2
			eltype(df[!,i])<:Union{Missing,Int} ? digits=0 : nothing
                        haskey(x.attrs,"col_format") ? nothing : x.attrs["col_format"]=Dict{String,Any}()
                        x.attrs["col_format"][n]="x=> x==null ? x : x.toLocaleString('pt',{minimumFractionDigits: $digits, maximumFractionDigits: $digits})"
                    end
                end
            end
        end
        
        ## Col Format
        if haskey(x.attrs,"col_format")
            @assert x.attrs["col_format"] isa Dict "col_format should be a Dict of cols and anonymous js function!"
            new_col_format=Dict{String,Any}()
            for (k,v) in x.attrs["col_format"]
                new_col_format[trf_col(k)]=v
                x.attrs["col_format"]=new_col_format
            end
            
            for (k,v) in x.attrs["col_format"]
				x.slots["item.$k='{item}'"]="""<div v-html="datatable_col_format(item.$k,@path@$(x.id).col_format.$k)"></div>"""
			end
        end	

        ## Col Template
        if haskey(x.attrs,"col_template")
            @assert x.attrs["col_template"] isa Dict "col_template should be a Dict of cols and anonymous js function!"
            new_col_template=Dict{String,Any}()
            for (k,v) in x.attrs["col_template"]
                new_col_template[trf_col(k)]=v
                x.attrs["col_template"]=new_col_template
            end
            
            for (k,v) in x.attrs["col_template"]
                value_dom=nothing
                v isa HtmlElement ? value_dom=v : nothing
                v isa VueElement ? value_dom=VueJS.dom(v) : nothing
                value_dom!=nothing ? trf_dom(value_dom) : nothing
                value_dom!=nothing ? value_str=VueJS.htmlstring(value_dom) : nothing
                
                v isa String ? value_str=VueJS.vue_escape(v) : nothing
                
                value_str=replace(value_str,"item."=>"item.c")
                x.slots["item.$k='{item}'"]=value_str
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

UPDATE_VALIDATION["v-tabs"]=(x)->begin

    @assert haskey(x.attrs,"names") "Vuetify tab with no names, please define names array!"
    @assert x.attrs["names"] isa Array "Vuetify tab names should be an array"
    @assert length(x.attrs["names"])==length(x.elements) "Vuetify Tabs elements should have the same number of names!"

    x.render_func=y->begin
       content=[]
       for (i,r) in enumerate(y.elements)
           push!(content,HtmlElement("v-tab",Dict(),nothing,y.attrs["names"][i]))
           value=r isa Array ? VueJS.dom(r) : VueJS.dom([r])
           push!(content,HtmlElement("v-tab-item",Dict(),12,value))
       end
       HtmlElement("v-tabs",y.attrs,12,content)
    end
end

UPDATE_VALIDATION["v-navigation-drawer"]=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify navigation with no items, please define items array!"
    @assert x.attrs["items"] isa Array "Vuetify navigation items should be an array"
    
    x.value_attr="items"
    
    item_names=collect(keys(x.attrs["items"][1]))
    x.tag="v-list"
    x.attrs["item"]="""<v-list-item dense link @click="open(item.href)">
            $("icon" in item_names ? "<v-list-item-icon><v-icon>{{ item.icon }}</v-icon></v-list-item-icon>" : "")
            <v-list-item-content><v-list-item-title>{{ item.title }}</v-list-item-title></v-list-item-content></v-list-item"""
    
    update_validate!(x)
    
    x.render_func=y->begin
        
        dom_nav=dom(y,prevent_render_func=true)
        
        nav_attrs=Dict()
        
        for (k,v) in Dict("clipped"=>true,"width"=>200)
            haskey(y.attrs,k) ? nav_attrs[k]=y.attrs[k] : nav_attrs[k]=v
        end
        
        HtmlElement("v-navigation-drawer",nav_attrs,12,dom_nav)
    end
end

UPDATE_VALIDATION["v-card"]=(x)->begin

    @assert haskey(x.attrs,"names") "Vuetify card with no names, please define names array!"
    @assert x.attrs["names"] isa Array "Vuetify card names should be an array"
    @assert length(x.attrs["names"])==length(x.elements) "Vuetify card elements should have the same number of names!"

    x.render_func=y->begin
       content=[]
       for (i,r) in enumerate(y.elements)
           push!(content,HtmlElement(y.attrs["names"][i],Dict(),12,dom(r)))
       end
       HtmlElement("v-card",y.attrs,y.cols,content)
    end
end

