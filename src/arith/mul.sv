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
//   ___\:::\   \:::\    \          Description : SVLib - Booth Encoded Multiplier
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

module mul #(
    parameter integer WIDTH = 8,
    parameter integer CPA_ALGORITHM = 1,  // 0: RCA, 1: CLA
    parameter integer PIPE_STAGE_AFTER_BOOTH = 1,  // Enable Flop stage after Booth encoder
    parameter integer PIPE_STAGE_CSA_LR1 = 0,  // Enable Flop stage after first layer of CSAs
    parameter integer PIPE_STAGE_CSA_LR2 = 0,  // Enable Flop stage after second layer of CSAs
    parameter integer PIPE_STAGE_CSA_LR3 = 0,  // Enable Flop stage after third layer of CSAs
    parameter integer PIPE_STAGE_CSA_LR4 = 0,  // Enable Flop stage after fourth layer of CSAs
    parameter integer PIPE_STAGES_CPA = 2  // Number of flop stages to break up CPA
) (
    input logic clk,

    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic             unsign,
    output logic [WIDTH-1:0] lower,
    output logic [WIDTH-1:0] upper
);

  logic [WIDTH:0] multiplicand_ext;
  logic [WIDTH:0] multiplicand_2x_ext;
  logic [WIDTH:0] multiplicand_neg_ext;
  logic [WIDTH:0] multiplicand_neg_2x_ext;

  logic [WIDTH+2:0] multiplier_ext;

  logic [2*WIDTH-1:0] pp_out[WIDTH/2:0];  // 8 + 1 extra in case is unsigned
  logic [WIDTH/2:0] p;
  logic [WIDTH/2:0] s;
  logic unsign_i;


  logic [2*WIDTH-1:0] sum;

  assign multiplicand_ext        = {~unsign & a[WIDTH-1], a[WIDTH-1:0]};
  assign multiplicand_2x_ext     = {a[WIDTH-1:0], 1'b0};
  assign multiplicand_neg_ext    = {~(~unsign & a[WIDTH-1]), ~a[WIDTH-1:0]};
  assign multiplicand_neg_2x_ext = {~a[WIDTH-1:0], 1'b1};

  assign multiplier_ext          = {2'b0, b[WIDTH-1:0], 1'b0};

  generate
    for (genvar i = 0; i <= WIDTH / 2; i = i + 1) begin : gen_pp_out
      logic [WIDTH:0] pp_out_i;

      if (i == 0) begin
        booth_encoder #(
            .WIDTH(WIDTH),
            .PIPE_STAGE(PIPE_STAGE_AFTER_BOOTH)
        ) booth_encoder_inst (
            .clk                (clk),
            .unsign             (unsign),
            .multiplier         (multiplier_ext[2:0]),
            .multiplicand       (multiplicand_ext),
            .multiplicand_2x    (multiplicand_2x_ext),
            .multiplicand_neg   (multiplicand_neg_ext),
            .multiplicand_neg_2x(multiplicand_neg_2x_ext),
            .pp_out             (pp_out_i),
            .p                  (p[i]),
            .s                  (s[i])
        );
        assign pp_out[i] = {
          {2 * WIDTH - 3 - WIDTH - 1{1'b0}}, p[i], ~p[i], ~p[i], pp_out_i[WIDTH:0]
        };
      end else begin
        booth_encoder #(
            .WIDTH(WIDTH),
            .PIPE_STAGE(PIPE_STAGE_AFTER_BOOTH)
        ) booth_encoder_inst (
            .clk                (clk),
            .unsign             (unsign),
            .multiplier         (multiplier_ext[2*i+2:2*i]),
            .multiplicand       (multiplicand_ext),
            .multiplicand_2x    (multiplicand_2x_ext),
            .multiplicand_neg   (multiplicand_neg_ext),
            .multiplicand_neg_2x(multiplicand_neg_2x_ext),
            .pp_out             (pp_out_i),
            .p                  (p[i]),
            .s                  (s[i])
        );

        assign pp_out[i] = ({{(2 * WIDTH - (WIDTH + 5)){1'b0}}, 1'b1, p[i], pp_out_i[WIDTH:0], 1'b0, s[i-1]}) << (2 * (i - 1));
      end
    end
  endgenerate

  generate
    if (PIPE_STAGE_AFTER_BOOTH != 0) begin : gen_flops_unsign
      register #(1) unsign_dff_inst (
          .clk (clk),
          .din (unsign),
          .dout(unsign_i)
      );
    end else begin
      assign unsign_i = unsign;
    end
  endgenerate

  localparam integer NUM_CSA_LAYERS =
      (WIDTH >= 64) ? 3 : (WIDTH >= 32) ? 2 : (WIDTH >= 16) ? 1 : 0;
  localparam integer NUM_CF_STAGES = NUM_CSA_LAYERS + 1;
  logic [2*WIDTH-1:0] cf[NUM_CF_STAGES:0];

  assign cf[0] = (unsign_i) ?  pp_out[WIDTH/2] | {{WIDTH+1{1'b0}}, s[WIDTH/2-1], {WIDTH-2{1'b0}}} : {{WIDTH+1{1'b0}}, s[WIDTH/2-1], {WIDTH-2{1'b0}}};

  /* ***** LAYER 0 of CSAs ***** */
  logic [2*WIDTH-1:0] pp_sum_lr0[(WIDTH / 2 / 4)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr0[(WIDTH / 2 / 4)-1:0];
  logic [2*WIDTH-1:0] pp_sum_lr0_i[(WIDTH / 2 / 4)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr0_i[(WIDTH / 2 / 4)-1:0];

  generate
    if (WIDTH >= 8) begin : gen_layer_0
      for (genvar i = 0; i < WIDTH / 2 / 4; i = i + 1) begin : gen_layer_0_csa
        csa_4_2 #(
            .WIDTH(2 * WIDTH)
        ) csa_4_2_inst (
            .in0  (pp_out[4*i]),
            .in1  (pp_out[4*i+1]),
            .in2  (pp_out[4*i+2]),
            .in3  (pp_out[4*i+3]),
            .sum  (pp_sum_lr0_i[i]),
            .carry(pp_carry_lr0_i[i])
        );
      end
    end
  endgenerate

  generate
    if (PIPE_STAGE_CSA_LR1 != 0 && WIDTH >= 8) begin : gen_flops_layer_0_cf
      register #(
          .WIDTH(2 * WIDTH)
      ) cf_dff_inst (
          .clk (clk),
          .din (cf[0]),
          .dout(cf[1])
      );
    end else if (WIDTH >= 8) begin : gen_flops_layer_0_cf_bypass
      assign cf[1] = cf[0];
    end

    for (genvar i = 0; i < WIDTH / 2 / 4; i = i + 1) begin : gen_flops_layer_0_csa
      if (PIPE_STAGE_CSA_LR1 != 0 && WIDTH >= 8) begin : gen_flops_layer_0_csa
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_sum_lr0_dff_inst (
            .clk (clk),
            .din (pp_sum_lr0_i[i]),
            .dout(pp_sum_lr0[i])
        );
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_carry_lr0_dff_inst (
            .clk (clk),
            .din (pp_carry_lr0_i[i]),
            .dout(pp_carry_lr0[i])
        );
      end else begin : gen_flops_layer_0_csa_bypass
        assign pp_sum_lr0[i]   = pp_sum_lr0_i[i];
        assign pp_carry_lr0[i] = pp_carry_lr0_i[i];
      end
    end
  endgenerate

  /* ***** LAYER 1 of CSAs ***** */
  logic [2*WIDTH-1:0] pp_sum_lr1[(WIDTH / 2 / 4/2)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr1[(WIDTH / 2 / 4/2)-1:0];
  logic [2*WIDTH-1:0] pp_sum_lr1_i[(WIDTH / 2 / 4/2)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr1_i[(WIDTH / 2 / 4/2)-1:0];

  generate
    if (WIDTH >= 16) begin : gen_layer_1
      for (genvar i = 0; i < WIDTH / 2 / 4 / 2; i = i + 1) begin : gen_layer_1_csa
        csa_4_2 #(
            .WIDTH(2 * WIDTH)
        ) csa_4_2_inst (
            .in0  (pp_sum_lr0[2*i]),
            .in1  (pp_sum_lr0[2*i+1]),
            .in2  ({pp_carry_lr0[2*i][2*WIDTH-2:0], 1'b0}),
            .in3  ({pp_carry_lr0[2*i+1][2*WIDTH-2:0], 1'b0}),
            .sum  (pp_sum_lr1_i[i]),
            .carry(pp_carry_lr1_i[i])
        );
      end
    end
  endgenerate

  generate
    if (PIPE_STAGE_CSA_LR2 != 0 && WIDTH >= 16) begin : gen_flops_layer_1_cf
      register #(
          .WIDTH(2 * WIDTH)
      ) cf_dff_inst (
          .clk (clk),
          .din (cf[1]),
          .dout(cf[2])
      );
    end else if (WIDTH >= 16) begin : gen_flops_layer_1_cf_bypass
      assign cf[2] = cf[1];
    end

    for (genvar i = 0; i < WIDTH / 2 / 4 / 2; i = i + 1) begin : gen_flops_layer_1_csa
      if (PIPE_STAGE_CSA_LR2 != 0 && WIDTH >= 16) begin : gen_flops_layer_1_csa
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_sum_lr1_dff_inst (
            .clk (clk),
            .din (pp_sum_lr1_i[i]),
            .dout(pp_sum_lr1[i])
        );
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_carry_lr1_dff_inst (
            .clk (clk),
            .din (pp_carry_lr1_i[i]),
            .dout(pp_carry_lr1[i])
        );
      end else begin : gen_flops_layer_1_csa_bypass
        assign pp_sum_lr1[i]   = pp_sum_lr1_i[i];
        assign pp_carry_lr1[i] = pp_carry_lr1_i[i];
      end
    end
  endgenerate

  /* ***** LAYER 2 of CSAs ***** */
  logic [2*WIDTH-1:0] pp_sum_lr2[(WIDTH / 2 / 4 / 2 / 2)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr2[(WIDTH / 2 / 4 / 2 / 2)-1:0];
  logic [2*WIDTH-1:0] pp_sum_lr2_i[(WIDTH / 2 / 4 / 2 / 2)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr2_i[(WIDTH / 2 / 4 / 2 / 2)-1:0];

  generate
    if (WIDTH >= 32) begin : gen_layer_2
      for (genvar i = 0; i < WIDTH / 2 / 4 / 2 / 2; i = i + 1) begin : gen_layer_2_csa
        csa_4_2 #(
            .WIDTH(2 * WIDTH)
        ) csa_4_2_inst (
            .in0  (pp_sum_lr1[2*i]),
            .in1  (pp_sum_lr1[2*i+1]),
            .in2  ({pp_carry_lr1[2*i][2*WIDTH-2:0], 1'b0}),
            .in3  ({pp_carry_lr1[2*i+1][2*WIDTH-2:0], 1'b0}),
            .sum  (pp_sum_lr2_i[i]),
            .carry(pp_carry_lr2_i[i])
        );
      end
    end
  endgenerate

  generate
    if (PIPE_STAGE_CSA_LR3 != 0 && WIDTH >= 32) begin : gen_flops_layer_2_cf
      register #(
          .WIDTH(2 * WIDTH)
      ) cf_dff_inst (
          .clk (clk),
          .din (cf[2]),
          .dout(cf[3])
      );
    end else if (WIDTH >= 32) begin : gen_flops_layer_2_cf_bypass
      assign cf[3] = cf[2];
    end

    for (genvar i = 0; i < WIDTH / 2 / 4 / 2 / 2; i = i + 1) begin : gen_flops_layer_2_csa
      if (PIPE_STAGE_CSA_LR3 != 0 && WIDTH >= 32) begin : gen_flops_layer_2_csa
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_sum_lr2_dff_inst (
            .clk (clk),
            .din (pp_sum_lr2_i[i]),
            .dout(pp_sum_lr2[i])
        );
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_carry_lr2_dff_inst (
            .clk (clk),
            .din (pp_carry_lr2_i[i]),
            .dout(pp_carry_lr2[i])
        );
      end else begin : gen_flops_layer_2_csa_bypass
        assign pp_sum_lr2[i]   = pp_sum_lr2_i[i];
        assign pp_carry_lr2[i] = pp_carry_lr2_i[i];
      end
    end
  endgenerate

  /* ***** LAYER 3 of CSAs ***** */
  logic [2*WIDTH-1:0] pp_sum_lr3[(WIDTH / 2 / 4 / 2 / 2 / 2)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr3[(WIDTH / 2 / 4 / 2 / 2 / 2)-1:0];
  logic [2*WIDTH-1:0] pp_sum_lr3_i[(WIDTH / 2 / 4 / 2 / 2 / 2)-1:0];
  logic [2*WIDTH-1:0] pp_carry_lr3_i[(WIDTH / 2 / 4 / 2 / 2 / 2)-1:0];

  generate
    if (WIDTH >= 64) begin : gen_layer_3
      for (genvar i = 0; i < WIDTH / 2 / 4 / 2 / 2 / 2; i = i + 1) begin : gen_layer_3_csa
        csa_4_2 #(
            .WIDTH(2 * WIDTH)
        ) csa_4_2_inst (
            .in0  (pp_sum_lr2[2*i]),
            .in1  (pp_sum_lr2[2*i+1]),
            .in2  ({pp_carry_lr2[2*i][2*WIDTH-2:0], 1'b0}),
            .in3  ({pp_carry_lr2[2*i+1][2*WIDTH-2:0], 1'b0}),
            .sum  (pp_sum_lr3_i[i]),
            .carry(pp_carry_lr3_i[i])
        );
      end
    end
  endgenerate

  generate
    if (PIPE_STAGE_CSA_LR4 != 0 && WIDTH >= 64) begin : gen_flops_layer_3_cf
      register #(
          .WIDTH(2 * WIDTH)
      ) cf_dff_inst (
          .clk (clk),
          .din (cf[3]),
          .dout(cf[4])
      );
    end else if (WIDTH >= 64) begin : gen_flops_layer_3_cf_bypass
      assign cf[4] = cf[3];
    end

    for (genvar i = 0; i < WIDTH / 2 / 4 / 2 / 2 / 2; i = i + 1) begin : gen_flops_layer_3_csa
      if (PIPE_STAGE_CSA_LR4 != 0 && WIDTH >= 64) begin : gen_flops_layer_3_csa
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_sum_lr3_dff_inst (
            .clk (clk),
            .din (pp_sum_lr3_i[i]),
            .dout(pp_sum_lr3[i])
        );
        register #(
            .WIDTH(2 * WIDTH)
        ) pp_carry_lr3_dff_inst (
            .clk (clk),
            .din (pp_carry_lr3_i[i]),
            .dout(pp_carry_lr3[i])
        );
      end else begin : gen_flops_layer_3_csa_bypass
        assign pp_sum_lr3[i]   = pp_sum_lr3_i[i];
        assign pp_carry_lr3[i] = pp_carry_lr3_i[i];
      end
    end
  endgenerate


  /* ***** Select the proper output Layer ***** */
  logic [2*WIDTH-1:0] pp_sum_final;
  logic [2*WIDTH-1:0] pp_carry_final;
  logic [2*WIDTH-1:0] cf_final;
  generate
    if (WIDTH == 8) begin : gen_layer_0_sel
      assign pp_sum_final   = pp_sum_lr0[0];
      assign pp_carry_final = pp_carry_lr0[0];
      assign cf_final       = cf[1];
    end else if (WIDTH == 16) begin : gen_layer_1_sel
      assign pp_sum_final   = pp_sum_lr1[0];
      assign pp_carry_final = pp_carry_lr1[0];
      assign cf_final       = cf[2];
    end else if (WIDTH == 32) begin : gen_layer_2_sel
      assign pp_sum_final   = pp_sum_lr2[0];
      assign pp_carry_final = pp_carry_lr2[0];
      assign cf_final       = cf[3];
    end else if (WIDTH == 64) begin : gen_layer_3_sel
      assign pp_sum_final   = pp_sum_lr3[0];
      assign pp_carry_final = pp_carry_lr3[0];
      assign cf_final       = cf[4];
    end
  endgenerate

  /* ***** Correction Factor 3:2 Compressor ***** */
  logic [2*WIDTH-1:0] cf_sum_i;
  logic [2*WIDTH-1:0] cf_carry_i;

  csa_3_2 #(
      .WIDTH(2 * WIDTH)
  ) csa_3_2_inst (
      .in0  (cf_final),
      .in1  (pp_sum_final),
      .in2  ({pp_carry_final[2*WIDTH-2:0], 1'b0}),
      .sum  (cf_sum_i),
      .carry(cf_carry_i)
  );

  /* Final Carry-Propagate Adder */
  logic [2*WIDTH-1:0] cf_carry_i_ext;
  assign cf_carry_i_ext = {cf_carry_i[2*WIDTH-2:0], 1'b0};

  /* Final CPA */
  adder_pipe #(
      .WIDTH(2 * WIDTH),
      .NUM_ADDERS(PIPE_STAGES_CPA)
  ) adder_pipe_inst (
      .clk (clk),
      .in0 (cf_sum_i),
      .in1 (cf_carry_i_ext),
      .cin (1'b0),
      .sum (sum),
      .cout()
  );


  assign lower = sum[WIDTH-1:0];
  assign upper = sum[2*WIDTH-1:WIDTH];

endmodule
