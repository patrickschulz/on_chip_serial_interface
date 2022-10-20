local settings = require "settings"

local lines = {}

table.insert(lines, "module command_register(clk, data, receive, ready, command);")
table.insert(lines, "    input clk;")
table.insert(lines, "    input data;")
table.insert(lines, "    input receive;")
table.insert(lines, "    output ready;")
table.insert(lines, "    output [`CMD_LEN - 1:0] command;")
table.insert(lines, "    assign ready =")
for i = 1, settings.start_pattern_length do
    local line = {}
    table.insert(line, string.format("        cmd_reg[`CMD_LEN + %d - %d] == 1'b%d", settings.start_pattern_length, i, settings.start_pattern[i]))
    if i ~= settings.start_pattern_length then
        table.insert(line, " &&")
    else
        table.insert(line, ";")
    end
    table.insert(lines, table.concat(line))
end
table.insert(lines, "    assign command = cmd_reg[`CMD_LEN - 1:0];")
table.insert(lines, string.format("    reg [`CMD_LEN + %d - 1:0] cmd_reg;", settings.start_pattern_length))
table.insert(lines, string.format("    reg [`CMD_LEN + %d - 1:0] cmd_reg_pre;", settings.start_pattern_length))
table.insert(lines, "    always @ (negedge clk) begin")
table.insert(lines, "        cmd_reg <= cmd_reg_pre;")
table.insert(lines, "    end")
table.insert(lines, "    always @(posedge clk) begin")
table.insert(lines, "        if(receive) begin")
table.insert(lines, "            cmd_reg_pre <= (cmd_reg << 1) | data;")
table.insert(lines, "        end")
table.insert(lines, "        else begin")
table.insert(lines, "            cmd_reg_pre <= (cmd_reg << 1);")
table.insert(lines, "        end")
table.insert(lines, "    end")
table.insert(lines, "endmodule")

local file = io.open("command_register.v", "w")
file:write(table.concat(lines, "\n"))
file:close()
