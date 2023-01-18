function parameters()
    pcell.add_parameters(
        {"resetpattern", { 0, 0, 0, 0, 0, 0, 0, 0 }}
    )
end

function layout(toplevel, _P)
    local bp = pcell.get_parameters("stdcells/base")

    local data_length = #_P.resetpattern
    local data_numbits = math.ceil(math.log(data_length, 2))

    local data_ready = 2 ^ data_numbits - data_length

    local cellnames = {}

    for i = 1, data_numbits do
        table.insert(cellnames,
        {
            { instance = string.format("ison_%i", i), reference = "isogate" },
            { instance = string.format("dffn_%i", i), reference = "dffnq" },
            { instance = string.format("or_%i", i), reference = "or_gate" },
            { instance = string.format("tielo_%i", i), reference = "tie_low" },
            { instance = string.format("ison_%i", i+1), reference = "isogate" },
            { instance = string.format("ison_%i", i+2), reference = "isogate" },
            { instance = string.format("ison_%i", i+3), reference = "isogate" },
            { instance = string.format("ison_%i", i+4), reference = "isogate" },
        })

        table.insert(cellnames, 
        {
            { instance = string.format("isop_%i", i), reference = "isogate" },
            { instance = string.format("dffp_%i", i), reference = "dffpq" },
            { instance = string.format("tie_%i", i), reference = "tie_high" },
            { instance = string.format("not_or_iso_%i", i), reference = (data_ready & (1 << i) and "not_gate" or "isogate") },
            { instance = string.format("and_%i", i), reference = "and_gate" },
            { instance = string.format("isop_%i", i+1), reference = "isogate" },
            { instance = string.format("isop_%i", i+2), reference = "isogate" },
        })

        table.insert(cellnames, 
        {
            { instance = string.format("isom_%i", i), reference = "isogate" },
            { instance = string.format("tiehi_%i", i), reference = "tie_high" },
            { instance = string.format("mux_%i", i), reference = "mux" },
            { instance = string.format("xnor_%i", i), reference = "xnor_gate" },
        })

        -- variable amount of and_gates depending on vector width, for
        -- data_ready signal insert all cells at end of third row
        if i ~= 1 then
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i), reference = "isogate" }
            )
            table.insert(cellnames[#cellnames],
                { instance = string.format("and_ready_%i", i), reference = "and_gate" }
            )
        else
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i), reference = "isogate" }
            )
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i+1), reference = "isogate" }
            )
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i+2), reference = "isogate" }
            )
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i+3), reference = "isogate" }
            )
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i+4), reference = "isogate" }
            )
            table.insert(cellnames[#cellnames],
                { instance = string.format("iso%i", i+5), reference = "isogate" }
            )

        end
    end
    
    local xpitch = bp.gspace + bp.glength
    local rows = placement.create_reference_rows(cellnames, xpitch)
    local cells = placement.rowwise(toplevel, rows)

    local routes = {}

    -- clk connections
    for i = 1, data_numbits - 1 do
        table.insert(routes, 
        { name = string.format("clk_%i", i),
            { type = "point", nodraw = false, where = cells[string.format("dffn_%i", i)]:get_anchor("CLK") },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("dffp_%i", i)]:get_anchor("CLK") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("dffn_%i", i+1)]:get_anchor("CLK") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("dffp_%i", i+1)]:get_anchor("CLK") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
        })
    end

    -- outp connections
    for i = 1, data_numbits do
        table.insert(routes, 
        { name = string.format("outp_%i", i),
            { type = "point", nodraw = true, where = cells[string.format("dffp_%i", i)]:get_anchor("Q") },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", x = -1 },
            { type = "rowshift", rows = -1},
            { type = "delta", y = ((i % 2 == 0) and -1 or 1)},
            { type = "point", nodraw = false, where = cells[string.format("dffn_%i", i)]:get_anchor("D") },
        })
    end

    -- outn connections
    for i = 1, data_numbits do
        table.insert(routes, 
        { name = string.format("outb_%i", i),
            { type = "point", nodraw = true, where = cells[string.format("dffn_%i", i)]:get_anchor("Q") },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", x = 2, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("or_%i", i)]:get_anchor("B") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "rowshift", rows = 2 },
            { type = "via", z = -1, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("xnor_%i", i)]:get_anchor("B") },
        })
    end

    -- net0 connections
    for i = 1, data_numbits do
        table.insert(routes, 
        { name = string.format("net0_%i", i),
            { type = "point", nodraw = true, where = cells[string.format("xnor_%i", i)]:get_anchor("O") },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", y = 2, nodraw = false },
            { type = "delta", x = -25, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("mux_%i", i)]:get_anchor("IP") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
        })
    end

    -- next connections
    for i = 1, data_numbits do
        table.insert(routes, 
        { name = string.format("next_%i", i),
            { type = "point", nodraw = true, where = cells[string.format("dffp_%i", i)]:get_anchor("D") },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", x = -1, nodraw = false },
            { type = "rowshift", rows = 1 },
            { type = "delta", y = ((i % 2 == 0) and 2 or 4) },
            { type = "delta", x = 16, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("mux_%i", i)]:get_anchor("O") },
            { type = "via", z = -1, nodraw = false },
        })
    end

    -- carry connections
    for i = 1, data_numbits - 1 do
        table.insert(routes, 
        { name = string.format("carry_%i", i + 1),
            { type = "point", nodraw = true, where = cells[string.format("or_%i", i)]:get_anchor("O") },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", x = 1, nodraw = false },
            { type = "rowshift", rows = 3 },
            { type = "delta", y = -2, nodraw = false },
            { type = "delta", x = -3, nodraw = false },
            { type = "delta", y = ((i % 2 == 0) and 1 or 3) },
            { type = "point", nodraw = false, where = cells[string.format("or_%i", i + 1)]:get_anchor("A") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", x = 4, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "rowshift", rows = 2 },
            { type = "via", z = -1, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("xnor_%i", i + 1)]:get_anchor("A") },
            { type = "via", z = -1, nodraw = false },
        })
    end

    -- first carry connection
    table.insert(routes, 
    { name = "carry_1",
        { type = "point", nodraw = true, where = cells["tielo_1"]:get_anchor("O") },
        { type = "via", z = 1, nodraw = false },
        { type = "delta", y = 1 },
        { type = "point", nodraw = false, where = cells["or_1"]:get_anchor("A") },
        { type = "via", z = -1, nodraw = false },
        { type = "via", z = 1, nodraw = false },
        { type = "rowshift", rows = 2 },
        { type = "point", nodraw = false, where = cells["xnor_1"]:get_anchor("A") },
        { type = "via", z = -1, nodraw = false },
    })

    -- mux in HI connections
    for i = 1, data_numbits do
        table.insert(routes, 
        { name = string.format("HI_%i", i),
            { type = "point", nodraw = true, where = cells[string.format("mux_%i", i)]:get_anchor("IN") },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", x = -6, nodraw = false },
            { type = "delta", y = ((i % 2 == 0) and -1 or 1) },
            { type = "delta", x = -2, nodraw = false },
            { type = "delta", y = ((i % 2 == 0) and -1 or 1) },
            { type = "point", nodraw = false, where = cells[string.format("tiehi_%i", i)]:get_anchor("O") },
            { type = "via", z = -1, nodraw = false },
        })
    end

    -- reset connections
    for i = 1, data_numbits - 1 do
        table.insert(routes, 
        { name = string.format("reset_%i", i),
            { type = "point", nodraw = true, where = cells[string.format("mux_%i", i)]:get_anchor("SEL") },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "via", z = 1, nodraw = false },
            { type = "point", nodraw = false, where = cells[string.format("mux_%i", i + 1)]:get_anchor("SEL") },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
            { type = "via", z = -1, nodraw = false },
        })
    end

    -- assign data_ready = 2 ^ data_numbits - data_length
    for i = 1, data_numbits do

        if (data_ready & (1 << i)) == 1 then
            --FIXME: todo proper connection for now its just all 0
            table.insert(routes, 
            { name = string.format("outnpre%i", i),
                { type = "point", nodraw = true, where = cells[string.format("dffn_%i", i)]:get_anchor("Q") },
                { type = "via", z = 1, nodraw = false },
                { type = "point", nodraw = false, where = cells[string.format("and_%i", i)]:get_anchor("A") },
                { type = "via", z = -1, nodraw = false },
            })
        else

            -- connection of outn to not_gate, just go one gate to the left and place a via
            table.insert(routes, 
            { name = string.format("outnpre%i", i),
                { type = "point", nodraw = true, where = cells[string.format("not_or_iso_%i", i)]:get_anchor("I") },
                { type = "via", z = 1, nodraw = false },
                { type = "delta", x = -1, nodraw = false },
                { type = "via", z = 1, nodraw = false },
                { type = "point", nodraw = true, where = cells[string.format("dffn_%i", i)]:get_anchor("Q") },
            })

            -- connection of not_gate to and_gate
            table.insert(routes, 
            { name = string.format("net1%i", i),
                { type = "point", nodraw = true, where = cells[string.format("not_or_iso_%i", i)]:get_anchor("O") },
                { type = "via", z = 1, nodraw = false },
                { type = "delta", x = 1, nodraw = false },
                { type = "delta", y = 1, nodraw = false },
                { type = "point", nodraw = false, where = cells[string.format("and_%i", i)]:get_anchor("A") },
                { type = "via", z = -1, nodraw = false },
            })
        end

        table.insert(routes, 
        { name = string.format("high%i", i),
            { type = "point", nodraw = true, where = cells[string.format("tie_%i", i)]:get_anchor("O") },
            { type = "via", z = 1, nodraw = false },
            { type = "delta", y = ((i % 2 == 0) and -1 or 1) },
            { type = "point", nodraw = false, where = cells[string.format("and_%i", i)]:get_anchor("B") },
            { type = "via", z = -1, nodraw = false },
        })
    end

    -- final cascaded and_gates for data_ready signal
    table.insert(routes, 
    { name = "data_ready_pre_b1",
        { type = "point", nodraw = true, where = cells["and_1"]:get_anchor("O") },
        { type = "via", z = 1, nodraw = false },
        { type = "delta", x = -2 },
        { type = "rowshift", rows = 3 },
        { type = "delta", y = 1 },
        { type = "point", nodraw = false, where = cells["and_ready_2"]:get_anchor("B") },
        { type = "via", z = -1, nodraw = false },
    })

    for i = 2, data_numbits - 1 do
        table.insert(routes, 
        { name = string.format("data_ready_pre_b%i", i),
            { type = "point", nodraw = true, where = cells[string.format("and_ready_%i", i)]:get_anchor("O") },
            { type = "via", z = 1, nodraw = false },
            { type = "rowshift", rows = 3 },
            { type = "delta", y = 1 },
            { type = "point", nodraw = false, where = cells[string.format("and_ready_%i", i + 1)]:get_anchor("B") },
            { type = "via", z = -1, nodraw = false },
        })
    end

    for i = 2, data_numbits do
        table.insert(routes, 
        { name = string.format("data_ready_pre_a%i", i),
            { type = "point", nodraw = true, where = cells[string.format("and_%i", i)]:get_anchor("O") },
            { type = "via", z = 1, nodraw = false },
            { type = "rowshift", rows = 1 },
            { type = "delta", y = ((i % 2 == 0) and 1 or -1) },
            { type = "point", nodraw = false, where = cells[string.format("and_ready_%i", i)]:get_anchor("A") },
            { type = "via", z = -1, nodraw = false },
        })
    end

    local width = bp.routingwidth
    local xgrid = bp.gspace + bp.glength
    local ygrid = bp.routingwidth + bp.routingspace
    local pnumtracks = bp.pnumtracks
    local nnumtracks = bp.nnumtracks
    local numinnerroutes = bp.numinnerroutes
    routing.route(toplevel, routes, width, numinnerroutes, pnumtracks, nnumtracks, xgrid, ygrid)
end
