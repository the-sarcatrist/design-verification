
// ========================================================================
//Filename        : farc_addsub.v
//Project         : Ripple Carry Adder 
//Author          : Rahul Prakash Joshi
//Date            : 19-02-2025
// ========================================================================
//Abstract   : Adder/Subtractor with inputs a, b and addsub_sel
//             Performs addition if addsub_sel = 0 else 
//             Perform subtraction if addsub_sel = 1
// ========================================================================

`timescale 1ns/1ps

module farc_addsub # (
  parameter SM2C = 1, // SM2C = 0 --> 2's Complement, SM2C = 1 --> Sign-Magnitude
  parameter ADDER_WIDTH = 32
) 
(
  fa_a_in,
  fa_b_in,
  sm2c_sel,
  addsub_sel,
  fa_sum_out,
  fa_carry_out
);

//////////////////////////////////////
// Top Level port list declaration
//////////////////////////////////////

// input ports
input  [ADDER_WIDTH-1:0]    fa_a_in;
input  [ADDER_WIDTH-1:0]    fa_b_in;
input                       sm2c_sel;
input                       addsub_sel;

// output ports
output [ADDER_WIDTH-1:0]    fa_sum_out;
output                      fa_carry_out;

//////////////////////////////////////
// Reg/Wire Declarations
//////////////////////////////////////

reg [ADDER_WIDTH-1:0]       as_sum_out_c;
reg                         as_carry_out_c;

wire [ADDER_WIDTH-1:0]      fa_axor_in;
wire [ADDER_WIDTH-1:0]      fa_bxor_in;
wire [ADDER_WIDTH-1:0]      carry_int;
wire [ADDER_WIDTH-1:0]      fa_sum_2c;
wire                        a2c_w;
wire                        b2c_w;
wire [ADDER_WIDTH-1:0]      as_a_2c;
wire                        as_a_carry_2c;
wire [ADDER_WIDTH-1:0]      as_b_2c;
wire                        as_b_carry_2c;
wire [ADDER_WIDTH-1:0]      as_a_2corin;
wire [ADDER_WIDTH-1:0]      as_b_2corin;
wire [ADDER_WIDTH-1:0]      sum_1c;
wire [ADDER_WIDTH-1:0]      sum_2c;
wire                        carry_2c;
wire                        ain_bin_xor;
wire                        ain_bin_and;
wire                        as_carry_out_w;

//////////////////////////////////////
// Logic
//////////////////////////////////////


  assign a2c_w = sm2c_sel & fa_a_in[ADDER_WIDTH-1];
  assign b2c_w = sm2c_sel & (fa_b_in[ADDER_WIDTH-1] ^ addsub_sel);

  // If sign-Magnitude format then the 2's Complement of -ve Inputs is needed
  generate
    if (SM2C)
    begin
      // 2's Complement of A if A is -ve
      // Sign bit as it is
      assign fa_axor_in[ADDER_WIDTH-1] = fa_a_in[ADDER_WIDTH-1];
      // 1's Complement of A
      assign fa_axor_in[ADDER_WIDTH-2:0] = {ADDER_WIDTH-1{1'b1}} ^ fa_a_in[ADDER_WIDTH-2:0];	     
      // 2C Adder for A
      full_adder_array # (
        .ADDER_WIDTH(ADDER_WIDTH)
      ) 
      a_full_adder_array
        (
         .faa_a_in(fa_axor_in),
         .faa_b_in({ADDER_WIDTH{1'b0}}),
         .faa_c_in(a2c_w),
         .faa_sum(as_a_2c),
         .faa_cout(as_a_carry_2c)
        );	    

      //2's Complement of B if B is -ve      
      // Sign bit as it is
      assign fa_bxor_in[ADDER_WIDTH-1] = addsub_sel ? b2c_w : fa_b_in[ADDER_WIDTH-1];
      // 1's Complement of B
      assign fa_bxor_in[ADDER_WIDTH-2:0] = {ADDER_WIDTH{1'b1}} ^ fa_b_in[ADDER_WIDTH-2:0];
      // 2C Adder for B
      full_adder_array  # (
        .ADDER_WIDTH(ADDER_WIDTH)
      )
      b_full_adder_array
        (
         .faa_a_in(fa_bxor_in),
         .faa_b_in({ADDER_WIDTH{1'b0}}),
         .faa_c_in(b2c_w),
         .faa_sum(as_b_2c),
         .faa_cout(as_b_carry_2c)
        );     
    end      
    else
    begin
      assign as_a_2c = {ADDER_WIDTH{1'b0}};	    
      assign as_a_carry_2c = 1'b0;
      assign as_b_2c = {ADDER_WIDTH{1'b0}};
      assign as_b_carry_2c = 1'b0;      
      assign as_a_xor = {ADDER_WIDTH{1'b0}};
      assign as_b_xor = {ADDER_WIDTH{1'b0}};
    end	    
  endgenerate	    

   
  assign as_a_2corin = a2c_w ? as_a_2c : fa_a_in;
  assign as_b_2corin = b2c_w ? as_b_2c : (addsub_sel ? {b2c_w,fa_b_in[ADDER_WIDTH-2:0]} : fa_b_in);

  // Operational Adder/Subtractor
  generate
  genvar i;
    for (i = 0; i < ADDER_WIDTH; i = i+1)
    begin
      if (i == 0) // first instance, c_in connected to addsub_sel	      
        full_adder i_full_adder
        (
         .a_in(as_a_2corin[i]),
         .b_in(as_b_2corin[i]),
         .c_in(1'b0),
         .s(fa_sum_2c[i]),
         .c_out(carry_int[i])
        );
      else      
        full_adder i_full_adder
        (
         .a_in(as_a_2corin[i]),
         .b_in(as_b_2corin[i]),
         .c_in(carry_int[i-1]),
         .s(fa_sum_2c[i]),
         .c_out(carry_int[i])
        );
    end
  endgenerate
 
  // If sign-Magnitude format then the 2's Complement of Sum is needed 
  generate
    if (SM2C)
    begin
      // 1's Complement of SUM
      assign sum_1c = {ADDER_WIDTH{1'b1}} ^ fa_sum_2c;
      // 2C Adder
      full_adder_array # (
        .ADDER_WIDTH(ADDER_WIDTH)
      ) 
      r_full_adder_array
        (
         .faa_a_in(sum_1c),
         .faa_b_in({ADDER_WIDTH{1'b0}}),
         .faa_c_in(1'b1),
         .faa_sum(sum_2c),
         .faa_cout(carry_2c)
        );      
    end
    else 
    begin
      assign sum_2c = {ADDER_WIDTH{1'b0}};
      assign carry_2c = 1'b0;
    end
  endgenerate

  // If Sign-Magnitude/2C format then the sign bit of result
  always @(*)
  begin
    if (sm2c_sel & ~addsub_sel) // SM ADDER
    begin
      if (fa_a_in[ADDER_WIDTH-2:0] > fa_b_in[ADDER_WIDTH-2:0]) // A > B
	as_sum_out_c[ADDER_WIDTH-1] = fa_a_in[ADDER_WIDTH-1];
      else if (fa_a_in[ADDER_WIDTH-2:0] < fa_b_in[ADDER_WIDTH-2:0]) // A < B
	as_sum_out_c[ADDER_WIDTH-1] = fa_b_in[ADDER_WIDTH-1];
      else // A = B
        as_sum_out_c[ADDER_WIDTH-1] = (fa_a_in[ADDER_WIDTH-1] ^ fa_b_in[ADDER_WIDTH-1]);	  
    end
    else if(sm2c_sel & addsub_sel) // SM SUBTRACTOR
    begin
      if (fa_a_in[ADDER_WIDTH-2:0] > fa_b_in[ADDER_WIDTH-2:0]) // A > B
        as_sum_out_c[ADDER_WIDTH-1] = fa_a_in[ADDER_WIDTH-1];
      else if (fa_a_in[ADDER_WIDTH-2:0] < fa_b_in[ADDER_WIDTH-2:0]) // A < B
      begin
        if (fa_a_in[ADDER_WIDTH-1] != fa_b_in[ADDER_WIDTH-1])
          as_sum_out_c[ADDER_WIDTH-1] = fa_a_in[ADDER_WIDTH-1];
        else // (fa_a_in[ADDER_WIDTH-1] = fa_b_in[ADDER_WIDTH-1])
          as_sum_out_c[ADDER_WIDTH-1] = ~(fa_a_in[ADDER_WIDTH-1] & fa_b_in[ADDER_WIDTH-1]);
      end
      else // A = B	 
      begin
        if (fa_a_in[ADDER_WIDTH-1] != fa_b_in[ADDER_WIDTH-1])
	  as_sum_out_c[ADDER_WIDTH-1] = fa_a_in[ADDER_WIDTH-1];
	else // (fa_a_in[ADDER_WIDTH-1] = fa_b_in[ADDER_WIDTH-1])
	  as_sum_out_c[ADDER_WIDTH-1] = (fa_a_in[ADDER_WIDTH-1] ^ fa_b_in[ADDER_WIDTH-1]);	  
      end	  
    end
    else // 2's Complement Format
    begin
      as_sum_out_c[ADDER_WIDTH-1] = fa_sum_2c[ADDER_WIDTH-1];
    end
  end

  // 2C operation performed on either A or B inputs
  assign ain_bin_xor = addsub_sel ? (fa_a_in[ADDER_WIDTH-1] ^ b2c_w) : (fa_a_in[ADDER_WIDTH-1] ^ fa_b_in[ADDER_WIDTH-1]);
  // 2C on both inputs when 1, No 2C on both inputs when 0
  assign ain_bin_and =  addsub_sel ? (fa_a_in[ADDER_WIDTH-1] & b2c_w) : (fa_a_in[ADDER_WIDTH-1] & fa_b_in[ADDER_WIDTH-1]);
  // Carry out of i_full_adder final stage
  assign as_carry_out_w = carry_int[ADDER_WIDTH-1] | as_a_carry_2c | as_b_carry_2c; 

  // Magnitude bits of Result
  always @(*)
  begin
    if (sm2c_sel) // Inputs in SM format
    begin
      if (ain_bin_xor & as_carry_out_w) // After 2C operation on input, carry generated after +/- operation with i_full_adder, ignore carry use i_full_adder output as SUM
      begin	      
        as_sum_out_c[ADDER_WIDTH-2:0] = fa_sum_2c[ADDER_WIDTH-2:0];
        as_carry_out_c = as_carry_out_w;	
      end	
      else if (ain_bin_xor) // After 2C operation on input, no carry generated after +/- operation with i_full_adder, so 2C i_full_adder output --> r_full_adder_array output as SUM 
      begin	      
        as_sum_out_c[ADDER_WIDTH-2:0] = sum_2c[ADDER_WIDTH-2:0];	      
        as_carry_out_c = carry_2c;	
      end	
      else if (ain_bin_and) // 2C on both inputs, so 2C i_full_adder output --> r_full_adder_array output as SUM
      begin	      
        as_sum_out_c[ADDER_WIDTH-2:0] = sum_2c[ADDER_WIDTH-2:0];	      
        as_carry_out_c = carry_2c;	
      end
      else // No 2C on both inputs, direct i_full_adder output as SUM
      begin	      
        as_sum_out_c[ADDER_WIDTH-2:0] = fa_sum_2c[ADDER_WIDTH-2:0];	      
        as_carry_out_c = as_carry_out_w;	
      end      
    end
    else // Inputs in 2C format 
    begin	    
      as_sum_out_c[ADDER_WIDTH-2:0] = fa_sum_2c[ADDER_WIDTH-2:0];	      
      as_carry_out_c = as_carry_out_w;	
    end      
  end  

  // Sum Result  
  assign fa_sum_out = as_sum_out_c;		     

  // Carry out Result  
  assign fa_carry_out = as_carry_out_c;

endmodule

