mutable struct VueSFC
    name::String                # "page"
    url::String                 # "/pages/page.vue"
    path::Union{Nothing,String} # "/web/pages/page.vue"
    props::Dict                 # Dict("attr1"=>"value")
end
VueSFC(name::String, url::String, path::Union{Nothing,String}; props = Dict())  = VueSFC(name, url, path, props)
VueSFC(name::String, url::String; props = Dict())                               = VueSFC(name, url, nothing, props=props)
VueSFC(url::String; props = Dict())                                             = VueSFC(replace(last(splitpath(url)), ".vue"=>""), url, props=props)

const DEFAULT_WEB_FOLDER = "web"

"""
    Create a Page based in SFC file list (Single File Component)

    Usage examples:
        sfc_page("my-page", [
            VueSFC("my-page", "/pages/Home.vue",           "/web/pages/Home.vue"),
            VueSFC("my-menu", "/components/Menu.vue",      "/web/components/Menu.vue"),
            VueSFC("my-comp", "/components/Component.vue", "/web/components/Component.vue"),
        ])

        sfc_page([
            VueSFC("my-page", "/pages/Home.vue",           "/web/pages/Home.vue"),
            VueSFC("my-menu", "/components/Menu.vue",      "/web/components/Menu.vue"),
        ], title="Home")

"""
function sfc_page(
    placeholder ::String,
    sfc         ::Vector{VueSFC};
    props       ::Dict                      = Dict(),
    scripts     ::Vector{String}            = String[],
    cookies     ::Dict                      = Dict{String, Any}(),
    globals     ::Dict                      = Dict{String, Any}(),
    meta        ::Vector{HtmlElement}       = META,
    title       ::Union{String, Nothing}    = nothing) :: Page

    sfc_dt = Dict([s.name => s for s in sfc])
    @assert haskey(sfc_dt, placeholder) "Placeholder component not available ('$placeholder')"
    sfc_dt["_placeholder"] = sfc_dt[placeholder]
    sfc_dt["_placeholder"].props = props

    return Page(DEPENDENCIES, sfc_dt, scripts, cookies, globals, meta, title)
end
function sfc_page(sfc::Vector{VueSFC}; kwargs...) :: Page
    @assert length(sfc)>0 "Empty components list"
    return sfc_page(sfc[1].name, sfc; kwargs...)
end

"""
Create a Page based in a placeholder component and a SFC folder structure. Method
will scan for .vue files. If no folder is provided, '/web' folder will be used.
    
Usage examples:
    sfc_page("Form")
    sfc_page("Form", title="FORM")
    sfc_page("Form", "web")
    sfc_page("Form", "web", title="FORM")
    sfc_page("Form", ["web", "src/handlers/web"])
    sfc_page("Form", "web/Page.vue")
"""
function sfc_page(placeholder::String, paths::Vector{String}; kwargs...) :: Page
    sfc = components(paths)
    @assert length(sfc)>0 "No component files found (.vue)"
    return sfc_page(placeholder, sfc; kwargs...)
end
sfc_page(placeholder::String, path::String; kwargs...) = sfc_page(placeholder, [path]; kwargs...)
sfc_page(placeholder::String; kwargs...) = sfc_page(placeholder, [DEFAULT_WEB_FOLDER]; kwargs...)

"""
Scan for SFC files in a folder (and subfolders)

Usage examples:
    sfc = components("web")end
    sfc = components(["web/components", web/pages", "src/web/MyComponent.vue"])
"""
components(path::String) = components([path])
function components(paths::Vector{String}) :: Vector{VueSFC}

    SFC_EXTENSIONS = ["vue"]

    file_extension(file::String) = file[findlast(==('.'), file)+1:end]

    function add_sfc!(res, file, root)
        if file_extension(file) in SFC_EXTENSIONS
            web_root = joinpath(pop!(splitpath(root)))
            comp_name = String(file[1:(last(findlast(".", file))-1)])
            push!(res, VueSFC(comp_name, web_root))        
        end        
    end

    res = VueSFC[]
    for path in paths
        if isfile(path)
            root = joinpath(splitpath(path)[1:end-1])
            add_sfc!(res, last(splitpath(path)), root)
        elseif isdir(path)
            for (root, dirs, files) in walkdir(path)
                for file in files
                    add_sfc!(res, file, root)
                end
            end
        end
    end
    
    return res
end

"""
Helper for obtaing a SFC page response

Usage examples:
    HTTP.register!(routes, "GET", "/",      (req)->sfc_response("Home"))
    HTTP.register!(routes, "GET", "/Page",  (req)->sfc_response("Page", "web"))
    HTTP.register!(routes, "GET", "/About", (req)->sfc_response("About", title="About"))

"""
sfc_response(placeholder::String; kwargs...) = response(sfc_page(placeholder; kwargs...))
sfc_response(placeholder::String, paths::Union{String, Vector{String}}; kwargs...) =  response(sfc_page(placeholder, paths; kwargs...)) 