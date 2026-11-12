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
//   ___\:::\   \:::\    \          Description : SVLib - Clock Domain Crossing (CDC) Synchronizer
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


module cdc_sync #(
    parameter integer N     = 2,
    parameter integer WIDTH = 1
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

  (* ASYNC_REG = "TRUE", SILISCALE_CDC = "TRUE" *) logic [WIDTH-1:0] sync_reg[N-1:0];

  always @(posedge clk) begin
    for (int i = 0; i < N; i++) begin
      if (i == 0) begin
        sync_reg[i] <= din;
      end else begin
        sync_reg[i] <= sync_reg[i-1];
      end
    end
  end

  assign dout = sync_reg[N-1];

endmodule
