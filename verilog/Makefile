sources := config.v data_counter.v reset_counter.v serial_ctrl.v command_register.v toplevel.v
gatelevelsources := register_cell.v shift_register.v down_counter.v
stdlib := /home/pkurth/Workspace/openPCells/resources/opc
VFLAGS := -g2012

# intermediate files
compiled_design  := design
synthesis_script := sythesize
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
	@echo "  simulate"
	@echo "  synth"
	@echo "  simulate_synth"
	@echo "  waveforms"
	@echo "  timing"
	@echo required tools are iverilog for simulation, gtkwave for viewing the waveforms, yosys for synthesis and openSTA for timing analysis

.PHONY: simulate
simulate:
	@$(simulator) $(VFLAGS) $(stdlib).v $(sources) $(gatelevelsources) testbench.v -o $(compiled_design)
	@$(simulator_vm) $(compiled_design)
	@rm $(compiled_design)

.PHONY: simulate_synth
simulate_synth: synth
	@$(simulator) $(VFLAGS) config.v serial_interface_synthesized.v testbench.v $(stdlib).v -o $(compiled_design)
	@$(simulator_vm) $(compiled_design)
	@rm $(compiled_design)

.PHONY: waveforms
waveforms:
	@$(waveformviewer) -O /dev/null -A --rcvar 'fontname_signals Monospace 14' --rcvar 'fontname_waves Monospace 10' signals.vcd signals.gtkw &

serial_interface_synthesized.v: $(sources) $(gatelevelsources)
	@echo "synthesizing..."
	@echo "# RTL sources" > $(synthesis_script);
	@for source in $(sources); do printf "read_verilog -sv %s\n" "$$source" >> $(synthesis_script); done
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
	@rm -f serial_interface_synthesized.v
