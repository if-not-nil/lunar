#!/usr/bin/env lua
local files = {
  "~/.config/nvim/init.lua",
  "~/.config/wezterm/wezterm.lua",
  "~/.config/fish/config.fish",
  "~/.bashrc",
  "~/.config/waybar/config.jsonc",
  "~/bin/cfed.lua",
  "~/.config/hypr/hyprland.conf",
  "~/.config/home-manager/home.nix"
}
local n = os.tmpname()
local f = io.open(n, "w")
if f == nil then os.exit(1) end
f:write(table.concat(files, "\n"))

local res = io.popen("cat " .. n .. " | fzf"):read("*a")
f:close()
os.remove(n)
if res == "" then os.exit(1) end

local ret = res:gsub("\n", "")
os.execute("nvim " .. ret)
-- io.stdout:write(ret)
-- io.stdout:flush()
