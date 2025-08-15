//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: Triangular counter, switching between counting up and down once thresholds are hit
// Author: Karl Rinne
// Create Date: 29/10/2021
// Design Name: generic
// Revision: 1.0
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2001
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

`include "timing.v"

module counter_triangular
#(
    parameter           COUNTER_NOB=11,
    parameter           PRESCALER=30,
    parameter           THRESHOLD_LOW=50,
    parameter           THRESHOLD_HIGH=60,
    parameter           COUNTER_INIT=55,
    parameter           COUNTER_INIT_DIR_UP=1
)
(
    input wire          clk,                // clock input
    input wire          reset,              // reset input (synchronous)
    input               in,                 // input event (posedges being counted)
    output reg [COUNTER_NOB-1:0] counter
);

reg in_s;
wire in_edge;

reg [$clog2(PRESCALER)-1:0] prescaler;
wire        prescaler_zero;

reg         counter_dir;
wire        counter_max;
wire        counter_min;
wire        counter_zero;

// detect pos edges of input
always @ (posedge clk) begin
    if (reset) begin
        in_s<=0;
    end else begin
        in_s<=in;
    end
end
assign in_edge=(in==1'b1)&&(in_s==1'b0);

// manage prescaler reloadable counter
always @ (posedge clk) begin
    if (reset) begin
        prescaler<=PRESCALER-1;
    end else begin
        if ( in_edge ) begin
            if ( prescaler_zero ) begin
                prescaler<=PRESCALER-1;
            end else begin
                prescaler<=prescaler-1;
            end
        end
    end
end
assign prescaler_zero=(prescaler==0);

always @ (posedge clk) begin
    if (reset) begin
        counter<=COUNTER_INIT; counter_dir<=COUNTER_INIT_DIR_UP;
    end else begin
        if ( prescaler_zero && in_edge) begin
            if ( counter_dir ) begin
                // counting up
                if ( counter_max ) begin
                    counter_dir<=0; counter<=counter-1;
                end else begin
                    counter<=counter+1;
                end
            end else begin
                // counting down
                if ( counter_min ) begin
                    counter_dir<=1; counter<=counter+1;
                end else begin
                    counter<=counter-1;
                end
            end
        end
    end
end
assign counter_max=(counter==THRESHOLD_HIGH);
assign counter_min=(counter==THRESHOLD_LOW);

endmodule
