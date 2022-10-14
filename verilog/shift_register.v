/* shift register consisting of `DATA_LEN register_cells with data in and data out port */
module shift_register
(
    input clk,
    input data_in,
    input update,
    input reset,
    input enable,
    input write,
    output data_out,
    output [`DATA_LEN - 1:0] bit_out
);
    wire clk;
    wire data_in;
    wire update;
    wire reset;
    wire enable;
    wire write;
    wire [`DATA_LEN - 1:0] cells_out;
    wire data_out;
    assign data_out = cells_out[0];
    wire data_in_internal;

    // FIXME: this is done to retain the data in the shift register
    // however, the data_inout pin is driven with exactly the same data so
    // that can be read back directly (without the mux). Check this!
    mux data_in_mux (
        .A(data_in),
        .B(data_out),
        .SEL(write),
        .O(data_in_internal)
    );

    register_cell regcell[`DATA_LEN - 1:0](
        .chain_in({ data_in_internal, cells_out[`DATA_LEN - 1:1] }),
        .update(update),
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .chain_out(cells_out),
        .bit_out(bit_out)
    );
endmodule
