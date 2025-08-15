//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 pg03
// Author: Luke Griffin
// Create Date: 05/12/2024
// Design Name: random_generator
// Revision: 1.0
//////////////////////////////////////////////////////////////////////////////////
module random_generator (
    input wire clk,                // Clock signal
    input wire reset,              // Reset signal
    input wire [31:0] user_freq,   // User-defined frequency divider value
    output reg signal_out,         // PRBS signal output
    output reg signal_cycle        // Cycle rollover signal
);

    // Parameters for LFSR taps (stages 8, 6, 5, and 4)
    parameter LFSR_WIDTH = 8;
    parameter TAP1 = 6;
    parameter TAP2 = 5;
    parameter TAP3 = 4;

    reg [LFSR_WIDTH-1:0] lfsr;    // Linear Feedback Shift Register
    reg [7:0] state_counter;      // Counter for detecting rollovers
    reg [31:0] freq_div_counter;  // Frequency divider counter
    reg enable_prbs;              // Enable signal for PRBS update

    // Frequency divider logic to generate enable_prbs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            freq_div_counter <= 0;
            enable_prbs <= 0;
        end else begin
            if (freq_div_counter == user_freq - 1) begin
                freq_div_counter <= 0;
                enable_prbs <= 1;  // Enable PRBS update for one cycle
            end else begin
                freq_div_counter <= freq_div_counter + 1;
                enable_prbs <= 0;
            end
        end
    end

    // LFSR with XNOR-based feedback logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= 8'b1;          // Initialize LFSR to avoid lock-up (all-zero state)
            signal_out <= 0;
            signal_cycle <= 0;
            state_counter <= 0;
        end else if (enable_prbs) begin
            // Update LFSR
            signal_out <= lfsr[LFSR_WIDTH-1]; // Output is the MSB of LFSR
            lfsr <= {lfsr[LFSR_WIDTH-2:0], 
                     ~(lfsr[LFSR_WIDTH-1] ^ lfsr[TAP1-1] ^ lfsr[TAP2-1] ^ lfsr[TAP3-1])};

            // Update state counter and generate cycle signal
            if (state_counter == 8'hFF) begin
                signal_cycle <= 1;   // Assert rollover signal
                state_counter <= 0;
            end else begin
                signal_cycle <= 0;
                state_counter <= state_counter + 1;
            end
        end
    end
endmodule