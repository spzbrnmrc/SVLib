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
//   ___\:::\   \:::\    \          Description : SVLib - Carry Save Adder (compressor) 3 to 2
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

module csa_3_2 #(
    parameter integer WIDTH = 32
) (
    input logic [WIDTH-1:0] in0,
    input logic [WIDTH-1:0] in1,
    input logic [WIDTH-1:0] in2,

    output logic [WIDTH-1:0] sum,
    output logic [WIDTH-1:0] carry
);

  genvar i;
  for (i = 0; i < WIDTH; i = i + 1) begin
    fa fa_inst (
        .a   (in0[i]),
        .b   (in1[i]),
        .cin (in2[i]),
        .sum (sum[i]),
        .cout(carry[i])
    );
  end

endmodule
