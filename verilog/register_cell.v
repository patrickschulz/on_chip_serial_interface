module register_cell(chain_in, update, clk, reset, enable, chain_out, bit_out);
  wire hold_write;
  wire in_or_reset;
  output bit_out;
  input chain_in;
  output chain_out;
  input clk;
  input enable;
  wire ff_in;
  input reset;
  input update;
  mux hold_write_mux (
    .B(chain_out),
    .A(chain_in),
    .SEL(enable),
    .O(hold_write)
  );
  and_gate and_gate (
    .A(ff_in),
    .B(reset),
    .O(in_or_reset)
  );
  dffpq dff_buf (
    .CLK(update),
    .D(in_or_reset),
    .Q(bit_out)
  );
  dffnq dff_out (
    .CLK(clk),
    .D(ff_in),
    .Q(chain_out)
  );
  dffpq dff_in (
    .CLK(clk),
    .D(hold_write),
    .Q(ff_in)
  );
endmodule
