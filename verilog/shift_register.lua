local util = require "util"

return function(settings, flat)
    local lines = util.make_lines_insert()
    local prefix = flat and "_shift_register_" or ""
    if not flat then -- module header
        lines:add("module shift_register")
        lines:add("(")
        lines:add("    input wire clk,")
        lines:add("    input wire data_in,")
        lines:add("    input wire update_shift_register,")
        lines:add("    input wire reset_shift_register,")
        lines:add("    input wire enable_shift_register,")
        lines:add("    input wire write_shift_register,")
        lines:add("    output wire data_out,")
        lines:add("    output reg [31:0] bit_out")
        lines:add(");")
    else
        lines:add("    // shift register")
    end
    lines:add("    reg [%d:0] %sff_in;", settings.data_length - 1, prefix)
    lines:add("    reg [%d:0] %scells_out;", settings.data_length - 1, prefix)
    lines:add("    reg [%d:0] %sstore;", settings.data_length - 1, prefix)
    lines:add("    assign data_out = %scells_out[0];", prefix)
    -- flip-flop chain-in
    lines:add("    always @(posedge clk) begin")
    lines:add("        if (enable_shift_register) begin")
    lines:add("            if (write_shift_register) begin")
    lines:add("                %sff_in[%d:0] <= { data_in, %scells_out[%d:1] };", prefix, settings.data_length - 1, prefix, settings.data_length - 1)
    lines:add("            end")
    lines:add("            else begin")
    lines:add("                %sff_in[%d:0] <= { %scells_out[0], %scells_out[%d:1] };", prefix, settings.data_length - 1, prefix, prefix, settings.data_length - 1)
    lines:add("            end")
    lines:add("        end")
    lines:add("        else begin")
    lines:add("            %sff_in[%d:0] <= %scells_out[%d:0];", prefix, settings.data_length - 1, prefix, settings.data_length - 1)
    lines:add("        end")
    lines:add("    end")

    -- flip-flop chain-out
    lines:add("    always @(negedge clk) begin")
    lines:add("        %scells_out[%d:0] <= %sff_in[%d:0];", prefix, settings.data_length - 1, prefix, settings.data_length - 1)
    lines:add("    end")
    -- flip-flop bit datum
    local resetpattern_formatted = {}
    for i = settings.data_length - 1, 0, -1 do
        table.insert(resetpattern_formatted, settings.resetpattern[settings.data_length - i] == 1 and "1" or "0")
    end
    lines:add("    always @(posedge clk) begin")
    lines:add("        if (!reset_shift_register) begin")
    lines:add("            bit_out[%d:0] <= %d'b%s;", settings.data_length - 1, settings.data_length, table.concat(resetpattern_formatted))
    lines:add("        end")
    lines:add("        else begin")
    lines:add("            if(update_shift_register) begin")
    lines:add("                bit_out[%d:0] <= %scells_out[%d:0];", settings.data_length - 1, prefix, settings.data_length - 1)
    lines:add("            end")
    lines:add("            else begin")
    lines:add("                bit_out[%d:0] <= %sstore[%d:0];", settings.data_length - 1, prefix, settings.data_length - 1)
    lines:add("            end")
    lines:add("        end")
    lines:add("    end")
    -- flip-flop bit store
    lines:add("    always @(negedge clk) begin")
    lines:add("        %sstore[%d:0] <= bit_out[%d:0];", prefix, settings.data_length - 1, settings.data_length - 1)
    lines:add("    end")

    if not flat then
        lines:add("endmodule")
    end
    return lines
end

--[[ old content:

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
--]]
