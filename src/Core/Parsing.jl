function parse(req::HTTP.Request)
    
     body=Dict()
    headers=Dict{String,String}(req.headers)
    content_type=get(headers,"Content-Type","")
    args=HTTP.URIs.queryparams(HTTP.URI(req.target))
    
    if startswith(content_type,"multipart")
        mp=HTTP.parse_multipart_form(req)
        files_arr=[]
        for (i,p) in enumerate(mp)
            if p.name=="json"
                body=JSON.parse(p.data, Dict)
            else
               push!(files_arr,Dict("name"=>p.name,"filename"=>p.filename,"contenttype"=>p.contenttype,"data"=>String(take!(p.data))))
            end
        end

        nl=nested_levels(body)
        for f in files_arr            
            name_arr=String.(split(f["name"],"."))
            ln=length(name_arr)
            st=ln-(nl+1)
            st<2 ? st=2 : nothing
            name_arr=name_arr[st:ln-2]
            obj=body
            for n in name_arr
                obj=obj[n]
            end 
            push!(obj,f)
        end
        
    else
       body=JSON.parse(String(req.body), dicttype = Dict)
    end
    
    return (body=body,headers=headers,args=args)
end

function nested_levels(body::Dict;n=1)
    for (k,v) in body
        if v isa Dict
            ret=nested_levels(v;n=n+1)
            ret>n ? n=ret : nothing
        end
    end
    return n
end
