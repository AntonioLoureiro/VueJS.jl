function test(req)

    @el(okay, "v-alert", content="OKay", type="success", value=true,
        timeout=100000,
        dismissible=true, delay=500, close-icon="mdi-close-box")
    @el(toggleokay, "v-btn", value="toggle okay", click="okay.value = !okay.value")
    @el(innertext, "v-text-field", label="Inner stuff",
        events=
            Dict(
            "mounted"=>["this.vv.innertext.value='Alterado por hook'"])
        )
    @el(name, "v-text-field", label="texto",
        slots=Dict("default"=>"{{changeName}}"))

    @el(field, "v-text-field", label="Computed teste", slots=Dict("append"=>"{{testtuple}}"))
    @el(fromcookie, "v-text-field", value="teste", label="Cookie", cookie="ras", cookie-read-only=false)
    @el(fromstorage, "v-text-field", value="storage", label="Storage", storage=true)
    @el(btn, "v-btn", value="click to open page", click="open(' teste')")

    vv = VueStruct("vv", [innertext, name, fromstorage, btn],
        watch=Dict("innertext.value"=>"function(val){console.log(this.innertext.value);}"))
    #datatable filter
    @el(rf,"v-slider",value=0,max=5000,label="Slider Filter", input="filter_dt(d1,'B',rf.value,'>')")
    @el(d1,"v-data-table", items=DataFrame(a=[1,2,3], b=[5,4,6]))
    #arr = [okay, vv, field, fromcookie, toggleokay, d1, rf]
    p = page([okay, vv, field, fromcookie, toggleokay, d1],
        methods=Dict(
        "hide"=>"function(el){el.value = !(el.value)}",
        "togoogle"=>("open('http://google.com')", ["file"])),
        computed=Dict("changeName"=>"""
                get : function() {return 'teste'},
                set : function(v) {this.vv.name.value = this.vv.innertext.value + ' ok'}
                """,
                "testtuple"=>("function(){ return this.vv.name.value }", Dict("cache"=>false))
                )
        )
    return response(p)
end

router = HTTP.Router()
@HTTP.register(router, "/", test)
try close(server) catch; end
server = Sockets.listen(ip"127.0.0.1", 8888)
@async HTTP.serve(router, server=server)
@info ("Ready")
