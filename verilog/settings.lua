local resetpattern = { 0, 0, 0, 0, 0, 0, 0, 0 }
local data_length = #resetpattern
local data_numbits = math.ceil(math.log(data_length + 1, 2))

local start_pattern = { 1, 0, 1 }

--[[
    the minimum number of consecutive ones for internal reset
    depends on the longest legal sequence of ones
    every command ends with a zero stop bit
    when 1...1 is sent as data, this data are surrounded by:
    START SEQUENCE (101) + stop bit (0) + 1...1 + high value of next start pattern
    this means that !WITH THE CURRENT START SEQUENCE! the longest legal consecutive
    sequence of ones is DATA_LEN + 1
    the number of reset bits must be the *next* power of two
    (e.g. if DATA_LEN + 1 is 4, the number of reset bits must be 8!)
    the following expression calculates this by adding one more (+2)
    FIXME: for a very small DATA_LEN, the command length has to be considered
    as well, as the command register needs to be flushed during the reset
    this is important for the interfacing circuits
--]]
local reset_length = math.ceil(math.log(data_length + 2, 2)) + 1
local reset_numbits = 2 ^ reset_length

-- command types to be received from the external controller
-- after a command a zero stop bit is sent
-- this ensures that the line is pulled down after a command
local commands = {
    reset   = { 0, 0, },
    update  = { 0, 1, },
    receive = { 1, 0, },
    send    = { 1, 1, },
}
local commands_length = 0
for _, command in pairs(commands) do
    local len = #command
    if commands_length > 0 and len ~= commands_length then
        error("all commands must have the same number of bits!")
    end
    commands_length = len
end

local idle_cycles = 5 -- FIXME: figure out the correct value for this
                      --        this is most likely more of an issue for low data lenghts
                      --        furthermore, it depends on the exact sequence of commands so also an update could be problematic

return {
    resetpattern = resetpattern,
    data_length = data_length,
    data_numbits = data_numbits,
    reset_length = reset_length,
    reset_numbits = reset_numbits,
    start_pattern = start_pattern,
    start_pattern_length = #start_pattern,
    commands = commands,
    commands_length = commands_length,
    idle_cycles = idle_cycles
}
