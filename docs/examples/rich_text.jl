## Rich Text Editor using VueQuill ##
@el(q1,"quill-editor",value="<p>Lore Ipsilum</p><p><b>Lore Ipsilum</b></p>",toolbar="full",cols=6) ## Default contenType is HTML
@el(q2,"quill-editor",value="Lore Ipsilum",toolbar="minimal",cols=6) 

h1raw=[[html("h3","RAW HTML:",cols=6),html("div","{{q1.value}}",cols=6)]] ## Binding of content
h1html=[[html("h3","RENDERED HTML:",cols=6),html("div",nothing,Dict("v-html"=>"q1.value"),cols=6)]] ## Binding of content (rendered)
    
page([[q1,q2],h1raw,h1html])