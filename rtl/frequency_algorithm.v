// University of Limerick
// Design: EE6621 pg03
// Author: Luke Griffin
// Create Date: 05/12/2024
// Design Name: frequency_algorithm
// Revision: 1.1
//////////////////////////////////////////////////////////////////////////////////
`include "timing.v"

module frequency_algorithm #(
    parameter CLK_FREQ_KHZ = 100_000,
    parameter MAX_PERIOD   = 200_000,     //search range
    parameter BIT_WIDTH    = 32,
    parameter MAX_ITER     = 40           // more iterations for accuracy
)(
    input  wire                clk,
    input  wire                reset,
    input  wire [15:0]         user_freq,   // frequency e.g., 500 = 50.0 kHz
    output reg  [BIT_WIDTH-1:0] pulse_period // result
);
    // states
    localparam INIT     = 2'd0,
               COMPUTE  = 2'd1,
               FINISH   = 2'd2;

    reg [1:0] state;
   
    // binary search registers
    reg [BIT_WIDTH-1:0] low;
    reg [BIT_WIDTH-1:0] high;
    reg [BIT_WIDTH-1:0] mid;
    reg [BIT_WIDTH-1:0] product;
    reg [5:0] iteration_count; // up to 63 iterations

    // scale the target by 10:
    // before - mid * freq(kHz) ≈ 100,000
    // now - mid * freq(0.1 kHz) ≈ 1,000,000
    wire [BIT_WIDTH-1:0] target_value = CLK_FREQ_KHZ * 10; // 1,000,000
    wire [BIT_WIDTH-1:0] next_mid     = (low + high) >> 1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= INIT;
            pulse_period   <= 2000;
            low            <= 0;
            high           <= MAX_PERIOD;
            mid            <= 0;
            product        <= 0;
            iteration_count <= 0;
        end else begin
            case (state)
                INIT: begin
                    // initialize the binary search
                    low  <= 0;
                    high <= MAX_PERIOD;
                    iteration_count <= 0;
                    mid <= next_mid;
                    state <= COMPUTE;
                end

                COMPUTE: begin
                    // compute product = mid * user_freq
                    product <= mid * user_freq;
                    state <= FINISH;
                end

                FINISH: begin
                    // adjust bounds based on product vs target
                    if (product < target_value) begin
                        low <= mid + 1;
                    end else begin
                        // T could be smaller or this might be exact
                        high <= mid;
                    end

                    iteration_count <= iteration_count + 1;
                    mid <= (low + high) >> 1;

                    // either convergence or iteration limit
                    if ((low >= high) || (iteration_count == MAX_ITER)) begin
                        pulse_period <= high;  // or low; nearly equal at convergence
                        state <= INIT; // Restart computation automatically
                    end else begin
                        // keep refining result
                        state <= COMPUTE;
                    end
                end
            endcase
        end
    end

endmodule