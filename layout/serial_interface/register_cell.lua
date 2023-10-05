function parameters()

end

function layout(register)
    pcell.push_overwrites("basic/mosfet", {
        actext = 80
    })
    pcell.push_overwrites("stdcells/base", {
        pnumtracks = 5,
        nnumtracks = 5,
        numinnerroutes= 3,
        drawtopbotwelltaps = false,
        powerwidth = 200,
        routingwidth = 60,
        routingspace = 60,
        basepwidth = 500,
        basenwidth = 500,
    })
    local bp = pcell.get_parameters("stdcells/base")
    local cellnames = {
        {
            { reference = "mux",        instance = "hold_write_mux"  },
            { reference = "dffnq",      instance = "dff_in"  },
            { reference = "dffpq",      instance = "dff_out"  },
            { reference = "mux",        instance = "dff_buf_mux"  },
        },
        {
            { reference = "and_gate",   instance = "reset_and_gate"  },
            { reference = "dffpq",      instance = "dff_buf"  },
            { reference = "dffnq",      instance = "dff_store"  },
        },
    }
    local xpitch = bp.gspace + bp.glength
    local rows = placement.create_reference_rows(cellnames, xpitch)
    local cells = placement.rowwise(register, rows)
    -- all wires:
    --[[
    input wire clk;
    input wire reset;
    input wire enable;
    input wire update;
    input wire chain_in;
    output wire chain_out;
    output wire bit_out;
    wire ff_in;
    wire store;
    wire hold_write;
    wire in_or_reset;
    wire update_or_store;
    --]]
end

