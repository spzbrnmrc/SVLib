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
//   ___\:::\   \:::\    \          Description : SVLib - Program Counter
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

module program_counter #(
    parameter integer                PC_WIDTH   = 32,
    parameter logic   [PC_WIDTH-1:0] INC_AMOUNT = 4
) (
    input logic                clk,
    input logic                rstn,
    input logic [PC_WIDTH-1:0] reset_vector,

    /* Control Signals */
    input logic load,
    input logic inc,
    input logic stall,

    /* Data Signals */
    input  logic [PC_WIDTH-1:0] pc_in,
    output logic [PC_WIDTH-1:0] pc_out,
    output logic                pc_out_valid,
    // Value captured by the counter when load or inc is set. The current
    // value when the counter holds. One incrementer feeds both this and the
    // register, so a caller does not grow a second adder for the next PC.
    output logic [PC_WIDTH-1:0] pc_next
);

  logic [PC_WIDTH-1:0] pc_d, pc_q;
  logic update_pc;

  register_en_sync_rstn_vector #(
      .WIDTH(PC_WIDTH)
  ) pc_dff (
      .clk         (clk),
      .rstn        (rstn),
      .reset_vector(reset_vector[PC_WIDTH-1:0]),
      .en          (update_pc),
      .din         (pc_d[PC_WIDTH-1:0]),
      .dout        (pc_q[PC_WIDTH-1:0])
  );

  logic [PC_WIDTH-1:0] last_pc;

  always_ff @(posedge clk) begin
    if (!rstn) begin
      last_pc <= 'b0;
    end else if (!stall) begin
      last_pc <= pc_q;
    end
  end

  always_comb begin
    unique casez ({
      load, inc, stall
    })
      3'b1?0: begin  // Load
        update_pc = 1'b1;
        pc_d = pc_in;
        pc_out_valid = 1'b1;
      end
      3'b??1: begin  // Stall
        update_pc = 1'b0;
        pc_d = 'b0;
        pc_out_valid = 1'b1;
      end
      3'b010: begin  // Inc
        update_pc = 1'b1;
        pc_d = pc_q + INC_AMOUNT;
        pc_out_valid = 1'b1;
      end
      default: begin
        pc_d = 'b0;
        update_pc = 1'b0;
        pc_out_valid = 1'b0;
      end
    endcase
  end

  assign pc_out[PC_WIDTH-1:0] = (stall) ? last_pc[PC_WIDTH-1:0] : pc_q[PC_WIDTH-1:0];
  assign pc_next = update_pc ? pc_d : pc_q;

endmodule
