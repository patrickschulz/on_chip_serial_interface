local M = {}

function M.make_lines_insert()
    local meta = {
        add = function(self, ...)
            table.insert(self, string.format(...))
        end
    }
    meta.__index = meta
    return setmetatable({}, meta)
end

function M.write_lines(filename, lines)
    local file = io.open(filename, "w")
    file:write(table.concat(lines, "\n"))
    file:close()
end

function M.format_binary(binnum)
    local numstr = {}
    for i = 1, #binnum do
        table.insert(numstr, tostring(binnum[i]))
    end
    return string.format("%d'b%s", #binnum, table.concat(numstr))
end

return M
