// ========================================================================
//Filename        : ripple_full_adder.v
//Project         : Ripple Carry Adder 
//Author          : R Hariharan
//Date            : 24-04-2025
// ========================================================================
//Abstract   : Uses operational full adders to create a ripple carry adder for Signed Magnitude and 2s complement
//             
// ========================================================================

`timescale 1ns/1ps

module full_adder  
(
  a_in,
  b_in,
  c_in,
  s,
  c_out
);

//////////////////////////////////////
// Top Level port list declaration
//////////////////////////////////////

// input ports
input      a_in;
input      b_in;
input      c_in;

// output ports
output     s;
output     c_out;

//////////////////////////////////////
// Reg/Wire Declarations
//////////////////////////////////////

wire       axorb;
wire       aandb;
wire       axorbandcin;

//////////////////////////////////////
// Logic
//////////////////////////////////////

  // Sum
  assign axorb = a_in ^ b_in;
  assign s = axorb ^ c_in;

  // Carry Out
  assign aandb = a_in & b_in;
  assign axorbandcin = axorb & c_in;
  assign c_out = aandb | axorbandcin;

endmodule


module full_adder_array # (
  parameter ADDER_WIDTH =32 
) 
(
  faa_a_in,
  faa_b_in,
  faa_c_in,
  faa_sum,
  faa_cout
);


//////////////////////////////////////
// Top Level port list declaration
//////////////////////////////////////

// input ports
input  [ADDER_WIDTH-1:0] faa_a_in;
input  [ADDER_WIDTH-1:0] faa_b_in;
input                    faa_c_in;

// output ports
output [ADDER_WIDTH-1:0] faa_sum;
output                   faa_cout;

//////////////////////////////////////
// Reg/Wire Declarations
//////////////////////////////////////

wire [ADDER_WIDTH-1:0] faa_cout_w;

//////////////////////////////////////
// Logic
//////////////////////////////////////

  // array of full adders
  generate
  genvar i;
    for (i = 0; i < ADDER_WIDTH; i = i+1)
    begin
      if (i == 0) // first instance, c_in connected to faa_c_in       
        full_adder i_full_adder
        (
         .a_in(faa_a_in[i]),
         .b_in(faa_b_in[i]),
         .c_in(faa_c_in),
         .s(faa_sum[i]),
         .c_out(faa_cout_w[i])
        );
      else      
        full_adder i_full_adder
        (
         .a_in(faa_a_in[i]),
         .b_in(faa_b_in[i]),
         .c_in(faa_cout_w[i-1]),
         .s(faa_sum[i]),
         .c_out(faa_cout_w[i])
        );
    end
  endgenerate
  assign faa_cout = faa_cout_w[ADDER_WIDTH-1];
endmodule


module farc_addsub # (parameter ADDER_WIDTH =32) 
 (
  fa_a_in,
  fa_b_in,
  sm2c_sel,  // SM2C = 0 -> 2s complement, SM2C =1 -> Signed magnitude
  addsub_sel, // addsub_sel = 0 -> add, addsub_sel = 1 -> subtract
  fa_sum_out,
  fa_carry_out,
        fa_overflow
 );

input [ADDER_WIDTH-1:0] fa_a_in;
input [ADDER_WIDTH-1:0] fa_b_in;
input                   sm2c_sel;
input                   addsub_sel; // If 0 -> add. If 1 -> Subtract

output reg[ADDER_WIDTH-1:0] fa_sum_out;
output reg                 fa_carry_out;
output reg                 fa_overflow;

// Wire declarations
wire a2c_w; // Control signal for 2's complement conversion of input A. eff sign A
wire b2c_w; // Control signal for 2's complement conversion of input B. eff sign B
wire [ADDER_WIDTH-1:0] fa_oneC; // One's complement of input A
wire [ADDER_WIDTH-1:0] fb_oneC; // One's complement of input B
wire [ADDER_WIDTH-1:0] fa_twoC; // Two's complement of input A
wire [ADDER_WIDTH-1:0] fb_twoC; // Two's complement of input B

wire [ADDER_WIDTH-1:0] adder_in_a; // Final input A to the adder
wire [ADDER_WIDTH-1:0] adder_in_b; // Final input B to the adder

wire [ADDER_WIDTH:0] fa_sum_2c; // Sum output from the adder in 2's complement form

wire [ADDER_WIDTH-1:0] carry_int; // Internal carry signals for the ripple carry adder

wire [ADDER_WIDTH-1:0] fa_sum;         // Output from the main adder
wire [ADDER_WIDTH:0] fa_sum_1c;        // One's complement of sum for 2C conversion

wire tc_overflow;                      // Two's complement overflow flag
reg carry_temp;

assign a2c_w = fa_a_in[ADDER_WIDTH-1];
assign b2c_w = fa_b_in[ADDER_WIDTH-1] ^ addsub_sel; // If subtracting, we need to take 2's complement of B

assign fa_oneC = sm2c_sel ? {1'b1, ~fa_a_in[ADDER_WIDTH-2:0]} : ~fa_a_in; // One's complement of A
assign fb_oneC = sm2c_sel ? {1'b1, ~fa_b_in[ADDER_WIDTH-2:0]} : ~fa_b_in; // One's complement of B

// 2's complement of A and B
full_adder_array # (
        .ADDER_WIDTH(ADDER_WIDTH)
    ) 
    A_two_comp_adder
    (
        .faa_a_in(fa_oneC),
        .faa_b_in({ADDER_WIDTH{1'b0}}),
        .faa_c_in(1'b1), // Carry in for the first full adder
        .faa_sum(fa_twoC),
        .faa_cout()
    );

full_adder_array # (
        .ADDER_WIDTH(ADDER_WIDTH)
    )
    B_two_comp_adder
    (
        .faa_a_in(fb_oneC),
        .faa_b_in({ADDER_WIDTH{1'b0}}),
        .faa_c_in(1'b1), // Carry in for the first full adder
        .faa_sum(fb_twoC),
        .faa_cout()
    );

assign adder_in_a = (sm2c_sel && a2c_w) ? fa_twoC : fa_a_in; // Input A to the adder
assign adder_in_b = ((sm2c_sel && b2c_w) || (!sm2c_sel && addsub_sel)) ? fb_twoC : (sm2c_sel ? {1'b0,fa_b_in[ADDER_WIDTH-2:0]} : fa_b_in); // Input B to the adder. effective -ve in SM or sub in 2c

// Main adder module
generate
        genvar i;
    for (i = 0; i < ADDER_WIDTH; i = i+1)
    begin
        if (i == 0) // first instance, c_in is given 0       
        full_adder i_full_adder
        (
            .a_in(adder_in_a[i]),
            .b_in(adder_in_b[i]),
            .c_in(1'b0),
            .s(fa_sum[i]),
            .c_out(carry_int[i])
        );
        else      
        full_adder i_full_adder
        (
            .a_in(adder_in_a[i]),
            .b_in(adder_in_b[i]),
            .c_in(carry_int[i-1]),
            .s(fa_sum[i]),
            .c_out(carry_int[i])
        );
    end
endgenerate

// For 2's complement: overflow occurs when operands have same sign but result has different sign
assign tc_overflow = carry_int[ADDER_WIDTH-2] ^ carry_int[ADDER_WIDTH-1];

// Sum 2c adder
assign fa_sum_1c = ~{carry_int[ADDER_WIDTH-1],fa_sum};
full_adder_array # (
        .ADDER_WIDTH(ADDER_WIDTH+1)
    ) 
    sum_2c_adder
    (
        .faa_a_in(fa_sum_1c),
        .faa_b_in({ADDER_WIDTH+1{1'b0}}),
        .faa_c_in(1'b1), // Carry in for the first full adder
        .faa_sum(fa_sum_2c),
        .faa_cout()
    );
// Sign and magnitude adjust for SM and 2C conversion
always @(*) begin
    if(sm2c_sel) 
    begin
        if (tc_overflow)
        begin
            if(fa_sum[ADDER_WIDTH-1])
            begin // Positive overflow
          {carry_temp,fa_sum_out} = {carry_int[ADDER_WIDTH-1], fa_sum[ADDER_WIDTH-1:0]}; // 2C to SM
            end 
            else 
            begin // Negative overflow
              {carry_temp,fa_sum_out} = {carry_int[ADDER_WIDTH-1],fa_sum_2c[ADDER_WIDTH-1:0]}; // 2C to SM
            end
        end 
        else if (fa_sum[ADDER_WIDTH-1]) 
        begin // Negative result
            {carry_temp,fa_sum_out} = {carry_int[ADDER_WIDTH-1],1'b1, fa_sum_2c[ADDER_WIDTH-2:0]}; // 2C to SM
        end
        else
        begin // Positive result
            {carry_temp,fa_sum_out} = {carry_int[ADDER_WIDTH-1], fa_sum[ADDER_WIDTH-1:0]}; // SM to 2C
        end        
    end
    else 
    begin
        {carry_temp,fa_sum_out} = {carry_int[ADDER_WIDTH-1], fa_sum[ADDER_WIDTH-1:0]}; // 2C to SM
    end
end
assign fa_carry_out = fa_overflow && carry_temp;
assign fa_overflow = tc_overflow; // Select appropriate overflow based on format
endmodule 