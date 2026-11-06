# Cubeland coding rules

These rules apply to every file in `cubeland/`. They come on top of the
12dPL language notes in `../12dpl differences from c`.

## 1. Honest functions

A function is **honest** when its signature lists everything it reads and
writes. Calling it with the same arguments always does the same thing, and
the only things it changes are its reference (`&`) parameters and its return
value. You can tell what an honest function touches without reading its body,
and you can test it by building its arguments by hand.

```
// Dishonest: reads and writes globals the caller can't see
void player_heal(Integer p_amount)
{
  g_player_health = g_player_health + p_amount;
}

// Honest: the record it changes is a parameter
void player_heal(Attributes &p_player, Integer p_amount)
{
  player_set_health(p_player, player_health(p_player) + p_amount);
}
```

What to do:

- **Pass globals in, don't read them.** Reach a global record
  (`g_player`, `g_cows`, ...) only in the controller (`*_panel.4dm`) and
  in `game.4dm`'s top-level update and dispatch. Everything below that gets
  the record as a parameter: `player_position(g_player, x, y, z)`, not
  `player_position(x, y, z)`.
- **Use `&` for anything the function writes,** including records. A record
  parameter without `&` means "read only".
- **Pass hidden inputs in.** Randomness, the clock and user input are inputs
  too:
  - Randomness comes from a random record (`Attributes &random`,
    `random_next(random)`), never from `Get_random_number*` inside a model
    function.
  - Time comes in as `Real now` / `Real dt` parameters. Only the controller
    calls `Get_time`.
  - Keys and mouse positions come in as parameters from the controller.
- **Extract the dishonest part.** When a function mixes a calculation with
  a hidden read or write, split it. Make the calculation an honest function,
  and leave a thin wrapper (ideally in the controller) that does the read or
  write and calls it. The wrapper stays small and the logic becomes
  testable.
- **Report results through parameters or the return value,** not through
  "result" globals. For example, `physics_move_box` returns what it hit
  through a result record, not through `g_hit_*` globals.

### Allowed exceptions

Some data is too big or too hot to pass around as records. These stay
global arrays, each owned by one module:

| Table                                   | Owner            | Why                                   |
|-----------------------------------------|------------------|---------------------------------------|
| `g_world`, `g_height_map`, biome map    | `world.4dm`      | 1.5 million cells, read millions of times a frame |
| face cache `g_face_*`, `g_section_*`    | `mesh.4dm`       | hundreds of thousands of entries      |
| texture pixels, palettes and rectangles | `textures.4dm`   | built once, read-only afterwards      |
| render scratch buffers, `g_view_*` frame copies | `render_world.4dm` | per-frame working memory, filled from records by `render_view_from` |
| block edit list `g_edit_*`              | `save.4dm`       | up to 65,536 entries                  |
| byte buffers `g_pack_*`, `g_inflate_*`  | `resource_pack.4dm` | hundreds of thousands of bytes while decoding a pack |
| relighting queue `g_light_q*`           | `world.4dm`      | up to 65,536 cells per light update   |
| icon polygon scratch `g_icon_*`         | `render_hud.4dm` | point lists for `Draw_polygon`        |

Rules for these tables:

- Only the owning module writes the table, and other modules read it only
  through the owner's functions (`world_get_block`, `texture_get`).
- A function that touches one of these tables is called a **table function**.
  The owner's header lists its table functions under a
  `// Table functions` comment, so the dishonesty is written down.
- Read-only lookup tables that are filled once at start-up (textures,
  recipes) count as constants once they are built.

At the time of writing, 421 of the 522 functions are honest: they touch no
global at all. The other 101 are table functions or controllers. (The
resource pack decoder added many table functions: it works on byte buffers
far too big to pass around as records.)

Try to raise the share of honest functions with every change. A new
function should be honest unless it is a table function or part of the
controller.

## 2. Records: Attributes in place of structs

12dPL has no structs. Use 12d `Attributes` for any group of related values
that would be a struct in C.

- **One record per thing.** The player, the settings, the inventory and
  the random generator each get their own record. Each module's header
  declares its records' field names as object-like macros:
  `#define ATTR_PLAYER_SELECTED ("selected")`. Shared names such as
  `ATTR_X` are in `records.h`. Never spell a field name as a literal at the
  point of use.
- **Stamp the datatype.** `record_clear(record, DATATYPE_...)` empties a
  record and writes its `datatype` field, so a dump says what the record is.
- **Collections are one record.** Entity number `n` keeps its fields as
  `"<field>_<n>"`. Use `record_real_at(cows, ATTR_X, cow)` rather than
  arrays of Attributes or nested Attributes groups. This works whether 12d
  copies Attributes by value or shares them as handles.
- **Use getters and setters.** Each record type has accessor functions in
  its module, such as `player_position(player, x, y, z)`,
  `player_set_health(player, value)` and `cow_alive(cows, cow)`. Other
  modules call those instead of naming fields. The generic
  `record_integer` / `record_real` / `record_text` and their setters are
  for writing accessors.
- **Keep one type per field.** A field is created with the type of its
  first write. Always write a field with the same setter and read it with
  the matching getter. Reading an Integer field as a Real fails.
- **Always pass records with `&`, and never copy them** with `=`. Whether
  12d copies an `Attributes` or shares it is not documented, so code must
  work either way.

## 3. Event-based architecture (MVC)

- **Model** modules (`world`, `player`, `inventory`, `cows`, `drops`,
  `furnace`, `crafting`, `save`) hold the game state and the rules.
- **View** modules (`render_*`) draw. A view reads records and never
  changes game state.
- **Controller** modules (`*_panel.4dm`) own the panels, read 12d events
  (mouse, keys, time) and call the model.

Modules report what happened by emitting an event instead of calling each
other:

- Emit with the `emit_*` functions into the event queue record that is
  passed in, e.g. `emit_cell_event(events, EVT_BLOCK_BROKEN, x, y, z, block)`.
- `game_dispatch_events()` takes each event off the queue into an event
  record and passes it to every module's `*_on_event(event, ...)` handler.
  Each handler takes the records it may change as parameters.
- A module never calls another module to tell it something happened. It
  may call another module's honest functions to ask a question
  (`block_is_solid`, `item_name`).
- To add a reaction to something, add a case to the relevant `*_on_event`
  handler. Don't add a call at the place where it happens.

## 4. Formatting and structure

- Every function is written as:

  ```
  <return_type> <function_name>(<parameters,...>)
  // ----------------------------------------------------------------
  // What the function is for
  // Any other important details
  // ----------------------------------------------------------------
  {
    // code...
  }
  ```

- Align declarations and repeated statements, and use meaningful names
  rather than abbreviations.
- **Name prefixes.** 12dPL doesn't allow a variable and a function to
  share a name, so every variable carries a prefix that no function
  name has:

  | Kind        | Prefix | Example                 |
  |-------------|--------|-------------------------|
  | global      | `g_`   | `g_player`, `g_world`   |
  | parameter   | `p_`   | `Attributes &p_player`  |
  | local       | `l_`   | `Integer l_count = 0;`  |
  | function    | none   | `player_position(...)`  |

  The test harness's lint reports a parameter without `p_` or a local
  without `l_`.
- Write constants as object-like macros in the appropriate header:
  `SUCCESS (0)`, `FAILURE (-1)`, field names, sizes.
- Sources live in `src/<part>/` (core, blocks, world, items, mobs, player,
  render, program, ui) and each module's header in `include/<part>/`, the
  same folder name. A new module goes in the folder of the part it belongs
  to, and `src/build.4dm` gets a line for it in that folder's group.
- Each file includes the headers it uses. `src/build.4dm` includes every
  source file and must work in any order.
- Use the debug macros (`D1`..`D4`, `DVAR1`..`DVAR4`) from
  `include/core/debug.h`. They compile to nothing unless `DEBUG` is defined.

## 5. 12dPL pitfalls to avoid

- Arrays start at 1 and their sizes must be literal numbers.
- There is no short-circuit evaluation: `if (i <= n && a[i] > 0)` still
  reads `a[i]` when `i > n`, so guard array reads with nested `if`s.
- A variable declared in a `for` header lives on after the loop. Declare
  loop variables at the top of the function and never declare a name twice
  in one function.
- Don't use `+=` and friends, `?:`, or `"literal" + "literal"`. Assign a
  macro string to a `Text` variable before joining it to another literal.
- Convert Reals to Integers by assignment (`Integer i = Floor(x);`) or with
  `floor_integer()`. Don't pass a Real where an Integer parameter is
  expected.
- Variables and functions must not share a name (the `g_`, `p_` and
  `l_` prefixes in section 4 make sure they never do).

## 6. Safety

- `include/core/safety.h` is the first include of `src/build.4dm`. It
  `#define`s every dangerous 12d call as `illegal_call`, so using one is
  a compile error. Never include anything before it, never `#undef` its
  names, and add any new dangerous call you come across to it.
- Open files only with `safe_file_open()`. It reads anywhere but writes
  only inside `SAFE_WRITE_FOLDER` (`cubeland_worlds`).
- Don't delete files: overwrite them with a marker instead (see
  `save_delete_world()`).

## 7. Testing

`tools/test_harness` translates the macro into C++ and runs scripted
scenarios. Its Attributes stand-in copies by value and checks field types,
so it catches records that are passed without `&` and fields written or
read with the wrong type. Run `./build.sh` and `./run.sh --all` after a
change. Read the lint warnings from the build, and check that the type
error count printed at the end of each run is 0.
