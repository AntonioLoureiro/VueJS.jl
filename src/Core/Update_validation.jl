
UPDATE_VALIDATION["vue-editor"]=(
doc="",
library="vue2editor",
fn=(x)->begin
    x.cols==nothing ? x.cols=6 : nothing
end)

UPDATE_VALIDATION["hot-table"]=(
doc="",
library="handsontable",
value_attr="data",
fn=(x)->x)
