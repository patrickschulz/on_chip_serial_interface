local settings = require "settings"

local util = require "util"

local lines = util.make_lines_insert()

lines:add( "module command_register(clk, data, receive, empty, ready, command);")
lines:add( "    input wire clk;")
lines:add( "    input wire data;")
lines:add( "    input wire receive;")
lines:add( "    output wire empty;")
lines:add( "    output wire ready;")
lines:add( "    output wire [%d:0] command;", settings.commands_length - 1)
lines:add(string.format("    reg [%d:0] cmd_reg;", settings.commands_length + settings.start_pattern_length - 1))
lines:add(string.format("    reg [%d:0] cmd_reg_pre;", settings.commands_length + settings.start_pattern_length - 1))
lines:add( "    assign empty = cmd_reg == 0;")
lines:add( "    assign ready =")
for i = 1, settings.start_pattern_length do
    local line = {}
    table.insert(line, string.format("        cmd_reg[%d] == 1'b%d", settings.commands_length +  settings.start_pattern_length - i, settings.start_pattern[i]))
    if i ~= settings.start_pattern_length then
        table.insert(line, " &&")
    else
        table.insert(line, ";")
    end
    lines:add(table.concat(line))
end
lines:add("    assign command = cmd_reg[%d:0];", settings.commands_length - 1)
lines:add("    always @ (negedge clk) begin")
lines:add("        cmd_reg <= cmd_reg_pre;")
lines:add("    end")
lines:add("    always @(posedge clk) begin")
lines:add("        if(receive) begin")
lines:add("            cmd_reg_pre <= (cmd_reg << 1) | data;")
lines:add("        end")
lines:add("        else begin")
lines:add("            cmd_reg_pre <= (cmd_reg << 1);")
lines:add("        end")
lines:add("    end")
lines:add("endmodule")

util.write_lines("command_register.v", lines)
