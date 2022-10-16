module data_counter
(
    input clk,
    input reset,
    output data_ready
);

wire clk;
wire reset;
wire data_ready;
reg [`BIT_COUNT_LEN - 1:0] count;

down_counter #(.N(`BIT_COUNT_LEN)) down_counter(.clk(clk), .reset(reset), .outn(count));
assign data_ready = (count == 2**`BIT_COUNT_LEN - `DATA_LEN);

endmodule
