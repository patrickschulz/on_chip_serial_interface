module serial_interface
(
    /* off-chip ports */
    input clk,
    inout data_inout,
    /* on-chip ports */
    output [`DATA_LEN - 1:0] bit_out
);
wire enable_data_counter;
wire data_ready;
wire reset_internal;

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
    .data_ready(data_ready),
    .reset_internal(reset_internal),
    .enable_data_counter(enable_data_counter),
    .update(update),
    .reset_shift_reg_out(reset_shift_register),
    .enable_shift_register(enable_shift_register),
    .write_shift_register(write_shift_register)
);

reset_counter reset_counter (
    .clk(clk),
    .data(data_in),
    .reset(reset_internal)
);

data_counter data_counter (
    .clk(clk),
    .reset(enable_data_counter),
    .data_ready(data_ready)
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
