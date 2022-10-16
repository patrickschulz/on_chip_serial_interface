/*
              |---------------------------------------------------------------------------------------------|
              |                                                net0[N-1:0]                                  |
              |--MUX   next[0:N]                                                           |-------XNOR     |
                 MUX -----------------DFFP  out[N-1:0]                      outn[N-1:0]    |       XNOR-----|
    1'b1 --------MUX                  DFFP------------------------DFFN---------------------(---*-- XNOR
                  |          clk o--->DFFP                        DFFN                     |   |       
                  |                                      clk o--->DFFN                     |   |-----OR
      reset o-----|                                                                        |         OR--- carry[N-1:0]
                                                               carry[N-2:0], vss ----------*---------OR
*/

module down_counter(clk, reset, outp, outn);
    parameter N = 16;
    input clk;
    input reset;
    output wire [N - 1:0] outp;
    output wire [N - 1:0] outn;
    wire [N - 1:0] next;
    wire [N - 1:0] carry;
    wire [N - 1:0] net0;
    dffpq dffpq[N - 1:0] (.CLK(clk), .D(next), .Q(outp));
    dffnq dffnq[N - 1:0] (.CLK(clk), .D(outp), .Q(outn));
    xnor_gate xnor_gate[N - 1:0] (.A({carry[N-2:0], 1'b0}), .B(outn), .O(net0));
    or_gate or_gate[N - 1:0] (.A({carry[N-2:0], 1'b0}), .B(outn), .O(carry));
    mux mux[N - 1:0] (.A(net0), .B(1'b1), .SEL(reset), .O(next));
endmodule
