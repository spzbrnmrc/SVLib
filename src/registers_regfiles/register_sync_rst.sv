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
//   ___\:::\   \:::\    \          Description : SVLib - Register w/ Sync Active-High Reset
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

module register_sync_rst #(
    parameter integer             WIDTH     = 1,
    parameter logic   [WIDTH-1:0] RESET_VAL = '0
) (
    input logic clk,
    input logic rst,

    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

  always_ff @(posedge clk) begin
    if (rst) begin
      dout <= RESET_VAL;
    end else begin
      dout <= din;
    end
  end

endmodule
