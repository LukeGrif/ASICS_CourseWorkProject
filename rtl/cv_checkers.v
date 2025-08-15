//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA Project (targeting Digilent Cmod A7-x5T)
// Author: Karl Rinne
// Design Name: Composite Video (cv). Test pattern generator (checkers)
// Revision: 1.0 10/08/2021
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2005
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

// [20] http://www.batsocks.co.uk/readme/video_timing.htm

`include "timing.v"

module cv_checkers
#(
    parameter MAX_PIXEL_H=1280,                     // max value of pixel counter
    parameter MAX_SCANLINES=625,
    parameter CHECKERS_SIZE=8
)
(
    input wire                  clk,                // clock input (rising edge)
    input wire                  reset,              // reset input (synchronous)
    input wire                  en,                 // enable cv_control
    input wire                  clk_en_pixel,       // clk enable signal active pixel (one in every N clk cycles)
    input wire                  x_vis,              // x visible flag
    input wire [$clog2(MAX_PIXEL_H)-1:0] x_pos,     // x position
    input wire [$clog2(MAX_SCANLINES)-1:0] y_pos,   // y position
    output reg [1:0]            lum
);

localparam              SHIFT_NOB=$clog2(CHECKERS_SIZE);

    wire [1:0]                  out_lum0;
    wire                        out_lum_inv;

always @ (posedge clk) begin
    if ( reset || (~en) ) begin
        lum<=0;
    end
    else begin
        if ( clk_en_pixel ) begin
            if ( x_vis ) begin
                lum<= (out_lum0 ^ {out_lum_inv,out_lum_inv} );
            end else begin
                lum<=0;
            end
        end
    end
end

assign out_lum0=x_pos>>SHIFT_NOB;
assign out_lum_inv=y_pos>>SHIFT_NOB;

endmodule
