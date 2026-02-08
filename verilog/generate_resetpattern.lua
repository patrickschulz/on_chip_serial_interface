local registers = {
    {
        name = "idac_ctrl0",
        data = { 0, 0, 1, 0, 0, 0, 0, 0 },
    },
    {
        name = "idac_ctrl1",
        data = { 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    {
        name = "drive_strength0",
        data = { 0, 0, 0, 0, 1, 1, 1, 1 },
    },
    {
        name = "drive_strength1",
        data = { 0, 0, 0, 0, 1, 1, 1, 1 },
    },
}

-- check register length
local reglength
for _, reg in ipairs(registers) do
    if not reglength then
        reglength = #reg.data
    else
        if reglength ~= #reg.data then
            error("register bit lengths do not match")
        end
    end
end

local file = io.open("resetpattern.lua", "w")

file:write("return {\n")

for _, reg in ipairs(registers) do
    file:write("    ")
    file:write(string.format("-- register: %s\n", reg.name))
    file:write("    ")
    for _, bit in ipairs(reg.data) do
        file:write(string.format("%d, ", bit))
    end
    file:write("\n")
end

file:write("}")

file:close()
