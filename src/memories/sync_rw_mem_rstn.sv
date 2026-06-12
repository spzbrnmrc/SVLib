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

`timescale 1ns / 1ps

module sync_rw_mem_rstn #(
    parameter int    DEPTH     = 1024,
    parameter int    WIDTH     = 32,
    parameter string INIT_FILE = ""
) (
    input  logic                     clk,
    input  logic                     rstn,
    input  logic [$clog2(DEPTH)-1:0] raddr,
    input  logic                     rvalid_in,
    output logic [        WIDTH-1:0] rdata,
    output logic                     rvalid_out,
    input  logic [$clog2(DEPTH)-1:0] waddr,
    input  logic                     wen,
    input  logic [        WIDTH-1:0] wdata
);

  logic [WIDTH-1:0] mem[DEPTH];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  register_sync_rstn #(
      .WIDTH(1)
  ) rvalid_ff (
      .clk (clk),
      .rstn(rstn),
      .din (rvalid_in),
      .dout(rvalid_out)
  );

  register_sync_rstn #(
      .WIDTH(WIDTH)
  ) rdata_ff (
      .clk (clk),
      .rstn(rstn),
      .din (mem[raddr]),
      .dout(rdata)
  );

  always_ff @(posedge clk) begin
    if (wen) begin
      mem[waddr] <= wdata;
    end
  end

endmodule
