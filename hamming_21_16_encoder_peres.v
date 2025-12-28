`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/28/2025 06:05:14 PM
// Design Name: 
// Module Name: hamming_21_16_encoder_peres
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module hamming_21_16_encoder_peres (
    input  wire [15:0] data_in,
    output wire [20:0] encoded,
    output wire [39:0] garbage_out
);
    
    wire [9:0] p1_inputs = {data_in[15], data_in[13], data_in[11], data_in[10], data_in[8], data_in[6], data_in[4], data_in[3], data_in[1], data_in[0]};
    wire p1;
    wire [9:0] p1_garbage;
    peres_multi_xor #(.WIDTH(10)) calc_p1 (
        .inputs(p1_inputs), .result(p1), .garbage(p1_garbage)
    );
    
    
    wire [8:0] p2_inputs = {data_in[13], data_in[12], data_in[10], data_in[9], data_in[6], data_in[5], data_in[3], data_in[2], data_in[0]};
    wire p2;
    wire [8:0] p2_garbage;
    peres_multi_xor #(.WIDTH(9)) calc_p2 (
        .inputs(p2_inputs), .result(p2), .garbage(p2_garbage)
    );
    
   
    wire [8:0] p4_inputs = {data_in[15], data_in[14], data_in[10], data_in[9], data_in[8], data_in[7], data_in[3], data_in[2], data_in[1]};
    wire p4;
    wire [8:0] p4_garbage;
    peres_multi_xor #(.WIDTH(9)) calc_p4 (
        .inputs(p4_inputs), .result(p4), .garbage(p4_garbage)
    );
    
    
    wire [6:0] p8_inputs = {data_in[10], data_in[9], data_in[8], data_in[7], data_in[6], data_in[5], data_in[4]};
    wire p8;
    wire [6:0] p8_garbage;
    peres_multi_xor #(.WIDTH(7)) calc_p8 (
        .inputs(p8_inputs), .result(p8), .garbage(p8_garbage)
    );
    
    
    wire [4:0] p16_inputs = {data_in[15], data_in[14], data_in[13], data_in[12], data_in[11]};
    wire p16;
    wire [4:0] p16_garbage;
    peres_multi_xor #(.WIDTH(5)) calc_p16 (
        .inputs(p16_inputs), .result(p16), .garbage(p16_garbage)
    );
    
    
    assign encoded = {
        data_in[15], data_in[14], data_in[13], data_in[12], data_in[11], p16, data_in[10], data_in[9], data_in[8], data_in[7], data_in[6], data_in[5], data_in[4], p8, data_in[3], data_in[2], data_in[1], p4, data_in[0], p2, p1
    };
    
    assign garbage_out = {p16_garbage, p8_garbage, p4_garbage, p2_garbage, p1_garbage};
endmodule
