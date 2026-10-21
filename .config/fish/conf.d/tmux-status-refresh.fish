# Redraw the tmux status bar after each command so the path and git branch
# update at once instead of waiting up to status-interval. -S forces the #()
# jobs (git-status.sh) to re-run. Lives in conf.d: event handlers in functions/
# are autoloaded only on first call, so they would never register.
if set -q TMUX
    function __tmux_status_refresh --on-event fish_postexec
        command tmux refresh-client -S 2>/dev/null &
        disown 2>/dev/null
    end
end
