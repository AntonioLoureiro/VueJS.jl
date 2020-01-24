
specific_update_validation=Dict(

"v-select"=>(x)->begin
        
    @assert haskey(x.dom.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.dom.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"
    
end

)


function update_validate!(vuel::VueElement,args::Dict)
    
    ## Default Binding value_attr 
    vuel.binds=[vuel.value_attr]
        
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
    
    vuel=VueElement(id,htmlElement(tag,args,""),"",[],[],"value",cols)
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



function VueComponent(id::String,garr::Array;binds=Dict{String,String}(),kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    scripts=haskey(args,"scripts") ? args["scripts"] : []
        
    data=haskey(args,"data") ? args["data"] : Dict()
    
    scope=[]
    garr=element_path(garr,scope)
    comp=VueJS.VueComponent(id,garr,binds,scripts,3,data,Dict{String,Any}())
    element_binds!(comp,binds=binds)
    update_data!(comp)
    return comp
end

function element_path(arr::Array,scope::Array)
    
    new_arr=deepcopy(arr)
    scope_str=join(scope,".")
    
    for (i,r) in enumerate(new_arr)
        ## Vue Element
        if typeof(r)==VueElement
            r.path=scope_str
        ## Vue Component
        elseif typeof(r)==VueJS.VueComponent
            push!(scope,r.id)
            r.grid=element_path(r.grid,scope)
            r.binds=Dict(scope_str=="" ? k=>v : scope_str*"."*k=>scope_str*"."*v for (k,v) in r.binds)
        ## Array Elements/Components
        elseif typeof(r)<:Array
            r=element_path(r,scope)
        end
    end
    return new_arr
end

element_binds!(comp::VueJS.VueComponent;binds=Dict())=map(x->element_binds!(x,binds=comp.binds),comp.grid)
element_binds!(el::Array;binds=Dict())=map(x->element_binds!(x,binds=binds),el)

function element_binds!(el::VueJS.VueElement;binds=Dict())    
    
    for (k,v) in binds
        
        (path_tgt,attr_tgt)=try 
            arr_s=split(v,".")
            (join(arr_s[1:end-1],"."),arr_s[end])
        catch
            ("","")
        end
        
        ## update binds in element due to be binded in other element
        if startswith(path_tgt,el.path)
           push!(el.binds,attr_tgt)
        end
        
         (path_src,attr_src)=try 
            arr_s=split(k,".")
            (join(arr_s[1:end-1],"."),arr_s[end])
        catch
            ("","")
        end
        
        ## update binds in element due to be binded in other element
        if startswith(path_src,el.path)
            el_path=path_tgt*"."*attr_tgt
            el.dom.attrs[":$attr_src"]=el_path
            el.dom.attrs["@input"]="$el_path= \$event" 
        end
            
    end
    
    el.binds=unique(el.binds)

    ## Bind el values
    for b in el.binds
        attr_path=(el.path=="" ? el.id*".$(b)" : el.path*"."*el.id*".$(b)")
        el.dom.attrs[":$b"]=attr_path
        el.dom.attrs["@input"]="$attr_path= \$event"
        
    end
    
end

function update_data!(el::VueJS.VueElement,datavalue)
    
    def_data=Dict{String,Any}()
    for b in el.binds
        
        if haskey(el.dom.attrs,b)
           realdata=el.dom.attrs[b]
           if b==el.value_attr && datavalue!=nothing
                realdata=datavalue
           end
           delete!(el.dom.attrs,b)
        else
           realdata=""
        end
        
        def_data[b]=realdata
    end
    return Dict(el.id=>def_data)
end

function update_data!(el::Array,datavalue=Dict{String,Any}())
    def_data=Dict{String,Any}()
    for e in el
       datavalue=update_data!(e,datavalue)
       merge!(def_data,datavalue)
    end
    
    return def_data
end

function update_data!(el::VueJS.VueComponent,datavalue=Dict{String,Any}())
    
    for e in el.grid
        
        if typeof(e) in [VueElement,VueComponent]
            if haskey(el.data,e.id)
                datavalue=el.data[e.id]
            else    
                datavalue=nothing
            end
            
            def_data=update_data!(e,datavalue)
            merge!(el.def_data,def_data)
        elseif typeof(e)<:Array
            def_data=update_data!(e,el.data)
            merge!(el.def_data,def_data)
        end
    end
        
    return Dict(el.id=>el.def_data)
end


function page(garr::Array;kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    data=haskey(args,"data") ? args["data"] : Dict()
    (arr_dom,def_data)=grid(garr,data=data)
    
    scripts=haskey(args,"scripts") ? args["scripts"] : []
    
    push!(scripts,"const app_state = $(JSON.json(def_data))")
    
    ## component script
    comp_script=[]
    push!(comp_script,"el: '#app'")
    push!(comp_script,"vuetify: new Vuetify()")
    push!(comp_script,"data: app_state")
    comp_script="var app = new Vue({"*join(comp_script,",")*"})"
    push!(scripts,comp_script)
    
    body=htmlElement("body",Dict(),htmlElement("div",Dict("id"=>"app"),htmlElement("v-app",Dict(),htmlElement("v-container",Dict("fluid"=>true),arr_dom))))
    
    page_inst=VueJS.page(deepcopy(VueJS.HEAD),VueJS.INCLUDE_SCRIPTS,VueJS.INCLUDE_STYLES,body,join(scripts,"\n"))
    
    include_scripts=map(x->htmlElement("script",Dict("src"=>x),""),page_inst.include_scripts)
    include_styles=map(x->htmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>x),nothing),page_inst.include_styles)
    
    append!(page_inst.head.value,include_scripts)
    append!(page_inst.head.value,include_styles)
    
    htmlpage=htmlElement("html",Dict(),[page_inst.head,page_inst.body])
    
    return htmlString(htmlpage)*"<script>$(page_inst.scripts)</script>"
end 
