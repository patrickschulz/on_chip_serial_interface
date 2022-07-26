//`define DEBUG_LEVEL
`define LOWER_LIMIT 0
`define UPPER_LIMIT 2 ** `DATA_LEN - 1

`define IDLE_CYCLES 0
`define CYCLE_BREAK 8

module testbench;
    localparam
        RESET_CMD      = 2'b00, // reset internal state
        START_SND_CMD  = 2'b01, // start transmission of saved data
        START_RCV_CMD  = 2'b10, // start receiving of data
        UPDATE_CMD     = 2'b11; // update the shift registers output cells
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

    reg reset = 1;

    assign data_inout = (write_not_read == 1'b1) ? data_in : 1'bZ;

    // place serial interface DUT
    serial_interface serial_interface(
      .clk(clk),
      .data_inout(data_inout),
      .reset_in(reset),
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

    task send_command(reg [`CMD_LEN - 1:0] cmd);
        // send start bit
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
        @(negedge clk);
        data_in <= 1'b0;

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
        @(negedge clk);
        data_in <= 1'b0; 
        `ifdef DEBUG_LEVEL
            $display("time is %0t after data", $time);
        `endif
    endtask

    // test procedure
    initial begin
        data_in <= 1'b0;
        write_not_read = 1'b1;    

        // reset
        #5 reset = 0;
        #15 reset = 1;

        #75;

        `ifdef DEBUG_LEVEL
            $monitor("data_in = %b", data_in);
            $monitor("ser_ctrl_cmd_reg = %b", serial_interface.cmd_reg);
        `endif

        `ifdef DEBUG_LEVEL
            assert (serial_interface.curr_state == RESET_ST) else $error("fehler reset at %0t", $time);
        `endif

        // loop to try all possible values that can be stored in the daisychain
        for (int j = `LOWER_LIMIT; j <= `UPPER_LIMIT; j++) begin
            test_data = j;

            send_command(START_RCV_CMD);
            send_data(test_data);
            wait_n_clk_cycles(`IDLE_CYCLES);

            send_command(UPDATE_CMD);
            wait_n_clk_cycles(1); // wait for update
            wait_n_clk_cycles(`IDLE_CYCLES);

            `ifdef DEBUG_LEVEL
                assert (serial_interface.curr_state == UPDATE_ST) else $error("fehler update at %0t", $time);
            `endif

            wait_n_clk_cycles(1); // wait until data is ready
            assert (bit_out == test_data) else $error("bit out %b bei %b", bit_out, test_data);

            send_command(START_SND_CMD);
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

        // test reset
        send_command(RESET_CMD);
        wait_n_clk_cycles(2); // wait for reset
        wait_n_clk_cycles(`IDLE_CYCLES);

        $finish;
    end
    initial begin
        $dumpfile("signals.vcd");
        $dumpvars(0, testbench);
    end
endmodule
