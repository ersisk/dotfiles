"""Worktree'leri fzf satirlarina cevirir (bkz worktree-panel.sh).

Her satir: <yol>\t<gorunen metin>
PR merged + calisma agaci temiz olanlar "temizlenebilir" olarak isaretlenir;
karar kullaniciya birakilir, script hicbir seyi silmez.
"""
import json, subprocess, sys, time, os
from concurrent.futures import ThreadPoolExecutor

KW = {"green": "\033[38;2;152;187;108m", "yellow": "\033[38;2;230;195;132m",
      "orange": "\033[38;2;255;158;59m", "blue": "\033[38;2;126;156;216m",
      "grey": "\033[38;2;114;113;105m", "off": "\033[0m"}

CACHE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "worktree-panel-pr.json")
CACHE_TTL = 300  # PR durumu bu kadar hizli degismiyor; panel aninda acilsin

def cache_load():
    try:
        if time.time() - os.stat(CACHE).st_mtime < CACHE_TTL:
            with open(CACHE) as f:
                return json.load(f)
    except Exception:
        pass
    return None

def cache_save(data):
    try:
        with open(CACHE, "w") as f:
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

paths = [l.split(" ", 1)[1] for l in porcelain.splitlines() if l.startswith("worktree ")]
main_path = paths[0] if paths else None  # git ana worktree'yi silmeye izin vermez

# PR durumlarini tek cagride al: her branch icin ayri ayri sormak yavas
pr_state = cache_load()
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
    try:
        days = int((now - os.stat(p).st_mtime) // 86400)
    except OSError:
        days = 0
    return p, branch, detached, dirty, days

def lookup_pr(branch):
    # Son 100 PR listesinde yoksa (eski merged dallar) branch icin ayrica sor
    one = run(["gh", "pr", "list", "--head", branch, "--state", "all",
               "--limit", "1", "--json", "number,state"], repo)
    try:
        arr = json.loads(one) if one else []
        if arr:
            return branch, [arr[0]["number"], arr[0]["state"]]
    except Exception:
        pass
    return branch, [None, None]  # PR'i olmayan dal da cachelenmeli, yoksa her acilista tekrar sorulur

# Worktree basina iki git cagrisi + eksik PR sorgusu var; seri calisinca panel saniyeler suruyor
with ThreadPoolExecutor(max_workers=8) as ex:
    rows = list(ex.map(collect, paths))
    missing = [b for _, b, detached, _, _ in rows if not detached and b not in pr_state]
    if missing:
        pr_state.update(dict(ex.map(lookup_pr, missing)))

for p, branch, detached, dirty, days in rows:
    num, state = pr_state.get(branch, (None, None))

    if dirty:
        status = "{}● {} dosya{}".format(KW["orange"], dirty, KW["off"])
    else:
        status = "{}✓ temiz{}".format(KW["green"], KW["off"])

    if num:
        col = KW["grey"] if state == "MERGED" else KW["blue"]
        pr = "{}#{} {}{}".format(col, num, (state or "").lower(), KW["off"])
    else:
        pr = "{}PR yok{}".format(KW["grey"], KW["off"])

    # Temizlenebilir: isi bitmis (merged) ve kaybedilecek bir sey yok
    flag = ""
    if p == main_path:
        flag = " {}(ana){}".format(KW["grey"], KW["off"])
    elif state == "MERGED" and not dirty and not detached:
        flag = " {}← temizlenebilir{}".format(KW["yellow"], KW["off"])

    age = "{}{}g{}".format(KW["grey"], days, KW["off"])
    print("{}\t{:<46} {:<22} {:<26} {:>5}{}".format(
        p, branch[:44], status, pr, age, flag))

cache_save(pr_state)
