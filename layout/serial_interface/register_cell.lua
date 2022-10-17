function parameters()

end

function layout(register)
    local invref = pcell.create_layout("stdcells/not_gate")
    local invname = pcell.add_cell_reference(invref, "not_gate")
    local nandref = pcell.create_layout("stdcells/nand_gate")
    local nandname = pcell.add_cell_reference(nandref, "nand_gate")
    local dffpref = pcell.create_layout("stdcells/dff")
    local dffpname = pcell.add_cell_reference(dffpref, "dffp")
    local dffnref = pcell.create_layout("stdcells/dff")
    local dffnname = pcell.add_cell_reference(dffnref, "dffn")
    local dffprref = pcell.create_layout("stdcells/dff")
    local dffprname = pcell.add_cell_reference(dffprref, "dffpr")
    local fillref = pcell.create_layout("stdcells/isogate")
    local fillname = pcell.add_cell_reference(fillref, "isogate")

    local rows = { 
        { 
            { reference = fillname, instance = "fill_1_1" }, 
            { reference = fillname, instance = "fill_1_2" }, 
            { reference = fillname, instance = "fill_1_3" }, 
            { reference = fillname, instance = "fill_1_4" }, 
            { reference = fillname, instance = "fill_1_5" }, 
            { reference = fillname, instance = "fill_1_6" }, 
            { reference = fillname, instance = "fill_1_7" }, 
            { reference = fillname, instance = "fill_1_8" }, 
            { reference = dffprname,  instance = "dffpr"  }, 
        },
        { 
            { reference = invname,    instance = "inv"    }, 
            { reference = nandname,   instance = "nand1"  }, 
            { reference = nandname,   instance = "nand2"  }, 
            { reference = dffnname,   instance = "dffn"   }, 
        },
        { 
            { reference = nandname,   instance = "nand3"  }, 
            { reference = fillname, instance = "fill_3_1" }, 
            { reference = fillname, instance = "fill_3_2" }, 
            { reference = fillname, instance = "fill_3_3" }, 
            { reference = fillname, instance = "fill_3_4" }, 
            { reference = fillname, instance = "fill_3_5" }, 
            { reference = dffpname,   instance = "dffp"   }, 
        },
    }
    local cells = placement.rowwise(register, rows)
end
