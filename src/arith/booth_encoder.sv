///////////////////////////////////////////////////////////////////////////////
//     Copyright (c) 2025 Siliscale Consulting, LLC
// 
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
///////////////////////////////////////////////////////////////////////////////
//           _____          
//          /\    \         
//         /::\    \        
//        /::::\    \       
//       /::::::\    \      
//      /:::/\:::\    \     
//     /:::/__\:::\    \            Vendor      : Siliscale
//     \:::\   \:::\    \           Version     : 2025.1
//   ___\:::\   \:::\    \          Description : SVLib - Booth Encoder
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

module booth_encoder #(
    parameter integer WIDTH = 32,
    parameter integer PIPE_STAGE = 0
) (

    input logic           clk,
    input logic           mc_sign,
    input logic [    2:0] multiplier,
    input logic [WIDTH:0] multiplicand,
    input logic [WIDTH:0] multiplicand_2x,
    input logic [WIDTH:0] multiplicand_neg,
    input logic [WIDTH:0] multiplicand_neg_2x,

    output logic [WIDTH:0] pp_out,
    output logic p,
    output logic s
);

  logic [WIDTH:0] pp_out_i;

  logic s_i, e_i, p_i;

  always_comb begin
    unique case (multiplier)
      3'b001:  pp_out_i = multiplicand;
      3'b010:  pp_out_i = multiplicand;
      3'b011:  pp_out_i = multiplicand_2x;
      3'b100:  pp_out_i = multiplicand_neg_2x;
      3'b101:  pp_out_i = multiplicand_neg;
      3'b110:  pp_out_i = multiplicand_neg;
      default: pp_out_i = {WIDTH + 1{1'b0}};
    endcase
  end


  assign s_i = multiplier[2] & ~(&multiplier[1:0]);
  assign e_i = ~((s_i ^ multiplicand[WIDTH-1]) & ~(&multiplier[2:0])) | ~(|multiplier[2:0]);

  assign p_i = (mc_sign) ? e_i : ~s_i;

  generate
    if (PIPE_STAGE != 0) begin
      register #(WIDTH + 1) pp_out_dff_inst (
          .clk (clk),
          .din (pp_out_i),
          .dout(pp_out)
      );
      register #(1) p_dff_inst (
          .clk (clk),
          .din (p_i),
          .dout(p)
      );
      register #(1) s_dff_inst (
          .clk (clk),
          .din (s_i),
          .dout(s)
      );
    end else begin
      assign pp_out = pp_out_i;
      assign p = p_i;
      assign s = s_i;
    end
  endgenerate

endmodule
