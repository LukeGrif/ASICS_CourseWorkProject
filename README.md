# Reaction Timer and Programmable Pulse Generator

## Overview

This repository contains the source code and reports for a coursework project undertaken as part of
the **EE6621 (ASICS)** module at the University of Limerick.  The assignment builds on the
provided **`rt2` reaction timer** design, whose objective is to measure the time between an
audible start beep and a human pressing a push‑button.  The original reaction timer measures
intervals from 0 ms to 9999 ms with 1 ms resolution and displays the result on a 6‑character,
common‑anode 7‑segment display.  An FPGA wrapper instantiates the reaction timer module,
generates a 100 MHz system clock and maps the interface signals to the **Cmod A7** board used
in EE6621 labs.  The extended project described here (referred to as **pg03**) retains the
original reaction timer behaviour while adding a programmable pulse generator and other new
features.  These enhancements include a configurable pulse width (`tph`), adjustable pulse
repetition frequency and a pseudo‑random bit‑sequence (PRBS) mode.

<img width="263" height="209" alt="image" src="https://github.com/user-attachments/assets/992971b4-077a-425c-a8fc-9dd718c305e1" />

> Componenets added using SMT Prototyping station

## Module and Platform

The design targets the **Cmod A7 FPGA** module, which integrates an Artix‑7 FPGA, six
7‑segment display characters, two user push‑buttons and a piezo buzzer.  A 12 MHz crystal
oscillator on the board is multiplied and divided in the wrapper to generate the 100 MHz system
clock used by the reaction timer and the new pulse‑generator.  All logic is written in Verilog and
constrained for the Artix‑7 implementation; the design could also be synthesised for an
ASIC using the XFAB 180 nm library specified in the coursework brief.

## Project Description (pg03)

The extended project uses the `rt2` design as a foundation and adds a configurable pulse
generator.  A concise description of the development steps is given below:

- **Start from `rt2` template:** The display driver and state machine of `rt2` were reused
  and extended to support the new features.
- **Signal‐out module:** A new module and testbench were created to generate the
  `signal_out` waveform; its period (`tph`) can be configured and is displayed alongside the
  reaction timer information.
- **Configurable `tph` value:** Additional states were added to the `fsm_game` state
  machine to allow two FPGA buttons to increment or decrement the pulse width; the
  value can be adjusted between 0.1 µs and 9.9 µs and is displayed in real time.
- **Button integration:** Push‑button handling reused code from `test02`; the buttons
  change state and modify `tph`.  The onboard JA pins were wired out so that the
  `signal_out` waveform could be measured externally.
- **Buzzer integration:** The buzzer is enabled to provide audible feedback whenever any
  button is pressed.
- **PRBS mode:** An 8‑bit linear feedback shift register (LFSR) was implemented to
  generate a pseudo‑random bit sequence; the LFSR advances at a user‑set frequency
  and asserts a rollover signal every 256 states.  The LFSR output replaces the normal
  pulse output when PRBS mode is selected.
- **Frequency adjustment:** A binary search algorithm computes the necessary cycle count
  for a desired frequency without performing an expensive division.  This algorithm uses
  simple add/shift/compare operations and a multiplier to converge on the correct period.
  It maintains upper and lower bounds, calculates the midpoint, and refines the range
  until the final period is found.
- **Composite video (partial):** Work began on generating composite video output to
  display “pg03” on a monitor.  This feature was removed because it interfered with
  timing on the pulse generator.

## Implemented Features

The project specification divided the enhancements into *M*, *L* and *XL* tiers.  The status of
each feature in the final implementation is summarised below:

| Feature | Description | Status |
|---|---|---|
| **signal_out and signal_cycle** | Generate an output pulse and cycle count for the external JA connector | **Implemented** |
| **Configurable `tph` value** | User can adjust pulse width between 0.1 µs and 9.9 µs | **Implemented** |
| **Push‑buttons** | Buttons mapped via `muxpb` and `buttons[1:0]` allow state changes and `tph` adjustment; ESC button intermittently failed | **Implemented** |
| **7‑segment display** | Shows start‑up information, current mode and configured parameters | **Implemented** |
| **Pulse‑mode defaults** | Default pulse width of 2.5 µs and frequency of 50 kHz | **Implemented** |
| **Blinking state** | Display blinks when editing `tph` values | **Implemented** |
| **Buzzer on button press** | Audible feedback via piezo buzzer when any button is pressed | **Implemented** |
| **Pulse output on Pmod** | Pulse signal can be accessed via a Pmod connector | **Implemented** |
| **User‑adjustable pulse repetition frequency (L)** | Frequency can be set by the user using the binary search period converter | **Implemented** |
| **PRBS mode (L)** | Pseudo‑random bit sequence generated by an 8‑bit LFSR | **Implemented** |
| **Composite video (XL)** | Display project name over composite video output | **Partially implemented** – only “pg03” text could be displayed |

<img width="1145" height="482" alt="image" src="https://github.com/user-attachments/assets/9d948b68-ee94-4364-a60d-9d22d516918f" />

> Initial Operating conditions (tph = 2.5 μs & f = 50Hz)

<img width="1147" height="489" alt="image" src="https://github.com/user-attachments/assets/616d01b6-f7cb-4242-88d4-9f31a767b3ad" />

> Maximum Operating conditions (tph = 9.9 μs & f = 99.9Hz)

<img width="1091" height="467" alt="image" src="https://github.com/user-attachments/assets/7a7e9658-b965-4ac8-b3ba-abad78649d7f" />

> Example of scenario when the device is put into PRBS mode.

<img width="1047" height="444" alt="image" src="https://github.com/user-attachments/assets/ea25e6d4-e0ba-45f0-b817-1f6ad829d89f" />

> Measurement of signal_cycle showing that the pulse width is 100ns

## Hardware Utilisation

Post‑implementation analysis with Xilinx Vivado reports the following resource utilisation for
the complete design:

<img width="1155" height="522" alt="image" src="https://github.com/user-attachments/assets/f7d3e333-c4e1-4072-a71b-ade32268fb26" />

> Hardware Utilization Report

* **Total resources used:** 1 030 slice LUTs and 753 slice registers, out of 20 800 and
  41 600 available respectively.  This corresponds to around 5 % LUT and 1.8 % register
  utilisation on the target Artix‑7 device.
* **Frequency converter block:** The `frequency_algorithm` consumes 144 LUTs and 145
  registers, representing approximately 14 % of total LUT usage and 19 % of total register
  usage.  It is therefore the dominant contributor to resource
  consumption.
* **Scope for optimisation:** While the overall design easily fits into the target device, the
  frequency converter could potentially be optimised by sharing resources or simplifying
  the binary search logic.

## Bench Verification and Measurement

Verification was performed through simulation and hardware measurements:

* **Functional testbenches:** Separate Verilog testbenches were written for the
  `signal_out` module, the binary search frequency algorithm and the PRBS generator.
* **Scope measurements:** The pulse width and frequency were measured on an oscilloscope for
  several configurations.  At the default settings (2.5 µs, 50 kHz) the waveform matched
  the expected timing.  The maximum configuration (9.9 µs, ≈99 kHz) and minimum
  configuration (0.1 µs, ≈3.2 kHz) were also measured and found to be close to the target
  values.  PRBS mode produced a pseudo‑random stream whose average voltage was
  approximately half the supply voltage, indicating an equal number of ones and zeros.

<img width="1147" height="597" alt="image" src="https://github.com/user-attachments/assets/2d385b4d-935f-4703-ad4c-5b09e6124fff" />

> Testbench Simulation results for frequency_algorithm and random_generator

## Design Files and Reused Modules

The project reuses many modules from `rt2` and earlier lab examples.  The following files
were reused without modification: `buzzer.v`, `clkgen_cmod_a7.v`, `counter_down_rld.v`,
`debounce.v`, `display_7s.v`, `display_7s_mux.v`, `mbutton.v`, `synchroniser_3s.v`, `cv_char` and
related character ROM modules.  Existing source files were adapted to create
`fpga_wrapper_pg03.v` (based on `fpga_wrapper_rt2.v`), `fsm_game.v` and the top‐level `pg03.v`.
Constraint files such as `cmod‑a7‑config.xdc` and `rt2.xdc` were also reused.

## Build and Run Instructions

1. **Prerequisites:** Install Xilinx Vivado 2023.1 or later.  Ensure that the Artix‑7 device support
   and the Digilent board files for the Cmod A7 are installed.
2. **Clone this repository:** The repository contains Verilog source files, constraint files and
   testbenches.  Open the project in Vivado and create a new project targeting the
   **xc7a35tcpg236‑1** (or **xc7a15tcpg236‑1** for the smaller board) device.
3. **Add sources and constraints:** Add all `.v` files in the `src` directory and the relevant
   `.xdc` files.  Set `pg03.v` as the top module.
4. **Simulate:** Run behavioural simulation to verify the reaction timer, pulse generator and
   PRBS functionality.  Use the provided testbenches for `signal_out`, `frequency_algorithm`
   and the random generator.
5. **Synthesize and implement:** Synthesize the design and run implementation.  The design
   should meet timing with only one minor timing warning reported in the final report.
6. **Generate bitstream:** After implementation completes, generate a bitstream (`.bit` file).
7. **Program the board:** Connect the Cmod A7 board via USB and program it with the
   generated bitstream.  Ensure that the 7‑segment display, push‑buttons and buzzer are
   connected as described in the lab hand‑out.  Use the JA port to observe the
   `signal_out` waveform on an oscilloscope.
8. **Operate:** After programming, the design powers up in start‑up mode.  Use the
   push‑buttons to select pulse width and frequency, enter PRBS mode and start new
   reaction timer measurements.  Pressing the buttons while in edit mode will adjust the
   displayed parameter; pressing the main button during steady mode triggers the
   reaction timer.

## Issues and Future Work

* **ESC button glitch:** The ESC button worked during initial development but stopped
  functioning consistently later.  This appears to be a firmware issue rather than a hardware
  failure.
* **Composite video:** Only the string “pg03” could be displayed on a composite monitor.
  Extending the video generator to display dynamic data remains unfinished.
* **Testbench coverage:** Due to time constraints, comprehensive testbenches were only
  written for the frequency conversion and PRBS generator.  Greater test coverage,
  including integration tests, would improve confidence in the design.

## Acknowledgements

The author thanks **Taha Al‑Salihi** and **Michael Cronin** for their support and assistance during the
project.  The coursework report was produced individually.
