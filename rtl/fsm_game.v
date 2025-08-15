//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 pg03 
// Author: Luke Griffin
// Create Date: 05/12/2024
// Design Name: fsm_game
// Revision: 1.1
//////////////////////////////////////////////////////////////////////////////////

`include "timing.v"

module fsm_game
#(
    parameter           WAIT_VLONG=3999,
    parameter           WAIT_LONG=1999,
    parameter           WAIT_MEDIUM=300,
    parameter           WAIT_SHORT=199,
    parameter           RND_MIN=10,
    parameter           RND_MAX=990
)
(
    input wire          clk,
    input wire          reset,
    input wire          timebase,
    input wire          button,
    input wire          button_r,
    input wire [5:0]    mbuttons,
    output reg [3:0]    dis_sel,
    output reg          beep,
    output reg [31:0]   tph_output,
    output reg [31:0]   frequency_output,
    output wire [3:0]   fsm_state,
    output reg [3:0]    tph_hundreds, 
    output reg [3:0]    tph_tens,
    output reg [3:0]    freq_hundreds,
    output reg [3:0]    freq_tens,
    output reg [3:0]    freq_ones
    
);

`include "wordlength.v"
`include "fsm_game_states.v"

reg [S_NOB-1:0] state;
reg [S_NOB-1:0] next_state;
reg [wordlength(WAIT_VLONG)-1:0] counter;
reg [wordlength(WAIT_VLONG)-1:0] counter_load_value;
reg counter_load;
wire counter_zero;

reg [wordlength(WAIT_VLONG)-1:0] rnd_counter;
wire rnd_counter_max;
reg counter_load_rnd;

reg [31:0]   tph_output_saved;
reg [31:0]   frequency_output_saved;


reg [3:0]  tph_ones;
reg [3:0] tph_hundreds_saved, tph_tens_saved, tph_ones_saved;
reg [3:0] freq_hundreds_saved, freq_tens_saved, freq_ones_saved;



assign fsm_state = state;


always @(posedge clk) begin
    if (reset) begin
        counter <= 0;
    end else if (counter_load) begin
        counter <= counter_load_value;
    end else if (counter_load_rnd) begin
        counter <= rnd_counter;
    end else if (~counter_zero & timebase) begin
        counter <= counter - 1'b1;
    end
end
assign counter_zero = (counter == 0);

always @(posedge clk) begin
    if (reset) begin
        rnd_counter <= RND_MIN;
    end else if (timebase) begin
        if (rnd_counter_max) begin
            rnd_counter <= RND_MIN;
        end else begin
            rnd_counter <= rnd_counter + 1;
        end
    end
end
assign rnd_counter_max = (rnd_counter == RND_MAX);

always @(posedge clk) begin
    if (reset) begin
        state <= S_RESET;
    end else begin
        state <= next_state;
    end
end

// On reset, initialize the digits for tph_output = 250 and frequency_output = 500
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // 250 -> hundreds=2, tens=5, ones=0
        tph_hundreds <= 4'd2;
        tph_tens <= 4'd5;
        tph_ones <= 4'd0;
        
        // 500 -> hundreds=5, tens=0, ones=0
        freq_hundreds <= 4'd5;
        freq_tens <= 4'd0;
        freq_ones <= 4'd0;
    end else begin
        case (state)
            S_SHOW_BLINKDATA: begin
                if (counter_zero) begin
                    // Adjust the hundreds digit of tph_output
                    if (button | mbuttons[3]) begin
                        // increment hundreds digit (if 9 -> wrap to 0 else +1)
                        if (tph_hundreds == 4'd9)
                            tph_hundreds <= 4'd0;
                        else
                            tph_hundreds <= tph_hundreds + 4'd1;
                    end else if (mbuttons[2]) begin
                        // decrement hundreds digit (if 0 -> wrap to 9 else -1)
                        if (tph_hundreds == 4'd0)
                            tph_hundreds <= 4'd9;
                        else
                            tph_hundreds <= tph_hundreds - 4'd1;
                    end else if (mbuttons[5]) begin
                        // restore saved
                        tph_hundreds <= tph_hundreds_saved;
                        tph_tens <= tph_tens_saved;
                        tph_ones <= tph_ones_saved;
                    end
                end
            end

            S_SHOW_BLINKDATA_2: begin
                if (counter_zero) begin
                    // Adjust the tens digit of tph_output
                    if (button | mbuttons[3]) begin
                        // increment tens digit (if 9 -> wrap to 0 else +1)
                        if (tph_tens == 4'd9)
                            tph_tens <= 4'd0;
                        else
                            tph_tens <= tph_tens + 4'd1;
                    end else if (mbuttons[2]) begin
                        // decrement tens digit (if 0 -> wrap to 9 else -1)
                        if (tph_tens == 4'd0)
                            tph_tens <= 4'd9;
                        else
                            tph_tens <= tph_tens - 4'd1;
                    end else if (mbuttons[5]) begin
                        // restore saved
                        tph_hundreds <= tph_hundreds_saved;
                        tph_tens <= tph_tens_saved;
                        tph_ones <= tph_ones_saved;
                    end
                end
            end

            S_SHOW_BLINKDATA_3: begin
                if (counter_zero) begin
                    // Adjust the hundreds digit of frequency_output
                    if (button | mbuttons[3]) begin
                        // increment freq hundreds digit
                        if (freq_hundreds == 4'd9)
                            freq_hundreds <= 4'd0;
                        else
                            freq_hundreds <= freq_hundreds + 4'd1;
                    end else if (mbuttons[2]) begin
                        // decrement freq hundreds digit
                        if (freq_hundreds == 4'd0)
                            freq_hundreds <= 4'd9;
                        else
                            freq_hundreds <= freq_hundreds - 4'd1;
                    end else if (mbuttons[5]) begin
                        // restore saved
                        freq_hundreds <= freq_hundreds_saved;
                        freq_tens <= freq_tens_saved;
                        freq_ones <= freq_ones_saved;
                    end
                end
            end

            S_SHOW_BLINKDATA_4: begin
                if (counter_zero) begin
                    // Adjust the tens digit of frequency_output
                    if (button | mbuttons[3]) begin
                        if (freq_tens == 4'd9)
                            freq_tens <= 4'd0;
                        else
                            freq_tens <= freq_tens + 4'd1;
                    end else if (mbuttons[2]) begin
                        if (freq_tens == 4'd0)
                            freq_tens <= 4'd9;
                        else
                            freq_tens <= freq_tens - 4'd1;
                    end else if (mbuttons[5]) begin
                        freq_hundreds <= freq_hundreds_saved;
                        freq_tens <= freq_tens_saved;
                        freq_ones <= freq_ones_saved;
                    end
                end
            end

            S_SHOW_BLINKDATA_5: begin
                if (counter_zero) begin
                    // Adjust the ones digit of frequency_output
                    if (button | mbuttons[3]) begin
                        if (freq_ones == 4'd9)
                            freq_ones <= 4'd0;
                        else
                            freq_ones <= freq_ones + 4'd1;
                    end else if (mbuttons[2]) begin
                        if (freq_ones == 4'd0)
                            freq_ones <= 4'd9;
                        else
                            freq_ones <= freq_ones - 4'd1;
                    end else if (mbuttons[5]) begin
                        freq_hundreds <= freq_hundreds_saved;
                        freq_tens <= freq_tens_saved;
                        freq_ones <= freq_ones_saved;
                    end
                end
            end

            default: begin
                // No change
            end
        endcase
    end
end

always @(*) begin
    // Convert current digits into full integer values
    tph_output = (tph_hundreds * 100) + (tph_tens * 10) + tph_ones;
    frequency_output = (freq_hundreds * 100) + (freq_tens * 10) + freq_ones;
    
    // Convert saved digits into full integer values
    tph_output_saved = (tph_hundreds_saved * 100) + (tph_tens_saved * 10) + tph_ones_saved;
    frequency_output_saved = (freq_hundreds_saved * 100) + (freq_tens_saved * 10) + freq_ones_saved;
end




// Combinational Logic os FSM
always @(*) begin
    next_state=state;
    dis_sel=D_UL; beep=0;
    counter_load=0; counter_load_value=WAIT_LONG; counter_load_rnd=0;
    case (state)
        S_RESET: begin
            counter_load=1; counter_load_value=WAIT_MEDIUM;
            next_state=S_SHOW_UL;
        end
        S_SHOW_UL: begin
            dis_sel=D_UL;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_ECE;
            end
        end
        S_SHOW_ECE: begin
            dis_sel=D_ECE;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_MODULE;
            end
        end
        S_SHOW_MODULE: begin
            dis_sel=D_MODULE;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_ID;
            end
        end
        S_SHOW_ID: begin
            dis_sel=D_ID;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_DESIGN;
            end
        end
        S_SHOW_DESIGN: begin
            dis_sel=D_LAB;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_MEDIUM;
                next_state=S_SHOW_DATA;
            end
        end
        S_SHOW_DATA: begin
            dis_sel=D_DATA;
            if ( counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_SHORT;
                tph_hundreds_saved <= tph_hundreds;
                tph_tens_saved <= tph_tens;
                tph_ones_saved <= tph_ones;
                freq_tens_saved <= freq_hundreds;
                        freq_tens_saved <= freq_tens;
                        freq_ones_saved <= freq_ones;
                if ( mbuttons[4] ) begin 
                    next_state=S_SHOW_RANDOM;
                end else if ( button_r | mbuttons[0] ) begin
                    next_state=S_SHOW_BLINKDATA;
                end else if ( mbuttons[1] ) begin
                    next_state=S_SHOW_BLINKDATA_5;
                end
            end
        end
        S_SHOW_BLINKDATA: begin
            dis_sel=D_BLINKDATA;
            if ( counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_SHORT;
                if ( button_r | mbuttons[0] ) begin
                    next_state=S_SHOW_BLINKDATA_2;
                end else if ( mbuttons[1] | mbuttons[4] | mbuttons[5] ) begin
                    next_state=S_SHOW_DATA;
                end
            end
        end
        S_SHOW_BLINKDATA_2: begin
            dis_sel=D_BLINKDATA_2;
            if ( counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_SHORT;
                if ( mbuttons[1] ) begin
                    next_state=S_SHOW_BLINKDATA;
                end else if ( button_r | mbuttons[0] ) begin
                    next_state=S_SHOW_BLINKDATA_3;
                end else if ( mbuttons[4] | mbuttons[5] ) begin
                    next_state=S_SHOW_DATA;
                end 
            end
        end
        S_SHOW_BLINKDATA_3: begin
            dis_sel=D_BLINKDATA_3;
            if ( counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_SHORT;
                if ( mbuttons[1] ) begin
                    next_state=S_SHOW_BLINKDATA_2;
                end else if ( button_r | mbuttons[0] ) begin
                    next_state=S_SHOW_BLINKDATA_4;
                end else if ( mbuttons[4] | mbuttons[5] ) begin
                    next_state=S_SHOW_DATA;
                end 
            end
        end
        S_SHOW_BLINKDATA_4: begin
            dis_sel=D_BLINKDATA_4;
            if ( counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_SHORT;
                if ( mbuttons[1] ) begin
                    next_state=S_SHOW_BLINKDATA_3;
                end else if ( button_r | mbuttons[0] ) begin
                    next_state=S_SHOW_BLINKDATA_5;
                end else if ( mbuttons[4] | mbuttons[5] ) begin
                    next_state=S_SHOW_DATA;
                end 
            end
        end
        S_SHOW_BLINKDATA_5: begin
            dis_sel=D_BLINKDATA_5;
            if ( counter_zero ) begin
                counter_load=1; counter_load_value=WAIT_SHORT;
                if ( mbuttons[1] ) begin
                    next_state=S_SHOW_BLINKDATA_4;
                end else if ( button_r | mbuttons[0] | mbuttons[4] | mbuttons[5] ) begin
                    next_state=S_SHOW_DATA;
                end 
            end
        end
        S_SHOW_RANDOM: begin
            dis_sel=D_RANDOM;
            if ( counter_zero & ( button | button_r | mbuttons ) ) begin
                if ( button || button_r || mbuttons  ) begin
                    counter_load=1; counter_load_value=WAIT_SHORT;
                    next_state=S_SHOW_DATA; end

            end
        end
        default: begin
            next_state=S_RESET;
        end
    endcase
end

endmodule