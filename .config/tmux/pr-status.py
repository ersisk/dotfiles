"""PR JSON'unu popup icin kisa bir ozete cevirir (bkz pr-status.sh)."""
import sys, json

STATE = {"OPEN": ("", "Open"), "MERGED": ("", "Merged"), "CLOSED": ("", "Closed")}
REVIEW = {
    "APPROVED": " approved",
    "CHANGES_REQUESTED": " changes requested",
    "REVIEW_REQUIRED": " review bekliyor",
}

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)

icon, label = STATE.get(d.get("state", ""), ("", d.get("state", "?")))
if d.get("isDraft"):
    label += " (draft)"

title = (d.get("title") or "")[:56]
print("#{}  {}".format(d.get("number", "?"), title))
print("{} {}".format(icon, label))

checks = d.get("statusCheckRollup") or []
if checks:
    ok = sum(1 for c in checks if c.get("conclusion") in ("SUCCESS", "NEUTRAL"))
    skipped = sum(1 for c in checks if c.get("conclusion") == "SKIPPED")
    failed = [c for c in checks if c.get("conclusion") in ("FAILURE", "TIMED_OUT", "CANCELLED")]
    running = sum(1 for c in checks if c.get("status") != "COMPLETED")
    parts = [" {}".format(ok)]
    if failed:
        parts.append(" {}".format(len(failed)))
    if running:
        parts.append(" {}".format(running))
    if skipped:
        parts.append(" {}".format(skipped))
    print("checks: " + "  ".join(parts))
    for c in failed[:3]:
        print("   {}".format((c.get("name") or "?")[:44]))

rd = d.get("reviewDecision") or ""
if rd:
    print("review: " + REVIEW.get(rd, rd.lower()))
