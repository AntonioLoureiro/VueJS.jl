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
