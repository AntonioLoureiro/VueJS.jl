# Example name => example file (relative to ./examples)
examples = [
    "Elements Basics"           =>"element_basics.jl",
    "Basic Grid"                =>"basic_grid.jl",
    "Basic Binding"             =>"basic_binding.jl",
    "Basic Events"              =>"basic_events.jl",
    "Elements Special args Tooltip and Menu" => "element_special_tooltip_menus.jl",
    "Vue Struct"                =>"vuestruct.jl",
    "Iterable Vue Struct"       =>"iterable_vuestruct.jl",
    "Basic Datatables"          =>"basic_datatables.jl",
    "Navigation and Bar"        =>"navigation_bars.jl",
    "Lists"                     =>"lists.jl",
    "Computed, Async and Mounted" => "lifecycle.jl",
    "ECharts"                   =>"echarts.jl"
]

# Example name => (notebook = "notebook file", html = "html file", icon = "mdi-icon") (files are relative to ./notebooks)
notebooks = [
    "Elements"      => (notebook = "DocsElements.ipynb",  html = "DocsElements.html", icon = "mdi-file-document-outline"),
    "Styling"       => (notebook = "DocsStyling.ipynb",   html = "DocsStyling.html",  icon = "mdi-palette-swatch-outline"),
    "Holders"       => (notebook = "DocsHolders.ipynb",   html = "DocsHolders.html",  icon = "mdi-account-group-outline"),
    "Structs"       => (notebook = "DocsStructs.ipynb",   html = "DocsStructs.html",  icon = "mdi-domain"),
    "Methods"       => (notebook = "DocsMethods.ipynb",   html = "DocsMethods.html",  icon = "mdi-laptop"),
    "Computed"      => (notebook = "DocsComputed.ipynb",  html = "DocsComputed.html", icon = "mdi-calculator"),
    "Hooks"         => (notebook = "DocsHooks.ipynb",     html = "DocsHooks.html",    icon = "mdi-hook")
]
