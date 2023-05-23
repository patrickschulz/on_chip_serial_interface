opc := /home/pkurth/Workspace/openPCells/opc

serial_interface.gds: generate.lua data_counter.lua register_cell.lua reset_counter.lua serial_ctrl.lua shift_register.lua
	${opc} --cellpath .. --technology GF22FDSOI --export gds --cellscript generate.lua --enable-dprint
