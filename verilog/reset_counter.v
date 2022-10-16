module reset_counter
(
    input clk,
    input data,
    output reset
);
    wire [`RESET_LEN - 1:0] count;
    down_counter #(.N(`RESET_LEN)) down_counter(.clk(clk), .reset(data), .outn(count));
    assign reset = !count[`RESET_LEN - 1];
endmodule
