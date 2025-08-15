`include "timing.v"

module algorithm_tb02;

    // Parameters
    parameter CLK_FREQ_KHZ = 100_000;  // 100 MHz = 100,000 kHz
    parameter MAX_PERIOD   = 200_000;  // Upper bound on search range
    parameter BIT_WIDTH    = 32;
    parameter MAX_ITER     = 40;

    // Testbench signals
    reg clk;
    reg reset;
    reg [15:0] user_freq;
    wire [BIT_WIDTH-1:0] pulse_period;

    // Instantiate the Unit Under Test (UUT)
    frequency_algorithm #(
        .CLK_FREQ_KHZ(CLK_FREQ_KHZ),
        .MAX_PERIOD(MAX_PERIOD),
        .BIT_WIDTH(BIT_WIDTH),
        .MAX_ITER(MAX_ITER)
    ) uut (
        .clk(clk),
        .reset(reset),
        .user_freq(user_freq),
        .pulse_period(pulse_period)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        user_freq = 0;

        // Reset the design
        #20 reset = 0;
        // Test case 1: 50.0 kHz (user_freq = 500)
        user_freq = 500;
        #700
        user_freq = 990;
        #700 
        user_freq = 33;
        #800

        // Finish the simulation
        #100 $stop;
    end
endmodule
