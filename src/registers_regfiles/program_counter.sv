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
    output logic                pc_out_valid
);

  logic [PC_WIDTH-1:0] pc_d, pc_q;
  logic update_pc;
  logic [PC_WIDTH-1:0] fetch_pc;

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

  /* A load presents the target on fetch_pc immediately and steps the
     flop past it, so the next cycle fetches the following instruction.
     last_pc remembers that target: a stall replays it, and the release
     cycle fetches the stepped PC. */
  always_ff @(posedge clk) begin
    if (!rstn) begin
      last_pc <= 'b0;
    end else if (!stall) begin
      last_pc <= fetch_pc;
    end
  end

  always_comb begin
    unique casez ({
      load, inc, stall
    })
      3'b1?0: begin  // Load
        update_pc = 1'b1;
        pc_d = pc_in + INC_AMOUNT;
        pc_out_valid = 1'b1;
        fetch_pc = pc_in;
      end
      3'b??1: begin  // Stall
        update_pc = 1'b0;
        pc_d = 'b0;
        pc_out_valid = 1'b1;
        fetch_pc = last_pc;
      end
      3'b010: begin  // Inc
        update_pc = 1'b1;
        pc_d = pc_q + INC_AMOUNT;
        pc_out_valid = 1'b1;
        fetch_pc = pc_q;
      end
      default: begin
        pc_d = 'b0;
        update_pc = 1'b0;
        pc_out_valid = 1'b0;
        fetch_pc = pc_q;
      end
    endcase
  end

  assign pc_out[PC_WIDTH-1:0] = fetch_pc[PC_WIDTH-1:0];

endmodule
