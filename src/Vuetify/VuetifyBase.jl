UPDATE_VALIDATION["v-data-table"]=(x)->begin

    if haskey(x.attrs,"items")
        if x.attrs["items"] isa DataFrame
            df=x.attrs["items"]
            arr=[]
            for n in names(df)
               length(arr)==0 ? arr=map(x->Dict{String,Any}(string(n)=>x),df[:,n]) : map((x,y)->y[string(n)]=x,df[:,n],arr)
            end
            x.attrs["items"]=arr
            if !(haskey(x.attrs,"headers"))
                x.attrs["headers"]=[Dict("value"=>n,"text"=>n,"align"=>(eltype(df[:,Symbol(n)])<:Number ? "end" : "start")) for n in string.(names(df))]
            end
            if !(haskey(x.attrs, "search")) #initialize empty search
                x.attrs["search"] = ""
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