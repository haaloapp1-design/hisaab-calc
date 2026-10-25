# AGENTS.md — rules for the AI coding agent

You are building **Calculator**, an advanced Flutter calculator app (Basic, Scientific,
Programmer, Unit converter, Currency, Tools, History/Memory, Settings).
You have NO memory between sessions. These files ARE your memory. Follow this loop exactly.

## The session loop (do this every time, in order)

1. Read `docs/PROGRESS.md` (bottom 40 lines are enough) to see what was done last.
2. Read `docs/TASKS.md` and find the FIRST task that is `- [ ]` (unchecked) and not blocked.
3. Read ONLY the docs that task's `Read:` line names (e.g. `docs/BUSINESS_LOGIC.md §3`).
   Do not read every doc. Do not scan the whole codebase. Open only files the task names.
4. Do that ONE task. Nothing else. Do not start the next task.
5. Verify:
   - `flutter analyze` → must show no errors.
   - `flutter test` → all tests pass (if the task adds logic, it must add tests).
6. Update memory:
   - In `docs/TASKS.md` change that task's `- [ ]` to `- [x]`.
   - Append ONE entry to the end of `docs/PROGRESS.md` using the template there.
   - If you made a design choice the docs do not cover, add it to "Decisions" in `docs/PROGRESS.md`.
7. Commit: `git add -A && git commit -m "T<id>: <short title>"`.
8. Stop and tell the user: task done, what changed, what the next task is.

If a task is too big to finish in one go: split it into T<id>a, T<id>b in `docs/TASKS.md`,
do the first part, log it, stop.
If you are blocked (missing info, failing test you cannot fix): write `BLOCKED:` and the reason
in the PROGRESS entry, leave the task unchecked, stop and ask the user.

## Hard rules

- Flutter + Dart only. State management: **Riverpod** (`flutter_riverpod`). No other state library.
- All calculation logic lives in `lib/core/` as **pure Dart** (no Flutter imports) so it can be unit tested.
  UI widgets never do maths themselves; they call the engine/services.
- Use the `decimal` package for + − × ÷ and % so `0.1 + 0.2` shows `0.3`. See BUSINESS_LOGIC.md §2.
- Never put colours, font sizes or radii as magic numbers in widgets: use `lib/theme/app_tokens.dart`.
- One feature folder per screen under `lib/features/` (see `docs/ARCHITECTURE.md`).
- Never delete or rewrite `docs/` files except: ticking tasks, appending to PROGRESS, splitting tasks.
- For ANY UI task, open the matching `docs/screens/NN-*.html` and copy its sizes, colours and layout exactly.
- Keep files under ~300 lines. Split widgets into small files.
- Do not add packages that are not listed in ARCHITECTURE.md without logging a Decision.
- Every engine function gets a test in `test/` mirroring the `lib/` path.

## Where things are

| Need | File |
|---|---|
| What to build next | `docs/TASKS.md` |
| What was done | `docs/PROGRESS.md` |
| Every feature, screen by screen | `docs/SPEC.md` |
| How the maths works (engine rules) | `docs/BUSINESS_LOGIC.md` |
| Folders, packages, state | `docs/ARCHITECTURE.md` |
| Colours, fonts, sizes | `docs/DESIGN.md` |
| Exact look of each screen | `docs/screens/NN-name.html` (see `docs/screens/README.md`) |
