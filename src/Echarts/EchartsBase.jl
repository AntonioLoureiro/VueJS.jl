function VueElement(id::String, ec::EChart,attrs::Dict)
    
    attrs_ec=Dict("option"=>ec.options,"width"=>ec.width,"height"=>ec.height)
    merge!(attrs_ec,attrs)
    return VueElement(id, "vuechart", attrs_ec)   
end

UPDATE_VALIDATION["vuechart"]=(
doc="",
library="echarts",
value_attr=nothing,
fn=(x)->begin
    x.cols==nothing ? x.cols=6 : nothing
    width=deepcopy(x.attrs["width"])
    delete!(x.attrs,"width")
    height=deepcopy(x.attrs["height"])
    delete!(x.attrs,"height")
        
    if !haskey(x.attrs,"style") && !haskey(x.binds,"style")
       x.binds["style"]="adjust_to_window_size($width,$height,$(x.cols))"
    end
     
    x.attrs["autoresize"]=true
end)