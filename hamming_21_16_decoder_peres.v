`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 02:03:33 PM
// Design Name: 
// Module Name: hamming_21_16_decoder_peres
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


module hamming_21_16_decoder_peres (
    input  wire [20:0] encoded_in,
    output wire [15:0] data_out,
    output wire error_detected,
    output wire error_corrected,
    output wire [39:0] garbage_out
);
    
    wire p1_rx  = encoded_in[0];
    wire p2_rx  = encoded_in[1];
    wire p4_rx  = encoded_in[3];
    wire p8_rx  = encoded_in[7];
    wire p16_rx = encoded_in[15];
    
    wire [15:0] data_rx = {
        encoded_in[20], encoded_in[19], encoded_in[18], encoded_in[17],
        encoded_in[16], encoded_in[14], encoded_in[13], encoded_in[12],
        encoded_in[11], encoded_in[10], encoded_in[9],  encoded_in[8],
        encoded_in[6],  encoded_in[5],  encoded_in[4],  encoded_in[2]
    };
    
    
    wire [9:0] p1_calc_inputs = {data_rx[15], data_rx[13], data_rx[11], data_rx[10], data_rx[8], data_rx[6], data_rx[4], data_rx[3], data_rx[1], data_rx[0]};
    wire p1_calc;
    wire [9:0] p1_calc_garbage;
    peres_multi_xor #(.WIDTH(10)) recalc_p1 (
        .inputs(p1_calc_inputs), .result(p1_calc), .garbage(p1_calc_garbage)
    );
    
    wire [8:0] p2_calc_inputs = {data_rx[13], data_rx[12], data_rx[10], data_rx[9], data_rx[6], data_rx[5], data_rx[3], data_rx[2], data_rx[0]};
    wire p2_calc;
    wire [8:0] p2_calc_garbage;
    peres_multi_xor #(.WIDTH(9)) recalc_p2 (
        .inputs(p2_calc_inputs), .result(p2_calc), .garbage(p2_calc_garbage)
    );
    
    wire [8:0] p4_calc_inputs = {data_rx[15], data_rx[14], data_rx[10], data_rx[9], data_rx[8], data_rx[7], data_rx[3], data_rx[2], data_rx[1]};
    wire p4_calc;
    wire [8:0] p4_calc_garbage;
    peres_multi_xor #(.WIDTH(9)) recalc_p4 (
        .inputs(p4_calc_inputs), .result(p4_calc), .garbage(p4_calc_garbage)
    );
    
    wire [6:0] p8_calc_inputs = {data_rx[10], data_rx[9], data_rx[8], data_rx[7], data_rx[6], data_rx[5], data_rx[4]};
    wire p8_calc;
    wire [6:0] p8_calc_garbage;
    peres_multi_xor #(.WIDTH(7)) recalc_p8 (
        .inputs(p8_calc_inputs), .result(p8_calc), .garbage(p8_calc_garbage)
    );
    
    wire [4:0] p16_calc_inputs = {data_rx[15], data_rx[14], data_rx[13], data_rx[12], data_rx[11]};
    wire p16_calc;
    wire [4:0] p16_calc_garbage;
    peres_multi_xor #(.WIDTH(5)) recalc_p16 (
        .inputs(p16_calc_inputs), .result(p16_calc), .garbage(p16_calc_garbage)
    );
    
    
    wire [4:0] syndrome = {
        p16_calc ^ p16_rx,
        p8_calc  ^ p8_rx,
        p4_calc  ^ p4_rx,
        p2_calc  ^ p2_rx,
        p1_calc  ^ p1_rx
    };
    
    assign error_detected = (syndrome != 5'b00000);
    assign error_corrected = error_detected;
    
   
    wire [15:0] data_corrected;
    assign data_corrected[0]  = (syndrome == 5'd3)  ? ~data_rx[0]  : data_rx[0];
    assign data_corrected[1]  = (syndrome == 5'd5)  ? ~data_rx[1]  : data_rx[1];
    assign data_corrected[2]  = (syndrome == 5'd6)  ? ~data_rx[2]  : data_rx[2];
    assign data_corrected[3]  = (syndrome == 5'd7)  ? ~data_rx[3]  : data_rx[3];
    assign data_corrected[4]  = (syndrome == 5'd9)  ? ~data_rx[4]  : data_rx[4];
    assign data_corrected[5]  = (syndrome == 5'd10) ? ~data_rx[5]  : data_rx[5];
    assign data_corrected[6]  = (syndrome == 5'd11) ? ~data_rx[6]  : data_rx[6];
    assign data_corrected[7]  = (syndrome == 5'd12) ? ~data_rx[7]  : data_rx[7];
    assign data_corrected[8]  = (syndrome == 5'd13) ? ~data_rx[8]  : data_rx[8];
    assign data_corrected[9]  = (syndrome == 5'd14) ? ~data_rx[9]  : data_rx[9];
    assign data_corrected[10] = (syndrome == 5'd15) ? ~data_rx[10] : data_rx[10];
    assign data_corrected[11] = (syndrome == 5'd17) ? ~data_rx[11] : data_rx[11];
    assign data_corrected[12] = (syndrome == 5'd18) ? ~data_rx[12] : data_rx[12];
    assign data_corrected[13] = (syndrome == 5'd19) ? ~data_rx[13] : data_rx[13];
    assign data_corrected[14] = (syndrome == 5'd20) ? ~data_rx[14] : data_rx[14];
    assign data_corrected[15] = (syndrome == 5'd21) ? ~data_rx[15] : data_rx[15];
    
    assign data_out = data_corrected;
    assign garbage_out = {p16_calc_garbage, p8_calc_garbage, p4_calc_garbage,p2_calc_garbage, p1_calc_garbage};
endmodule