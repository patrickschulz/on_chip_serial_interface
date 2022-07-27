module serial_interface
(
    /* off-chip ports */
    input clk,
    inout data_inout,
    /* on-chip ports */
    output [`DATA_LEN - 1:0] bit_out
);
wire reset_count;
wire count_reached;

wire update_shift_reg;
wire reset_shift_reg;
wire enable_shift_register;
wire data_out_shift_reg;

serial_ctrl control (
    .clk(clk),
    .data_inout(data_inout),
    .count_reached_in(count_reached),
    .data_out_shift_reg_in(data_out_shift_reg),
    .reset_count_out(reset_count),
    .update_shift_reg_out(update_shift_reg),
    .reset_shift_reg_out(reset_shift_reg),
    .enable_shift_register(enable_shift_register),
    .write_shift_register(write_shift_register)
);

bit_counter counter (
    .clk(clk),
    .reset_in(reset_count),
    .count_reached_out(count_reached)
);

shift_register daisychain (
    .clk(clk),
    .data_in(data_inout),
    .update(update_shift_reg),
    .reset(reset_shift_reg),
    .enable(enable_shift_register),
    .write(write_shift_register),
    .data_out(data_out_shift_reg),
    .bit_out(bit_out)
);

endmodule
