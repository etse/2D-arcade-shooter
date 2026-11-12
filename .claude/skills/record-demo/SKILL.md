---
name: record-demo
description: Record short gameplay/demo videos (MP4) of "The invasion" — only when the user asks for a video — by scripting an autoplay "director" that drives menus, input and the shop and is allowed to cheat (money, spawning, weapon levels, jumping between scenes). Use when asked to record, film, capture or make a video/clip/trailer/GIF of the game or of a feature; do not record on your own initiative (use a screenshot to check visuals).
---

# Recording demo videos

Videos are rendered with Godot's Movie Maker (deterministic, fixed 30 fps,
1920×1080, game audio included) while a **director** script plays the game,
then converted to H.264 MP4 with ffmpeg.

**Store all videos (and review images) in the repo's `demo/` folder.** It is
git-ignored (`/demo/` in `.gitignore`) — never commit videos.

## Files (in this skill's `scripts/` folder)

| File | Purpose |
| --- | --- |
| `record.sh` | `record.sh [--dry-run] <director.gd> [out.mp4]` — records to `demo/<director-name>.mp4` by default |
| `demo_base.gd` | Base class for directors with helpers (scenes, menu clicks, input, spawning, waits) |
| `demos/*.gd` | Ready-made directors. `weapon_shop.gd` = weak weapon → shop upgrades 1→10 → maxed weapon vs rows + boss (~18 s). `menus_tour.gd` = main menu → options → upgrade ship → weapon shop → level with HUD (~20 s). `spread_fire.gd` = shop: browse with live preview, buy Spread fire, power up/down → power 3 and 10 vs rows + boss (~17 s). `game_tour.gd` = whole-game trailer (~56 s): Level 1 first wave → fade → Attackers wave → fade → boss kill → shop: buy Spread fire + 6 upgrades → fade into Attackers with it. `level2_tour.gd` = Level 2 (~60 s): Rush, gunships, Crossfire, all three Dreadnought phases |
| `contact_sheet.sh` | `contact_sheet.sh <video> [out.png] [fps=1] [cols=5]` — tiles frames into one PNG for reviewing |

Requirements: `$DISPLAY` (rendering is not headless), `ffmpeg`/`ffprobe`, the
Godot binary via `tools/godot.sh`. Recording runs at roughly real time.

## Workflow

1. **Pick or write a director.** Reuse one from `scripts/demos/` if it fits.
   Otherwise create `scripts/demos/<name>.gd` (keep it if it's reusable):

   ```gdscript
   extends "res://.claude/skills/record-demo/scripts/demo_base.gd"

   func run() -> void:
       await goto(MENU)                                   # load a scene, wait until ready
       await click(node("MenuContainer/MainMenu/%StartGame"))
       var level := await scene_named("Level")            # wait for scene changed by the game
       var row := spawn_row(level, 5, 140.0, 380.0)       # cheat: spawn enemies
       Loadout.weapon_level = 6                           # cheat: set upgrades
       press("shoot")
       await hold("move_left", 0.5)
       await wait_until_cleared(6.0)
       press("shoot", false)
       log_line("alive=%d" % enemies_alive().size())     # shows up in record.sh output
   ```
   The recording ends when `run()` returns. Read `demo_base.gd` for all helpers.

2. **Dry-run** (headless, fast, no video) and check the `DEMO` lines and that
   there are no `SCRIPT ERROR`s:
   ```bash
   .claude/skills/record-demo/scripts/record.sh --dry-run .claude/skills/record-demo/scripts/demos/<name>.gd
   ```
3. **Record:**
   ```bash
   .claude/skills/record-demo/scripts/record.sh .claude/skills/record-demo/scripts/demos/<name>.gd
   # -> demo/<name>.mp4  (pass a 2nd arg for another name, still inside demo/)
   ```
4. **Review it** — always look before handing it over:
   ```bash
   .claude/skills/record-demo/scripts/contact_sheet.sh demo/<name>.mp4   # -> demo/<name>_sheet.png
   ```
   then Read the PNG. Check that the intended things actually happen on screen
   (enemies die, shop values change, no long empty stretches at the end).
5. Report the video path, its length, what it shows and which cheats were used.

## Making demos that work

- **Wait for outcomes, not fixed times.** Headless dry-runs aren't frame-locked
  and gameplay is physics-based, so fixed `wait()`s that "just about" kill an
  enemy are flaky. Use `wait_until_dead(enemy, timeout)` /
  `wait_until_cleared(timeout)` and position the player under targets.
- **Movement:** the player accelerates fast and is capped at 500 px/s while
  shooting; `hold("move_left", 0.3)` moves ≈130 px. The player starts at
  x=960, y=950. Spawned rows are centred on x=960.
- **Weak weapon is weak:** level-1 Pulse fire needs ~3 hits per BasicEnemy (6 HP)
  and its 2 bullets straddle a target — park directly under enemies.
- **Cutting between parts of the game** (`demo_base.gd`): `fade_out()` / `fade_in()` / `black()` use a black overlay owned by the director (survives scene changes). `goto_level(n)` starts level n directly (sets `Campaign.level_index`; beating a boss advances it, so reset it if a demo replays a level). While black: `skip_to_wave(level, "Attackers")` (any wave node name from `Level1.gd` `waves`; clears the screen and returns the wave node, e.g. `.boss` for `BossBattle`), `fast_forward(seconds)` (runs the game at 6× so a fresh wave fills the screen, or to skip the level's own fade back to the menu), `wait_for_scene(MENU)` when the game changes scene by itself.
- **Playing by itself:** `autopilot(seconds, until := Callable())` holds fire and steers under one target at a time (heavies preferred) until it dies or leaves. It doesn't dodge, so pair it with `god_mode(level)` (keeps the player at full health). Don't add dodging back naively: it fought the targeting and the ship froze in place.
- **Cheats available:** `Score.add_score(n)`, `Loadout.weapon_level = n`,
  `spawn_row(...)`, `spawn_boss(level, health)` (boss default 140 HP vs 230 in
  the game), `goto(scene)` to skip menus, editing any node directly.
- **Keep it short:** the user typically wants 10–20 s. Trim waits, use
  `click(label, 0.02, 0.3)` for rapid repeated menu presses, and end shortly
  after the last explosion.
- **Menu buttons** are `components/UI/MenuRow` nodes; `click()` focuses one,
  then calls its `press()` (flash + sound, then `selected`) like a real key press.
  Main menu rows are `MenuRow`s with unique names: `MenuContainer/MainMenu/%StartGame`
  (also `%UpgradeWeapon`, `%UpgradeShip`, `%Options`); Options has `%FullScreen`/`%Save`;
  The weapon shop has no buttons: drive it with `tap("ui_down")` / `tap("ui_up")` (cursor over weapons + DONE; starts on the equipped weapon), `tap("ui_right")` / `tap("ui_left")` (upgrade / downgrade the equipped weapon), `tap("ui_accept")` (buy highlighted / DONE) and `tap("ui_cancel")` (back). Cheat a weapon directly with `Loadout.weapon = Loadout.WEAPONS[i]`.
- **Real recordings open a window, and the real mouse pointer may sit over it.** UI that reacts to `mouse_entered` can then change under you (the shop used to); if a menu behaves differently in the recording than in the dry run, suspect the pointer.
- The level's own waves keep running (first enemies after ~5 s); scenes longer
  than that will include them.
- If node paths or scene names change in the game, update `demo_base.gd` and
  the directors (dry-run will show `SCRIPT ERROR`s).
