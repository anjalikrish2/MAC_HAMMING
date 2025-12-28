`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/27/2025 09:19:33 PM
// Design Name: 
// Module Name: peres_multi_xor
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
module peres_multi_xor #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] inputs,
    output wire result,
    output wire [WIDTH-1:0] garbage
);
    wire [WIDTH:0] cascade;
    assign cascade[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) 
        begin : xor_chain
            wire p_temp = cascade[i];
            wire q_temp = cascade[i] ^ inputs[i];
            wire r_temp = (cascade[i] & inputs[i]);
            
            assign cascade[i+1] = q_temp;
            assign garbage[i] = r_temp;
        end
    endgenerate
    
    assign result = cascade[WIDTH];
endmodule
