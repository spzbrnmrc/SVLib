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
//   ___\:::\   \:::\    \          Description : SVLib - 2's Complement
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


module twoscomp #(
    parameter WIDTH = 32
) (
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

  logic [WIDTH-1:1] dout_temp;
  genvar i;

  for (i = 1; i < WIDTH; i++) begin
    assign dout_temp[i] = (|din[i-1:0]) ? ~din[i] : din[i];
  end

  assign dout[WIDTH-1:0] = {dout_temp[WIDTH-1:1], din[0]};

endmodule
