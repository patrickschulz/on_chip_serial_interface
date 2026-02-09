local util = require "util"

return function(settings, flat)
    local lines = util.make_lines_insert()
    local prefix = flat and "_reset_counter_" or ""
    if not flat then -- module header
        lines:add("module reset_counter")
        lines:add("(")
        lines:add("    input wire clk,")
        lines:add("    input wire data_in,")
        lines:add("    output wire reset_internal")
        lines:add(");")
    else
        lines:add("    // reset counter")
    end
    lines:add("    reg [%d:0] %soutp;", settings.reset_length - 1, prefix)
    lines:add("    reg [%d:0] %soutn;", settings.reset_length - 1, prefix)
    lines:add("    assign reset_internal = !%soutn[%d];", prefix, settings.reset_length - 1)
    lines:add("    always @(posedge clk) begin")
    lines:add("        if(data_in) begin")
    lines:add("            %soutp <= %soutn - 1;", prefix, prefix)
    lines:add("        end")
    lines:add("        else begin")
    lines:add("            %soutp <= %s;", prefix, util.format_binary(util.fill_length_with(settings.reset_length, 1)))
    lines:add("        end")
    lines:add("    end")
    lines:add("    always @(negedge clk) begin")
    lines:add("        %soutn <= %soutp;", prefix, prefix)
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
table.insert(lines, string.format("    wire [%d:0] outp;", settings.reset_length - 1))
table.insert(lines, string.format("    wire [%d:0] outn;", settings.reset_length - 1))
table.insert(lines, string.format("    wire [%d:0] next;", settings.reset_length - 1))
table.insert(lines, string.format("    wire [%d:0] carry;", settings.reset_length - 1))
table.insert(lines, string.format("    wire [%d:0] net0;", settings.reset_length - 1))
table.insert(lines, string.format("    dffpq dffpq[%d:0] (.CLK(clk), .D(next), .Q(outp));", settings.reset_length - 1))
table.insert(lines, string.format("    dffnq dffnq[%d:0] (.CLK(clk), .D(outp), .Q(outn));", settings.reset_length - 1))
table.insert(lines, string.format("    xnor_gate xnor_gate[%d:0] (.A({carry[%d:0], 1'b0}), .B(outn), .O(net0));", settings.reset_length - 1, settings.reset_length - 2))
table.insert(lines, string.format("    or_gate or_gate[%d:0] (.A({carry[%d:0], 1'b0}), .B(outn), .O(carry));", settings.reset_length - 1, settings.reset_length - 2))
table.insert(lines, string.format("    mux mux[%d:0] (.IP(net0), .IN(1'b1), .SEL(data), .O(next));", settings.reset_length - 1))
table.insert(lines, string.format("    assign reset = !outn[%d];", settings.reset_length - 1))
table.insert(lines, "endmodule")
--]]
