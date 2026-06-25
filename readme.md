# FPGA Square Wave Synthesizer

An 8-voice polyphonic square-wave synthesizer implemented on the DE10-Lite (MAX-10 FPGA) in VHDL, producing real-time audio output via I²S at ~45.95 kHz sample rate.

## Demo

▶️ [Watch the demo](https://youtu.be/l18Umr7pZi4)

## Report

🛈 [Read the report](/docs/main.pdf)

## Contributors

- **Josué Bouchard** — Note generator design, pin assignments, simulation, polyphonic mixer logic
- **Abigail John** — I²S controller design, top-level module integration, hardware connections

## Overview

Polyphonic audio synthesis requires computing multiple independent voices simultaneously under strict timing constraints. At CD-quality sample rates, the next state for all oscillators must be computed and mixed every ~22.7 microseconds. An FPGA is well-suited for this task because each voice can be implemented as an independent hardware datapath running in parallel, eliminating the sequential bottleneck inherent to software execution.

This project synthesizes 8 simultaneous square-wave voices tuned to the C major scale (C4–C5) using equal temperament, mixes them into a single signed 16-bit audio stream, and outputs it via I²S to a MAX98357 amplifier connected to a speaker.

## Architecture

The system is composed of five VHDL modules:

### `square_wave_generator`
A toggle divider that generates a square wave at a specified frequency by counting clock cycles. Takes a generic parameter `N` (the toggle count) derived from the 50 MHz input clock and the desired output frequency.

### `voice_generators`
Instantiates multiple `square_wave_generator` components in parallel, one per voice. Each voice has an individual enable signal; disabled voices output 0. The toggle divider values are precomputed using equal temperament tuning:

```julia
# Distance in semitones from A4 → frequency → toggle count
f(semitones) = semitones .|> n -> 440*2^(n/12) .|> n -> round(50_000_000/n * 0.5) .|> Int
# C4, D4, E4, F4, G4, A4, B4, C5 = [-9, -7, -5, -4, -2, 0, 2, 3]
# Result: (47778, 50619, 56818, 63776, 71587, 75843, 85131, 95551)
```

### `voice_mixer`
Centers each square wave from [0,1] to [-1,+1], sums all active voices, and scales the result to fit within a signed 16-bit integer without clipping. Handles up to 8 simultaneous voices.

### `i2s_controller`
Converts the 16-bit amplitude signal into a serial I²S stream. Derives BCLK (~1.6 MHz) and LRCLK (~45.95 kHz) from the 50 MHz system clock. Outputs mono audio on the left channel; right channel is silent.

### `top_synth` / `synth`
`top_synth` is the parameterized top-level component that wires all modules together. `synth` is a wrapper around `top_synth` to work around Quartus's limitation with array generics in top-level components.

## Hardware

| Component | Part |
|---|---|
| FPGA Board | DE10-Lite (Intel MAX-10) |
| Amplifier | MAX98357 I²S Class D |
| Speaker | 3W 8Ω |

### Pin Assignments

| Signal | DE10-Lite Pin |
|---|---|
| Clock (50 MHz) | PIN_P11 |
| Reset (KEY0) | PIN_B8 |
| Enable (SW[7:0]) | PIN_C10–PIN_A14 |
| BCLK | PIN_W10 |
| LRCLK | PIN_V10 |
| DATA | PIN_V9 |

## Validation

Voice generator frequencies were verified on an oscilloscope against theoretical equal temperament values:

| Note | Measured (Hz) | Theoretical (Hz) | Error (Hz) |
|---|---|---|---|
| C3 | 261.64 | 261.63 | 0.01 |
| D3 | 293.77 | 293.66 | 0.11 |
| E3 | 329.59 | 329.62 | 0.03 |

Voice mixer behavior was verified via functional simulation in University Program VWF, confirming correct centering, scaling, and independence of channels.

Full system validation was performed by toggling the DE10-Lite switches to enable individual notes and chords through the speaker.

## Requirements

- Quartus Prime (Lite edition is sufficient)
- DE10-Lite board with MAX-10 FPGA
- MAX98357 I²S amplifier module
- 3W 8Ω speaker