-- interface configuration
local settings = require "settings"

-- utility functions
local util = require "util"

-- sub-modules
local control = require "control"
local reset_counter = require "reset_counter"
local data_counter = require "data_counter"
local shift_register = require "shift_register"

-- control whether to generate sub-modules
local generate_flat = true

-- target file and content lines
local toplevelfile = io.open("serial_interface.v", "w")
local lines = util.make_lines_insert()

-- write sub-modules
if not generate_flat then
    local control_lines = control(settings, false)
    toplevelfile:write(table.concat(control_lines, "\n"))
    toplevelfile:write("\n")
    toplevelfile:write("\n")

    local reset_counter_lines = reset_counter(settings, false)
    toplevelfile:write(table.concat(reset_counter_lines, "\n"))
    toplevelfile:write("\n")
    toplevelfile:write("\n")

    local data_counter_lines = data_counter(settings, false)
    toplevelfile:write(table.concat(data_counter_lines, "\n"))
    toplevelfile:write("\n")
    toplevelfile:write("\n")

    local shift_register_lines = shift_register(settings, false)
    toplevelfile:write(table.concat(shift_register_lines, "\n"))
    toplevelfile:write("\n")
    toplevelfile:write("\n")
end

-- toplevel module header
lines:add("module serial_interface")

-- toplevel ports
lines:add("(")
lines:add("    /* off-chip ports (but only data_inout and clk actually cross the chip boundary) */")
lines:add("    input wire clk,")
lines:add("    input wire data_in,")
lines:add("    output wire data_out,")
lines:add("    /* on-chip ports */")
lines:add("    output wire write,")
if generate_flat then -- if no sub-modules are present, the bit registers are in the toplevel modules
    lines:add("    output reg [%d:0] bit_out", settings.data_length - 1)
else -- if hierarchy is present, the bit registers are in the shift_register module
    lines:add("    output wire [%d:0] bit_out", settings.data_length - 1)
end
lines:add(");")

-- internal wires
lines:add("    // internal wires")
lines:add("    wire enable_data_counter;")
lines:add("    wire data_ready;")
lines:add("    wire reset_internal;")
lines:add("    wire update_shift_register;")
lines:add("    wire reset_shift_register;")
lines:add("    wire enable_shift_register;")
lines:add("    wire data_out_shift_reg;")
lines:add("    wire write_shift_register;")
lines:add("")

if generate_flat then
    -- control lines
    local control_lines = control(settings, true)
    util.append_lines(lines, control_lines)

    -- reset counter
    local reset_counter_lines = reset_counter(settings, true)
    util.append_lines(lines, reset_counter_lines)

    -- data counter
    local data_counter_lines = data_counter(settings, true)
    util.append_lines(lines, data_counter_lines)

    -- shift register
    local shift_register_lines = shift_register(settings, true)
    util.append_lines(lines, shift_register_lines)
else
    lines:add("    serial_ctrl control (")
    lines:add("        .clk(clk),")
    lines:add("        .data_in(data_in),")
    lines:add("        .write(write),")
    lines:add("        .data_ready(data_ready),")
    lines:add("        .reset_internal(reset_internal),")
    lines:add("        .enable_data_counter(enable_data_counter),")
    lines:add("        .update_shift_register(update_shift_register),")
    lines:add("        .reset_shift_register(reset_shift_register),")
    lines:add("        .enable_shift_register(enable_shift_register),")
    lines:add("        .write_shift_register(write_shift_register)")
    lines:add("    );")
    lines:add("")
    lines:add("    reset_counter reset_counter (")
    lines:add("        .clk(clk),")
    lines:add("        .data_in(data_in),")
    lines:add("        .reset_internal(reset_internal)")
    lines:add("    );")
    lines:add("")
    lines:add("    data_counter data_counter (")
    lines:add("        .clk(clk),")
    lines:add("        .enable_data_counter(enable_data_counter),")
    lines:add("        .data_ready(data_ready)")
    lines:add("    );")
    lines:add("")
    lines:add("    shift_register daisychain (")
    lines:add("        .clk(clk),")
    lines:add("        .data_in(data_in),")
    lines:add("        .update_shift_register(update_shift_register),")
    lines:add("        .reset_shift_register(reset_shift_register),")
    lines:add("        .enable_shift_register(enable_shift_register),")
    lines:add("        .write_shift_register(write_shift_register),")
    lines:add("        .data_out(data_out),")
    lines:add("        .bit_out(bit_out)")
    lines:add("    );")
end

-- finished toplevel module
lines:add("endmodule")

toplevelfile:write(table.concat(lines, "\n"))
toplevelfile:close()

-- generate defines file (number of bits)
local definesfile = io.open("serial_interface_defines.v", "w")
definesfile:write(string.format("`define SERIAL_INTERFACE_DATA_LENGTH %d", settings.data_length))
definesfile:close()
