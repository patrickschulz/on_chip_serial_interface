sources := config.v register_cell.v shift_register.v data_counter.v reset_counter.v serial_ctrl.v toplevel.v
gatelevelsources := down_counter.v
stdlib := /home/pkurth/Workspace/openPCells/resources/opc
VFLAGS := -g2012

# intermediate files
timing_script := timing.tcl

.PHONY: all
all:
	@echo possible actions:
	@echo " simulate"
	@echo " synth"
	@echo " timing"

.PHONY: simulate
simulate:
	iverilog $(VFLAGS) $(stdlib).v $(sources) $(gatelevelsources) testbench.v -o design
	vvp design
	iverilog $(VFLAGS) $(stdlib).v $(sources) $(gatelevelsources) testbench_reset.v -o design
	vvp design
	rm design

.PHONY: simulate_synth
simulate_synth: synth
	iverilog $(VFLAGS) config.v serial_interface_synthesized.v testbench.v $(stdlib).v -o design
	vvp design
	rm design

.PHONY: waveforms
waveforms:
	gtkwave -A --rcvar 'fontname_signals Monospace 14' --rcvar 'fontname_waves Monospace 10' signals.vcd signals.gtkw &

.PHONY: check
check:
	for source in $(sources); do printf "read_verilog %s\n" "$$source" >> synthesize; done
	echo synth -top serial_interface >> synthesize
	echo stat >> synthesize
	yosys -s synthesize
	rm synthesize

serial_interface_synthesized.v: $(sources)
	rm -f synthesize
	for source in $(sources); do printf "read_verilog -sv %s\n" "$$source" >> synthesize; done
	echo read_liberty -lib $(stdlib).lib >> synthesize
	echo synth -top serial_interface >> synthesize
	echo dfflibmap -liberty $(stdlib).lib >> synthesize
	echo abc -liberty $(stdlib).lib >> synthesize
	echo opt >> synthesize
	echo opt_clean -purge >> synthesize
	echo clean >> synthesize
	#echo flatten >> synthesize
	echo stat -liberty $(stdlib).lib >> synthesize
	echo write_verilog serial_interface_synthesized.v >> synthesize
	yosys -s synthesize
	rm synthesize

.PHONY: synth
synth: serial_interface_synthesized.v

.PHONY: timing
timing: synth
	rm -f $(timing_script)
	echo read_verilog serial_interface_synthesized.v > $(timing_script)
	echo read_liberty $(stdlib).lib >> $(timing_script)
	echo link_design serial_interface >> $(timing_script)
	echo create_clock -name clk -period 10000 {clk} >> $(timing_script)
	echo report_checks -path_delay min_max >> $(timing_script)
	sta -exit -no_splash $(timing_script)
	rm $(timing_script)
