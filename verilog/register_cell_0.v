module register_cell_0(clk, reset, update, enable, chain_in, chain_out, bit_out);
  input wire clk;
  input wire reset;
  input wire enable;
  input wire update;
  input wire chain_in;
  output wire chain_out;
  output wire bit_out;
  wire ff_in;
  wire store;
  wire hold_write;
  wire in_or_reset;
  wire update_or_store;
  /* shifting dffs */
  mux hold_write_mux (
    .IP(chain_in),
    .IN(chain_out),
    .SEL(enable),
    .O(hold_write)
  );
  dffpq dff_in (
    .CLK(clk),
    .D(hold_write),
    .Q(ff_in)
  );
  dffnq dff_out (
    .CLK(clk),
    .D(ff_in),
    .Q(chain_out)
  );
  /* bit-out dff */
  mux dff_buf_mux (
    .IP(chain_out),
    .IN(store),
    .SEL(update),
    .O(update_or_store)
  );
  and_gate reset_and_gate ( /* this gate has to be changed if reset-high registers are needed */
    .A(reset),
    .B(update_or_store),
    .O(in_or_reset)
  );
  dffpq dff_buf (
    .CLK(clk),
    .D(in_or_reset),
    .Q(bit_out)
  );
  dffnq dff_store (
    .CLK(clk),
    .D(bit_out),
    .Q(store)
  );
endmodule
