#!/usr/bin/env lua
-- assumes you're on a posix system

local editor = os.getenv("EDITOR") or error("set your $EDITOR environment variable")
local location = os.getenv("NT_DIR") or os.getenv("HOME") .. "/nt-notes"

local find_command = [[cd %s && find -name '*.md' 2>/dev/null]]
local fzf_command =
	[[cat %s | fzf --reverse --style full --prompt 'nt✴ ' --preview-window=%s:wrap --preview '$(%s preview {})']]
local fzf_string = "%s @ %s (%s)\n"
local edit_cmd = "cd " .. location .. " && $EDITOR " .. location .. "/%s"

local function dir_exists(path)
	local ok = os.execute('[ -d "' .. path .. '" ]')
	return ok == true or ok == 0
end
if not dir_exists(location) then
	os.execute("mkdir -p " .. location)
	if os.getenv("NT_USE_GIT") ~= "false" then
		os.execute("cd " .. location .. " && git init .")
	end
end

if os.getenv("NT_USE_GIT") ~= "false" and not dir_exists(location .. "/.git") then
	print([[
(disable this by setting export NT_USE_GIT=false)
hey man your note location doesn't have a git repository in it.
you should have one repo per location
]])
	io.stdout:write("make a new repo? [Y/n] ")
	local yn = string.lower(io.read()) ~= "n"
	if not yn then
		os.exit(0)
	else
		os.execute("cd " .. location .. " && git init .")
	end
end

local commands = {
	new = {
		exec = function()
			io.stdout:write(";new note: ")
			local cmd = string.format("%s %s/%s.md", editor, location, io.read())
			os.execute(cmd)
		end,
		desc = "create a new note",
	},
	git_push = {
		exec = function()
			os.execute("cd " .. location .. " && git add . && git commit")
		end,
		desc = "git adds your git changes and lets git you git review them",
	},
}

local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function get_title(path)
	local fd = io.open(path, "r")
	if not fd then
		return path
	end
	local first_line = fd:lines()()
	if not first_line then
		return "./" .. path:match("^.+/(.+)$")
	end
	if string.match(first_line, "^#") then
		return trim(first_line:match("^#%s*(.*)") or path:match("^.+/(.+)$"))
	end
end

local function is_today(unix_time)
	local today = os.date("*t")
	local input = os.date("*t", unix_time)

	return today.year == input.year and today.month == input.month and today.day == input.day
end

local function get_preview_position()
	local handle = io.popen("stty size", "r")
	if not handle then
		return "right:50%"
	end
	local output = handle:read("*a")
	handle:close()

	local rows, cols = output:match("(%d+)%s+(%d+)")
	rows, cols = tonumber(rows), tonumber(cols)
	if cols and cols < 100 then
		return "up:70%"
	else
		return "right:50%"
	end
end

function string:last_paren()
	---@diagnostic disable-next-line: param-type-mismatch
	return self:match("%(([^()]*)%)%s*$") or self:match("%(([^()]*)%)")
end

local function tui()
	local find_baked_cmd = string.format(find_command, location)
	local find_result = io.popen(find_baked_cmd) or error("couldnt run find")
	local files = {}
	for path in find_result:lines() do
		local fullpath = location .. "/" .. path
		local stat = io.popen("stat -c %Y " .. fullpath) or error("stat isn't available 4 ur system")
		table.insert(files, {
			path = path,
			mtime = tonumber(stat:read()),
			title = get_title(fullpath),
		})
	end
	find_result:close()
	local tmpname = os.tmpname()
	local tmpfile = io.open(tmpname, "w+") or error("couldnt make tmpfile")
	for _, f in ipairs(files) do
		local mtime = os.date("%d %b %Y")
		if is_today(f.mtime) then
			mtime = os.date("%H:%M")
		end
		tmpfile:write(string.format(fzf_string, f.title, mtime, f.path))
	end
	for i, _ in pairs(commands) do
		tmpfile:write(";" .. i .. "\n")
	end

	local res = io.popen(string.format(fzf_command, tmpname, get_preview_position(), arg[0]), "r"):read()
	if not res then
		os.exit(0)
	end

	tmpfile:close()
	os.remove(tmpname)
	-- idek what it does i just stole it

	local command = res:match(";(%S+)")
	if command then
		commands[command].exec()
		os.exit()
	else
		local path = res:last_paren()
		print(string.format(edit_cmd, path))
	end
end

local function has(cmd)
	local ok = os.execute("command -v " .. cmd .. " > /dev/null 2>&1")
	return ok == 0 or ok == true
end

if arg[1] == "preview" then
	local path = arg[2]
	if path:match(";%S+") then
		local match = path:match(";(%S+)")
		io.stdout:write("echo -ne ;" .. match .. ":\n " .. commands[match].desc)
	else
		local cat = "cat"
		if has("batcat") then
			cat = "batcat --style=plain --color=always --paging=never"
		elseif has("bat") then
			cat = "bat --style=plain --color=always --paging=never"
		end

		---@diagnostic disable-next-line: param-type-mismatch
		print(cat .. " " .. location .. "/" .. path:last_paren())
	end
	os.exit(0)
end

local function check_deps()
	-- table means optional string means necessary
	for _, dep in pairs({
		"fzf",
		editor,
		"stat",
		"find",
		{ "git", "sync not available" },
		{ "bat", "pretty printing not available" },
	}) do
		if type(dep) == "table" then
			if not has(dep[1]) then
				print(dep[1] .. " not found: " .. dep[2])
			end
		elseif not has(dep) then
			print("dependency " .. dep .. " not found. the program won't run without it!")
			os.exit(0)
		end
	end
end

check_deps()
tui()
