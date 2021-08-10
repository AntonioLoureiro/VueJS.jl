@el(r1, "v-text-field", value="R1 Value", label="R1", disabled=true)
@el(r2, "v-text-field", value="R2 Value", label="R2", disabled=false)
@el(r3, "v-text-field", value="R3 Value", label="R3", disabled=false)
@el(r4, "v-text-field", value="R4 Value", label="R4", disabled=false)
#=
    v-select options are passed under the `items` keyword
=#
@el(r5, "v-select", items=["A","B"], label="R5")
@el(r6, "v-select", items=["A","B"], label="R6")
@el(r7, "v-slider", value=20,        label="Slider 7")

page([r1, r2,
     #inner arrays will alter the grid orientation
     [r3,r4,r5], 
     r6,r7])