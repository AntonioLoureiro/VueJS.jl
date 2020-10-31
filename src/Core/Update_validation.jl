
UPDATE_VALIDATION["vue-editor"]=(x)->begin

    x.cols==nothing ? x.cols=6 : nothing
end

UPDATE_VALIDATION["hot-table"]=(x)->begin
    
    x.value_attr="data"
end
