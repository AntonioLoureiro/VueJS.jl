## VueJS uses Namtso Echarts Library. A Namtso Echart object should be created and then attributed to a Vue Element
points=1000
ec=EChart("scatter",rand(points),rand(points),title=Dict("text"=>"Double Scatter"),width=800,height=600) ## You can define the aspect ratio, it will be preserved
series!(ec,"scatter",rand(points),rand(points),name="Blue Series")

ec2=EChart("bar",["A","B","C","D","E"],[100,130,80,50,60],title=Dict("text"=>"Bar Chart"))
## Attribute Echart to Vue Element
@el(v_ec,ec,cols=6) ## Cols defines the cols absolute width, preserving the aspect ratio, default is 6
@el(v_ec2,ec2,cols=6)
page([[v_ec,v_ec2]])