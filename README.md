# lunar

a collections of tui tools i've written. a lot of them will rely on you having lua or fzf installed

## nt
> lua btw

a TUI note-taking suite, manages search and sync  
dependencies: ```fzf, lua, git``` and whatever comes with your posix system  
features right now:  
- infers note names
- list notes within fzf
- the preview window is gonna look good in most aspect ratios
- two builtin commands: `;new` and `;git_push` 
- you don't have to learn anything or get used to anything

**instructions:**
```bash
git clone https://github.com/if-not-nil/lunar /tmp/nil-lunar
cp /tmp/nil-lunar/nt/nt.lua .
./nt.lua #there's a shebang here which lets you execute it like a binary
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
