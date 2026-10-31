# Cubeland test harness

A way to run and check Cubeland on Linux without 12d Model.

12dPL is close enough to C++ that the macro can be turned into a C++ program
with a few mechanical changes. The harness does that, replaces each 12d
library call with a small stand-in, and drives the game from a script of
clicks and keys instead of a person. It is only a testing tool: the macro
never uses it, and nothing here goes into 12d.

## What it can tell you

- **The game logic works.** Scenarios break blocks, craft, kill a cow, cook
  beef, fall, die, respawn, and save and load worlds. `call dump` prints the
  player, inventory, cows, drops and furnaces so you can see the result.
- **What the screen looks like.** Every polygon the macro draws is filled
  into an image. `snap` saves the current frame to `run/out`.
- **Array mistakes.** It is compiled with AddressSanitizer and
  UndefinedBehaviorSanitizer, so reading past the end of an array, or before
  index 1, stops the run with a report pointing at the line.
- **Some 12dPL pitfalls.** The translator warns about `+=`, `?:`, variables
  declared in `for` headers, joining two string literals, and declaring
  the same variable twice in a function.

What it can't tell you: how fast the macro runs in 12d, how 12d's own panels
and widgets behave, or whether 12d accepts something that C++ accepts. The
stand-ins only copy the behaviour the macro relies on.

## How it works

1. `translate.py` runs the C preprocessor over `cubeland.4dm`, removes the
   `{ }` braces around global variables, adds 1 to every array size (12dPL
   arrays start at 1), renames `main` and writes `build/game.cpp`.
2. `runtime.h` defines the 12dPL types (`Integer`, `Real`, `Text`, ...) and
   stand-ins for the library calls: maths, text, files, panels and widgets,
   the cursor and the clock.
3. `harness.cpp` holds the drawing calls, which fill polygons into a pixel
   buffer, and `Wait_on_events`, which plays back the scenario script. Each
   script step becomes the event 12d would send, and the clock moves on
   1/30 s per event.
4. `hooks.cpp` is appended to the translated game, so it can read and change
   the macro's globals. That's where `call` commands such as `dump`,
   `give_beef` or `aim_cow` live.

## Using it

You need `g++`, `python3` and `cpp`. Pillow (`pip install pillow`) is only
needed to turn the snapshots into `.png` files.

```bash
./build.sh
```

```bash
./run.sh --all
```

```bash
./run.sh scenarios/02_break_build_craft.txt
```

Each run starts with no saved worlds. Pass `--keep` to keep them, which
scenario 06 needs because it loads the world that 05 saves. Worlds go in
`run/cubeland_worlds` and snapshots in `run/out`. Rebuild after changing the
macro.

## Scenario scripts

One command per line; `#` starts a comment.

| Command                | What it does                                                   |
|------------------------|----------------------------------------------------------------|
| `input <title>\|<text>` | type text into the input box with that title                   |
| `button <reply>`       | press a button (`create`, `play`, `delete`, `save`, `quit`)    |
| `select <n>`           | select the nth saved world in the menu                         |
| `click <x> <y>`        | left click the view at (x, y), from the bottom left            |
| `rclick`, `lbdown`, `move` | right click, mouse down, or mouse move at (x, y)           |
| `capclick`, `caprclick` | left or right click at the cursor while it's captured         |
| `look <dx> <dy>`       | move the mouse by (dx, dy) pixels                              |
| `wait <n>`             | let n frames pass                                              |
| `key <c> [n]`          | press a key (n times); `space` for the space bar               |
| `holdkey <c> <n>`      | hold a key for n frames (auto-repeat)                          |
| `time <s>`             | move the clock on by s seconds without a frame                 |
| `snap <name>`          | save the next frame as `run/out/<name>.ppm`/`.png`             |
| `call <hook>`          | run a hook from `hooks.cpp`                                    |
| `quit`                 | close the panel                                                |

When a script runs out, the panel is closed, so every scenario ends.

## Scenarios

| Script                        | Checks                                                          |
|-------------------------------|-----------------------------------------------------------------|
| `01_tour`                     | create a world, help screen, looking, walking, inventory        |
| `02_break_build_craft`        | break blocks with cracks, pick up drops, place, hand crafting   |
| `03_cow_and_furnace`          | kill a cow for beef, place a furnace facing the player          |
| `04_texture_stats`            | how many rectangles each texture is drawn with                  |
| `05_cooking_and_save`         | cook beef through the furnace screen, eat, save                 |
| `06_load_fall_respawn`        | load the world from 05, fall damage, death and respawn          |
| `07_scenery`                  | swimming, forests, hills, debug info                            |
| `08_crack_and_underwater`     | crack overlay on stone, the underwater view                     |
| `09_help_screen`              | the help panel                                                  |

Hooks use block and item numbers directly (11 is a furnace, 21 raw beef), so
update `hooks.cpp` if those change in `src/blocks.4dm`.
