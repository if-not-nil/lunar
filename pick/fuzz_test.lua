#!/usr/bin/env lua
local fuzz = require("fuzz")
local test_table = { "asdf", "qwer" }
assert(not pcall(function()
	fuzz.get_input("asdf")
end), "accepts a string")

assert(not pcall(function()
	fuzz.get_input()
end), "accepts 0 args")

assert(type(fuzz.get_input(test_table)) == "string", "fzf output wrong")
assert(string.match(fuzz.get_input(test_table, true), "^%d+: "), "append numbers doesnt work")
assert(fuzz.match_output(fuzz.get_input(test_table), test_table) == test_table[1])

print("tests passed")
