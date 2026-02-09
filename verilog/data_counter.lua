local util = require "util"

return function(settings, flat)
    local lines = util.make_lines_insert()
    local prefix = flat and "_data_counter_" or ""
    if not flat then -- module header
        lines:add("module data_counter")
        lines:add("(")
        lines:add("    input wire clk,")
        lines:add("    input wire enable_data_counter,")
        lines:add("    output wire data_ready")
        lines:add(");")
    else
        lines:add("    // data counter")
    end
    lines:add("    reg [%d:0] _data_counter_outp;", settings.data_numbits - 1)
    lines:add("    reg [%d:0] _data_counter_outn;", settings.data_numbits - 1)
    lines:add("    assign data_ready = (_data_counter_outn == 2 ** %d - %d);", settings.data_numbits, settings.data_length)
    lines:add("    always @(posedge clk) begin")
    lines:add("        if(enable_data_counter) begin")
    lines:add("            _data_counter_outp <= _data_counter_outn - 1;")
    lines:add("        end")
    lines:add("        else begin")
    lines:add("            _data_counter_outp <= %s;", util.format_binary(util.fill_length_with(settings.data_numbits, 1)))
    lines:add("        end")
    lines:add("    end")
    lines:add("    always @(negedge clk) begin")
    lines:add("        _data_counter_outn <= _data_counter_outp;")
    lines:add("    end")
    lines:add("")
    if not flat then
        lines:add("endmodule")
    end
    return lines
end

--[[ old content:
local settings = require "settings"

local lines = {}
table.insert(lines, "module data_counter")
table.insert(lines, "(")
table.insert(lines, "    input clk,")
table.insert(lines, "    input reset,")
table.insert(lines, "    output data_ready")
table.insert(lines, ");")
table.insert(lines, string.format("    wire [%d:0] outp;", settings.data_numbits - 1))
table.insert(lines, string.format("    wire [%d:0] outn;", settings.data_numbits - 1))
table.insert(lines, string.format("    wire [%d:0] next;", settings.data_numbits - 1))
table.insert(lines, string.format("    wire [%d:0] carry;", settings.data_numbits - 1))
table.insert(lines, string.format("    wire [%d:0] net0;", settings.data_numbits - 1))
table.insert(lines, string.format("    dffpq dffpq[%d:0] (.CLK(clk), .D(next), .Q(outp));", settings.data_numbits - 1))
table.insert(lines, string.format("    dffnq dffnq[%d:0] (.CLK(clk), .D(outp), .Q(outn));", settings.data_numbits - 1))
table.insert(lines, string.format("    xnor_gate xnor_gate[%d:0] (.A({carry[%d:0], 1'b0}), .B(outn), .O(net0));", settings.data_numbits - 1, settings.data_numbits - 2))
table.insert(lines, string.format("    or_gate or_gate[%d:0] (.A({carry[%d:0], 1'b0}), .B(outn), .O(carry));", settings.data_numbits - 1, settings.data_numbits - 2))
table.insert(lines, string.format("    mux mux[%d:0] (.IP(net0), .IN(1'b1), .SEL(reset), .O(next));", settings.data_numbits - 1))
table.insert(lines, string.format("    assign data_ready = (outn == 2 ** %d - %d);", settings.data_numbits, settings.data_length))
table.insert(lines, "endmodule")

local file = io.open("data_counter.v", "w")
file:write(table.concat(lines, "\n"))
file:close()
--]]
