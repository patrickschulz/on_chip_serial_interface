gatelevelsources := register_cell_0.v register_cell_1.v shift_register.v
stdlib := /home/pkurth/Workspace/openPCells/resources/opc
VFLAGS := -g2012 -Wall -Wno-timescale

# intermediate files
compiled_design  := design
synthesis_script := synthesize
timing_script 	 := timing.tcl

# tools
simulator    	:= iverilog
simulator_vm 	:= vvp
waveformviewer  := gtkwave
synthesis_tool 	:= yosys
timing_tool 	:= sta

.PHONY: all
all:
	@echo possible actions:
	@echo "  resetpattern"
	@echo "  export"
	@echo "  simulate"
	@echo "  synth"
	@echo "  simulate_synth"
	@echo "  waveforms"
	@echo "  timing"
	@echo required tools are iverilog for simulation, gtkwave for viewing the waveforms, yosys for synthesis and openSTA for timing analysis

.PHONY: resetpattern
resetpattern: resetpattern.lua

.PHONY: export
export: serial_interface.v

.PHONY: simulate
simulate: generate_verilog $(gatelevelsources) testbench.v
	@$(simulator) $(VFLAGS) timescale.v $(stdlib).v $(gatelevelsources) serial_interface.v testbench.v -o $(compiled_design)
	@$(simulator_vm) $(compiled_design)
	@rm $(compiled_design)

.PHONY: simulate_synth
simulate_synth: synth testbench.v
	@$(simulator) $(VFLAGS) timescale.v serial_interface_synthesized.v testbench.v $(stdlib).v -o $(compiled_design)
	@$(simulator_vm) $(compiled_design)
	@rm $(compiled_design)

.PHONY: waveforms
waveforms:
	@$(waveformviewer) -O /dev/null -A --rcvar 'fontname_signals Monospace 14' --rcvar 'fontname_waves Monospace 10' signals.vcd signals.gtkw &

resetpattern.lua: generate_resetpattern.lua
	@lua generate_resetpattern.lua

# generated verilog source files
shift_register.v: generate_shift_register.lua settings.lua resetpattern.lua
	@lua generate_shift_register.lua

serial_interface.v: generate_toplevel.lua settings.lua resetpattern.lua
	@lua generate_toplevel.lua

testbench.v: generate_testbench.lua settings.lua resetpattern.lua
	@lua generate_testbench.lua

serial_interface_synthesized.v: serial_interface.v $(gatelevelsources)
	@echo "synthesizing..."
	@echo "# RTL sources" > $(synthesis_script);
	@printf "read_verilog -sv %s\n" "serial_interface.v" >> $(synthesis_script)
	@echo "# gate-level sources" >> $(synthesis_script);
	@for source in $(gatelevelsources); do printf "read_verilog -sv %s\n" "$$source" >> $(synthesis_script); done
	@echo "# liberty file" >> $(synthesis_script);
	@echo read_liberty -lib $(stdlib).lib >> $(synthesis_script)
	@echo "# synthesis" >> $(synthesis_script);
	@echo synth -top serial_interface >> $(synthesis_script)
	@echo dfflibmap -liberty $(stdlib).lib >> $(synthesis_script)
	@echo abc -liberty $(stdlib).lib >> $(synthesis_script)
	@echo opt >> $(synthesis_script)
	@echo opt_clean -purge >> $(synthesis_script)
	@echo clean >> $(synthesis_script)
	@echo stat -liberty $(stdlib).lib >> $(synthesis_script)
	@echo write_verilog serial_interface_synthesized.v >> $(synthesis_script)
	@$(synthesis_tool) -s $(synthesis_script) -l synthesis.log > /dev/null
	@rm $(synthesis_script)

.PHONY: synth
synth: serial_interface_synthesized.v

.PHONY: timing
timing: synth
	@echo read_verilog serial_interface_synthesized.v > $(timing_script)
	@echo read_liberty $(stdlib).lib >> $(timing_script)
	@echo link_design serial_interface >> $(timing_script)
	@echo create_clock -name clk -period 10000 {clk} >> $(timing_script)
	@echo report_checks -path_delay min_max >> $(timing_script)
	@$(timing_tool) -exit -no_splash $(timing_script)
	@rm $(timing_script)

.PHONY: clean
clean:
	@rm -f resetpattern.lua signals.vcd serial_interface_synthesized.v shift_register.v serial_interface.v serial_interface_defines.v testbench.v synthesis.log
