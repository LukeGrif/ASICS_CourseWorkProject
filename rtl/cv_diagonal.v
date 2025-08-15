//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA Project (targeting Digilent Cmod A7-x5T)
// Author: Karl Rinne
// Design Name: Composite Video (cv). Test pattern generator (diagonal test pattern)
// Revision: 1.0 12/08/2021
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2005
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

// [20] http://www.batsocks.co.uk/readme/video_timing.htm

`include "timing.v"

module cv_diagonal
#(
    parameter MAX_PIXEL_H=1280,                     // max value of pixel counter
    parameter MAX_SCANLINES=625,
    parameter THICKNESS_PIXELS=4,
    parameter DISTANCE_PIXELS=64,
    parameter LUM=3
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

reg [$clog2(THICKNESS_PIXELS):0] out_cnt;
wire out_cnt_zero;
reg out_cnt_set;
reg [$clog2(THICKNESS_PIXELS):0] out_cnt_set_v;
wire [$clog2(DISTANCE_PIXELS)-1:0] x_pos_trunc;
wire [$clog2(DISTANCE_PIXELS)-1:0] y_pos_trunc;

always @ (posedge clk) begin
    if ( reset || (~en) ) begin
        out_cnt<=0;
    end
    else begin
        if ( clk_en_pixel ) begin
            if ( out_cnt_set ) begin
                out_cnt<=out_cnt_set_v;
            end else begin
                if ( !out_cnt_zero ) begin
                    out_cnt<=out_cnt-1;
                end
            end
        end
    end
end
assign out_cnt_zero=(out_cnt==0);

always @ (posedge clk) begin
    if ( reset || (~en) ) begin
        lum<=0;
    end
    else begin
        if ( clk_en_pixel ) begin
            if ( !out_cnt_zero ) begin
                lum<=LUM;
            end else begin
                lum<=0;
            end
        end
    end
end

always @(*) begin
    out_cnt_set=0; out_cnt_set_v=0;
    if ( x_vis ) begin
        if ( x_pos_trunc==y_pos_trunc ) begin
            out_cnt_set=1; out_cnt_set_v=THICKNESS_PIXELS;
        end
    end
end

// assign truncated positions
assign x_pos_trunc=x_pos;
assign y_pos_trunc=y_pos;

endmodule
