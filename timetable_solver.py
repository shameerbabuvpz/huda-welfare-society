"""
School Timetable Solver (fixed & working)
Generates a conflict-free timetable where no teacher is assigned
to more than one class in the same period.

Teachers: Ramla (R), Shafna (S), Farseena (F), Noora (N)
Classes : 1, 2, 3
Days    : Mon, Tue, Wed, Thu, Fri
Periods : P1-P8

Approach (two phase):
  Phase A - Edge colouring: place every (class, teacher) lesson into a
            period-slot so that in any (day, period) no teacher teaches
            two classes and no class is taught twice. Free periods absorb
            the slack (36 lessons into 38 available slots per class).
  Phase B - Subject filling: spread each (class, teacher) subject counts
            across that pair's assigned slots, avoiding the same subject
            twice in one day where possible.
"""

import random

# ── Subject requirements per class (subject, teacher, count_per_week) ───────
REQUIREMENTS = {
    1: [
        ("English", "S", 5), ("Maths", "F", 5), ("EVS", "R", 5),
        ("MS", "F", 4), ("Malayalam", "R", 4), ("Arabic", "N", 4),
        ("Hifz", "N", 3), ("Thilavath", "N", 3), ("IT", "S", 2),
        ("Art", "S", 1),
    ],
    2: [
        ("English", "S", 5), ("Maths", "F", 5), ("EVS", "R", 5),
        ("MS", "F", 4), ("Malayalam", "R", 4), ("Arabic", "N", 4),
        ("Hifz", "N", 3), ("Thilavath", "N", 3), ("IT", "S", 2),
        ("Art", "S", 1),
    ],
    3: [
        ("English", "S", 5), ("Maths", "F", 5), ("EVS", "R", 5),
        ("MS", "F", 4), ("Malayalam", "R", 4), ("Arabic", "N", 4),
        ("Hifz", "N", 2), ("Thilavath", "N", 2), ("IT", "S", 2),
        ("Art", "S", 1), ("Hindi", "S", 2),
    ],
}

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]
PERIODS = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]
CLASSES = [1, 2, 3]

# Fixed special slots (external teacher — no conflict constraint needed)
FIXED_SLOTS = {
    ("Wed", "P6", 1): ("Abacus", "EXT"),
    ("Wed", "P7", 2): ("Abacus", "EXT"),
    ("Wed", "P8", 3): ("Abacus", "EXT"),
    ("Thu", "P6", 1): ("Skating", "EXT"),
    ("Thu", "P6", 2): ("Karate", "EXT"),
    ("Thu", "P6", 3): ("Box", "EXT"),
}

TEACHER_NAME = {"R": "Ramla", "S": "Shafna", "F": "Farseena",
                "N": "Noora", "EXT": "—"}

ALL_SLOTS = [(d, p) for d in DAYS for p in PERIODS]


# ── Phase A : edge colouring (assign teachers to slots) ─────────────────────
def class_loads():
    """loads[cls][teacher] = number of lessons that pair needs."""
    loads = {c: {} for c in CLASSES}
    for c, reqs in REQUIREMENTS.items():
        for subj, teacher, count in reqs:
            loads[c][teacher] = loads[c].get(teacher, 0) + count
    return loads


def forbidden_slots():
    """Slots where a class cannot take a teacher lesson (external/fixed)."""
    forb = {c: set() for c in CLASSES}
    for (d, p, c) in FIXED_SLOTS:
        forb[c].add((d, p))
    return forb


def assign_teachers(max_restarts=200000):
    """
    Greedy randomized edge colouring with restarts.
    Returns teacher_grid[(day,period)][class] = teacher  (or None for free).
    """
    loads = class_loads()
    forb = forbidden_slots()

    # Build the flat lesson list (class, teacher), hardest teachers first.
    teacher_total = {}
    for c in CLASSES:
        for t, n in loads[c].items():
            teacher_total[t] = teacher_total.get(t, 0) + n

    lessons = []
    for c in CLASSES:
        for t, n in loads[c].items():
            lessons.extend([(c, t)] * n)
    # order: teachers with most overall load first, then by class
    lessons.sort(key=lambda ct: (-teacher_total[ct[1]], ct[0]))

    for _ in range(max_restarts):
        # occupancy maps
        class_used = {c: set() for c in CLASSES}        # slots already used by class
        teacher_used = {t: set() for t in teacher_total}  # slots used by teacher
        assignment = {}  # lesson index -> slot

        ok = True
        # slight shuffle within equal-priority groups for variety
        order = lessons[:]
        # keep hard ordering but randomize ties by shuffling small windows
        random.shuffle(order)
        order.sort(key=lambda ct: -teacher_total[ct[1]])

        for idx, (c, t) in enumerate(order):
            feasible = [
                s for s in ALL_SLOTS
                if s not in forb[c]
                and s not in class_used[c]
                and s not in teacher_used[t]
            ]
            if not feasible:
                ok = False
                break
            s = random.choice(feasible)
            class_used[c].add(s)
            teacher_used[t].add(s)
            assignment[idx] = (c, t, s)

        if not ok:
            continue

        # success — build grid
        grid = {s: {c: None for c in CLASSES} for s in ALL_SLOTS}
        for idx, (c, t) in enumerate(order):
            _, _, s = assignment[idx]
            grid[s][c] = t
        return grid

    return None


# ── Phase B : fill subjects for each (class, teacher) ───────────────────────
def fill_subjects(teacher_grid, max_tries=20000):
    """
    Returns timetable[day][period][class] = (subject, teacher).
    Spreads subjects across the pair's slots, trying to avoid the same
    subject twice in a day for a class.
    """
    # subject pool per (class, teacher)
    subj_pool = {c: {} for c in CLASSES}
    for c, reqs in REQUIREMENTS.items():
        for subj, teacher, count in reqs:
            subj_pool[c].setdefault(teacher, []).extend([subj] * count)

    # collect slots assigned to each (class, teacher)
    slots_for = {c: {} for c in CLASSES}
    for s in ALL_SLOTS:
        for c in CLASSES:
            t = teacher_grid[s][c]
            if t is not None:
                slots_for[c].setdefault(t, []).append(s)

    for _ in range(max_tries):
        timetable = {d: {p: {} for p in PERIODS} for d in DAYS}
        # fixed slots
        for (d, p, c), (subj, teacher) in FIXED_SLOTS.items():
            timetable[d][p][c] = (subj, teacher)

        good = True
        for c in CLASSES:
            # per-day subject usage for this class (to avoid duplicates/day)
            day_subj = {d: set() for d in DAYS}
            # include fixed subjects in day_subj
            for (d, p, cc), (subj, teacher) in FIXED_SLOTS.items():
                if cc == c:
                    day_subj[d].add(subj)

            for t, slots in slots_for[c].items():
                subs = subj_pool[c][t][:]
                random.shuffle(subs)
                slot_list = slots[:]
                random.shuffle(slot_list)

                # greedily place subjects avoiding same-subject-twice-per-day
                placed = {}
                remaining = subs[:]
                for s in slot_list:
                    d, p = s
                    choice = None
                    for sub in remaining:
                        if sub not in day_subj[d]:
                            choice = sub
                            break
                    if choice is None:
                        choice = remaining[0]  # accept duplicate as last resort
                    remaining.remove(choice)
                    day_subj[d].add(choice)
                    placed[s] = choice

                for s, sub in placed.items():
                    d, p = s
                    timetable[d][p][c] = (sub, t)

        if good:
            return timetable
    return None


# ── Verification ────────────────────────────────────────────────────────────
def verify(timetable):
    conflicts = []
    for day in DAYS:
        for period in PERIODS:
            seen = {}
            for c in CLASSES:
                if c in timetable[day][period]:
                    subj, teacher = timetable[day][period][c]
                    if teacher == "EXT":
                        continue
                    if teacher in seen:
                        conflicts.append(
                            f"CONFLICT: {day} {period} — {TEACHER_NAME[teacher]} "
                            f"in Class {seen[teacher]} AND Class {c}")
                    else:
                        seen[teacher] = c
    return conflicts


def verify_counts(timetable):
    """Check every subject meets its required weekly count."""
    errors = []
    actual = {c: {} for c in CLASSES}
    for day in DAYS:
        for period in PERIODS:
            for c in CLASSES:
                if c in timetable[day][period]:
                    subj, teacher = timetable[day][period][c]
                    actual[c][subj] = actual[c].get(subj, 0) + 1
    for c, reqs in REQUIREMENTS.items():
        for subj, teacher, count in reqs:
            got = actual[c].get(subj, 0)
            if got != count:
                errors.append(f"Class {c} {subj}: need {count}, got {got}")
    return errors


# ── HTML output ─────────────────────────────────────────────────────────────
def generate_html(timetable):
    period_times = {
        "P1": "9:30–10:10", "P2": "10:10–10:50",
        "P3": "11:00–11:40", "P4": "11:40–12:20",
        "P5": "12:20–1:00", "P6": "1:30–2:10",
        "P7": "2:10–2:50", "P8": "2:50–3:30",
    }
    subj_colors = {
        "English": "#d6eaf8", "Maths": "#d5f5e3", "EVS": "#fdebd0",
        "MS": "#f9ebea", "Malayalam": "#e8daef", "Arabic": "#fbeee6",
        "Hifz": "#eafaf1", "Thilavath": "#fef9e7", "IT": "#ebf5fb",
        "Art": "#fdedec", "Hindi": "#e8f8f5",
        "Abacus": "#d2b4de", "Skating": "#aed6f1",
        "Karate": "#f5b7b1", "Box": "#f9e79f",
    }

    html = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Conflict-Free School Timetable</title>
<style>
  body{font-family:Arial,sans-serif;font-size:12px;margin:16px;background:#f5f5f5}
  h1{text-align:center;color:#2c3e50;margin-bottom:4px}
  h2{text-align:center;color:#555;font-size:13px;margin-top:0}
  .section{margin-bottom:28px}
  h3{background:#2c3e50;color:white;padding:6px 12px;border-radius:4px;margin-bottom:0}
  table{width:100%;border-collapse:collapse;background:white}
  th{background:#34495e;color:white;padding:6px 4px;text-align:center;border:1px solid #ccc}
  td{border:1px solid #ccc;padding:5px 4px;text-align:center;vertical-align:middle;min-width:90px}
  .period-label{background:#ecf0f1;font-weight:bold;color:#333;width:110px}
  .break-row td{background:#f9e79f;font-style:italic;color:#7d6608;font-weight:bold}
  .lunch-row td{background:#fad7a0;font-style:italic;color:#784212;font-weight:bold}
  .subject{font-weight:bold;display:block}
  .teacher{font-size:10px;color:#666;display:block}
  .free{color:#aaa;font-style:italic}
  .ok{color:green;font-weight:bold}
  .count-table{width:100%;border-collapse:collapse;background:white;margin-top:10px;font-size:11px}
  .count-table th{background:#7f8c8d;color:white;padding:4px;border:1px solid #ccc}
  .count-table td{border:1px solid #ccc;padding:3px 6px;text-align:center}
  .free-cell{background:#fbfbfb}
  @media print{
    body{background:white;margin:0;font-size:11px}
    .section{page-break-inside:avoid;break-inside:avoid;margin-bottom:18px}
    h1,h2{page-break-after:avoid}
    .pagebreak{page-break-before:always}
    td,th{-webkit-print-color-adjust:exact;print-color-adjust:exact}
    table,td,th{-webkit-print-color-adjust:exact;print-color-adjust:exact}
    .noprint{display:none}
  }
  *{-webkit-print-color-adjust:exact;print-color-adjust:exact}
</style>
</head>
<body>
<h1>📅 Conflict-Free School Weekly Timetable</h1>
<h2>9:30 AM – 3:30 PM | Monday to Friday | ✅ Verified – No Teacher Double-Booking</h2>
<p style="text-align:center" class="noprint">
  <button onclick="window.print()" style="padding:6px 16px;font-size:13px;
    background:#2c3e50;color:white;border:none;border-radius:4px;cursor:pointer">
    🖨️ Print / Save as PDF</button>
</p>
"""

    for c in CLASSES:
        html += f'<div class="section"><h3>Class {c}</h3>\n<table>\n'
        html += ('<tr><th class="period-label">Time</th>'
                 + ''.join(f'<th>{d}</th>' for d in DAYS) + '</tr>\n')
        for period in PERIODS:
            if period == "P3":
                html += ('<tr class="break-row"><td colspan="6">'
                         '☕ Morning Break 10:50–11:00</td></tr>\n')
            if period == "P6":
                html += ('<tr class="lunch-row"><td colspan="6">'
                         '🍱 Lunch Break 1:00–1:30</td></tr>\n')
            html += (f'<tr><td class="period-label">{period}<br>'
                     f'{period_times[period]}</td>')
            for day in DAYS:
                if c in timetable[day][period]:
                    subj, teacher = timetable[day][period][c]
                    color = subj_colors.get(subj, "#ffffff")
                    tname = TEACHER_NAME.get(teacher, teacher)
                    html += (f'<td style="background:{color}">'
                             f'<span class="subject">{subj}</span>'
                             f'<span class="teacher">{tname}</span></td>')
                else:
                    html += '<td><span class="free">— free —</span></td>'
            html += '</tr>\n'
        html += '</table></div>\n'

    # ── Per-teacher schedules ──────────────────────────────────────────────
    html += '<div class="pagebreak"></div>\n'
    html += '<h1>👩‍🏫 Per-Teacher Schedules</h1>\n'
    teachers = ["R", "S", "F", "N"]
    for t in teachers:
        html += (f'<div class="section"><h3>{TEACHER_NAME[t]} ({t})</h3>\n'
                 '<table>\n')
        html += ('<tr><th class="period-label">Time</th>'
                 + ''.join(f'<th>{d}</th>' for d in DAYS) + '</tr>\n')
        load = 0
        for period in PERIODS:
            if period == "P3":
                html += ('<tr class="break-row"><td colspan="6">'
                         '☕ Morning Break 10:50–11:00</td></tr>\n')
            if period == "P6":
                html += ('<tr class="lunch-row"><td colspan="6">'
                         '🍱 Lunch Break 1:00–1:30</td></tr>\n')
            html += (f'<tr><td class="period-label">{period}<br>'
                     f'{period_times[period]}</td>')
            for day in DAYS:
                cell = None
                for c in CLASSES:
                    if c in timetable[day][period]:
                        subj, teacher = timetable[day][period][c]
                        if teacher == t:
                            cell = (subj, c)
                            break
                if cell:
                    subj, c = cell
                    color = subj_colors.get(subj, "#ffffff")
                    load += 1
                    html += (f'<td style="background:{color}">'
                             f'<span class="subject">{subj}</span>'
                             f'<span class="teacher">Class {c}</span></td>')
                else:
                    html += '<td class="free-cell"><span class="free">free</span></td>'
            html += '</tr>\n'
        html += '</table>\n'
        html += f'<p style="margin:4px 0;color:#555">Total periods/week: <b>{load}</b></p>\n'
        html += '</div>\n'

    # ── Weekly subject count summary ───────────────────────────────────────
    html += '<div class="section"><h3>📊 Weekly Subject Counts</h3>\n'
    html += '<table class="count-table">\n<tr><th>Subject</th><th>Teacher</th>'
    html += ''.join(f'<th>Class {c}</th>' for c in CLASSES) + '</tr>\n'
    all_subjects = []
    for c in CLASSES:
        for subj, teacher, count in REQUIREMENTS[c]:
            if subj not in [s for s, _ in all_subjects]:
                all_subjects.append((subj, teacher))
    for subj, teacher in all_subjects:
        html += f'<tr><td>{subj}</td><td>{TEACHER_NAME[teacher]}</td>'
        for c in CLASSES:
            cnt = next((n for s, t, n in REQUIREMENTS[c] if s == subj), None)
            html += f'<td>{cnt if cnt is not None else "—"}</td>'
        html += '</tr>\n'
    html += '</table></div>\n'

    # Conflict verification table
    html += '<div class="pagebreak"></div>\n'
    html += ('<div class="section"><h3>✅ Conflict Verification</h3>\n'
             '<table class="count-table">\n'
             '<tr><th>Day</th><th>Period</th><th>Class 1</th><th>Class 2</th>'
             '<th>Class 3</th><th>Status</th></tr>\n')
    all_ok = True
    for day in DAYS:
        for period in PERIODS:
            teachers = {}
            for c in CLASSES:
                if c in timetable[day][period]:
                    t = timetable[day][period][c][1]
                    teachers[c] = TEACHER_NAME.get(t, t)
                else:
                    teachers[c] = "—"
            non_ext = [teachers[c] for c in CLASSES if teachers[c] not in ("—", "")]
            status = "✅" if len(non_ext) == len(set(non_ext)) else "❌ CONFLICT"
            if "❌" in status:
                all_ok = False
            html += (f'<tr><td>{day}</td><td>{period}</td>'
                     f'<td>{teachers[1]}</td><td>{teachers[2]}</td>'
                     f'<td>{teachers[3]}</td><td>{status}</td></tr>\n')
    html += '</table></div>\n'

    summary = "✅ ALL PERIODS CONFLICT-FREE" if all_ok else "❌ Some conflicts remain"
    html += f'<h2 class="ok">{summary}</h2>\n</body></html>'
    return html


# ── Main ────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    random.seed(42)
    print("Solving timetable...")
    grid = assign_teachers()
    if grid is None:
        print("❌ Could not assign teachers to slots.")
        raise SystemExit(1)
    print("✅ Teacher/slot assignment found (Phase A).")

    timetable = fill_subjects(grid)
    if timetable is None:
        print("❌ Could not fill subjects.")
        raise SystemExit(1)
    print("✅ Subjects filled (Phase B).")

    conflicts = verify(timetable)
    count_errors = verify_counts(timetable)

    if conflicts:
        print("Conflicts found:")
        for c in conflicts:
            print("  ", c)
    else:
        print("✅ No teacher conflicts!")

    if count_errors:
        print("Count mismatches:")
        for e in count_errors:
            print("  ", e)
    else:
        print("✅ All weekly subject counts correct!")

    if not conflicts and not count_errors:
        html = generate_html(timetable)
        with open("timetable_output.html", "w", encoding="utf-8") as f:
            f.write(html)
        print("✅ Saved to timetable_output.html")
