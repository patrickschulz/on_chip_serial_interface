module testbench;
    reg clk = 0;
    always #5 clk = ~clk;

    wire data_inout;
    reg write_not_read = 1;
    reg data_in = 1;

    assign (supply0, supply1) data_inout = (write_not_read == 1'b1) ? data_in : 1'bZ;

    // place serial interface DUT
    serial_interface serial_interface(
      .clk(clk),
      .data_inout(data_inout)
    );
    initial begin
        $dumpfile("signals_reset.vcd");
        $dumpvars(0, testbench);
    end
    initial begin
        #300 $finish;
    end
endmodule
