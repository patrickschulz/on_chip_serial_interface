/*
              |-----------------------------------------------------------------------|
              |                                                                       |
              |--MUX    pre[0:N]                      |-------XNOR                    |
                 MUX -----------------DFFN  out[0:N]  |       XNOR------------DFFP    |
    1'b1 --------MUX                  DFFN------------(---*-- XNOR            DFFP----| out_pre[0:N]
                  |          clk o--->DFFN            |   |          clk o--->DFFP
                  |                                   |   |-----OR
      reset o-----|                                   |         OR--- carry[0:N]
                          vss,carry[0:N-1] -----------*---------OR
*/

module down_counter(clk, reset, out);
    parameter N = 16;
    input clk;
    input reset;
    output wire [N - 1:0] out;
    wire [N - 1:0] out_pre;
    wire [N - 1:0] pre;
    wire [N - 1:0] carry;
    wire [N - 1:0] net0;
    dffnq dffnq[N - 1:0] (.CLK(clk), .D(pre), .Q(out));
    xnor_gate xnor_gate[N - 1:0] (.A({carry[N-2:0], 1'b0}), .B(out), .O(net0));
    or_gate or_gate[N - 1:0] (.A({carry[N-2:0], 1'b0}), .B(out), .O(carry));
    mux mux[N - 1:0] (.A(out_pre), .B(1'b1), .SEL(reset), .O(pre));
    dffpq dffpq[N - 1:0] (.CLK(clk), .D(net0), .Q(out_pre));
endmodule
