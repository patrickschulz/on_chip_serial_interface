//`define DEBUG_LEVEL
`define LOWER_LIMIT 0
`define UPPER_LIMIT 2 ** `DATA_LEN - 1

`define IDLE_CYCLES 0
`define CYCLE_BREAK 0

module testbench;
    // general settings
    //timeunit 1ns/1ps;
    initial begin
        // shall print %t with scaled in ns (-9), with 2 precision digits, and would print the " ns" string
        $timeformat(-9, 2, " ns", 20);
    end

    reg clk = 0;
    always #5 clk = ~clk;

    wire data_inout;
    wire [0 : `DATA_LEN - 1] bit_out;
    reg write_not_read;
    reg data_in;
    reg [0:`DATA_LEN - 1] test_data;
    reg [0:`DATA_LEN - 1] test_data_out;

    assign (supply0, supply1) data_inout = (write_not_read == 1'b1) ? data_in : 1'bZ;
    pulldown(data_inout);

    // place serial interface DUT
    serial_interface serial_interface(
      .clk(clk),
      .data_inout(data_inout),
      .bit_out(bit_out)
    );

    // task definitions 
    task wait_n_clk_cycles(int n_cycles);
        for (int i = 0; i < n_cycles; i++) begin
            @(negedge clk);
        end
        `ifdef DEBUG_LEVEL
            $display("time is %0t after waiting", $time);
        `endif
    endtask

    task send_stop_bit;
        @(negedge clk);
        data_in <= 1'b0;
    endtask

    task send_command(reg [`CMD_LEN - 1:0] cmd);
        // send start bits
        @(negedge clk);
        data_in <= 1'b1;
        @(negedge clk);
        data_in <= 1'b0;
        @(negedge clk);
        data_in <= 1'b1;

        // send command
        for(int i = `CMD_LEN - 1; i >= 0; i--) begin
            @(negedge clk);
            data_in <= cmd[i];
            `ifdef DEBUG_LEVEL
                $display("wrote command bit %b at %0t", cmd[i], $time);
            `endif 
        end

        `ifdef DEBUG_LEVEL
            $display("time is %0t after command", $time);
        `endif 
    endtask

    task send_data(reg [`DATA_LEN - 1 : 0] data);
        for(int i = 0; i < `DATA_LEN; i++) begin
            @(negedge clk);
            data_in <= data[i];

            `ifdef DEBUG_LEVEL
                assert (serial_interface.curr_state == RCV_DATA_ST) else $error("fehler rcv state at %0t", $time);
                $display("wrote data bit %b at %0t", data[i], $time);
            `endif
        end
        `ifdef DEBUG_LEVEL
            $display("time is %0t after data", $time);
        `endif
    endtask

    // test procedure
    initial begin
        data_in <= 1'b0;
        write_not_read = 1'b1;    

        `ifdef DEBUG_LEVEL
            $monitor("data_in = %b", data_in);
            $monitor("ser_ctrl_cmd_reg = %b", serial_interface.cmd_reg);
        `endif

        `ifdef DEBUG_LEVEL
            assert (serial_interface.curr_state == RESET_ST) else $error("fehler reset at %0t", $time);
        `endif

        // force reset of internal circuitry (NOT reset command, which resets the data registers)
        write_not_read = 1'b1; 
        data_in <= 1'b0;
        wait_n_clk_cycles(4);
        data_in <= 1'b1;
        wait_n_clk_cycles(4 * `DATA_LEN);
        data_in <= 1'b0;

        // wait for reset
        wait_n_clk_cycles(2);

        // loop to try all possible values that can be stored in the daisychain
        for (int j = `LOWER_LIMIT; j <= `UPPER_LIMIT; j++) begin
            test_data = j;

            send_command(`START_RECEIVE_CMD);
            send_data(test_data);
            send_stop_bit();
            wait_n_clk_cycles(`IDLE_CYCLES);

            send_command(`UPDATE_CMD);
            send_stop_bit();
            wait_n_clk_cycles(`IDLE_CYCLES);

            //`ifdef DEBUG_LEVEL
            //    assert (serial_interface.curr_state == UPDATE_ST) else $error("fehler update at %0t", $time);
            //`endif

            wait_n_clk_cycles(2); // wait until data is ready (takes two cycles after command)
            assert (bit_out == test_data) else $error("bit out %b bei %b", bit_out, test_data);

            send_command(`START_SEND_CMD);
            @(negedge clk);
            write_not_read = 1'b0; 
            // receive data
            @(posedge clk); // skip acknowledge phase
            for(int i = `DATA_LEN - 1; i >= 0; i--) begin
                @(posedge clk);
                test_data_out[i] = data_inout; 
            end
            @(negedge clk);
            @(negedge clk); // FIXME: why twice?
            write_not_read = 1'b1;    
            wait_n_clk_cycles(`IDLE_CYCLES);

            assert (test_data == test_data_out) $display("OK %b", test_data);
                  else $error("datenlesefehler! erwartet: %b bekommen: %b", test_data, test_data_out);

            wait_n_clk_cycles(`CYCLE_BREAK);
        end

        wait_n_clk_cycles(10);

        //// test reset
        //send_command(`RESET_CMD);
        //wait_n_clk_cycles(2); // wait for reset
        //wait_n_clk_cycles(`IDLE_CYCLES);

        $finish;
    end
    initial begin
        $dumpfile("signals.vcd");
        $dumpvars(0, testbench);
    end
endmodule
