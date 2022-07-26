module serial_ctrl
(
    /* external ports */
    inout data_inout,
    input clk,
    input reset_in,
    /* module ports */
    input count_reached_in,
    input data_out_shift_reg_in,
    output reset_count_out,
    output update_shift_reg_out,
    output reset_shift_reg_out,
    output enable_shift_register
);
    reg enable_write_pre, enable_write;
    //assign data_inout = (enable_write) ? data_out_shift_reg_in : 1'bZ;
    tbuf bidir_data_buffer(
        .I(data_out_shift_reg_in),
        .O(data_inout),
        .EN(enable_write)
    );

    reg reset_shift_reg_out;
    reg enable_shift_register;
    reg update_shift_reg_out;

    // control part state machine
    localparam 
        RESET_ST          = 4'b0000,  // reset control circuit
        RECOVER_ST        = 4'b0001,  // recover from write/read shift to prevent glitches
        IDLE_ST           = 4'b0010,  // wait for command
        UPDATE_ST         = 4'b0011,  // update shift register
        RESET_REGISTER_ST = 4'b0100,  // reset shift register
        RCV_CMD_ST        = 4'b0101,  // currently receiving a command
        ACK_CMD_ST        = 4'b0110,  // acknowledged a command successfully
        RCV_DATA_ST       = 4'b0111,  // receiving data
        SND_DATA_ST       = 4'b1000;  // sending data

    // command types to be received from the external controller
    localparam
        RESET_CMD      = 2'b00, // reset internal state
        START_SND_CMD  = 2'b01, // start transmission of saved data
        START_RCV_CMD  = 2'b10, // start receiving of data
        UPDATE_CMD     = 2'b11; // update the shift registers output cells

    reg [3:0] curr_state_pre;  // changes with posedge
    reg [3:0] curr_state;      // changes with negedge
    reg [3:0] curr_state_post; // changes with posedge

    wire statetransition;
    assign statetransition = curr_state_pre != curr_state_post;

    /* reset shift register (can't be a simple assign to stay ahead of glitches during state transitions) */
    always @(negedge clk) begin
        if(curr_state_pre == RESET_REGISTER_ST) begin
            reset_shift_reg_out <= 1'b0;
        end
        else begin
            reset_shift_reg_out <= 1'b1;
        end
    end

    /* enable shift register */
    reg enable_shift_register_pre;
    always @(posedge clk) begin
        enable_shift_register_pre <= enable_shift_register;
    end
    always @(negedge clk) begin
        if(statetransition)
            if(curr_state_pre == RCV_DATA_ST || curr_state_pre == SND_DATA_ST) begin
                enable_shift_register <= 1;
            end
            else begin
                enable_shift_register <= 0;
            end
        else begin
            enable_shift_register <= enable_shift_register_pre;
        end
    end

    /* enable write */
    always @(posedge clk) begin
        enable_write_pre <= enable_write;
    end
    always @(negedge clk or negedge reset_in) begin
        if(~reset_in) begin
            enable_write <= 0;
        end
        else begin
            if(statetransition)
                if(curr_state_pre == SND_DATA_ST) begin
                    enable_write <= 1;
                end
                else begin
                    enable_write <= 0;
                end
            else begin
                enable_write <= enable_write_pre;
            end
        end
    end

    /* reset counter */
    assign reset_count_out = !(statetransition && (curr_state == ACK_CMD_ST));

    /* update shift register */
    always @(posedge clk) begin
        if(curr_state == UPDATE_ST) begin
            update_shift_reg_out <= 1'b1;
        end
        else begin
            update_shift_reg_out <= 1'b0;
        end
    end

    /* register for saving incoming command */
    reg [`CMD_LEN - 1:0] cmd_reg_pre;
    reg [`CMD_LEN - 1:0] cmd_reg;
    always @ (negedge clk) begin
        cmd_reg_pre <= cmd_reg;
    end
    always @(posedge clk) begin
        cmd_reg <= (cmd_reg_pre << 1) | data_inout;
    end

    /* command counter */
    reg unsigned [$clog2(`CMD_LEN + `ACK_LEN):0] cmd_count_pre;
    reg unsigned [$clog2(`CMD_LEN + `ACK_LEN):0] cmd_count;
    always @ (negedge clk) begin
        if(curr_state_pre == IDLE_ST) begin
            cmd_count_pre <= 0;
        end
        else begin
            cmd_count_pre <= cmd_count + 1;
        end
    end
    always @(posedge clk) begin
        cmd_count <= cmd_count_pre;
    end

    /* update state, synchronize reset */
    reg syncreset1, syncreset2;
    always @(posedge clk or negedge reset_in) begin
        if(~reset_in) begin
            syncreset1 <= 1'b0;
        end
        else begin
            syncreset1 <= 1'b1;
        end
    end
    always @(negedge clk or negedge reset_in) begin
        if(~reset_in) begin
            syncreset2 <= 1'b0;
        end
        else begin
            syncreset2 <= syncreset1;
        end
    end
    always @(posedge clk, negedge syncreset2) begin
        if(!syncreset2) begin
            curr_state_pre <= RESET_ST;
        end
        else begin
            case (curr_state)
                RESET_ST : begin
                     curr_state_pre <= RESET_REGISTER_ST;
                end
                RECOVER_ST : begin
                     curr_state_pre <= IDLE_ST;
                end
                IDLE_ST : begin
                    if(data_inout) begin
                        curr_state_pre <= RCV_CMD_ST;
                    end
                    else begin
                        curr_state_pre <= IDLE_ST;
                    end
                end
                UPDATE_ST: begin
                    curr_state_pre <= IDLE_ST;
                end
                RESET_REGISTER_ST: begin
                    curr_state_pre <= IDLE_ST;
                end
                RCV_CMD_ST : begin // get command after start bit
                    if(cmd_count_pre < `CMD_LEN) begin
                        curr_state_pre <= RCV_CMD_ST;
                    end
                    else begin
                        curr_state_pre <= ACK_CMD_ST;
                    end
                end
                ACK_CMD_ST : begin
                    if(cmd_count_pre < `CMD_LEN + `ACK_LEN) begin
                        curr_state_pre <= ACK_CMD_ST;
                    end
                    else begin
                        case (cmd_reg)
                            START_SND_CMD: begin
                                curr_state_pre <= SND_DATA_ST;
                            end
                            START_RCV_CMD: begin
                                curr_state_pre <= RCV_DATA_ST;
                            end
                            RESET_CMD: begin
                                curr_state_pre <= RESET_REGISTER_ST;
                            end
                            UPDATE_CMD: begin
                                curr_state_pre <= UPDATE_ST;
                            end
                        endcase
                    end
                end
                SND_DATA_ST: begin
                    if (count_reached_in) begin
                        curr_state_pre <= RECOVER_ST;
                    end
                    else begin
                        curr_state_pre <= SND_DATA_ST;
                    end
                end
                RCV_DATA_ST: begin
                    if (count_reached_in) begin
                        curr_state_pre <= IDLE_ST;
                    end
                    else begin
                        curr_state_pre <= RCV_DATA_ST;
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
