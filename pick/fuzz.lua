#!/usr/bin/env lua
-- fzf bindings for lua
local M = {}
---@param options string[]
---@param append_numbers boolean? true by default
function M.get_input(options, append_numbers)
	if append_numbers == nil then
		append_numbers = true
	end
	assert(type(options) == "table", "dis function only accepts tables")
	local tmpn = os.tmpname()
	local f = io.open(tmpn, "w")
	assert(f, "couldnt make and open a tmpfile")

	for k, v in ipairs(options) do
		assert(type(k) == "number", "you need to give it a string array")
		if append_numbers then
			f:write(k .. ": " .. v .. "\n")
		else
			f:write(v .. "\n")
		end
	end
	f:flush()
	f:close()

	local cmd = string.format("cat %s | fzf", tmpn)
	local out, err = io.popen(cmd, "r")
	assert(out and not err, "couldnt run/read the output of fzf")
	local answer = out:lines()()
	os.remove(tmpn)
	return answer
end

function M.match_output(output, options)
	assert(type(options) == "table", "dis function only accepts tables")
	return options[tonumber(string.match(output, "^(%d+): "))]
end

return M
