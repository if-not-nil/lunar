# lunar
> a collections of tui tools i've written. a lot of them will rely on you having lua or fzf installed
a common recipe you should be using is a shortcut that opens them in a fullscreen terminal

## nt
> lua btw
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/7e318427-c5eb-4ee2-9018-01702fb16a36" />

a TUI note-taking suite, manages search and sync  
dependencies: ```fzf, lua, git``` and whatever comes with your posix system  
features right now:  
- infers note names
- list notes within fzf
- the preview window is gonna look good in most aspect ratios
- two builtin commands: `;new` and `;git_push` 
- you don't have to learn anything or get used to anything

**instructions:**
run once:
```bash
curl https://raw.githubusercontent.com/if-not-nil/lunar/refs/heads/main/nt/nt.lua -o /tmp/nt.lua
chmod +x /tmp/nt.lua
lua /tmp/nt.lua
rm /tmp/nt.lua
```
install forever:
```bash
curl https://raw.githubusercontent.com/if-not-nil/lunar/refs/heads/main/nt/nt.lua -o ~/bin/nt
chmod +x ~/bin/nt
~/bin/nt
```
**settings:**
```
export NT_USE_GIT=true
export NT_DIR=~/nt-notes/
```

**TODO:**   
[ ] add more colors to the output  
[ ] helpers for rsync  
[ ] a .nt file to manage prefs (only when i actually need it tho idk when that is)  
[ ] let notes be called just like whatever at the start  
[ ] if i could keep it in one lua file and still make it portable with some c ffi that would be just so great  

## cows
> a request manager in lua. everything is stored in lua too

dependencies : `jq`, `fzf`, `bat`
all relevant docs are in cows/README.md

## pick
> pick various things with `fzf`

can act as a minimal rofi replacement, pick a bunch of your config files and whatever i end up needing
