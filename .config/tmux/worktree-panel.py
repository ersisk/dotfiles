"""Turns worktrees into fzf rows (see worktree-panel.sh).

Each row: <path>\t<display text>
Ones with a merged PR and a clean working tree are marked "cleanable"; the
decision is left to the user, the script deletes nothing.
"""
import hashlib, json, subprocess, sys, time, os
from concurrent.futures import ThreadPoolExecutor

KW = {"green": "\033[38;2;152;187;108m", "yellow": "\033[38;2;230;195;132m",
      "orange": "\033[38;2;255;158;59m", "blue": "\033[38;2;126;156;216m",
      "grey": "\033[38;2;114;113;105m", "off": "\033[0m"}

CACHE_TTL = 300  # PR state does not change this fast; keep the panel instant

def cache_path(repo):
    """A separate file per repo.

    One shared file keyed PR state by branch name alone: with a branch of the
    same name in two repos (feat/x), one read the other's merged PR and called
    it "cleanable". The key now carries the repo identity too.
    """
    ident = run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], repo) or repo
    return os.path.join(os.environ.get("TMPDIR", "/tmp"),
                        "worktree-panel-pr-%s.json" % hashlib.sha1(ident.encode()).hexdigest()[:12])

def cache_load(path):
    try:
        if time.time() - os.stat(path).st_mtime < CACHE_TTL:
            with open(path) as f:
                return json.load(f)
    except Exception:
        pass
    return None

def cache_save(path, data):
    try:
        with open(path, "w") as f:
            json.dump(data, f)
    except OSError:
        pass

def run(args, cwd=None):
    try:
        r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=10)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""

repo = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
porcelain = run(["git", "worktree", "list", "--porcelain"], repo)
if not porcelain:
    sys.exit(0)

# Parsed block by block: the "locked" line is in the porcelain output and git will
# not delete a locked worktree without --force. Miss it and the panel says
# "cleanable" while the delete gets refused.
paths, locked_paths, cur = [], set(), None
for line in porcelain.splitlines():
    if line.startswith("worktree "):
        cur = line.split(" ", 1)[1]
        paths.append(cur)
    elif line.startswith("locked") and cur:
        locked_paths.add(cur)
main_path = paths[0] if paths else None  # git does not allow deleting the main worktree

# Fetch PR states in one call: asking per branch is slow
cache = cache_path(repo)
pr_state = cache_load(cache)
if pr_state is None:
    pr_state = {}
    raw = run(["gh", "pr", "list", "--state", "all", "--limit", "100",
               "--json", "number,state,headRefName"], repo)
    if raw:
        try:
            for pr in json.loads(raw):
                pr_state.setdefault(pr["headRefName"], [pr["number"], pr["state"]])
        except Exception:
            pass

now = time.time()

def collect(p):
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], p)
    detached = branch == "HEAD"
    if detached:
        branch = "detached " + (run(["git", "rev-parse", "--short", "HEAD"], p) or "?")

    dirty = len([l for l in run(["git", "status", "--porcelain"], p).splitlines() if l])
    # worktree-remove.sh counts this too and refuses the delete when it is non-zero;
    # the panel not counting it led to "cleanable" followed by a refusal.
    # With no upstream remove.sh counts 0, and the same behaviour is kept here.
    unpushed = run(["git", "rev-list", "--count", "@{u}..HEAD"], p)
    unpushed = int(unpushed) if unpushed.isdigit() else 0
    try:
        days = int((now - os.stat(p).st_mtime) // 86400)
    except OSError:
        days = 0
    return p, branch, detached, dirty, unpushed, days

def lookup_pr(branch):
    # Not in the last 100 PRs (old merged branches), so ask for that branch separately
    one = run(["gh", "pr", "list", "--head", branch, "--state", "all",
               "--limit", "1", "--json", "number,state"], repo)
    try:
        arr = json.loads(one) if one else []
        if arr:
            return branch, [arr[0]["number"], arr[0]["state"]]
    except Exception:
        pass
    return branch, [None, None]  # a branch with no PR must be cached too, else it is re-queried every time

# Two git calls per worktree plus the missing-PR queries; run serially the panel takes seconds
with ThreadPoolExecutor(max_workers=8) as ex:
    rows = list(ex.map(collect, paths))
    missing = [b for _, b, detached, _, _, _ in rows if not detached and b not in pr_state]
    if missing:
        pr_state.update(dict(ex.map(lookup_pr, missing)))

for p, branch, detached, dirty, unpushed, days in rows:
    num, state = pr_state.get(branch, (None, None))

    if dirty:
        status = "{}● {} files{}".format(KW["orange"], dirty, KW["off"])
    else:
        status = "{}✓ clean{}".format(KW["green"], KW["off"])

    if num:
        col = KW["grey"] if state == "MERGED" else KW["blue"]
        pr = "{}#{} {}{}".format(col, num, (state or "").lower(), KW["off"])
    else:
        pr = "{}no PR{}".format(KW["grey"], KW["off"])

    # When a finished (merged) worktree cannot be deleted, print why. A binary flag
    # hid the reason: the panel said "cleanable" while worktree-remove.sh refused.
    # The criteria are now the same and the blocker is on screen.
    # Non-merged ones get no extra note — the PR column already gives the reason.
    flag = ""
    if p == main_path:
        flag = " {}(main){}".format(KW["grey"], KW["off"])
    elif state == "MERGED":
        if detached:
            blocker = "detached"
        elif dirty:
            blocker = "uncommitted"
        elif unpushed:
            blocker = "{} unpushed".format(unpushed)
        elif p in locked_paths:
            blocker = "locked"
        else:
            blocker = None
        flag = (" {}← cleanable{}".format(KW["yellow"], KW["off"]) if blocker is None
                else " {}← {}{}".format(KW["orange"], blocker, KW["off"]))

    age = "{}{}d{}".format(KW["grey"], days, KW["off"])
    print("{}\t{:<46} {:<22} {:<26} {:>5}{}".format(
        p, branch[:44], status, pr, age, flag))

cache_save(cache, pr_state)
