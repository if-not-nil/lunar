#!/usr/bin/env lua

local TERM = 'foot'
local wm = {}
local entries = {}
local actions = {}

function wm.exec(cmd)
	os.execute(string.format("hyprctl dispatch exec %q", cmd))
end

function wm.list_windows()
	local f = io.popen("hyprctl clients -j", "r")
	if not f then return end
	local json = f:read("*a")
	f:close()

	local ok, data = pcall(function()
		return require("dkjson").decode(json)
	end)
	if not ok or type(data) ~= "table" then return end

	for _, c in ipairs(data) do
		if c.address then
			local label = " " .. c.class .. ": " .. (c.title or "")
			entries[#entries + 1] = label
			actions[label] = function()
				wm.focus_window(c.address)
			end
		end
	end
end

function wm.focus_window(addr)
	os.execute("hyprctl dispatch focuswindow address:" .. addr)
end

local desktop_dirs = {
	os.getenv("HOME") .. "/.local/share/applications",
	"/usr/share/applications"
}

local function collect_desktop_files()
	local files = {}
	for _, dir in ipairs(desktop_dirs) do
		local f = io.popen(
			string.format("find '%s' -name '*.desktop' 2>/dev/null", dir),
			"r"
		)
		if f then
			for line in f:lines() do
				files[#files + 1] = line
			end
			f:close()
		end
	end
	return files
end

local function parse_desktop_file(path)
	local name, exec
	for line in io.lines(path) do
		if line:match("^Name=") then
			name = line:sub(6)
		elseif line:match("^Exec=") then
			exec = line:sub(6):gsub("%%[fFuUdDnNickvm]", "")
		end
		if name and exec then break end
	end
	return name, exec
end

local function list_flatpaks()
	local f = io.popen("flatpak list --app --columns=application,name", "r")
	if not f then return end
	for line in f:lines() do
		local appid, name = line:match("^([%w%._-]+)%s+(.+)$")
		if appid and name then
			local label = " " .. name
			entries[#entries + 1] = label
			actions[label] = function()
				wm.exec("flatpak run " .. appid)
			end
		end
	end
	f:close()
end

local function list_apps()
	for _, file in ipairs(collect_desktop_files()) do
		local name, exec = parse_desktop_file(file)
		if name and exec then
			local label = " " .. name
			entries[#entries + 1] = label
			actions[label] = function()
				wm.exec(exec)
			end
		end
	end
end

local function list_appimages()
	local f = io.popen("ls ~/Applications", "r")
	if f then
		for line in f:lines() do
			local label = " " .. line
			entries[#entries + 1] = label
			actions[label] = function()
				wm.exec("~/Applications/" .. line)
			end
		end
		f:close()
	end
end

local function list_power()
	for label, cmd in pairs({
		["⏻ Shutdown"] = "systemctl poweroff",
		["󰜉 Reboot"] = "systemctl reboot",
		["󰤄 Suspend"] = "systemctl suspend",
		["󰍃 Logout"] = "hyprctl dispatch exit"
	}) do
		entries[#entries + 1] = label
		actions[label] = function()
			os.execute(cmd)
		end
	end
end

local function list_tmux()
	local f = io.popen([[sh -c "type tmux 1>/dev/null && tmux ls -F '#S'"]], "r")
	if not f then return nil end
	for line in f:lines() do
		entries[#entries + 1] = line
		actions[line] = function()
			wm.exec("tmux switch -t " .. line .. "; hyprctl dispatch focuswindow class:" .. TERM)
		end
	end
	f:close()
end

-- order matters here!!!!!!!!
wm.list_windows()
list_tmux()
list_apps()
list_flatpaks()
list_appimages()
list_power()

if #entries == 0 then os.exit(1) end

local tmp = os.tmpname()
local f = io.open(tmp, "w")
if not f then error("cant open a tempfile") end
for _, e in ipairs(entries) do
	f:write(e, "\n")
end
f:close()

local selected = io.popen(
	"fzf --info=hidden --no-sort --select-1 --exit-0 --tiebreak=index --layout=reverse --cycle --no-multi < " .. tmp,
	"r"
):read("*l")
os.remove(tmp)

if selected and actions[selected] then
	actions[selected]()
end
