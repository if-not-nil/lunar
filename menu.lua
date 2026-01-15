#!/usr/bin/env lua

local entries = {}
local wms = {
	hypr = {
		exec = function(cmd)
			os.execute(string.format("hyprctl dispatch exec %q", cmd))
		end,

		focus_window = function(addr)
			os.execute("hyprctl dispatch focuswindow address:" .. addr)
		end,
		list_windows = function(self)
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
					local label = "  " .. (c.class or "Unknown") .. ": " .. (c.title or "")
					table.insert(entries, { label = label, action = function() self.focus_window(c.address) end })
				end
			end
		end
	}
}
local TERM = 'foot'
local wm = wms.hypr

local function list_tmux()
	local f = io.popen([[sh -c "type tmux 1>/dev/null && tmux ls -F '#S' 2>/dev/null"]], "r")
	if not f then return end
	for line in f:lines() do
		table.insert(entries, {
			label = "  " .. line,
			action = function()
				wm.exec("tmux switch -t " .. line .. "; hyprctl dispatch focuswindow class:" .. TERM)
			end
		})
	end
	f:close()
end

local function get_apps()
	local apps = {}
	local desktop_dirs = {
		os.getenv("HOME") .. "/.local/share/applications",
		"/usr/share/applications"
	}
	for _, dir in ipairs(desktop_dirs) do
		local f = io.popen(string.format("find '%s' -name '*.desktop' 2>/dev/null", dir), "r")
		if f then
			local seen_apps = {}
			for path in f:lines() do
				local name, exec
				for line in io.lines(path) do
					if line:match("^Name=") then
						name = line:sub(6)
					elseif line:match("^Exec=") then
						exec = line:sub(6):gsub("%%[fFuUdDnNickvm]", "")
					end
					if name and exec then break end
				end
				if name and exec then
					if name and exec and not seen_apps[name] then
						table.insert(apps, { label = "  " .. name, action = function() wm.exec(exec) end })
						seen_apps[name] = true
					end
				end
			end
			f:close()
		end
	end

	local f_flat = io.popen("flatpak list --app --columns=application,name 2>/dev/null", "r")
	if f_flat then
		for line in f_flat:lines() do
			local appid, name = line:match("^([%w%._-]+)%s+(.+)$")
			if appid and name then
				table.insert(apps, { label = "  " .. name, action = function() wm.exec("flatpak run " .. appid) end })
			end
		end
		f_flat:close()
	end

	local f_img = io.popen("ls ~/Applications 2>/dev/null", "r")
	if f_img then
		for line in f_img:lines() do
			table.insert(apps, { label = "  " .. line, action = function() wm.exec("~/Applications/" .. line) end })
		end
		f_img:close()
	end

	table.sort(apps, function(a, b) return a.label < b.label end)
	for _, app in ipairs(apps) do
		table.insert(entries, app)
	end
end

local function add_power()
	for _, p in ipairs({
		{ "󰍃  logout", "hyprctl dispatch exit" },
		{ "󰤄  suspend", "systemctl suspend" },
		{ "󰜉  reboot", "systemctl reboot" },
		{ "⏻  shutdown", "systemctl poweroff" }
	}) do
		table.insert(entries, {
			label = p[1],
			action = function() os.execute(p[2]) end
		})
	end
end

wm.list_windows()
list_tmux()
get_apps()
add_power()

if #entries == 0 then os.exit(1) end

local display_list = {}
for _, e in ipairs(entries) do table.insert(display_list, e.label) end

local tmp = os.tmpname()
local f = io.open(tmp, "w")
if not f then os.exit(1) end
f:write(table.concat(display_list, "\n"))
f:close()

local fzf_cmd = "fzf --info=hidden --select-1 --exit-0 --layout=reverse --cycle --tiebreak=begin,length < " .. tmp
local selected_label = io.popen(fzf_cmd, "r"):read("*l")
os.remove(tmp)

if selected_label then
	for _, e in ipairs(entries) do
		if e.label == selected_label then
			e.action()
			break
		end
	end
end
