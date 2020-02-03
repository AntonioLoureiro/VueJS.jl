function methods_script(c::VueStruct)
    out=[]
    for (f_name,script) in c.methods
        
        str="""$f_name :(function(event) {
        for (key of Object.keys(app_state)) {
        eval("var "+key+" = app_state."+key)
        };

        return  function(event) {
          $script
        };
        })()
        """
        push!(out,str)

    end
    return "methods:{$(join(out,","))}"
end
