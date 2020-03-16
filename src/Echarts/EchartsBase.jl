function VueElement(id::String, ec::EChart,attrs::Dict)
    
    attrs_ec=Dict("options"=>ec.options,"width"=>ec.width,"height"=>ec.height)
    merge!(attrs_ec,attrs)
    return VueElement(id, "vuechart", attrs_ec)   
end

UPDATE_VALIDATION["vuechart"]=(x)->begin

    width=deepcopy(x.attrs["width"])
    delete!(x.attrs,"width")
    height=deepcopy(x.attrs["height"])
    delete!(x.attrs,"height")
    x.value_attr=nothing
    push!(x.style,"width: $(width)px;height: $(height)px;")
end