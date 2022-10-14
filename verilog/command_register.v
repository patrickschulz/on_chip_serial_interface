module command_register(clk, data, receive, ready, command);
    input clk;
    input data;
    input receive;
    output ready;
    output [`CMD_LEN - 1:0] command;
    assign ready = cmd_reg[`CMD_LEN + `START_LEN - 1:`CMD_LEN] == `START_BIT_PATTERN;
    assign command = cmd_reg[`CMD_LEN - 1:0];
    reg [`CMD_LEN + `START_LEN - 1:0] cmd_reg;
    reg [`CMD_LEN + `START_LEN - 1:0] cmd_reg_pre;
    always @ (negedge clk) begin
        cmd_reg <= cmd_reg_pre;
    end
    always @(posedge clk) begin
        if(receive) begin
            cmd_reg_pre <= (cmd_reg << 1) | data;
        end
        else begin
            cmd_reg_pre <= (cmd_reg << 1);
        end
    end
endmodule
