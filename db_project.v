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
    output wire       err_detected,    // Error detected in current cycle
    output wire       err_corrected,   // Error corrected in current cycle
    output wire [3:0] err_count,       // Rolling error count (saturates at 15)
    output wire [7:0] err_last_cycle   // Cycle when last error occurred
);

reg [7:0] reg_a, reg_b;
wire [15:0] W, Sum;

// Hammming encoding/decoding signals
wire [20:0] Out_encoded;
wire [15:0] Out_decoded;
wire hamming_err_detected, hamming_err_corrected;
reg [20:0] Out_encoded_reg;

// Error status registers
reg [3:0] error_count;
reg [7:0] last_error_cycle;
reg [7:0] cycle_counter;

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

// Vedic multiplier
vedic_8bit_multiplier m1(
    .A(reg_a),
    .B(reg_b),
    .P(W)
);

// Reversible 16-bit adder
reversible_16bit_adder a1(
    .A(Out_decoded),
    .B(W),
    .Cin(1'b0),
    .Sum(Sum)
);

// Hamming encoder for accumulator storage
hamming_21_16_encoder_peres encoder_inst(
    .data_in(Sum),
    .encoded(Out_encoded),
    .garbage_out()
);

// Hamming decoder for accumulator retrieval
hamming_21_16_decoder_peres decoder_inst(
    .encoded_in(Out_encoded_reg),
    .data_out(Out_decoded),
    .error_detected(hamming_err_detected),
    .error_corrected(hamming_err_corrected),
    .garbage_out()
);

always @(negedge clk or negedge rst_n) begin
    if (!rst_n)
        Out_encoded_reg <= 21'd0;
    else
        Out_encoded_reg <= Out_encoded;
end

// Error latching and counting
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        error_count <= 4'b0;
        last_error_cycle <= 8'b0;
    end else if (err_clear) begin
        error_count <= 4'b0;
    end else begin
        if (hamming_err_detected) begin
            if (error_count != 4'hF)
                error_count <= error_count + 1;
            last_error_cycle <= cycle_counter;
        end
    end
end

// MAC result output (always active, parallel with error detection)
assign {uio_out, uo_out} = Out_decoded;

// Error status outputs
assign err_detected   = hamming_err_detected;
assign err_corrected  = hamming_err_corrected;
assign err_count      = error_count;
assign err_last_cycle = last_error_cycle;

wire _unused = &{ena, 1'b0};

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
