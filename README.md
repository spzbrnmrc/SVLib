# SVLib: A synthesizable SystemVerilog Library for ASIC and FPGA design

## Overview

Reusable RTL primitives used by Tiny-Vedas and other Siliscale designs. Sources
live under `src/`; the Tiny-Vedas file lists pull in the arithmetic and register
blocks required by `core_top`.

## Modules

### Registers and register files

| Path | Description |
|------|-------------|
| `src/registers_regfiles/register.sv` | Generic DFF |
| `src/registers_regfiles/register_sync_rstn.sv` | DFF with synchronous reset |
| `src/registers_regfiles/register_en_sync_rstn.sv` | Enabled DFF with sync reset |
| `src/registers_regfiles/register_en_flush_sync_rstn.sv` | Enabled DFF with flush |
| `src/registers_regfiles/register_en_sync_rstn_vector.sv` | Vector of enabled DFFs |
| `src/registers_regfiles/program_counter.sv` | Program counter |

### Arithmetic

| Path | Description |
|------|-------------|
| `src/arith/fa.sv`, `ha.sv` | Full / half adders |
| `src/arith/cla_4.sv` | 4-bit carry-look-ahead block |
| `src/arith/adder.sv` | Parametric adder: `ALGORITHM` 0=RCA, 1=CLA, 2=Kogge-Stone (combinational) |
| `src/arith/adder_pipe.sv` | Pipelined multi-lane CPA (multiplier CPA options 0/1) |
| `src/arith/kogge_stone_adder.sv` | **`kogge_stone_adder`** — combinational Kogge-Stone; **`kogge_stone_pipe`** — 2-cycle pipelined variant (one flop) |
| `src/arith/csa_3_2.sv`, `csa_4_2.sv` | Carry-save compressors |
| `src/arith/booth_encoder.sv` | Radix-4 Booth partial-product encoder |
| `src/arith/mul.sv` | Booth-encoded multiplier with per-operand signedness and configurable CSA/CPA pipeline |
| `src/arith/twoscomp.sv` | Two's complement helper |

### Integer multipliers (Tiny-Vedas usage)

`mul` parameters of interest:

| Parameter | Meaning |
|-----------|---------|
| `WIDTH` | Operand width (8 / 16 / 32 / 64) |
| `a_sign`, `b_sign` | Per-operand signedness (ports) |
| `CPA_ALGORITHM` | `0` RCA, `1` CLA (`adder_pipe`), `2` Kogge-Stone (`kogge_stone_pipe`) |
| `PIPE_STAGE_AFTER_BOOTH` | Flop after Booth encoders |
| `PIPE_STAGE_CSA_LR1` … `LR4` | Flops after CSA tree layers |
| `PIPE_STAGES_CPA` | Lane count for `adder_pipe` (ignored when `CPA_ALGORITHM=2`) |

Mixed signed×unsigned multiply (e.g. RV32 `MULHSU`) requires separate
multiplicand sign extension and unsigned-multiplier Booth correction inside
`mul` — not a single global unsigned flag.

### Other

| Path | Description |
|------|-------------|
| `src/arith/kogge_stone_adder.sv` | Also contains `kogge_stone_prefix` (prefix-network building block) |

Clock-domain crossing and clock-gating blocks may be present in other branches
of the upstream SVLib repository.

For business inquiries, reach out at [info@siliscale.com](mailto:info@siliscale.com).
