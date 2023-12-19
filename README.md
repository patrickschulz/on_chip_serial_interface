# Serial Interface for Digital Control of Analog Integrated Circuits
This repository provides code for generating a serial interface with minimized pin count for inclusion in analog integrated circuits for research applications.

## Introduction
In many current research topics in the realm of analog integrated circuits, analog designers include digital calibration and settings in their circuits (e.g. resistor/capacitor tuning, delay line modification etc.).
In order to control these calibration bits often a serial interface is used, as there are too many bits for a parallel connection.
This can be either because there are a lot of bits or just because no bonding is done and the bare die is measured on a wafer prober.
Especially in the latter case the pin count of any additional circuitry must be minimized.
The serial interface in this repository provides a control circuit which only uses two bits: clock and a bidirectional data pin.

## Generation
The verilog (RTL) code can be generated in the `verilog` subfolder by running `make export`.
This creates two files: `serial_interface.v` and `serial_interface_defines.v`.
The first one contains the code for the serial interface, the second one creates a file with a macro defining the width of the internal data bus.
This can be included in a larger code base if this length is required.

## Customization
The generation depends on a reset pattern, that is, the data that is present on-chip after a reset.
Typically this should be some sensible default data for the analog circuitry.
Therefore, the entire interface is defined solely by this reset pattern (the data length is derived from the pattern, therefore all bits must be specified).
There is an example file `generate_example_resetpattern.lua`, which generates a `resetpattern.lua`.
The generation of the code of the serial interface expects the second file.
For customization, this file should be modified by the user.
It is a regular lua file, which should return one table with 1s and 0s.
