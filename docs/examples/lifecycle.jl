@el(el1, "v-chip", text-color="white",
    binds=Dict("content"=>"comp2<1 ? 'A' : 'B'","color"=>"comp2<1 ? 'green' : 'blue'"), cols=2)
@el(el2, "v-text-field", label="Random Triggered", 
    binds=Dict("label"=>"comp1"), cols=2)
@el(el3, "v-text-field", label="Submited Element x 2",
    binds=Dict("value"=>"comp3"), cols=2)
mounted  = "app_state.globals.heart_beat=0;setInterval(function(){app.globals.heart_beat=Date.now()},1000)"
computed = Dict("comp1"=>"function(){this.globals.heart_beat; return Math.random()*1000}","comp2"=>"function(){return this.comp1 % 2}")
asynccomputed = Dict("comp3"=>"function(){return this.submit('https://httpbin.org/post',{a:this.comp1}).then(x=>JSON.parse(x.responseText).json.a*2)}")

page([el1,el2,el3,"{{globals.heart_beat}}","{{comp1}}"], mounted = mounted, computed = computed, asynccomputed = asynccomputed)