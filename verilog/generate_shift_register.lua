local settings = require "settings"

local lines = {}
table.insert(lines, "module shift_register")
table.insert(lines, "(")
table.insert(lines, "    input wire clk,")
table.insert(lines, "    input wire data_in,")
table.insert(lines, "    input wire update,")
table.insert(lines, "    input wire reset,")
table.insert(lines, "    input wire enable,")
table.insert(lines, "    input wire write,")
table.insert(lines, "    output wire data_out,")
table.insert(lines, string.format("    output wire [%d:0] bit_out", settings.data_length - 1))
table.insert(lines, ");")
table.insert(lines, string.format("    wire [%d:0] cells_out;", settings.data_length - 1))
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
for i = settings.data_length - 1, 0, -1 do
    if settings.resetpattern[settings.data_length - i] == 1 then
        table.insert(lines, string.format("    register_cell_1 regcell_%d(", i))
    else
        table.insert(lines, string.format("    register_cell_0 regcell_%d(", i))
    end
    if i == settings.data_length - 1 then
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
local file = io.open("shift_register.v", "w")
file:write(table.concat(lines, "\n"))
file:close()
