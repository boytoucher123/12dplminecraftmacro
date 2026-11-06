# 12dPL macro scaffold

A starting point for a 12d Model macro: one panel with a message box and
Process / Finish / Help buttons, already split into model, view and
controller, with safety blocks, records, an event queue and debug macros.
Read `CODING_RULES.md` before adding code.

## Starting a new macro

1. Copy this folder and rename `scaffold.4dm` (and its
   `SCAFFOLD_BASE_FILE_4DM_INCLUDED` guard) after the macro.
2. Fill in the comment at the top of that file, `MACRO_TITLE` in
   `include/common.h` and `SAFE_WRITE_FOLDER` in `include/safety.h`.
3. Put the work in `src/model.4dm` (`model_process`), and the widgets
   and their reactions in `src/main_panel.4dm`.
4. Compile the renamed `.4dm` file in 12d.

## Layout

| File                     | What it holds |
|--------------------------|---------------|
| `scaffold.4dm`           | `main()`: makes the state and event records and runs the panel |
| `src/build.4dm`          | `include/safety.h` first, build mode (`RELEASE` / `DEBUG`), then every source file |
| `include/safety.h`       | turns every dangerous 12d call into a compile error; `safe_file_open()` |
| `include/common.h`       | `SUCCESS`, `FAILURE`, `TRUE`, `FALSE`, `SHUTDOWN_CODE`, macro title |
| `include/debug.h`        | `D1`..`D4`, `DVAR1`..`DVAR4`; nothing unless `DEBUG` is defined |
| `include/records.h`, `src/records.4dm` | Attributes used as structs: typed getters and setters, collections (`"x_3"`), seeded random numbers |
| `include/events.h`, `src/events.4dm`   | the event queue: `emit_*`, `next_event`, `EVT_*` codes |
| `include/model.h`, `src/model.4dm`     | example model: a state record and `model_process` |
| `include/panels.h`, `src/main_panel.4dm` | the panel loop, `main_panel_dispatch` and the view handler |
| `libs/macro_assert.h`    | `ASSERT(condition, info)` panel (debug builds only) |
| `libs/to_text.h`         | `to_text()` overloads |

## How an action flows

1. The user presses Process. `Wait_on_events` returns the command
   `CMD_PROCESS`.
2. The panel loop calls `model_process(state, events)`. The model does
   the work, updates the state record and emits `EVT_PROCESS_FINISHED`.
3. `main_panel_dispatch` takes each event off the queue and hands it to
   `model_on_event` and `main_panel_on_event`. The latter writes the
   message box.

To add a feature, add a `CMD_*` and a button, a model function, an
`EVT_*` for what it reports, and a case in whichever `*_on_event`
handler should react.
