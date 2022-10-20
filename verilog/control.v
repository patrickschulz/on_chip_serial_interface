module serial_ctrl
(
    input clk,
    input data_in,
    output write,
    input data_ready,
    input data_out_shift_reg_in,
    input reset_internal,
    output enable_data_counter,
    output update,
    output reset_shift_reg_out,
    output enable_shift_register,
    output write_shift_register
);
    // control part state machine
    // states are coded in order to minimize instance count
    localparam 
        RESET_ST             = 4'b1xxx,  // reset control circuit
        RECEIVE_DATA_ST      = 4'b0000,  // receiving data
        SEND_DATA_ST         = 4'b0001,  // sending data
        WAIT_FOR_COMMAND_ST  = 4'b0010,  // wait for command
        SEND_DATA_SETUP_ST   = 4'b0011,  // sending data, setup tristate buffer
        UPDATE_ST            = 4'b0101,  // update shift register
        RESET_REGISTER_ST    = 4'b0110,  // reset shift register
        SEND_DATA_RECOVER_ST = 4'b0111,  // recover from write/read shift to prevent glitches
        UNUSED_ST            = 4'b0100;

    reg [3:0] curr_state_pre;  // changes with posedge
    reg [3:0] curr_state;      // changes with negedge

    wire write;
    assign write = (curr_state == SEND_DATA_ST);

    wire write_shift_register;
    assign write_shift_register = (curr_state == RECEIVE_DATA_ST);

    wire enable_shift_register;
    assign enable_shift_register = write || write_shift_register;

    // reset shift register (synchronous reset, triggered by the update signal)
    wire reset_shift_reg_out;
    assign reset_shift_reg_out = !(curr_state == RESET_REGISTER_ST);

    // update shift register
    wire update;
    assign update = (curr_state == UPDATE_ST) || (curr_state == RESET_REGISTER_ST);

    // reset counter
    assign enable_data_counter = (curr_state == RECEIVE_DATA_ST) || (curr_state == SEND_DATA_ST);

    // command register
    wire receive_command;
    assign receive_command = curr_state == WAIT_FOR_COMMAND_ST;
    wire command_ready;
    wire [1:0] command;
    command_register command_register(.clk(clk), .data(data_in), .receive(receive_command), .ready(command_ready), .command(command));

    always @(posedge clk) begin
        if(reset_internal) begin
            curr_state_pre <= RESET_ST;
        end
        else begin
            case (curr_state)
                RESET_ST : begin
                    curr_state_pre <= RESET_REGISTER_ST;
                end
                WAIT_FOR_COMMAND_ST : begin
                    if(command_ready) begin
                        case (command)
                            2'b01: begin
                                curr_state_pre <= SEND_DATA_SETUP_ST;
                            end
                            2'b10: begin
                                curr_state_pre <= RECEIVE_DATA_ST;
                            end
                            2'b00: begin
                                curr_state_pre <= RESET_REGISTER_ST;
                            end
                            2'b11: begin
                                curr_state_pre <= UPDATE_ST;
                            end
                        endcase
                    end
                    else begin
                        curr_state_pre <= WAIT_FOR_COMMAND_ST;
                    end
                end
                UPDATE_ST: begin
                    curr_state_pre <= WAIT_FOR_COMMAND_ST;
                end
                RESET_REGISTER_ST: begin
                    curr_state_pre <= WAIT_FOR_COMMAND_ST;
                end
                SEND_DATA_SETUP_ST: begin
                    curr_state_pre <= SEND_DATA_ST;
                end
                SEND_DATA_ST: begin
                    if (data_ready) begin
                        curr_state_pre <= SEND_DATA_RECOVER_ST;
                    end
                    else begin
                        curr_state_pre <= SEND_DATA_ST;
                    end
                end
                SEND_DATA_RECOVER_ST : begin
                    curr_state_pre <= WAIT_FOR_COMMAND_ST;
                end
                RECEIVE_DATA_ST: begin
                    if (data_ready) begin
                        curr_state_pre <= WAIT_FOR_COMMAND_ST;
                    end
                    else begin
                        curr_state_pre <= RECEIVE_DATA_ST;
                    end
                end
                UNUSED_ST: begin
                    curr_state_pre <= WAIT_FOR_COMMAND_ST;
                end
            endcase
        end
    end
    always @(negedge clk) begin
        curr_state <= curr_state_pre;
    end
endmodule