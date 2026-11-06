# 🐍 Serpent-128 Basic Verilog Design in ~1000 LoCs.

## About

Exploring **Cryptography** and **Hardware Design**.

This repository is an attempt to bring the Serpent-128 block cipher to life using Verilog HDL.

## Why Serpent?

Serpent was one of the five finalists in the Advanced Encryption Standard (**AES**) competition.

Designed by **Ross Anderson**, **Eli Biham** and **Lars Knudsen**, it is a fascinating algorithm from a hardware enthusiast's perspective.

## Architecture

- 128-bit data blocks.
- 128-bit encryption keys.
- 32 encryption rounds.
- Eight different substitution boxes.
- A linear transformation based on 32-bit rotations and XOR operations.
- A dedicated key expansion algorithm.

**Key Expansion**

First came the key schedule.

Starting with a 128-bit key, the key expansion module generates the prekeys and subsequently produces the 33 round keys required by the encryption process.

This was one of the first interesting challenges: getting the word ordering, padding and rotations exactly right.

**S-Boxes**

Serpent uses eight different 4-bit substitution boxes.

I implemented them using Verilog functions and a bit-sliced datapath.

The same S-Box hardware is re-used during the encryption rounds.

**Linear Transformation**

The linear transformation is built around 32-bit rotations and XOR operations.

It is a relatively compact piece of RTL, but getting the word ordering right is essential.

**Encryption Controller**

A finite state machine coordinates the complete encryption process.

The implementation uses an **iterative** architecture: rather than building 32 independent encryption rounds, the hardware reuses the round-processing logic.

This keeps the architecture relatively compact and makes the control sequence easier to explore.

## Project Files
```text
.
├── serpent_encrypt.v
├── serpent_key_expand.v
├── serpent_sbox.v
├── serpent_lt.v
├── serpent_file_tb.v
└── serpent128_vectors.hex
```

| File	                 | Purpose                  |
|------------------------|--------------------------|
| serpent_encrypt.v	 | Main encryption engine   |
| serpent_key_expand.v	 | Key schedule             |
| serpent_sbox.v	 | Eight substitution boxes |
| serpent_lt.v	         | Linear transformation    |
| serpent_file_tb.v	 | Automatic testbench      |
| serpent128_vectors.hex | Reference test vectors   |

## Testing

**Icarus** **Verilog** was used to compile and simulate the complete design.

### Compiling

```bash
iverilog -g2012 -Wall -o serpent_key_sim serpent_sbox.v serpent_key_expand.v serpent_key_tb.v
```

```bash
iverilog -g2012 -Wall -o serpent_sim serpent_sbox.v serpent_lt.v serpent_key_expand.v serpent_encrypt.v serpent_tb.v
```

```bash
iverilog -g2012 -Wall -o serpent_file_sim serpent_file_tb.v serpent_encrypt.v serpent_key_expand.v serpent_sbox.v serpent_lt.v
```

### Simulating

```bash
vvp serpent_file_sim
[...]
========================================
 SERPENT-128 TEST SUMMARY
========================================
TOTAL TESTS : 1028
PASSED      : 1028
FAILED      : 0
TIMEOUTS    : 0
----------------------------------------
OVERALL RESULT: PASS
========================================
```

**1028** vectors. **1028** successful results.

This verification was performed in simulation. FPGA synthesis, hardware validation and timing analysis remain possible future steps.

## Tools

The project was developed and simulated using:

- **Verilog** HDL.
- **Icarus** **Verilog**.
- **GTKWave** (optional, for waveform inspection).
- Linux command line.

No FPGA board is required to run the simulation.

## What's Next?

There is still plenty to explore:

- Synthesis and FPGA implementation.
- Resource utilisation analysis.
- Timing optimisation.
- Waveform inspection.
- Comparing iterative and fully pipelined implementations.

## Author
**Pierre GENARD**

### Happy Hacking! 🐍
