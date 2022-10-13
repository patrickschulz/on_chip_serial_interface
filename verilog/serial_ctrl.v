module serial_ctrl
(
    input clk,
    input data_in,
    output write,
    input count_reached_in,
    input data_out_shift_reg_in,
    input reset_internal,
    output reset_count_out,
    output update,
    output reset_shift_reg_out,
    output enable_shift_register,
    output write_shift_register
);
    wire write;
    assign write = (curr_state == SEND_DATA_ST);

    wire write_shift_register;
    assign write_shift_register = (curr_state == RECEIVE_DATA_ST);

    wire enable_shift_register;
    assign enable_shift_register = write || write_shift_register;

    // control part state machine
    // states are coded in order to minimize instance count
    localparam 
        RESET_ST             = 4'b1xxx,  // reset control circuit
        RECEIVE_DATA_ST      = 4'b0000,  // receiving data
        SEND_DATA_ST         = 4'b0001,  // sending data
        WAIT_FOR_COMMAND_ST  = 4'b0010,  // wait for command
        SEND_DATA_SETUP_ST   = 4'b0011,  // sending data, setup tristate buffer
        SKIP_STOP_ST         = 4'b0100,  // skip stop bit
        UPDATE_ST            = 4'b0101,  // update shift register
        RESET_REGISTER_ST    = 4'b0110,  // reset shift register
        SEND_DATA_RECOVER_ST = 4'b0111;  // recover from write/read shift to prevent glitches

    reg [3:0] curr_state_pre;  // changes with posedge
    reg [3:0] curr_state;      // changes with negedge

    // reset shift register (synchronous reset, triggered by the update signal)
    wire reset_shift_reg_out;
    assign reset_shift_reg_out = !(curr_state == RESET_REGISTER_ST);

    // update shift register
    // uses the clock input of the corresponding DFF
    // therefore, this can't be a simply assign as glitches must be avoided
    // FIXME: code states so that this can be a simple assign
    reg update;
    always @(posedge clk) begin
        if((curr_state == UPDATE_ST) || (curr_state == RESET_REGISTER_ST)) begin
            update <= 1'b1;
        end
        else begin
            update <= 1'b0;
        end
    end

    // reset counter
    assign reset_count_out = (curr_state_pre == RECEIVE_DATA_ST) || (curr_state_pre == SEND_DATA_ST);

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
            cmd_reg_pre <= (cmd_reg << 1) | data_in;
        end
    end

    always @(posedge clk) begin
        if(reset_internal == 1) begin
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
                        case ((cmd_reg[`CMD_LEN - 2:0] << 1) | data_in) // last bit of command is not stored, this saves one cycle
                            `START_SEND_CMD: begin
                                curr_state_pre <= SEND_DATA_SETUP_ST;
                            end
                            `START_RECEIVE_CMD: begin
                                curr_state_pre <= RECEIVE_DATA_ST;
                            end
                            `RESET_CMD: begin
                                curr_state_pre <= RESET_REGISTER_ST;
                            end
                            `UPDATE_CMD: begin
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
endmodule
