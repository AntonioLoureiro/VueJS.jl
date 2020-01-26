
mutable struct VueComponent
    
     id::String
     grid::Array
     binds::Dict{String,String}
     scriptels::Vector{String}
     cols::Int64
     data::Dict{String,Any}
     def_data::Dict{String,Any}
     
end


function VueComponent(id::String,garr::Array;binds=Dict{String,String}(),data=Dict{String,Any}(),kwargs...)
    
    args=Dict(string(k)=>v for (k,v) in kwargs)
    
    scripts=haskey(args,"scripts") ? args["scripts"] : []
            
    scope=[]
    garr=element_path(garr,scope)
    comp=VueComponent(id,garr,binds,scripts,3,data,Dict{String,Any}())
    update_data!(comp,data)
    element_binds!(comp,binds=binds)
    
    return comp
end

function element_path(arr::Array,scope::Array)

    new_arr=deepcopy(arr)
    scope_str=join(scope,".")
    
    for (i,rorig) in enumerate(new_arr)
        r=deepcopy(rorig)
        ## Vue Element
        if typeof(r)==VueElement
            
            new_arr[i].path=scope_str

        ## Vue Component
        elseif typeof(r)==VueJS.VueComponent

            scope2=deepcopy(scope)
            push!(scope2,r.id)
            new_arr[i].grid=element_path(r.grid,scope2)
            new_arr[i].binds=Dict(scope_str=="" ? k=>v : scope_str*"."*k=>scope_str*"."*v for (k,v) in r.binds)
            
        ## Array Elements/Components
        elseif typeof(r)<:Array
            new_arr[i]=element_path(r,scope)
        end
    end
    return new_arr
end


element_binds!(comp::VueJS.VueComponent;binds=Dict())=element_binds!(comp.grid,binds=binds)

element_binds!(el::Array;binds=Dict())=map(x->element_binds!(x,binds=binds),el)

function element_binds!(el::VueJS.VueElement;binds=Dict())    
    full_path=el.path=="" ? el.id : el.path*"."*el.id
 
    for (k,v) in binds
        
        (path_tgt,attr_tgt)=try 
            arr_s=split(v,".")
            (join(arr_s[1:end-1],"."),arr_s[end])
        catch
            ("","")
        end
        
        ## update binds in element due to be binded in other element
        if startswith(path_tgt,full_path)
           push!(el.binds,attr_tgt)
        end
        
         (path_src,attr_src)=try 
            arr_s=split(k,".")
            (join(arr_s[1:end-1],"."),arr_s[end])
        catch
            ("","")
        end
            
        ## update binds in element due to be binded in other element
        if startswith(path_src,full_path)
            
            el_path=path_tgt*"."*attr_tgt
            el.dom.attrs[":$attr_src"]=el_path
            el.dom.attrs["@input"]="$el_path= \$event" 
            el.binds=filter(x->x!=attr_tgt,el.binds)
            delete!(el.dom.attrs,attr_src)
            
        end
            
    end
    
    el.binds=unique(el.binds)

    ## Bind el values
    for b in el.binds
        attr_path=(el.path=="" ? el.id*".$(b)" : el.path*"."*el.id*".$(b)")
        el.dom.attrs[":$b"]=attr_path
        el.dom.attrs["@input"]="$attr_path= \$event"
        
        if b==el.value_attr
            delete!(el.dom.attrs,b)
        end
        
    end
    
end




function merge_def_data!(a::Dict,b::Dict)

    for (k,v) in b
       if typeof(v)<:Dict && haskey(a,k)
          merge_def_data!(a[k],b[k])
       elseif haskey(b,k)
          b[k]==nothing ? nothing : a[k]=b[k]
            if !haskey(a,k)
                a[k]=b[k]
            end
       end
    end
    
end

function update_data!(el::VueElement,datavalue)
   
    real_data=nothing
    def_data=Dict{String,Any}()
    for b in el.binds
        
        if haskey(el.dom.attrs,b)   
           real_data=deepcopy(el.dom.attrs[b])
        end
        
        if b==el.value_attr && datavalue!=nothing
           real_data=datavalue
        end
        
        def_data[b]=real_data
        
    end
        
    return Dict(el.id=>def_data)
end

function update_data!(arr::Array,datavalue::Dict)
    
    def_data=Dict{String,Any}()
    for r in arr
        
        if typeof(r)==VueElement
            
            founddata=haskey(datavalue,r.id) ? datavalue[r.id] : nothing
            
        elseif typeof(r)==VueComponent
            
            founddata=haskey(datavalue,r.id) ? datavalue[r.id] : Dict{String,Any}()
            
        else
            founddata=datavalue
        end
                
        got_data=update_data!(r,founddata)
        merge!(def_data,got_data)
    end
    
    return def_data
end

function update_data!(el::VueComponent,datavalue=Dict{String,Any}())
    
    new_data=deepcopy(el.data)
    new_def_data=deepcopy(el.def_data)
    
    merge!(new_data,datavalue)
    updated_data=update_data!(el.grid,new_data)
    merge_def_data!(new_def_data,updated_data)

    el.data=new_data
    el.def_data=new_def_data
    
    return Dict(el.id=>new_def_data)
end
