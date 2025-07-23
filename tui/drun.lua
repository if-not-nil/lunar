#!/usr/bin/env lua

local desktop_dirs = {
  os.getenv("HOME") .. "/.local/share/applications",
  "/usr/share/applications"
}

local function collect_desktop_files()
  local files = {}
  for _, dir in ipairs(desktop_dirs) do
    local cmd = string.format("find '%s' -name '*.desktop' 2>/dev/null", dir)
    local f = io.popen(cmd, "r")
    if f then
      for line in f:lines() do
        table.insert(files, line)
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
      name = line:match("^Name=(.+)")
    elseif line:match("^Exec=") then
      exec = line:match("^Exec=(.+)")
      -- remove arguments like %U, %f
      exec = exec:gsub("%%[fFuUdDnNickvm]", "")
    end
    if name and exec then break end
  end
  return name, exec
end

local function build_app_list()
  local apps = {}
  for _, file in ipairs(collect_desktop_files()) do
    local name, exec = parse_desktop_file(file)
    if name and exec then
      table.insert(apps, { name = name, exec = exec })
    end
  end
  return apps
end

local apps = build_app_list()
if #apps == 0 then
  print("No apps found.")
  os.exit(1)
end

local tmp = os.tmpname()
local out = io.open(tmp, "w")
if out == nil then os.exit(1) end
for _, app in ipairs(apps) do
  out:write(app.name .. "\n")
end
out:close()
local preview_cmd =
[[lua -e "local q={q} local fn,err=load('return '..q) if not fn then print('load error:',err) else local ok,res=pcall(fn) if ok then print(res) else print('runtime error') end end"]]
local fzf_cmd = string.format("fzf --preview %q < %s", preview_cmd, tmp)
local selected = io.popen(fzf_cmd, "r"):read("*l")
os.remove(tmp)

if selected then
  for _, app in ipairs(apps) do
    if app.name == selected then
      -- change if ur on a diff wm
      os.execute(string.format("hyprctl dispatch exec %q", app.exec))
      os.execute("sleep 0.1") -- that's weird
      -- io.read()
      print("hyprctl dispatch exec " .. app.exec)
      break
    end
  end
else
  os.exit(1)
end
