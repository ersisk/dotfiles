
# fnm
set FNM_PATH "/home/ersan/.local/share/fnm"
# Linux only: on macOS /home is an autofs mount and this stat costs ~20ms per shell.
if not test -d /opt/homebrew; and [ -d "$FNM_PATH" ]
  set PATH "$FNM_PATH" $PATH
  fnm env | source
end
