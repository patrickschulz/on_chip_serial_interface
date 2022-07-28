/* chaincell consisting of 3 flip flops to minimize hold violations and buffer output that gets active when update signal is high */
module register_cell
(
  input chain_in, /* chain in from before chaincell or controller */
  input update,
  input clk,
  input reset,
  input enable,
  output chain_out, /* chain out to next chaincell */
  output bit_out /* bit to circuit */
);
    wire chain_in;
    wire update;
    wire clk;
    wire reset;
    wire enable;
    reg chain_out;
    reg bit_out;

    /* flip flop in */
    reg ff_in;
    always @(posedge clk) begin
        if (enable) begin
            ff_in <= chain_in;
        end
        else begin
            ff_in <= chain_out;
        end
    end
    
    /* flip flop out */
    always @(negedge clk) begin
        chain_out <= ff_in;
    end
    
    /* flip flop update */
    always @(posedge update) begin
        if (!reset) begin
            bit_out <= 0; // or 1, depending on the needed circuit configuration
        end
        else begin
            bit_out <= ff_in;
        end
    end
endmodule
