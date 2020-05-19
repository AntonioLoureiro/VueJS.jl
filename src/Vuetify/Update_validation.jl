
UPDATE_VALIDATION["v-switch"]=(x)->begin

    x.value_attr="input-value"
end

UPDATE_VALIDATION["v-chip"]=(x)->begin

    x.value_attr=nothing
end

UPDATE_VALIDATION["v-slider"]=(x)->begin

    x.cols==nothing ? x.cols=3 : nothing
end

UPDATE_VALIDATION["v-date-picker"]=(x)->begin

    x.cols==nothing ? x.cols=3 : nothing
end


UPDATE_VALIDATION["v-btn"]=(x)->begin

    ## attr alias of content
    haskey(x.attrs,"value") ? (x.attrs["content"]=x.attrs["value"];delete!(x.attrs,"value")) : nothing
    haskey(x.attrs,"text") ? (x.attrs["content"]=x.attrs["text"];delete!(x.attrs,"text")) : nothing

    x.value_attr=nothing
end

UPDATE_VALIDATION["v-spacer"]=(x)->begin
    x.value_attr=nothing
end

UPDATE_VALIDATION["v-text-field"]=(x)->begin
    x.cols==nothing ? x.cols=2 : nothing
end

UPDATE_VALIDATION["v-select"]=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"

    x.cols==nothing ? x.cols=2 : nothing
    
    if !haskey(x.attrs,"value")
        x.attrs["value"] = get(x.attrs, "multiple", false) != false ? [] : nothing
    end
end

UPDATE_VALIDATION["v-list"]=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify List element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify List element with non Array arg items!"
    @assert haskey(x.attrs,"item") "Vuetify List element with no arg item!"

    x.value_attr="items"

    x.attrs["v-for"]="item in $(x.id).value"
    x.binds["key"]="item.id"
    
    x.child=x.attrs["item"]
    delete!(x.attrs,"item")

end

UPDATE_VALIDATION["v-tabs"]=(x)->begin

    @assert haskey(x.attrs,"names") "Vuetify tab with no names, please define names array!"
    @assert x.attrs["names"] isa Array "Vuetify tab names should be an array"
    @assert length(x.attrs["names"])==length(x.elements) "Vuetify Tabs elements should have the same number of names!"

    x.render_func=(y;opts=PAGE_OPTIONS)->begin
       content=[]
       for (i,r) in enumerate(y.elements)
           push!(content,HtmlElement("v-tab",Dict(),nothing,y.attrs["names"][i]))
           value=r isa Array ? VueJS.dom(r,opts=opts) : VueJS.dom([r],opts=opts)
           push!(content,HtmlElement("v-tab-item",Dict(),12,value))
       end
       HtmlElement("v-tabs",y.attrs,12,content)
    end
end

UPDATE_VALIDATION["v-navigation-drawer"]=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify navigation with no items, please define items array!"
    @assert x.attrs["items"] isa Array "Vuetify navigation items should be an array"

    x.value_attr=nothing
    
    item_names=collect(keys(x.attrs["items"][1]))
    x.tag="v-list"
    x.attrs["item"]=html("v-list-item",[],Dict("dense"=>true,"link"=>true))
    "icon" in item_names ? push!(x.attrs["item"].value,html("v-list-item-icon",html("v-icon","{{ item.icon }}"))) : nothing
    "title" in item_names ? push!(x.attrs["item"].value,html("v-list-item-content",html("v-list-item-title","{{ item.title }}"))) : nothing
    "href" in item_names ? x.attrs["item"].attrs["click"]="open(item.href)" : nothing
            
    VueJS.update_validate!(x)

    x.render_func=(y;opts=PAGE_OPTIONS)->begin

        dom_nav=VueJS.dom(y,prevent_render_func=true,opts=PAGE_OPTIONS)

        nav_attrs=Dict()

        for (k,v) in Dict("clipped"=>true,"width"=>200, "expand-on-hover"=>true, "permanent"=>true, "right"=>false)
            haskey(y.attrs,k) ? nav_attrs[k]=y.attrs[k] : nav_attrs[k]=v
        end

        html("v-navigation-drawer",dom_nav,nav_attrs,cols=12)
    end
end


UPDATE_VALIDATION["v-card"]=(x)->begin

    @assert haskey(x.attrs,"names") "Vuetify card with no names, please define names array!"
    @assert x.attrs["names"] isa Array "Vuetify card names should be an array"
    @assert length(x.attrs["names"])==length(x.elements) "Vuetify card elements should have the same number of names!"

    x.render_func=(y;opts=PAGE_OPTIONS)->begin
       content=[]
       for (i,r) in enumerate(y.elements)
           push!(content,HtmlElement(y.attrs["names"][i],Dict(),nothing,dom(r,opts=opts)))
       end
       HtmlElement("v-card",y.attrs,y.cols,content)
    end
end

UPDATE_VALIDATION["v-alert"]=(x)->begin
    
    x.cols==nothing ? x.cols=12 : nothing
    
    ## Validations
    haskey(x.attrs,"value") ? (@assert x.attrs["value"] isa Bool "Value Attr of Alert Should be Bool") : nothing
    
    ## 3 Basic Defaults
    haskey(x.attrs,"content") ? nothing : x.attrs["content"]=""
    haskey(x.attrs,"type") ? nothing : x.attrs["type"]="success"
    haskey(x.attrs,"value") ? nothing : x.attrs["value"]=false
    
    ## 3 Basic Bindings
    x.binds["content"]=x.id*".content"
    x.binds["type"]=x.id*".type"
    x.binds["value"]=x.id*".value"
    
    x.binds["v-html"]=x.id*".content"
    x.value_attr=nothing

    dismissible = get(x.attrs, "dismissible", false)
    timeout = get(x.attrs, "timeout", 4000)
    delay = get(x.attrs, "delay", 0)

    timeout_func="function(val,old){val ? setTimeout(()=>{this.$(x.id).value = false}, $timeout) : ''}"
    haskey(x.events,"watch") ? x.events["watch"]["$(x.id).value"]=timeout_func : x.events["watch"]=Dict("$(x.id).value"=>timeout_func)

end
