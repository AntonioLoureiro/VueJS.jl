UPDATE_VALIDATION["v-data-table"]=(x)->begin
    
    if haskey(x.dom.attrs,"items")
        if x.dom.attrs["items"] isa DataFrame
            df=x.dom.attrs["items"]
            arr=[]
            for n in names(df)
               length(arr)==0 ? arr=map(x->Dict{String,Any}(string(n)=>x),df[!,n]) : map((x,y)->y[string(n)]=x,df[!,n],arr)
            end
            x.dom.attrs["items"]=arr
            if !(haskey(x.dom.attrs,"headers"))
                x.dom.attrs["headers"]=[Dict("value"=>n,"text"=>n) for n in string.(names(df))]
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

    @assert haskey(x.dom.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.dom.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"
end
