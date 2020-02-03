function methods_script(c::VueStruct)
    out=[]
<<<<<<< HEAD
    for (f_name,script) in c.methods 
=======
    for (f_name,script) in c.methods
>>>>>>> luis/master

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
