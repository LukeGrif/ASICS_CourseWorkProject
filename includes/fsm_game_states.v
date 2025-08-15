//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Author: Karl Rinne
// Create Date: 22/06/2020
// Module Name: fsm_game.v (definition of states)
// Target Platform and Devices: generic
//////////////////////////////////////////////////////////////////////////////////

localparam              S_NOB=4;

localparam              S_SHOW_UL=0;
localparam              S_SHOW_ECE=1;
localparam              S_SHOW_MODULE=2;
localparam              S_SHOW_DESIGN=3;
localparam              S_SHOW_ID=4;
localparam              S_SHOW_DATA=5;
localparam              S_SHOW_BLINKDATA=6;
localparam              S_SHOW_BLINKDATA_2=7;
localparam              S_SHOW_RANDOM=8;
localparam              S_SHOW_BLINKDATA_3=9;
localparam              S_SHOW_BLINKDATA_4=10;
localparam              S_SHOW_BLINKDATA_5=11;
localparam              S_RESET=15;

localparam              D_UL=0; 
localparam              D_ECE=1; 
localparam              D_MODULE=2;
localparam              D_LAB=3; 
localparam              D_ID=4; 
localparam              D_DATA=5;
localparam              D_BLINKDATA=6;
localparam              D_RANDOM=8;
localparam              D_BLINKDATA_2=7;
localparam              D_BLINKDATA_3=9;
localparam              D_BLINKDATA_4=10;
localparam              D_BLINKDATA_5=11;

