//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 pg03
// Author: Luke Griffin
// Create Date: 05/12/2024
// Design Name: signal_out
// Revision: 1.0
//////////////////////////////////////////////////////////////////////////////////
`include "timing.v"

module signal_out(
    input wire clk,              
    input wire reset,            
    input wire [31:0] tph_input,  // adjustable tph input
    input wire [31:0] cycle_input, // adjustable full cycle input
    output reg signal_out         // output signal
);

    // Parameters
    localparam integer CLK_FREQ = 100_000_000;    
    localparam integer MIN_TPH_CYCLES = 10;       //0.1 µs = 10 cycles at 100 MHz
    localparam integer MAX_TPH_CYCLES = 990;      // 9.9 µs = 990 cycles
    localparam integer DEFAULT_TPH_CYCLES = 250;  // default 2.5 µs = 250 cycles


    localparam integer MIN_T_CYCLES = 1_000;      // max cycle length
    localparam integer MAX_T_CYCLES = 30_303; // minimum cycle length 

    reg [31:0] tph_cycles; 
    reg [31:0] t_cycles;   
    reg [31:0] counter;    

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 32'd0;              // reset the counter
            signal_out <= 1'b0;            
            tph_cycles <= DEFAULT_TPH_CYCLES; // set to default TPH cycles
            t_cycles <= 2_000;         // default full cycle setting 
        end else begin
            // clamp tph_input within allowed range
            if (tph_input < MIN_TPH_CYCLES) begin
                tph_cycles <= MIN_TPH_CYCLES;
            end else if (tph_input > MAX_TPH_CYCLES) begin
                tph_cycles <= MAX_TPH_CYCLES;
            end else begin
                tph_cycles <= tph_input;
            end

            // clamp
            if (cycle_input < MIN_T_CYCLES) begin
                t_cycles <= MIN_T_CYCLES;
            end else if (cycle_input > MAX_T_CYCLES) begin
                t_cycles <= MAX_T_CYCLES;
            end else begin
                t_cycles <= cycle_input;
            end

            // Signal generation logic
            if (counter < t_cycles) begin
                counter <= counter + 1; // increment the counter

                if (counter < tph_cycles) begin
                //set high
                    signal_out <= 1'b1;
                end else begin
                    signal_out <= 1'b0;
                end
            end else begin
                counter <= 32'd0;
            end
        end 
    end

endmodule
