module register_cell(chain_in, update, clk, reset, enable, chain_out, bit_out);
  wire buf_in;
  wire ff_buf_reset;
  wire _02_;
  wire enableb;
  wire chain_in_enabled;
  output bit_out;
  input chain_in;
  output chain_out;
  input clk;
  input enable;
  wire ff_in;
  input reset;
  input update;
  not_gate enable_inv (
    .I(enable),
    .O(enableb)
  );
  nand_gate nand_chain_in (
    .A(chain_in),
    .B(enable),
    .O(chain_in_enabled)
  );
  nand_gate nand_enable_chain (
    .A(chain_out),
    .B(enableb),
    .O(_02_)
  );
  nand_gate nand_buf (
    .A(chain_in_enabled),
    .B(_02_),
    .O(buf_in)
  );
  /* reset 0
  // >>> for reset 0
  nand_gate ff_buf_nand_gate (
    .A(ff_in),
    .B(reset),
    .O(ff_buf_reset_not)
  );
  not_gate ff_buf_not_gate (
    .I(ff_buf_reset_not),
    .O(ff_buf_reset)
  );
  // <<<
  */
  // >>> for reset 1
  not_gate ff_buf_not_gate (
    .I(ff_in),
    .O(ff_in_not)
  );
  nand_gate ff_buf_and_gate (
    .A(ff_in_not),
    .B(reset),
    .O(ff_buf_reset)
  );
  // <<<

  dffpq dff_buf (
    .CLK(update),
    .D(ff_buf_reset),
    .Q(bit_out)
  );
  dffnq dff_out (
    .CLK(clk),
    .D(ff_in),
    .Q(chain_out)
  );
  dffpq dff_in (
    .CLK(clk),
    .D(buf_in),
    .Q(ff_in)
  );
endmodule

