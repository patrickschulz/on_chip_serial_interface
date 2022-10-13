module data_counter
(
    input clk,
    input reset,
    output count_reached
);

wire clk;
wire reset;
wire count_reached;
reg [`BIT_COUNT_LEN - 1:0] count;

down_counter #(.N(`BIT_COUNT_LEN)) down_counter(.clk(clk), .reset(reset), .out(count));

/* flag when given limit has been reached */
assign count_reached = (count == 2**`BIT_COUNT_LEN - (`DATA_LEN + 1));

endmodule
