local file = io.open("resetpattern.lua", "w")

file:write("return {\n")

for i = 1, 8 do
    file:write(string.format("    %d,\n", 0))
end

file:write("}")

file:close()
