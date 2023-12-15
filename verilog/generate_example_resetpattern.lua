local file = io.open("resetpattern.lua", "w")

file:write("return {\n")

for i = 1, 8 do
    file:write(string.format("    %d,\n", i % 2 == 0 and 1 or 0))
end

file:write("}")

file:close()
