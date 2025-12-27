module adder #(
    parameter integer WIDTH,
    parameter integer ALGORITHM  // 0: Ripple-Carry, 1: Carry-Look-Ahead
) (
    input  logic [WIDTH-1:0] in0,
    input  logic [WIDTH-1:0] in1,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout
);

  generate
    if (ALGORITHM == 0) begin  /* Ripple-Carry Adder */
      logic [WIDTH:0] sum_i;
      logic [WIDTH:0] carry_i;

      for (genvar i = 0; i < WIDTH; i = i + 1) begin
        if (i == 0) begin
          fa fa_inst (
              .a   (in0[i]),
              .b   (in1[i]),
              .cin (cin),
              .sum (sum_i[i]),
              .cout(carry_i[i])
          );
        end else begin
          fa fa_inst (
              .a   (in0[i]),
              .b   (in1[i]),
              .cin (carry_i[i-1]),
              .sum (sum_i[i]),
              .cout(carry_i[i])
          );
        end
      end
      assign sum  = sum_i;
      assign cout = carry_i[WIDTH-1];
    end else if (ALGORITHM == 1) begin  /* Carry-Look-Ahead Adder */
      localparam integer CLA_WIDTH = 4;
      localparam integer CLA_COUNT = WIDTH / CLA_WIDTH;

      logic [CLA_WIDTH-1:0] in0_i[CLA_COUNT];
      logic [CLA_WIDTH-1:0] in1_i[CLA_COUNT];
      logic [CLA_WIDTH-1:0] sum_i[CLA_COUNT];
      logic [CLA_COUNT:0] carry_i;

      for (genvar i = 0; i < CLA_COUNT; i = i + 1) begin
        assign in0_i[i] = in0[CLA_WIDTH*(i+1)-1:CLA_WIDTH*i];
        assign in1_i[i] = in1[CLA_WIDTH*(i+1)-1:CLA_WIDTH*i];
      end

      for (genvar i = 0; i < CLA_COUNT; i = i + 1) begin
        if (i == 0) begin
          cla_4 cla_4_inst (
              .in0 (in0_i[i]),
              .in1 (in1_i[i]),
              .cin (cin),
              .sum (sum_i[i]),
              .cout(carry_i[i])
          );
        end else begin
          cla_4 cla_4_inst (
              .in0 (in0_i[i]),
              .in1 (in1_i[i]),
              .cin (carry_i[i-1]),
              .sum (sum_i[i]),
              .cout(carry_i[i])
          );
        end
        assign sum[CLA_WIDTH*(i+1)-1:CLA_WIDTH*i] = sum_i[i];
      end
      assign cout = carry_i[CLA_COUNT-1];
    end
  endgenerate
endmodule

