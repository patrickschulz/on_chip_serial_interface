module reset_counter
(
    input clk,
    input data,
    output reset
);
    // the maximum number of allowed consecutive 1s is DATA_LEN, since the
    // data are surrounded by 0s (every command ends with 0 and there is a 0 stop bit after commands/data)
    // This means that if the controller sends out more than DATA_LEN 1s, this means that the circuit should be reset
    // HOWEVER: in extreme cases of a very low value of DATA_LEN,
    // the start pattern together with the command can produce more (legal) 1s: 101 + 110 -> 3 consecutive 1s
    // with the current settings for START_BIT_PATTERN and the command coding,
    // this only happens for DATA_LEN < 3
    // easiest fix is to spend one bit more than needed
    // FIXME: figure out the actual required bits
    wire [`RESET_LEN - 1:0] count;
    down_counter #(.N(`RESET_LEN)) down_counter(.clk(clk), .reset(data), .out(count));
    assign reset = !count[`RESET_LEN - 1];
endmodule
