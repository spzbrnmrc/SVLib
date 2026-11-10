///////////////////////////////////////////////////////////////////////////////
//     Copyright (c) 2025 Siliscale Consulting, LLC
// 
//    All rights reserved.
///////////////////////////////////////////////////////////////////////////////
//           _____          
//          /\    \         
//         /::\    \        
//        /::::\    \       
//       /::::::\    \      
//      /:::/\:::\    \     
//     /:::/__\:::\    \            Vendor      : Siliscale
//     \:::\   \:::\    \           Version     : 2025.1
//   ___\:::\   \:::\    \          Description : SVLib - Carry Save Adder (compressor) 4 to 2
//  /\   \:::\   \:::\    \ 
// /::\   \:::\   \:::\____\
// \:::\   \:::\   \::/    /
//  \:::\   \:::\   \/____/ 
//   \:::\   \:::\    \     
//    \:::\   \:::\____\    
//     \:::\  /:::/    /    
//      \:::\/:::/    /     
//       \::::::/    /      
//        \::::/    /       
//         \::/    /        
//          \/____/         
///////////////////////////////////////////////////////////////////////////////

module csa_4_2 #(
    parameter integer WIDTH = 32
) (
    input logic [WIDTH-1:0] in0,
    input logic [WIDTH-1:0] in1,
    input logic [WIDTH-1:0] in2,
    input logic [WIDTH-1:0] in3, // Fast input, goes only through the 3-2 compressor

    output logic [WIDTH-1:0] sum,
    output logic [WIDTH-1:0] carry
);

  logic [WIDTH-1:0] sum_i;
  logic [WIDTH-1:0] carry_i;

  logic [  WIDTH:0] sum_i_ext;
  logic [  WIDTH:0] carry_i_ext;

  csa_3_2 #(
      .WIDTH(WIDTH)
  ) csa_3_2_i0 (
      .in0  (in0),
      .in1  (in1),
      .in2  (in2),
      .sum  (sum_i),
      .carry(carry_i)
  );

  csa_3_2 #(
      .WIDTH(WIDTH + 1)
  ) csa_3_2_i1 (
      .in0  ({1'b0, in3}),
      .in1  ({1'b0, sum_i}),
      .in2  ({carry_i, 1'b0}),
      .sum  (sum_i_ext),
      .carry(carry_i_ext)
  );

  assign sum   = sum_i_ext[WIDTH-1:0];
  assign carry = carry_i_ext[WIDTH-1:0];

endmodule
