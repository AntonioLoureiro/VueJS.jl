
UPDATE_VALIDATION["vue-editor"]=(
doc="",
fn=(x)->begin
    x.cols==nothing ? x.cols=6 : nothing
end)

UPDATE_VALIDATION["hot-table"]=(
doc="",
value_attr="data",
fn=(x)->x)
