module vuetify

using ..VueJS,..XMLDict,..JSON

generic_validation=[]

specific_update_validation=Dict(

"v-select"=>(el)->begin
        
    @assert haskey(el.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(el.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"
    
end



)


function update_validate!(el::htmlElement)
    
   specific_update_validation[el.tag](el)
    
    return nothing
end

macro el(args...)
    
    @assert typeof(args[1])==Symbol "1st arg should be Variable name"
    @assert typeof(args[2])==String "2nd arg should be tag name"
    
    varname=(args[1])
    
    newargs=join(string.(args[3:end]),",")
    
    newexpr=(Meta.parse("""vuetify.el("$(string(args[1]))","$(string(args[2]))",$newargs)"""))
    return quote
        $(esc(varname))=$(esc(newexpr))
    end
end


function el(id::String,tag::String;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    ## Args for Vue
    haskey(args,"cols") ? cols=args["cols"] : cols=3
    
    ## Mandatory Args
    haskey(args,"value") ? nothing : args["value"]=""
    
    dom=htmlElement(tag,args,args["value"])   
    
    if haskey(specific_update_validation,tag)
       update_validate!(dom)
    end

    scriptels=[]
        
    typeof(args["value"])==String ? dom.value="" : nothing

    VueElement(id,dom,scriptels,cols)
    
end


function page(el::VueElement;scripts=[])
    
    (dom,elscripts)=domscripts(el)
    
    body=htmlElement("body",Dict(),htmlElement("div",Dict("id"=>"app"),htmlElement("v-app",Dict(),dom)))
        
    scripts=[elscripts]
    
    push!(scripts,"""var app=new Vue({el: '#app',vuetify: new Vuetify()})""")
        
    page_inst=VueJS.page(deepcopy(VueJS.HEAD),VueJS.INCLUDE_SCRIPTS,VueJS.INCLUDE_STYLES,body,join(scripts,"\n"))
    
    include_scripts=map(x->htmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->htmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x),nothing),page_inst.include_styles)
    
    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)
    
    htmlpage=htmlElement("html",Dict(),[page_inst.head,page_inst.body])
    
    return htmlString(htmlpage)*"<script>$(page_inst.scripts)</script>"
end



end