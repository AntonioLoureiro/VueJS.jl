
specific_update_validation=Dict(

"v-select"=>(x)->begin
        
    @assert haskey(x.dom.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.dom.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"
    
end

)


function update_validate!(vuel::VueElement,args::Dict)
    
    ## Mandatory Args
#     haskey(args,"value") ? nothing : args["value"]=""
    
    ## Binding value to vue element id
    vuel.binds["value"]=vuel.id   
    
    
    tag=vuel.dom.tag
    if haskey(specific_update_validation,tag)
        specific_update_validation[tag](vuel)
    end
    
    return nothing
end



function VueElement(id::String,tag::String;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    ## Args for Vue
    haskey(args,"cols") ? cols=args["cols"] : cols=3
    
    vuel=VueElement(id,htmlElement(tag,args,""),Dict(),[],cols)
    update_validate!(vuel,args)
    
    return vuel
end

macro el(args...)
    
    @assert typeof(args[1])==Symbol "1st arg should be Variable name"
    @assert typeof(args[2])==String "2nd arg should be tag name"
    
    varname=(args[1])
    
    newargs=join(string.(args[3:end]),",")
    
    newexpr=(Meta.parse("""VueElement("$(string(args[1]))","$(string(args[2]))",$newargs)"""))
    return quote
        $(esc(varname))=$(esc(newexpr))
    end
end



function VueComponent(id::String,garr::Array;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    scripts=haskey(args,"scripts") ? args["scripts"] : []
        
    data=haskey(args,"data") ? args["data"] : Dict()
        
    VueJS.VueComponent(id,garr,scripts,3,data)
    
end


function page(garr::Array;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    grid_data=grid(garr)
    
    scripts=haskey(args,"scripts") ? args["scripts"] : []
    push!(scripts,"el: '#app'")
    push!(scripts,"vuetify: new Vuetify()")
    
    data=haskey(args,"data") ? args["data"] : Dict
    def_data=grid_data["def_data"]
    
    update_def_data!(def_data,data)
    
    push!(scripts,"data: "*JSON.json(def_data))
    
    append!(scripts,grid_data["scriptels"])
    
    script="var app = new Vue({"*join(scripts,",")*"})"
    
    body=htmlElement("body",Dict(),htmlElement("div",Dict("id"=>"app"),htmlElement("v-app",Dict(),htmlElement("v-container",Dict("fluid"=>true),grid_data["arr_dom"]))))
    
    page_inst=VueJS.page(deepcopy(VueJS.HEAD),VueJS.INCLUDE_SCRIPTS,VueJS.INCLUDE_STYLES,body,script)
    
    include_scripts=map(x->htmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->htmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x),nothing),page_inst.include_styles)
    
    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)
    
    htmlpage=htmlElement("html",Dict(),[page_inst.head,page_inst.body])
    
    return htmlString(htmlpage)*"<script>$(page_inst.scripts)</script>"
end
 


