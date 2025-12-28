`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2025 07:50:23 PM
// Design Name: 
// Module Name: db_project
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
/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_db_MAC (
    // Standard Tiny Tapeout interface
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n,

    // Error detection/correction ports
    input  wire       err_clear,       // Clear latched errors and count
    output wire       err_mult,        // Multiplier error detected (latched)
    output wire       err_adder,       // Adder error detected (latched)
    output wire       err_tmr,         // TMR mismatch detected (latched)
    output wire       err_corrected,   // TMR corrected error (current cycle)
    output wire [3:0] err_count,       // Rolling error count (saturates at 15)
    output wire [7:0] err_last_cycle   // Cycle when last error occurred
);

reg [7:0] reg_a, reg_b;
wire [15:0] W, Sum;
wire mult_parity_err, adder_parity_err;

// TMR accumulator registers
reg [15:0] Out_0, Out_1, Out_2;
wire [15:0] Out_voted;
wire tmr_error, tmr_corrected;

// Error status registers
reg [3:0] error_count;
reg [7:0] last_error_cycle;
reg [7:0] cycle_counter;
reg err_mult_latched, err_adder_latched, err_tmr_latched;

assign uio_oe = clk ? 8'hFF : 8'h00;

// Input sampling on posedge
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_a <= 8'b0;
        reg_b <= 8'b0;
    end else begin
        reg_a <= ui_in;
        reg_b <= uio_in;
    end
end

// Cycle counter for error logging
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cycle_counter <= 8'b0;
    end else begin
        cycle_counter <= cycle_counter + 8'b1;
    end
end

// Vedic multiplier with parity error detection
vedic_8bit_multiplier_ecc m1(
    .A(reg_a),
    .B(reg_b),
    .P(W),
    .parity_error(mult_parity_err)
);

// Reversible 16-bit adder with parity checking
reversible_16bit_adder_ecc a1(
    .A(Out_voted),
    .B(W),
    .Cin(1'b0),
    .Sum(Sum),
    .parity_error(adder_parity_err)
);

// TMR Majority Voter
tmr_voter #(.WIDTH(16)) voter_inst (
    .in0(Out_0),
    .in1(Out_1),
    .in2(Out_2),
    .out(Out_voted),
    .error(tmr_error),
    .corrected(tmr_corrected)
);

// TMR accumulator update on negedge
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Out_0 <= 16'b0;
        Out_1 <= 16'b0;
        Out_2 <= 16'b0;
    end else begin
        Out_0 <= Sum;
        Out_1 <= Sum;
        Out_2 <= Sum;
    end
end

// Error latching and counting
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        error_count <= 4'b0;
        last_error_cycle <= 8'b0;
        err_mult_latched <= 1'b0;
        err_adder_latched <= 1'b0;
        err_tmr_latched <= 1'b0;
    end else if (err_clear) begin
        err_mult_latched <= 1'b0;
        err_adder_latched <= 1'b0;
        err_tmr_latched <= 1'b0;
        error_count <= 4'b0;
    end else begin
        if (mult_parity_err) err_mult_latched <= 1'b1;
        if (adder_parity_err) err_adder_latched <= 1'b1;
        if (tmr_error) err_tmr_latched <= 1'b1;

        if (mult_parity_err || adder_parity_err || tmr_error) begin
            if (error_count != 4'hF) error_count <= error_count + 4'b1;
            last_error_cycle <= cycle_counter;
        end
    end
end

// MAC result output (always active, parallel with error detection)
assign {uio_out, uo_out} = Out_voted;

// Error status outputs
assign err_mult       = err_mult_latched;
assign err_adder      = err_adder_latched;
assign err_tmr        = err_tmr_latched;
assign err_corrected  = tmr_corrected;
assign err_count      = error_count;
assign err_last_cycle = last_error_cycle;

wire _unused = &{ena, 1'b0};

endmodule


//=============================================================================
// TMR Majority Voter
//=============================================================================
module tmr_voter #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    input  wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] out,
    output wire error,
    output wire corrected
);

// Bitwise majority vote: out[i] = (in0[i] & in1[i]) | (in1[i] & in2[i]) | (in0[i] & in2[i])
assign out = (in0 & in1) | (in1 & in2) | (in0 & in2);

// Error if any input differs from voted output
wire err0 = |(in0 ^ out);
wire err1 = |(in1 ^ out);
wire err2 = |(in2 ^ out);

assign error = err0 | err1 | err2;

// Corrected if exactly one differs (single bit flip correctable)
assign corrected = error && ((err0 && !err1 && !err2) ||
                             (!err0 && err1 && !err2) ||
                             (!err0 && !err1 && err2));

endmodule


module BVPPG_gate (
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    input  wire E,
    output wire P,
    output wire Q,
    output wire R,
    output wire S,
    output wire T
);

wire [1:0]X;

buf b1(P, A);
buf b2(Q, B);
and a1(X[0], A, B);
xor x1(R, X[0], C);
buf b3(S, D);
and a2(X[1], A, D);
xor x3(T, X[1], E);

endmodule


module feynman_gate (
    input  wire A,
    input  wire B,
    output wire P,
    output wire Q
);

buf b1(P, A);
xor x1(Q, A, B);

endmodule


module peres_gate (
    input  wire A,
    input  wire B,
    input  wire C,
    output wire P,
    output wire Q,
    output wire R
);

wire X;

buf b1(P, A);
xor x1(Q, A, B);
and a1(X, A, B);
xor x2(R, X, C);

endmodule

module reversible_12bit_adder (
    input  wire [11:0] A,
    input  wire [11:0] B,
    input  wire [11:0] C,
    output wire [11:0] Sum
);

wire [11:0] sum1, carry1;
wire [2:0] carry2;

// First stage: CSA for 3 inputs A, B, C (bit-wise)
reversible_full_adder fa0 (A[0],  B[0],  C[0],  1'b0, sum1[0],  carry1[0]);
reversible_full_adder fa1 (A[1],  B[1],  C[1],  1'b0, sum1[1],  carry1[1]);
reversible_full_adder fa2 (A[2],  B[2],  C[2],  1'b0, sum1[2],  carry1[2]);
reversible_full_adder fa3 (A[3],  B[3],  C[3],  1'b0, sum1[3],  carry1[3]);
reversible_full_adder fa4 (A[4],  B[4],  C[4],  1'b0, sum1[4],  carry1[4]);
reversible_full_adder fa5 (A[5],  B[5],  C[5],  1'b0, sum1[5],  carry1[5]);
reversible_full_adder fa6 (A[6],  B[6],  C[6],  1'b0, sum1[6],  carry1[6]);
reversible_full_adder fa7 (A[7],  B[7],  C[7],  1'b0, sum1[7],  carry1[7]);
reversible_full_adder fa8 (A[8],  B[8],  C[8],  1'b0, sum1[8],  carry1[8]);
reversible_full_adder fa9 (A[9],  B[9],  C[9],  1'b0, sum1[9],  carry1[9]);
reversible_full_adder fa10(A[10], B[10], C[10], 1'b0, sum1[10], carry1[10]);
reversible_full_adder fa11(A[11], B[11], C[11], 1'b0, sum1[11], carry1[11]);

assign Sum[0] = sum1[0];

// Second stage: add sum1 + (carry1 << 1)
reversible_6bit_adder fa13(sum1[6:1], carry1[5:0], 6'b0, Sum[6:1], carry2[0]);
reversible_6bit_adder fa14({1'b0, sum1[11:7]}, carry1[11:6], {5'b0, carry2[0]}, {carry2[2], Sum[11:7]}, carry2[1]);

wire _unused = &{carry2[2:1]};

endmodule


module reversible_16bit_adder (
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire        Cin,
    output wire [15:0] Sum
);

wire [3:0] C;

reversible_4bit_adder fa0 (A[3:0],   B[3:0],   Cin,  Sum[3:0],   C[0]);
reversible_4bit_adder fa1 (A[7:4],   B[7:4],   C[0], Sum[7:4],   C[1]);
reversible_4bit_adder fa2 (A[11:8],  B[11:8],  C[1], Sum[11:8],  C[2]);
reversible_4bit_adder fa3 (A[15:12], B[15:12], C[2], Sum[15:12], C[3]);

wire _unused = &{C[3]};

endmodule


module reversible_4bit_adder (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Carry
);

// Intermediate wires for full adders
wire [2:0] C;

// Instantiation of reversible full adders
    reversible_full_adder fa0 (A[0], B[0], Cin,  1'b0, Sum[0], C[0]);
    reversible_full_adder fa1 (A[1], B[1], C[0], 1'b0, Sum[1], C[1]);
    reversible_full_adder fa2 (A[2], B[2], C[1], 1'b0, Sum[2], C[2]);
    reversible_full_adder fa3 (A[3], B[3], C[2], 1'b0, Sum[3], Carry);

endmodule



module reversible_6bit_adder (
    input  wire [5:0] A,
    input  wire [5:0] B,
    input  wire [5:0] C,
    output wire [5:0] Sum,
    output wire       Carry
);

// Intermediate wires for full adders
wire [5:0] sum1, carry1;
wire [5:0] carry2;


// First stage of full adders
reversible_full_adder fa0(A[0], B[0], C[0], 1'b0, sum1[0], carry1[0]);
reversible_full_adder fa1(A[1], B[1], C[1], 1'b0, sum1[1], carry1[1]);
reversible_full_adder fa2(A[2], B[2], C[2], 1'b0, sum1[2], carry1[2]);
reversible_full_adder fa3(A[3], B[3], C[3], 1'b0, sum1[3], carry1[3]);
reversible_full_adder fa4(A[4], B[4], C[4], 1'b0, sum1[4], carry1[4]);
reversible_full_adder fa5(A[5], B[5], C[5], 1'b0, sum1[5], carry1[5]);

buf b1(Sum[0], sum1[0]);

// Second stage of full adders
reversible_full_adder fa7(sum1[1], carry1[0], 1'b0, 1'b0, Sum[1], carry2[0]);
reversible_full_adder fa8(sum1[2], carry1[1], carry2[0], 1'b0, Sum[2], carry2[1]);
reversible_full_adder fa9(sum1[3], carry1[2], carry2[1], 1'b0, Sum[3], carry2[2]);
reversible_full_adder fa10(sum1[4], carry1[3], carry2[2], 1'b0, Sum[4], carry2[3]);
reversible_full_adder fa11(sum1[5], carry1[4], carry2[3], 1'b0, Sum[5], carry2[4]);
reversible_full_adder fa12(1'b0, carry1[5], carry2[4], 1'b0,  Carry, carry2[5]);

	wire _unused = &{carry2[5]};
endmodule


// Reversible full adder
module reversible_full_adder (
    input  wire A,
    input  wire B,
    input  wire Cin,
    input  wire Ctrl,
    output wire S,
    output wire Cout
);

wire [1:0] garbage;
wire [1:0] n;

peres_gate p1(A, B, Ctrl, garbage[0], n[0], n[1]);
peres_gate p2(n[0], Cin, n[1], garbage[1], S, Cout);

wire _unused = &{garbage};

endmodule


module vedic_2bit_multiplier(
    input wire [1:0] A, B,
    output wire [3:0] P
);

	wire [4:0]g;
	wire [3:1]i;
	wire [3:0]a;
	 
	 BVPPG_gate b1(A[0], B[0], 1'b0, B[1], 1'b0, g[0], i[1], P[0], i[2], a[0]);
	 peres_gate p1(A[1], i[1], 1'b0, i[3], g[1], a[1]);
	 peres_gate p2(i[3], i[2], 1'b0, g[2], g[3], a[2]);
	 peres_gate p3(a[0], a[1], 1'b0, g[4], P[1], a[3]);
	 feynman_gate f1(a[3], a[2], P[3], P[2]);

	wire _unused = &{g[4:0]};
	 

endmodule

// 4x4 Vedic Multiplier used for partial products
module vedic_4bit_multiplier (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] P
);

    // Intermediate partial products
    wire [3:0] P1, P2, P3;
    wire [3:2] P0;
    wire temp;

    // 2x2 Vedic Multipliers for 4x4 multiplication
    vedic_2bit_multiplier U0 (A[1:0], B[1:0], {P0[3:2], P[1:0]});
    vedic_2bit_multiplier U1 (A[1:0], B[3:2], P1[3:0]);
    vedic_2bit_multiplier U2 (A[3:2], B[1:0], P2[3:0]);
    vedic_2bit_multiplier U3 (A[3:2], B[3:2], P3[3:0]);
    
    reversible_6bit_adder a1({P3, P0[3:2]}, {2'b0, P2}, {2'b0, P1}, P[7:2], temp);
    
    wire _unused = &{temp};

endmodule


module vedic_8bit_multiplier (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [15:0] P
);

    wire [7:0]  P1, P2, P3;
    wire [7:4]  P0;

    vedic_4bit_multiplier U0 (A[3:0], B[3:0], {P0[7:4], P[3:0]});
    vedic_4bit_multiplier U1 (A[3:0], B[7:4], P1[7:0]);
    vedic_4bit_multiplier U2 (A[7:4], B[3:0], P2[7:0]);
    vedic_4bit_multiplier U3 (A[7:4], B[7:4], P3[7:0]);

    reversible_12bit_adder a1({P3, P0[7:4]}, {4'b0, P2}, {4'b0, P1}, P[15:4]);

endmodule


//=============================================================================
// ECC Wrapper: Vedic 8-bit Multiplier with Parity Error Detection
//=============================================================================
module vedic_8bit_multiplier_ecc (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [15:0] P,
    output wire parity_error
);

// Main multiplier
vedic_8bit_multiplier mult_inst(.A(A), .B(B), .P(P));

// Shadow computation on 2-bit slices for verification
wire [3:0] shadow_p0;
vedic_2bit_multiplier shadow_u0(A[1:0], B[1:0], shadow_p0);

// Compare shadow result with main result LSBs
assign parity_error = (shadow_p0[1:0] != P[1:0]);

endmodule


//=============================================================================
// ECC Wrapper: Reversible 16-bit Adder with Parity Error Detection
//=============================================================================
module reversible_16bit_adder_ecc (
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire        Cin,
    output wire [15:0] Sum,
    output wire        parity_error
);

// Main adder
reversible_16bit_adder adder_inst(.A(A), .B(B), .Cin(Cin), .Sum(Sum));

// Shadow 4-bit adder for verification
wire [3:0] shadow_sum;
wire shadow_carry;
reversible_4bit_adder shadow_add(A[3:0], B[3:0], Cin, shadow_sum, shadow_carry);

assign parity_error = (shadow_sum != Sum[3:0]);

wire _unused_shadow = &{shadow_carry};

endmodule
