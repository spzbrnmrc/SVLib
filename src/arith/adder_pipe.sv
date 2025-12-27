module adder_pipe #(
    parameter integer WIDTH = 16,
    parameter integer NUM_ADDERS = 4,
    parameter integer ALGORITHM = 0  // 0: Ripple-Carry, 1: Carry-Look-Ahead
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] in0,
    input  logic [WIDTH-1:0] in1,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout
);

  localparam integer ADDER_WIDTH = WIDTH / NUM_ADDERS;

  generate
    if (NUM_ADDERS > 1) begin : gen_adder_pipe
      /* Check if NUM_ADDERS is a power of 2 */
      localparam integer LOG2_NUM_ADDERS = $clog2(NUM_ADDERS);
      if (2 ** LOG2_NUM_ADDERS != NUM_ADDERS) begin : gen_adder_pipe_error
        $fatal("NUM_ADDERS must be a power of 2");
      end else begin  // gen_adder_pipe_error
        logic [ADDER_WIDTH-1:0] a  [NUM_ADDERS:0];
        logic [ADDER_WIDTH-1:0] b  [NUM_ADDERS:0];
        logic [   NUM_ADDERS:0] c;

        /* Splat the Operands */
        for (genvar i = 0; i < NUM_ADDERS; i = i + 1) begin : gen_adder_pipe_splat_operands
          assign a[i] = in0[(i+1)*ADDER_WIDTH-1:i*ADDER_WIDTH];
          assign b[i] = in1[(i+1)*ADDER_WIDTH-1:i*ADDER_WIDTH];
        end


        /* Generate The Lane */
        for (genvar i = 0; i < NUM_ADDERS; i = i + 1) begin : gen_adder_pipe_adder_lane
          logic [ADDER_WIDTH-1:0] a_i  [             i:0];
          logic [ADDER_WIDTH-1:0] b_i  [             i:0];
          logic [ADDER_WIDTH-1:0] sum_i[NUM_ADDERS-1-i:0];
          logic                   c_i;

          assign a_i[0] = a[i];
          assign b_i[0] = b[i];

          /* Flops in Front of the adder for a and b */
          if (i > 0) begin : gen_cpa_0_adder_flop_front
            for (genvar j = 0; j < i; j = j + 1) begin : gen_cpa_0_adder_flop_front_inner
              register #(2 * ADDER_WIDTH) a_dff_inst (
                  .clk (clk),
                  .din ({a_i[j], b_i[j]}),
                  .dout({a_i[j+1], b_i[j+1]})
              );
            end
          end else begin
            assign {c[0], a_i[0], b_i[0]} = {cin, a[0], b[0]};
          end

          /* Adder */
          adder #(
              .WIDTH    (ADDER_WIDTH),
              .ALGORITHM(ALGORITHM)
          ) adder_inst (
              .in0 (a_i[i]),
              .in1 (b_i[i]),
              .cin (c[i]),
              .sum (sum_i[0]),
              .cout(c_i)
          );

          /* Flop for the carry out - JUST ONE TO THE NEXT STAGE */
          if (i < NUM_ADDERS - 1) begin : gen_cpa_0_adder_flop_carry_out
            register #(1) c_dff_inst (
                .clk (clk),
                .din (c_i),
                .dout(c[i+1])
            );
          end else begin
            assign cout = c_i;
          end

          /* Flops in Back of the adder for sum */
          if (i < NUM_ADDERS - 1) begin : gen_cpa_0_adder_flop_back
            for (
                genvar j = 0; j < NUM_ADDERS - i - 1; j = j + 1
            ) begin : gen_cpa_0_adder_flop_back_inner
              register #(ADDER_WIDTH) sum_dff_inst (
                  .clk (clk),
                  .din (sum_i[j]),
                  .dout(sum_i[j+1])
              );
            end
          end
          /* Assign to the output */
          assign sum[(i+1)*ADDER_WIDTH-1:i*ADDER_WIDTH] = sum_i[NUM_ADDERS-1-i];
        end  // gen_cpa_0_adder_lane
      end
    end else begin
      adder #(
          .WIDTH    (WIDTH),
          .ALGORITHM(ALGORITHM)
      ) adder_inst (
          .in0 (in0),
          .in1 (in1),
          .cin (cin),
          .sum (sum),
          .cout(cout)
      );
    end
  endgenerate

endmodule
