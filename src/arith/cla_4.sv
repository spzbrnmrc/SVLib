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
//   ___\:::\   \:::\    \          Description : SVLib - Carry-Look-Ahead Adder (4-bit)
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

module cla_4 (
    input  logic [3:0] in0,
    input  logic [3:0] in1,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);

  logic [3:0] generate_i;
  logic [3:0] propagate_i;
  logic [3:0] carry_i;
  logic [3:0] sum_i;

  for (genvar i = 0; i < 4; i = i + 1) begin
    assign generate_i[i]  = in0[i] & in1[i];
    assign propagate_i[i] = in0[i] ^ in1[i];
  end

  for (genvar i = 0; i < 4; i = i + 1) begin
    if (i == 0) begin
      assign carry_i[i] = generate_i[i] | (propagate_i[i] & cin);
      assign sum_i[i]   = propagate_i[i] ^ cin;
    end else begin
      assign carry_i[i] = generate_i[i] | (propagate_i[i] & carry_i[i-1]);
      assign sum_i[i]   = propagate_i[i] ^ carry_i[i-1];
    end
  end

  assign sum  = sum_i;
  assign cout = carry_i[3];
endmodule
