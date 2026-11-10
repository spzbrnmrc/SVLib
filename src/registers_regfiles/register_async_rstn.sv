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
//   ___\:::\   \:::\    \          Description : SVLib - Register w/ Async Active-Low Reset
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

`timescale 1ns / 1ps

module register_async_rstn #(
    parameter integer             WIDTH     = 1,
    parameter logic   [WIDTH-1:0] RESET_VAL = '0
) (
    input logic clk,
    input logic rstn,

    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      dout <= RESET_VAL;
    end else begin
      dout <= din;
    end
  end

endmodule
