module bit_counter
(
    input clk,
    input reset_in,
    output count_reached_out
);

wire clk;
wire reset_in;
wire count_reached_out;
reg [`BIT_COUNT_LEN - 1:0] count;
reg [`BIT_COUNT_LEN - 1:0] count_pre;

/* flag when given limit has been reached */
assign count_reached_out = (count_pre == 2**`BIT_COUNT_LEN - `DATA_LEN);

always @(negedge clk) begin
    if (!reset_in) begin
        count_pre <= 2**`BIT_COUNT_LEN - 1;
    end
    else begin
        count_pre <= count - 1;
    end
end

always @(posedge clk) begin
    count <= count_pre;
end

endmodule
