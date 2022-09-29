module serial_interface
(
    /* off-chip ports */
    input clk,
    inout data_inout,
    /* on-chip ports */
    output [`DATA_LEN - 1:0] bit_out
);
wire reset_counter;
wire count_reached;

wire update;
wire reset_shift_register;
wire enable_shift_register;
wire data_out_shift_reg;
wire write;
wire write_shift_register;

wire data_in;
wire data_out;
assign data_in = data_inout;

tbuf bidir_data_buffer(
    .I(data_out),
    .O(data_inout),
    .EN(write)
);

serial_ctrl control (
    .clk(clk),
    .data_in(data_in),
    .write(write),
    .count_reached_in(count_reached),
    .reset_count_out(reset_counter),
    .update(update),
    .reset_shift_reg_out(reset_shift_register),
    .enable_shift_register(enable_shift_register),
    .write_shift_register(write_shift_register)
);

bit_counter counter (
    .clk(clk),
    .reset_in(reset_counter),
    .count_reached_out(count_reached)
);

shift_register daisychain (
    .clk(clk),
    .data_in(data_in),
    .update(update),
    .reset(reset_shift_register),
    .enable(enable_shift_register),
    .write(write_shift_register),
    .data_out(data_out),
    .bit_out(bit_out)
);

endmodule
