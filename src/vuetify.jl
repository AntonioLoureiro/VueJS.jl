
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
    vuel.dom.attrs[":value"]=vuel.id
    vuel.dom.attrs["@input"]="$(vuel.id) = \$event.target.value"
    
    
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

function comp(id::String,garr::Array;scripts=["vuetify: new Vuetify()"],kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    gridnt=grid(garr)
    scriptels=[]
    push!(scriptels,"el: '#$id'")
    append!(scriptels,scripts)
    def_data=gridnt.def_data
    
    if haskey(args,"data")
        for (k,v) in def_data
            haskey(args["data"],k) ? def_data[k]=args["data"][k] : nothing
        end
    end
    push!(scriptels,"data: "*JSON.json(def_data))
    
    script="new Vue({"*join(scriptels,",")*"})"
    VueComponent(id,gridnt.elements,htmlElement("div",Dict("id"=>id),htmlElement("v-container",Dict("fluid"=>true),gridnt.dom)),script,3,def_data)
    
end


function page(garr::Array;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    vueapp=comp("app",garr;kwargs...)
    
    body=htmlElement("body",Dict(),htmlElement("div",Dict("id"=>"app"),htmlElement("v-app",Dict(),htmlElement("v-container",Dict("fluid"=>true),vueapp.dom))))
        
    elscripts=[vueapp.script]
    
    haskey(args,"scripts") ? append!(elscripts,args["scripts"]) : nothing
            
    page_inst=VueJS.page(deepcopy(VueJS.HEAD),VueJS.INCLUDE_SCRIPTS,VueJS.INCLUDE_STYLES,body,join(elscripts,"\n"))
    
    include_scripts=map(x->htmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->htmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x),nothing),page_inst.include_styles)
    
    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)
    
    htmlpage=htmlElement("html",Dict(),[page_inst.head,page_inst.body])
    
    return htmlString(htmlpage)*"<script>$(page_inst.scripts)</script>"
end
 


