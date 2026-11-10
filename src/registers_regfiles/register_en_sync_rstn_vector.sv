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
//   ___\:::\   \:::\    \          Description : SVLib - Register w/ Sync Active-Low Reset & Reset Vector
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

module register_en_sync_rstn_vector #(
    parameter integer WIDTH = 1
) (
    input logic             clk,
    input logic             rstn,
    input logic [WIDTH-1:0] reset_vector,
    input logic             en,

    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

  always_ff @(posedge clk) begin
    if (~rstn) begin
      dout <= reset_vector;
    end else if (en) begin
      dout <= din;
    end
  end

endmodule
