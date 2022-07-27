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
    assign data_in_internal = write ? data_in : cells_out[0];

    // FIXME: reading data does not have to destroy the data
    //        just feed it back in the first chain flip-flop
    register_cell regcell[`DATA_LEN - 1:0](
        .chain_in({ data_in, cells_out[`DATA_LEN - 1:1] }),
        .update(update),
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .chain_out(cells_out),
        .bit_out(bit_out)
    );
endmodule
