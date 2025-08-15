module random_tb03;

    reg clk;                  // System clock (100 MHz)
    reg reset;                // Reset signal
    reg [31:0] user_freq;     // Frequency divider value

    wire signal_out;          // PRBS signal output
    wire signal_cycle;        // Cycle rollover signal

    random_generator uut (
        .clk(clk),
        .reset(reset),
        .user_freq(user_freq),
        .signal_out(signal_out),
        .signal_cycle(signal_cycle)
    );

    initial clk = 0;
    always #5 clk = ~clk;    

    integer cycle_count;     
    integer bit_count;        //

    initial begin
        reset = 1;
        user_freq = 32'd3000; 
        cycle_count = 0;
        bit_count = 0;

        #100 reset = 0;

        forever begin
            @(posedge clk);
            if (signal_out) bit_count = bit_count + 1;  
            if (signal_cycle) cycle_count = cycle_count + 1; 
        end
    end


    initial begin

        #2_000_000;

        $display("Test Completed:");
        $display("Total PRBS Bits Generated: %d", bit_count);
        $display("Total PRBS Cycles (Rollovers): %d", cycle_count);

        $stop;
    end
endmodule