#!/usr/bin/env lua
-- fzf bindings for lua
local test_list = { "asdf", "qwer", "zcxv" }
local M = {}
---@param list string[]
function M.get_fzf_input(list)
  assert(type(list) == "table", "ts function only accepts tables")
  local tmpn = os.tmpname()
  local f = io.open(tmpn, "w")
  assert(f)

  for k, v in ipairs(list) do
    print(k, v)
    f:write(v .. "\n")
  end
  os.exit(0)
  f:flush()
  f:close()

  local cmd = string.format("cat %s | fzf", tmpn)
  local out, err = io.popen(cmd, "r")
  assert(out and not err)
  local answer = out:lines()()
  os.remove(tmpn)
  return answer
end

return M
