
// ========================================================================
//Filename        : full_adder.v
//Project         : Ripple Carry Adder 
//Author          : Rahul Prakash Joshi
//Date            : 27-01-2025
// ========================================================================
//Abstract   : Full Adder
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

