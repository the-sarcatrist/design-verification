// ========================================================================
//Filename        : full_adder_array.v
//Project         : Ripple Carry Adder 
//Author          : Rahul Prakash Joshi
//Date            : 19-02-2025
// ========================================================================
//Abstract   : Instantiates Full adders equal to Input Operand Width
//             
// ========================================================================

`timescale 1ns/1ps

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
