update_style!(el, opts::VueJS.Opts)=nothing

function update_style!(el::VueElement,opts::Opts)
    
    el_new_style=convert(Dict{String,Any},get(opts.style,el.tag,Dict{String,Any}()))
    
    if length(el_new_style)!=0
        if haskey(el.attrs,"style")
           merge!(el_new_style,el.attrs["style"])
        else
            el.binds["style"]=el.id*".style"
        end
        el.attrs["style"]=el_new_style
    end
    
    el_new_class=get(opts.class,el.tag,Dict{Any,Any}())
    
    if length(el_new_class)!=0
        if haskey(el.attrs,"class")
           el_new_class=el.attrs["class"]*" "*el_new_class
        end
        el.attrs["class"]=el_new_class
    end
    
end

update_style!(arr::Array,opts::Opts)=map(x->update_style!(x,opts),arr)

function update_style!(el::VueStruct,opts::Opts)
    
    new_opts=deepcopy(opts)
    merge!(new_opts.style,get(el.attrs,"style",Dict{Any,Any}()))
    merge!(new_opts.class,get(el.attrs,"class",Dict{Any,Any}()))
    
    update_style!(el.grid,new_opts)

end

update_style!(vueh::VueHolder,opts::Opts)=update_style!(vueh.elements,opts)


macro style(tag_name,args...)

    @assert typeof(tag_name) <: AbstractString "1st arg should be tag name"
    newargs=treat_kwargs(args) 
        
    newargs="Dict($(join(newargs,",")))"
    newargs=Meta.parse(newargs)
    if haskey(PAGE_OPTIONS.style,tag_name)
        return quote
        merge!(PAGE_OPTIONS.style[$tag_name],$newargs)
        end
    else
        return quote
        PAGE_OPTIONS.style[$tag_name]=$newargs
        end
    end
end

macro class(tag_name,class_string)

    @assert typeof(tag_name) <: AbstractString "1st arg should be tag name"
    @assert typeof(class_string) <: AbstractString "2nd arg should be class string"
            
    return quote
       PAGE_OPTIONS.class[$tag_name]=$class_string
    end
end

macro css(css_tag,css_dict)
       
    return quote
       @assert $css_tag isa AbstractString "1st arg should be css selector"
       @assert $css_dict isa Dict{String,String} "2nd arg should be a Dict of css properties and values of type Dict{String,String}"
        
       VueJS.PAGE_OPTIONS.css[$css_tag]=$css_dict
    end
end

function css_str(css_dict::Dict{String,Dict{String,String}})
    css_arr=[]
    for (k,v) in css_dict
        push!(css_arr,"$k {"*join(["$kk:$vv;" for (kk,vv) in v])*"}")
    end
    return join(css_arr," ")
end