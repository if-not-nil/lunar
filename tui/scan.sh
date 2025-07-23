#!/bin/sh
# quick utility for scanning a source code repo for potential malicious software
# dependencies

# the command that'll be called when you select an item
OPEN_COMMAND="bat --style=numbers --color=always"

commands=(
  "rg --no-heading --line-number  -i -e 'eval\\(' -e 'exec\\(' -e 'base64_decode' -e 'system\\('\
    -e 'popen\\(' -e 'shell_exec' -e 'require\\(' -e 'include\\('\
    -e 'ob_start' -e 'ob_get_contents' -e 'gzinflate'\
    -e 'str_rot13' -e 'assert\\('"                                        # general suspicious patterns
  "rg --no-heading --line-number  -P '[A-Za-z0-9+/]{200,}'"               # long base64-like strings
  "rg --no-heading --line-number -i -e 'curl' -e 'wget' -e 'socket' -e 'connect'\
    -e 'ftp' -e 'http' -e 'https' -e 'file_get_contents'\
    -e 'fopen' -e 'readfile' -e 'fs\\.readFile'\
    -e 'net\\.connect'"                                                   # network
  "rg --no-heading --line-number -i 'eval|exec|subprocess|os\\.system'"   # eval in various languages
)

selected=$(printf "%s\n" "${commands[@]}"\
  | fzf --preview-window=right:70%:wrap\
  --preview 'eval {}'\
)

if [ -n "$selected" ]; then
  echo $(eval $selected) | $OPEN_COMMAND
fi

