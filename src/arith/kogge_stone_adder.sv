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
//   ___\:::\   \:::\    \          Description : SVLib - Kogge-Stone adder
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

// Combinational prefix network (building block, no registers).
module kogge_stone_prefix #(
    parameter integer WIDTH = 64,
    parameter integer LEVEL_BEGIN = 0,
    parameter integer LEVEL_COUNT = 1
) (
    input  logic [WIDTH-1:0] g_in,
    input  logic [WIDTH-1:0] p_in,
    output logic [WIDTH-1:0] g_out,
    output logic [WIDTH-1:0] p_out
);

  logic [WIDTH-1:0] g [LEVEL_COUNT:0];
  logic [WIDTH-1:0] p [LEVEL_COUNT:0];

  assign g[0] = g_in;
  assign p[0] = p_in;

  for (genvar lvl = 0; lvl < LEVEL_COUNT; lvl++) begin : gen_prefix_level
    localparam integer SPAN = (1 << (LEVEL_BEGIN + lvl));

    for (genvar i = 0; i < WIDTH; i++) begin : gen_prefix_bit
      if (i < SPAN) begin : gen_prefix_short
        assign g[lvl+1][i] = g[lvl][i];
        assign p[lvl+1][i] = p[lvl][i];
      end else begin : gen_prefix_combine
        assign g[lvl+1][i] = g[lvl][i] | (p[lvl][i] & g[lvl][i-SPAN]);
        assign p[lvl+1][i] = p[lvl][i] & p[lvl][i-SPAN];
      end
    end
  end

  assign g_out = g[LEVEL_COUNT];
  assign p_out = p[LEVEL_COUNT];

endmodule


// Combinational Kogge-Stone adder (no registers). Use kogge_stone_pipe for pipelined CPA.
module kogge_stone_adder #(
    parameter integer WIDTH = 64
) (
    input  logic [WIDTH-1:0] in0,
    input  logic [WIDTH-1:0] in1,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout
);

  localparam integer LEVELS = $clog2(WIDTH);

  logic [WIDTH-1:0] p0;
  logic [WIDTH-1:0] g_init;
  logic [WIDTH-1:0] p_init;
  logic [WIDTH-1:0] g_final;
  logic [WIDTH-1:0] p_final;

  generate
    if ((1 << LEVELS) != WIDTH) begin : gen_width_error
      initial $fatal(1, "kogge_stone_adder: WIDTH must be a power of 2");
    end else begin : gen_width_ok
      for (genvar i = 0; i < WIDTH; i++) begin : gen_init
        assign p0[i] = in0[i] ^ in1[i];
      end

      assign g_init[0] = (in0[0] & in1[0]) | (p0[0] & cin);
      assign p_init[0] = p0[0];
      for (genvar i = 1; i < WIDTH; i++) begin : gen_init_gp
        assign g_init[i] = in0[i] & in1[i];
        assign p_init[i] = p0[i];
      end

      kogge_stone_prefix #(
          .WIDTH       (WIDTH),
          .LEVEL_BEGIN (0),
          .LEVEL_COUNT (LEVELS)
      ) prefix_inst (
          .g_in (g_init),
          .p_in (p_init),
          .g_out(g_final),
          .p_out(p_final)
      );

      assign sum[0] = p0[0] ^ cin;
      for (genvar i = 1; i < WIDTH; i++) begin : gen_sum
        assign sum[i] = p0[i] ^ g_final[i-1];
      end
      assign cout = g_final[WIDTH-1];
    end
  endgenerate

endmodule


// Two-cycle Kogge-Stone adder (one register between prefix-tree halves).
module kogge_stone_pipe #(
    parameter integer WIDTH = 64
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] in0,
    input  logic [WIDTH-1:0] in1,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout
);

  localparam integer LEVELS          = $clog2(WIDTH);
  localparam integer STAGE1_LEVELS   = (LEVELS + 1) / 2;
  localparam integer STAGE2_BEGIN    = STAGE1_LEVELS;
  localparam integer STAGE2_LEVELS   = LEVELS - STAGE1_LEVELS;
  localparam integer STATE_WIDTH     = (3 * WIDTH) + 1;

  logic [WIDTH-1:0] p0;
  logic [WIDTH-1:0] g_init;
  logic [WIDTH-1:0] p_init;
  logic [WIDTH-1:0] g_stage1;
  logic [WIDTH-1:0] p_stage1;

  logic [WIDTH-1:0] g_stage2_in;
  logic [WIDTH-1:0] p_stage2_in;
  logic [WIDTH-1:0] p0_stage2;
  logic             cin_stage2;
  logic [WIDTH-1:0] g_final;
  logic [WIDTH-1:0] p_final;

  generate
    if ((1 << LEVELS) != WIDTH) begin : gen_pipe_width_error
      initial $fatal(1, "kogge_stone_pipe: WIDTH must be a power of 2");
    end else begin : gen_pipe_two_stage
      for (genvar i = 0; i < WIDTH; i++) begin : gen_pipe_p0
        assign p0[i] = in0[i] ^ in1[i];
      end

      assign g_init[0] = (in0[0] & in1[0]) | (p0[0] & cin);
      assign p_init[0] = p0[0];
      for (genvar i = 1; i < WIDTH; i++) begin : gen_pipe_gp_in
        assign g_init[i] = in0[i] & in1[i];
        assign p_init[i] = p0[i];
      end

      // Stage 1: generate/propagate init + lower half of prefix tree
      kogge_stone_prefix #(
          .WIDTH       (WIDTH),
          .LEVEL_BEGIN (0),
          .LEVEL_COUNT (STAGE1_LEVELS)
      ) prefix_stage1 (
          .g_in (g_init),
          .p_in (p_init),
          .g_out(g_stage1),
          .p_out(p_stage1)
      );

      // Single pipeline register between stages
      register #(
          .WIDTH(STATE_WIDTH)
      ) stage_reg (
          .clk (clk),
          .din ({g_stage1, p_stage1, p0, cin}),
          .dout({g_stage2_in, p_stage2_in, p0_stage2, cin_stage2})
      );

      // Stage 2: upper half of prefix tree + sum
      kogge_stone_prefix #(
          .WIDTH       (WIDTH),
          .LEVEL_BEGIN (STAGE2_BEGIN),
          .LEVEL_COUNT (STAGE2_LEVELS)
      ) prefix_stage2 (
          .g_in (g_stage2_in),
          .p_in (p_stage2_in),
          .g_out(g_final),
          .p_out(p_final)
      );

      assign sum[0] = p0_stage2[0] ^ cin_stage2;
      for (genvar i = 1; i < WIDTH; i++) begin : gen_pipe_sum
        assign sum[i] = p0_stage2[i] ^ g_final[i-1];
      end
      assign cout = g_final[WIDTH-1];
    end
  endgenerate

endmodule
