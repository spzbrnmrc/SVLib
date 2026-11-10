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
//   ___\:::\   \:::\    \          Description : SVLib - Register File w/ Async Active-High Reset
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

module regfile_async_rst #(
    parameter integer WIDTH    = 1,  // Width of each register
    parameter integer N_REG    = 1,  // Number of registers
    parameter integer N_RPORTS = 1,  // Number of read ports
    parameter integer N_WPORTS = 1   // Number of write ports
) (
    input logic clk,
    input logic rst,

    // Read
    input  logic [N_RPORTS-1:0][$clog2(N_REG)-1:0] raddr,
    output logic [N_RPORTS-1:0][        WIDTH-1:0] rdata,

    // Write
    input logic [N_WPORTS-1:0][$clog2(N_REG)-1:0] waddr,
    input logic [N_WPORTS-1:0]                    wen,
    input logic [N_WPORTS-1:0][        WIDTH-1:0] wdata

);

  genvar i;
  generate
    for (i = 0; i < N_REG; i++) begin : gen_reg
      register_en_async_rst #(
          .WIDTH(WIDTH)
      ) reg_inst (
          .clk (clk),
          .rst (rst),
          .en  (wen[i] & waddr[i] == i),
          .din (wdata[i]),
          .dout(rdata[i])
      );
    end
  endgenerate

  genvar j;
  generate
    for (j = 0; j < N_RPORTS; j++) begin : gen_rport
      assign rdata[j] = rdata[raddr[j]];
    end
  endgenerate

endmodule
