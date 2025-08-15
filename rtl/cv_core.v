//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA Project (targeting Digilent Cmod A7-x5T)
// Author: Karl Rinne
// Design Name: Composite Video (cv). Core
// Revision: 1.0 28/07/2021
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2005
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

`include "timing.v"

module cv_core
#(
    parameter CLKS_PER_PIXEL=5,
    parameter MAX_PIXEL_H=1280,
    parameter MAX_SCANLINES=625
)
(
    input wire                  clk,                // clock input (rising edge)
    input wire                  reset,              // reset input (synchronous)
    input wire [7:0]            cv_ctrl,
    output wire [2:0]           cv_lum,             // composite video luminance
    output wire                 cv_chrom,           // composite video chrominance (not currently used)
    output reg                  cv_sync,            // composite video sync (assumes open-drain output)
    output wire                 cv_sync_h,          // composite video debug/measurement
    output wire                 cv_sync_v           // composite video debug/measurement
);

    wire cv_en;                                     // enable composite video
    wire cv_bias;
    
    wire clk_en_pixel;                              // clk enable signal active pixel (one in every N clk cycles)
    wire x_vis;
    wire [$clog2(MAX_PIXEL_H)-1:0] x_pos;           // x position
    wire [$clog2(MAX_SCANLINES)-1:0] y_pos;         // y position

    wire cv_sync_pre;
    wire cv_sync_main;
    wire cv_sync_post;

    reg  [1:0] cv_lum_mask;
    wire [1:0] cv_lum_content0;         // video content provider 0
    wire [1:0] cv_lum_content1;         // video content provider 1
    wire [1:0] cv_lum_content2;
    wire [1:0] cv_lum_content3;
    wire [1:0] cv_lum_content4;
    wire [1:0] cv_lum_content5;
    wire [1:0] cv_lum_content6;
    wire [1:0] cv_lum_content7;
    wire [1:0] cv_lum_content8;
    wire [1:0] cv_lum_content9;
    
    // character rom, 2kB
    wire [10:0] crom_addr;
    wire [7:0] crom_din;

    // shared access to character rom
    wire [10:0] crom_addr0;
    wire [10:0] crom_addr1;
    wire [10:0] crom_addr2;
    wire [10:0] crom_addr3;
    wire [10:0] crom_addr4;
    wire [10:0] crom_addr5;
    wire [10:0] crom_addr6;
    wire [10:0] crom_addr7;
    wire [10:0] crom_addr8;
    wire [10:0] crom_addr9;
        
    
    wire [7:0] crom_din0;
    wire [7:0] crom_din1;
    wire [7:0] crom_din2;
    wire [7:0] crom_din3;
    wire [7:0] crom_din4;
    wire [7:0] crom_din5;
    wire [7:0] crom_din6;
    wire [7:0] crom_din7;
    wire [7:0] crom_din8;
    wire [7:0] crom_din9;
    

    
    wire crom_rq0;
    wire crom_rq1;
    wire crom_rq2;
    wire crom_rq3;
    wire crom_rq4;
    wire crom_rq5;
    wire crom_rq6;
    wire crom_rq7;
    wire crom_rq8;
    wire crom_rq9;
    
    // Handle control input
    assign cv_en=cv_ctrl[0];
    assign cv_bias=cv_ctrl[1];       // enables CV bias (pulling cv_lum[2] high
    assign cv_en_diagonal=cv_ctrl[4];
    assign cv_en_checkers=cv_ctrl[5];

    // Manage composite sync
    always @(*) begin
        if ( reset | (~cv_en) ) begin
            cv_sync=1; cv_lum_mask=2'b00;
        end else begin
            casex ( {cv_sync_pre,cv_sync_main,cv_sync_post} )
                3'b1xx: begin
                    cv_sync=1; cv_lum_mask=2'b00;
                end
                3'b01x: begin
                    cv_sync=0; cv_lum_mask=2'b00;
                end
                3'b001: begin
                    cv_sync=1; cv_lum_mask=2'b00;
                end
                default: begin
                    cv_sync=1; cv_lum_mask=2'b11;
                end
            endcase
        end
    end

    // Manage composite luminance (bias)
    assign cv_lum[2]=cv_bias;

    // Manage composite chrominance (not used, tied low)
    assign cv_chrom=0;

    // Instantiate composite video (central control and timing)
    cv_control #( .CLKS_PER_PIXEL(CLKS_PER_PIXEL) ) cv_control
    (
        .clk(clk),
        .reset(reset),
        .cv_en(cv_en),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .cv_sync_pre(cv_sync_pre),
        .cv_sync_main(cv_sync_main),
        .cv_sync_post(cv_sync_post),
        .cv_sync_h(cv_sync_h),
        .cv_sync_v(cv_sync_v)
    );

    // Combine luminance of all video content providers
    assign cv_lum[1:0]=(cv_lum_content0|cv_lum_content1|cv_lum_content2|cv_lum_content3|cv_lum_content4|cv_lum_content5|cv_lum_content6|cv_lum_content7|cv_lum_content8|cv_lum_content9) & cv_lum_mask;
    //assign cv_lum[1:0]=(cv_lum_content0|cv_lum_content1|cv_lum_content2|cv_lum_content3|cv_lum_content4) & cv_lum_mask;



    cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char0
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(10'd100),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("p"),
        .crom_addr(crom_addr0),
        .crom_rq(crom_rq0),
        .crom_din(crom_din0),
        .lum(cv_lum_content0)
    );

    cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char1
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(11'd116),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("g"),
        .crom_addr(crom_addr1),
        .crom_rq(crom_rq1),
        .crom_din(crom_din1),
        .lum(cv_lum_content1)
    );
    
    cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char2
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(12'd132),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("0"),
        .crom_addr(crom_addr2),
        .crom_rq(crom_rq2),
        .crom_din(crom_din2),
        .lum(cv_lum_content2)
    );
    
    cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char3
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(13'd148),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("3"),
        .crom_addr(crom_addr3),
        .crom_rq(crom_rq3),
        .crom_din(crom_din3),
        .lum(cv_lum_content3)
    );    
    
    cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char4
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(14'd164),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("u"),
        .crom_addr(crom_addr4),
        .crom_rq(crom_rq4),
        .crom_din(crom_din4),
        .lum(cv_lum_content4)
    );

    cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char5
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(13'd180),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("k"),
        .crom_addr(crom_addr5),
        .crom_rq(crom_rq5),
        .crom_din(crom_din5),
        .lum(cv_lum_content5)
    );
    
        cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char6
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(15'd200),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("e"),
        .crom_addr(crom_addr6),
        .crom_rq(crom_rq6),
        .crom_din(crom_din6),
        .lum(cv_lum_content6)
    );
    
        cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char7
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(16'd218),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("G"),
        .crom_addr(crom_addr7),
        .crom_rq(crom_rq7),
        .crom_din(crom_din7),
        .lum(cv_lum_content7)
    );
    
        cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char8
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(17'd236),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("r"),
        .crom_addr(crom_addr8),
        .crom_rq(crom_rq8),
        .crom_din(crom_din8),
        .lum(cv_lum_content8)
    );
    
        cv_char #( .NOF_TEXT_PIXELS(1) ) cv_char9
    (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clk_en_pixel(clk_en_pixel),
        .x_vis(x_vis),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .text_x(18'd252),
        .text_y(10'd100),
        .text_lum_bg(2'd0),
        .text_lum_fg(2'd3),
        .char_in("i"),
        .crom_addr(crom_addr9),
        .crom_rq(crom_rq9),
        .crom_din(crom_din9),
        .lum(cv_lum_content9)
    );

    // manage shared access to a single character rom
    cv_charrom_access cv_charrom_access
    (
        .clk(clk),
        .reset(reset),
        .crom_addr(crom_addr),
        .crom_din(crom_din),
        .all_addr({crom_addr9, crom_addr8, crom_addr7, crom_addr6, crom_addr5, crom_addr4, crom_addr3, crom_addr2, crom_addr1, crom_addr0}),
        .all_rq({crom_rq9, crom_rq8, crom_rq7, crom_rq6, crom_rq5, crom_rq4, crom_rq3, crom_rq2, crom_rq1, crom_rq0}),
        .all_data({crom_din9, crom_din8, crom_din7, crom_din6, crom_din5, crom_din4, crom_din3,crom_din2,crom_din1,crom_din0})
        //.all_addr({crom_addr4, crom_addr3, crom_addr2, crom_addr1, crom_addr0}),
        //.all_rq({crom_rq4, crom_rq3, crom_rq2, crom_rq1, crom_rq0}),
        //.all_data({crom_din4, crom_din3, crom_din2,crom_din1,crom_din0})
    );

    // character rom (256 ASCII characters, legacy VGA-compliant, 8 lines of 8b/line(
    cv_charrom cv_charrom
    (
        .clk(clk),
        .data(crom_din),
        .adr(crom_addr),
        .seln(1'b0),
        .rdn(1'b0)
    );
    
/*        // move char x
    counter_triangular #( .COUNTER_NOB(11), .PRESCALER(1), .THRESHOLD_LOW(83), .THRESHOLD_HIGH(100), .COUNTER_INIT(90), .COUNTER_INIT_DIR_UP(1) ) counter_triangular_x
    (
        .clk(clk),
        .reset(reset),
        .in(cv_sync_v),
        .counter(char_x)
    );

    // move char y
    counter_triangular #( .COUNTER_NOB(10), .PRESCALER(1), .THRESHOLD_LOW(90), .THRESHOLD_HIGH(110), .COUNTER_INIT(100), .COUNTER_INIT_DIR_UP(1) ) counter_triangular_y
    (
        .clk(clk),
        .reset(reset),
        .in(cv_sync_v),
        .counter(char_y)
    );*/

endmodule
