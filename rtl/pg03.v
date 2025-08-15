//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA Upcounter 1 (up1)
// Author: Karl Rinne
// Create Date: 27/05/2020
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
`include "fsm_game_states.v"

module pg03
(
    input wire                  clk,
    input wire                  reset,
    input wire					turbosim,
    input wire [1:0]            buttons,        // {L, R}
    input wire                  muxpb,          // multiplexed pushbutton
    output wire                 blink,
    output wire                 buzzer_p,
    output wire                 buzzer_n,
    output wire [7:0]           d7_cathodes_n,  // {DP,CG,CF,CE,CD,CC,CB,CA}
    output wire [7:0]           d7_anodes,
    output wire [3:0]           fsm_state,
    output wire                 signal_out,
    output wire                 signal_cycle,
    output wire [2:0]           cv_lum,
    output wire                 cv_chrom,
    output wire                 cv_sync,
    output wire                 cv_sync_h,
    output wire                 cv_sync_v
);


    localparam  d7_space=8'b00000000;    // display character ' '
    localparam  d7_A=8'b01110111;    // display character 'A'
    localparam  d7_C=8'b00111001;    // display character 'C'
    localparam  d7_c=8'b01011000;    // display character 'c'
    localparam  d7_d=8'b01011110;    // display character 'd'
    localparam  d7_E=8'b01111001;    // display character 'E'
    localparam  d7_F=8'b01110001;    // display character 'F'
    localparam  d7_h=8'b01110100;    // display character 'h'
    localparam  d7_I=8'b00110000;    // display character 'I'
    localparam  d7_L=8'b00111000;    // display character 'L'
    localparam  d7_r=8'b01010000;    // display character 'r'
    localparam  d7_S=8'b01101101;    // display character 'S'
    localparam  d7_t=8'b01111000;    // display character 't'
    localparam  d7_U=8'b00111110;    // display character 'U'
    localparam  d7_y=8'b01101110;    // display character 'y'
    localparam  d7_p=8'b01110011;    // display character 'P'
    localparam  d7_g=8'b00111101;    // display character 'G'
    localparam  d7_b=8'b01111100;    // display character 'b'

    
    

    wire                        reset_s;        // synchronised reset signal
    wire                        clk_ev_1ms;
    wire                        clk_ev_100us;

    wire                        button_l;       // debounced
    wire                        button_r;       // debounced
    wire [5:0]                  mbuttons;
    
    wire [7:0]                  buttons_all;
    
    wire                        beep;

    wire [79:0]                 d7_content_selected;
    wire [79:0]                 d7_content0;
    wire [79:0]                 d7_content1;
    wire [79:0]                 d7_content2;
    wire [79:0]                 d7_content3;
    wire [79:0]                 d7_content4;
    wire [79:0]                 d7_content5;
    wire [79:0]                 d7_content6;
    wire [79:0]                 d7_content7;
    wire [79:0]                 d7_content8;       
    wire [79:0]                 d7_content9;       
    wire [79:0]                 d7_content10;       
    wire [79:0]                 d7_content11;       
    wire [3:0]                  d7_content_sel;

    wire [7:0]                  digit_ones_out;
    wire [7:0]                  digit_tens_out; 
    
    wire [31:0]                 tph_input;
    wire [31:0]                 tph_output;
    
    wire [31:0]                 tph_output_saved;
    
    wire [31:0]                 cycle_input;
    wire [31:0]                 cycle_output;
    

    
    wire [31:0]                  pulse_period;
    
    reg [7:0]                   dot_digit;
    reg [7:0]                   tens_digit;
    
    wire [7:0]                  cycle_ones;
    wire [7:0]                  cycle_tens;
    wire [7:0]                  cycle_hundreds;
        
        
    wire prbs_out; // PRBS signal output
    wire prbs_cycle;
    
    wire [3:0]  tph_hundreds, tph_tens;
    wire [3:0]  freq_tens;
    wire [7:0]  freq_hundreds, freq_ones;

    // Assign display contents (blink, mode, data)
    // "UL    "
    assign d7_content0={8'b0000_1111,8'b0000_0000, 16'h0, d7_U, d7_L, d7_space, d7_space, d7_space, d7_space};
    // "UL ECE"
    assign d7_content1={8'b0000_0000,8'b0000_0000, 16'h0, d7_U, d7_L, d7_space, d7_E,d7_C,d7_E};
    // "EE6621"
    assign d7_content2={8'b0000_0000,8'b0000_1111, 16'h0, d7_E,d7_E, 8'h6,8'h6,8'h2,8'h1};
    // "   334528"
    assign d7_content3={8'b0000_0000,8'b0011_1111, 16'h0, 8'h3, 8'h3, 8'h4, 8'h5, 8'h2, 8'h8};
    // "   pg03"
    assign d7_content4={8'b0000_0000,8'b0000_0011, 16'h0, d7_space, d7_space, d7_p, d7_g, 8'h0, 8'h3};
    // "2.5 50.0"
    assign d7_content5={8'b0000_0000,8'b0011_0111, 16'h0, 4'h8, tph_hundreds, 4'h0,tph_tens, d7_space, freq_hundreds, 4'h8, freq_tens, freq_ones};
   
    assign d7_content6={8'b0010_0000,8'b0011_0111, 16'h0, 4'h8, tph_hundreds, 4'h0,tph_tens, d7_space, freq_hundreds, 4'h8, freq_tens, freq_ones};
        
    assign d7_content7={8'b0001_0000,8'b0011_0111, 16'h0, 4'h8, tph_hundreds, 4'h0,tph_tens, d7_space, freq_hundreds, 4'h8, freq_tens, freq_ones};
    
    assign d7_content8={8'b0000_0000,8'b0000_0111, 16'h0, d7_p, d7_r, d7_b, freq_hundreds, 4'h8, freq_tens, freq_ones};
    
    assign d7_content9={8'b0000_0100,8'b0011_0111, 16'h0, 4'h8, tph_hundreds, 4'h0,tph_tens, d7_space, freq_hundreds, 4'h8, freq_tens, freq_ones};
    
    assign d7_content10={8'b0000_0010,8'b0011_0111, 16'h0, 4'h8, tph_hundreds, 4'h0,tph_tens, d7_space, freq_hundreds, 4'h8, freq_tens, freq_ones};
    
    assign d7_content11={8'b0000_0001,8'b0011_0111, 16'h0, 4'h8, tph_hundreds, 4'h0,tph_tens, d7_space, freq_hundreds, 4'h8, freq_tens, freq_ones};
    
    assign tph_input = tph_output;
    
    assign buttons_all={mbuttons[5:0],button_l,button_r};

    assign signal_out = (fsm_state == S_SHOW_RANDOM) ? prbs_out : signal_out_normal;

    assign signal_cycle = (fsm_state == S_SHOW_RANDOM) ? prbs_cycle : signal_cycle_normal;

    

    // Synchronise the incoming raw reset signal
    synchroniser_3s synchroniser_3s_reset
    (
        .clk(clk),
        .reset(1'b0),
        .en(1'b1),
        .in(reset),
        .out(reset_s)
    );

    // Instantiate a down counter to provide 1ms time base
    counter_down_rld #( .COUNT_MAX(99_999), .COUNT_MAX_TURBOSIM(99) ) counter_1ms
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .rld(1'b0),
        .underflow(clk_ev_1ms)
    );

    // Instantiate a down counter to provide 100us time base (for sampling of button, debounce)
    counter_down_rld #( .COUNT_MAX(9_999), .COUNT_MAX_TURBOSIM(9) ) counter_100us
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .rld(1'b0),
        .underflow(clk_ev_100us)
    );

    // Instantiate a display mux
    display_7s_mux display_7s_mux
    (
        .dis_content0(d7_content0),
        .dis_content1(d7_content1),
        .dis_content2(d7_content2),
        .dis_content3(d7_content3),
        .dis_content4(d7_content4),
        .dis_content5(d7_content5),
        .dis_content6(d7_content6),
        .dis_content7(d7_content7),
        .dis_content8(d7_content8),
        .dis_content9(d7_content9),
        .dis_content10(d7_content10),
        .dis_content11(d7_content11), 
        .dis_data(d7_content_selected),
        .sel(d7_content_sel)
    );

    //Instantiate debounce for buttons[1] (left)
    debounce debounce_l
    (
        .clk(clk),
        .reset(reset_s),
        .en(clk_ev_100us),
        .signal_in(buttons[1]),
        .signal_debounced(button_l)
    );

    //Instantiate debounce for buttons[0] (right)
    debounce debounce_r
    (
        .clk(clk),
        .reset(reset_s),
        .en(clk_ev_100us),
        .signal_in(buttons[0]),
        .signal_debounced(button_r)
    );
    
        // Instantiate a buzzer (1.6kHz, 0.2s)
    buzzer #(.BUZZER_RLD(31_249), .BUZZER_DUR(639) ) buzzer
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .en_posedge(1'b1),  
        .en(|buttons_all),      
        .buzzer_p(buzzer_p),
        .buzzer_n(buzzer_n)
    );

    // Instantiate a 7-segment display driver
    display_7s #( .PRESCALER_RLD(99_999), .BLINK_RLD(499) ) display_7s
    (
        .clk(clk),
        .reset(reset_s),
        .turbosim(turbosim),
        .en(1'b1),
        .dis_data(d7_content_selected[63:0]),
        .dis_mode(d7_content_selected[71:64]),
        .dis_blink(d7_content_selected[79:72]),
        .negate_a(1'b0),            // we're using non-negating external drivers for anodes (npn emitter follower)
        .cathodes_n(d7_cathodes_n),
        .anodes(d7_anodes),
        .blink(blink)
    );

    // Instantiate the pulse generator for signal_out
    signal_out signal_1
    (
        .clk(clk),
        .reset(reset_s),
        .tph_input(tph_input),
        .cycle_input(pulse_period),
        .signal_out(signal_out_normal)
    );
    
    //instantiate the pulse generator for signal_cycle (100ns sync signal)
    signal_out signal_2
    (
    .clk(clk),
    .reset(reset_s),
    .tph_input(10),
    .cycle_input(pulse_period),
    .signal_out(signal_cycle_normal)
    );

    // Instantiate the pseudo-random binary sequence
    random_generator prbs_generator
    (
    .clk(clk),
    .reset(reset_s),
    .user_freq(pulse_period),
    .signal_out(prbs_out),
    .signal_cycle(prbs_cycle)
    );

    // Instantiate FSM for pg03
    fsm_game fsm_game
    (
        .clk(clk),
        .reset(reset_s),
        .timebase(clk_ev_1ms),
        .button(button_l),
        .button_r(button_r),
        .beep(beep),
        .dis_sel(d7_content_sel),
        .tph_output(tph_output),
        .fsm_state(fsm_state),
        .mbuttons(mbuttons),
        .frequency_output(cycle_output),
        .tph_hundreds(tph_hundreds),
        .tph_tens(tph_tens),
        .freq_hundreds(freq_hundreds),
        .freq_tens(freq_tens),
        .freq_ones(freq_ones)
        //.tph_output_saved(tph_output_saved)
    );
    
    // Instantiate the mbuttons for daghter board
    mbutton #(.MUX_NOB(8)) mbutton
    (
        .clk(clk),
        .reset(reset_s),
        .muxin(d7_anodes),
        .pbin(muxpb),
        .buttons(mbuttons)
    );
    
    // Instantiate the algorithm to compute the period of users frequency
    frequency_algorithm frequency_convertor
    (
        .clk(clk),
        .reset(reset_s),
        .user_freq(cycle_output),
        .pulse_period(pulse_period)
    );
    
    
   // Instantiate composite video
    cv_core #( .CLKS_PER_PIXEL(5) ) cv_core
    (
        .clk(clk),
        .reset(reset_s),
        .cv_ctrl(8'b00000011),
        .cv_lum(cv_lum),
        .cv_chrom(cv_chrom),
        .cv_sync(cv_sync),
        .cv_sync_h(cv_sync_h),
        .cv_sync_v(cv_sync_v)
    );
    
endmodule
