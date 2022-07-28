module serial_ctrl
(
    /* external ports */
    inout data_inout,
    input clk,
    /* module ports */
    input count_reached_in,
    input data_out_shift_reg_in,
    output reset_count_out,
    output update_shift_reg_out,
    output reset_shift_reg_out,
    output enable_shift_register,
    output write_shift_register
);
    wire enable_write;
    assign enable_write = (curr_state == SEND_DATA_ST);
    tbuf bidir_data_buffer(
        .I(data_out_shift_reg_in),
        .O(data_inout),
        .EN(enable_write)
    );

    // the maximum number of allowed consecutive 1s is DATA_LEN, since the
    // data are surrounded by 0s (every command ends with 0 and there is a 0 stop bit after commands/data)
    // This means that if the controller sends out more than DATA_LEN 1s, this means that the circuit should be reset
    // HOWEVER: in extreme cases of a very low value of DATA_LEN,
    // the start pattern together with the command can produce more (legal) 1s: 101 + 110 -> 3 consecutive 1s
    // with the current settings for START_BIT_PATTERN and the command coding,
    // this only happens for DATA_LEN < 3
    // easiest fix is to spend one bit more than needed
    // FIXME: figure out the actual required bits
    reg [`BIT_COUNT_LEN:0] rst_reg, rst_reg_pre;
    always @(negedge clk) begin
        rst_reg <= rst_reg_pre;
    end
    always @(posedge clk) begin
        if(~data_inout) begin
            rst_reg_pre <= 2**(`BIT_COUNT_LEN + 1) - 1;
        end
        else begin
            rst_reg_pre <= rst_reg - 1;
        end
    end

    reg reset_shift_reg_out;
    wire enable_shift_register;
    assign enable_shift_register = (curr_state == RECEIVE_DATA_ST) | (curr_state == SEND_DATA_ST);

    wire write_shift_register;
    assign write_shift_register = (curr_state == RECEIVE_DATA_ST);

    // control part state machine
    localparam 
        RESET_ST             = 4'b0000,  // reset control circuit
        SKIP_STOP_ST         = 4'b0001,  // skip stop bit
        WAIT_FOR_COMMAND_ST  = 4'b0010,  // wait for command
        UPDATE_ST            = 4'b0011,  // update shift register
        RESET_REGISTER_ST    = 4'b0100,  // reset shift register
        RECEIVE_DATA_ST      = 4'b0101,  // receiving data
        SEND_DATA_SETUP_ST   = 4'b0110,  // sending data, setup tristate buffer
        SEND_DATA_RECOVER_ST = 4'b0111,  // recover from write/read shift to prevent glitches
        SEND_DATA_ST         = 4'b1000;  // sending data

    // command types to be received from the external controller
    // all commands end with a zero bit
    // this ensures that the line is pulled down after a command
    localparam
        RESET_CMD         = 3'b000, // reset internal state
        START_SEND_CMD    = 3'b010, // start transmission of saved data
        START_RECEIVE_CMD = 3'b100, // start receiving of data
        UPDATE_CMD        = 3'b110; // update the shift registers output cells

    reg [3:0] curr_state_pre;  // changes with posedge
    reg [3:0] curr_state;      // changes with negedge
    reg [3:0] curr_state_post; // changes with posedge

    wire statetransition;
    assign statetransition = curr_state_pre != curr_state_post;

    // reset shift register (synchronous reset, triggered by the update signal)
    assign reset_shift_reg_out = !(curr_state == RESET_REGISTER_ST);

    // update shift register
    // uses the clock input of the corresponding DFF
    // therefore, this can't be a simply assign as glitches must be avoided
    // FIXME: code states so that this can be a simple assign
    reg update_shift_reg_out;
    //assign update_shift_reg_out = ((curr_state_post == UPDATE_ST) || (curr_state_post == RESET_REGISTER_ST));
    always @(posedge clk) begin
        if((curr_state == UPDATE_ST) || (curr_state == RESET_REGISTER_ST)) begin
            update_shift_reg_out <= 1'b1;
        end
        else begin
            update_shift_reg_out <= 1'b0;
        end
    end

    // reset counter
    assign reset_count_out = !(statetransition && ((curr_state_pre == RECEIVE_DATA_ST) | (curr_state_pre == SEND_DATA_ST)));

    // register for saving incoming command
    reg [`CMD_LEN - 1 + `START_LEN - 1:0] cmd_reg; // extra -1: last bit is not stored
    reg [`CMD_LEN - 1 + `START_LEN - 1:0] cmd_reg_pre;
    always @ (negedge clk) begin
        cmd_reg <= cmd_reg_pre;
    end
    always @(posedge clk) begin
        if(curr_state == SKIP_STOP_ST) begin
            cmd_reg_pre <= 0;
        end
        else begin
            cmd_reg_pre <= (cmd_reg << 1) | data_inout;
        end
    end

    always @(posedge clk) begin
        if(rst_reg == 0) begin
            curr_state_pre <= RESET_ST;
        end
        else begin
            case (curr_state)
                RESET_ST : begin
                     curr_state_pre <= RESET_REGISTER_ST;
                end
                SKIP_STOP_ST: begin
                     curr_state_pre <= WAIT_FOR_COMMAND_ST;
                 end
                WAIT_FOR_COMMAND_ST : begin
                    if(cmd_reg[`CMD_LEN - 1 + `START_LEN - 1:`CMD_LEN - 1] == `START_BIT_PATTERN) begin
                        case ((cmd_reg[`CMD_LEN - 2:0] << 1) | data_inout) // last bit of command is not stored, this saves one cycle
                            START_SEND_CMD: begin
                                curr_state_pre <= SEND_DATA_SETUP_ST;
                            end
                            START_RECEIVE_CMD: begin
                                curr_state_pre <= RECEIVE_DATA_ST;
                            end
                            RESET_CMD: begin
                                curr_state_pre <= RESET_REGISTER_ST;
                            end
                            UPDATE_CMD: begin
                                curr_state_pre <= UPDATE_ST;
                            end
                        endcase
                    end
                    else begin
                        curr_state_pre <= WAIT_FOR_COMMAND_ST;
                    end
                end
                UPDATE_ST: begin
                    curr_state_pre <= SKIP_STOP_ST;
                end
                RESET_REGISTER_ST: begin
                    curr_state_pre <= SKIP_STOP_ST;
                end
                SEND_DATA_SETUP_ST: begin
                    curr_state_pre <= SEND_DATA_ST;
                end
                SEND_DATA_ST: begin
                    if (count_reached_in) begin
                        curr_state_pre <= SEND_DATA_RECOVER_ST;
                    end
                    else begin
                        curr_state_pre <= SEND_DATA_ST;
                    end
                end
                SEND_DATA_RECOVER_ST : begin
                    curr_state_pre <= SKIP_STOP_ST;
                end
                RECEIVE_DATA_ST: begin
                    if (count_reached_in) begin
                        curr_state_pre <= SKIP_STOP_ST;
                    end
                    else begin
                        curr_state_pre <= RECEIVE_DATA_ST;
                    end
                end
            endcase
        end
    end
    always @(negedge clk) begin
        curr_state <= curr_state_pre;
    end
    always @(posedge clk) begin
        curr_state_post <= curr_state;
    end
endmodule
