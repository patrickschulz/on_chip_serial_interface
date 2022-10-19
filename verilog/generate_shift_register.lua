local resetpattern = { 0, 0, 0, 0, 0, 0, 0, 0 } -- must fit `DATA_LEN (FIXME: generate all relevant verilog source files)

local lines = {}
table.insert(lines, "/* shift register consisting of `DATA_LEN register_cells with data in and data out port */")
table.insert(lines, "module shift_register")
table.insert(lines, "(")
table.insert(lines, "    input clk,")
table.insert(lines, "    input data_in,")
table.insert(lines, "    input update,")
table.insert(lines, "    input reset,")
table.insert(lines, "    input enable,")
table.insert(lines, "    input write,")
table.insert(lines, "    output data_out,")
table.insert(lines, "    output [`DATA_LEN - 1:0] bit_out")
table.insert(lines, ");")
table.insert(lines, "    wire clk;")
table.insert(lines, "    wire data_in;")
table.insert(lines, "    wire update;")
table.insert(lines, "    wire reset;")
table.insert(lines, "    wire enable;")
table.insert(lines, "    wire write;")
table.insert(lines, "    wire [`DATA_LEN - 1:0] cells_out;")
table.insert(lines, "    wire data_out;")
table.insert(lines, "    assign data_out = cells_out[0];")
table.insert(lines, "    wire data_in_internal;")
table.insert(lines, "")
table.insert(lines, "    // FIXME: this is done to retain the data in the shift register")
table.insert(lines, "    // however, the data_inout pin is driven with exactly the same data so")
table.insert(lines, "    // that can be read back directly (without the mux). Check this!")
table.insert(lines, "    mux data_in_mux (")
table.insert(lines, "        .IP(data_in),")
table.insert(lines, "        .IN(data_out),")
table.insert(lines, "        .SEL(write),")
table.insert(lines, "        .O(data_in_internal)")
table.insert(lines, "    );")
table.insert(lines, "")
local datalen = #resetpattern
for i = datalen - 1, 0, -1 do
    if resetpattern[datalen - i] == 1 then
        table.insert(lines, string.format("    register_cell_1 regcell_%d(", i))
    else
        table.insert(lines, string.format("    register_cell_0 regcell_%d(", i))
    end
    if i == datalen - 1 then
        table.insert(lines, "        .chain_in(data_in_internal),")
    else
        table.insert(lines, string.format("        .chain_in(cells_out[%d]),", i + 1))
    end
    table.insert(lines, "        .update(update),")
    table.insert(lines, "        .clk(clk),")
    table.insert(lines, "        .reset(reset),")
    table.insert(lines, "        .enable(enable),")
    table.insert(lines, string.format("        .chain_out(cells_out[%d]),", i))
    table.insert(lines, string.format("        .bit_out(bit_out[%d])", i))
    table.insert(lines, "    );")
end
table.insert(lines, "endmodule")

print(table.concat(lines, "\n"))
