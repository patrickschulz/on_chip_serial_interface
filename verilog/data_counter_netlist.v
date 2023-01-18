module data_counter(clk, reset, data_ready);
    input clk;
    output [2:0] data_ready;
    wire [2:0] outp;
    wire [2:0] outn;
    wire [2:0] next;
    wire [2:0] carry;
    wire [2:0] net0;
    wire [2:0] low;
    wire [2:0] high;
    wire [2:0] highmux;
    wire [2:0] net1;

    tie_lo _01_ (.O(low[0]));
    tie_lo _02_ (.O(low[1]));
    tie_lo _03_ (.O(low[2]));
    tie_hi _04_ (.O(high[0]));
    tie_hi _05_ (.O(high[1]));
    tie_hi _06_ (.O(high[2]));
    tie_hi _07_ (.O(highmux[0]));
    tie_hi _08_ (.O(highmux[1]));
    tie_hi _09_ (.O(highmux[2]));
    dffpq _10_ (.CLK(clk), .D(next[0]), .Q(outp[0]));
    dffpq _11_ (.CLK(clk), .D(next[1]), .Q(outp[1]));
    dffpq _12_ (.CLK(clk), .D(next[2]), .Q(outp[2]));
    dffnq _13_ (.CLK(clk), .D(outp[0]), .Q(outn[0]));
    dffnq _14_ (.CLK(clk), .D(outp[1]), .Q(outn[1]));
    dffnq _15_ (.CLK(clk), .D(outp[2]), .Q(outn[2]));
    xnor_gate _16_ (.A(low[0]), .B(outn[0]), .O(net0[0]));
    xnor_gate _17_ (.A(carry[0]), .B(outn[1]), .O(net0[1]));
    xnor_gate _18_ (.A(carry[1]), .B(outn[2]), .O(net0[2]));
    or_gate _19_ (.A(low[0]), .B(outn[0]), .O(carry[0]));
    or_gate _20_ (.A(carry[0]), .B(outn[1]), .O(carry[1]));
    or_gate _21_ (.A(carry[1]), .B(outn[2]), .O(carry[2]));
    mux _22_ (.IP(net0[0]), .IN(highmux[0]), .SEL(reset), .O(next[0]));
    mux _23_ (.IP(net0[1]), .IN(highmux[1]), .SEL(reset), .O(next[1]));
    mux _24_ (.IP(net0[2]), .IN(highmux[2]), .SEL(reset), .O(next[2]));

    // assign data_ready = (outn == 2 ** 3 - 8);
    not_gate _25_ (.I(outn[0]), .O(net1[0]));
    not_gate _26_ (.I(outn[1]), .O(net1[1]));
    not_gate _27_ (.I(outn[2]), .O(net1[2]));
    and_gate _28_ (.A(net1[0]), .B(high[0]), .O(data_ready[0]));
    and_gate _29_ (.A(net1[1]), .B(high[1]), .O(data_ready[1]));
    and_gate _30_ (.A(net1[2]), .B(high[2]), .O(data_ready[2]));

endmodule
