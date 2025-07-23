#!/usr/bin/env lua

-- Helper function to run a command and capture output
local function capture(cmd)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  return s
end

local screenshot_dir = os.getenv("HOME") .. "/Pictures/Screenshots/"
os.execute("mkdir -p " .. screenshot_dir)
local filename = os.date("Screenshot_%y.%m.%d-%H:%M:%S.png")
local path = screenshot_dir .. filename

local function show_usage()
  print("usage: screenshot.lua [monitor|selection]")
end

local mode = arg[1]

if mode == "monitor" then
  os.execute(string.format("grim -t png -l 1 -o eDP-1 '%s'", path))
elseif mode == "selection" then
  local region = capture("slurp")
  if region then
    region = region:sub(0, #region - 1)
    os.execute(string.format("grim -t png -l 1 -g '%s' '%s'", region, path))
  else
    os.exit(1)
  end
else
  show_usage()
  os.exit(1)
end

if io.open(path) then
  os.execute("canberra-gtk-play -i camera-shutter -V -8 &")
  os.execute(string.format("notify-send '%s'", path))
  os.execute(string.format("wl-copy < '%s'", path))
  os.exit(0)
else
  print(path)
  print("screenshot cancelled or failed.")
  os.exit(1)
end
