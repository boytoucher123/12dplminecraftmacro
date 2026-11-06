# Coding rules

These rules apply to every file of a macro built from this scaffold. They come on top of the
12dPL language notes in `../12dpl differences from c`.

## 1. Honest functions

A function is **honest** when its signature lists everything it reads and
writes. Calling it with the same arguments always does the same thing, and
the only things it changes are its reference (`&`) parameters and its return
value. You can tell what an honest function touches without reading its body,
and you can test it by building its arguments by hand.

```
// Dishonest: reads and writes a global the caller can't see
void report_add_error(Text p_error)
{
  g_error_count = g_error_count + 1;
}

// Honest: the record it changes is a parameter
void report_add_error(Attributes &p_report, Text p_error)
{
  report_set_errors(p_report, report_errors(p_report) + 1);
}
```

What to do:

- **Pass state in, don't keep it in globals.** `main()` owns the records
  (the scaffold's `l_state` and `l_events`) and passes them to the panel,
  which passes them on. If a macro does need global records, only the
  controllers (`*_panel.4dm`) and `main()` may name them.
- **Use `&` for anything the function writes,** including records. A record
  parameter without `&` means "read only".
- **Pass hidden inputs in.** Randomness, the clock and user input are inputs
  too:
  - Randomness comes from a random record (`Attributes &random`,
    `random_next(random)`), never from `Get_random_number*` inside a model
    function.
  - Time comes in as `Real now` / `Real dt` parameters. Only the controller
    calls `Get_time`.
  - Widget values, keys and mouse positions come in as parameters from
    the controller.
- **Extract the dishonest part.** When a function mixes a calculation with
  a hidden read or write, split it. Make the calculation an honest function,
  and leave a thin wrapper (ideally in the controller) that does the read or
  write and calls it. The wrapper stays small and the logic becomes
  testable.
- **Report results through parameters or the return value,** not through
  "result" globals. Several results go in a result record.

### Allowed exceptions

Some data is too big or too hot to pass around as records (records are
slow: every field read is a name lookup). Such data may be a global array,
owned by one module:

- Only the owning module writes the table, and other modules read it only
  through the owner's functions.
- A function that touches one of these tables is called a **table function**.
  The owner's header lists its table functions under a
  `// Table functions` comment, so the dishonesty is written down.
- List each table, its owner and why it is global in a table in this
  section.
- Read-only lookup tables that are filled once at start-up count as
  constants once they are built.

A new function should be honest unless it is a table function or part of
a controller.

## 2. Records: Attributes in place of structs

12dPL has no structs. Use 12d `Attributes` for any group of related values
that would be a struct in C.

- **One record per thing.** The settings, the state, a report and the
  random generator each get their own record. Each module's header
  declares its records' field names as object-like macros:
  `#define ATTR_REPORT_ERRORS ("errors")`. Shared names such as
  `ATTR_X` are in `records.h`. Never spell a field name as a literal at the
  point of use.
- **Stamp the datatype.** `record_clear(record, DATATYPE_...)` empties a
  record and writes its `datatype` field, so a dump says what the record is.
- **Collections are one record.** Entity number `n` keeps its fields as
  `"<field>_<n>"`. Use `record_real_at(points, ATTR_X, point)` rather than
  arrays of Attributes or nested Attributes groups. This works whether 12d
  copies Attributes by value or shares them as handles.
- **Use getters and setters.** Each record type has accessor functions in
  its module, such as `report_errors(report)` and
  `report_set_errors(report, value)`. Other
  modules call those instead of naming fields. The generic
  `record_integer` / `record_real` / `record_text` and their setters are
  for writing accessors.
- **Keep one type per field.** A field is created with the type of its
  first write. Always write a field with the same setter and read it with
  the matching getter. Reading an Integer field as a Real fails.
- **Always pass records with `&`, and never copy them** with `=`. Whether
  12d copies an `Attributes` or shares it is not documented, so code must
  work either way.
- **Keep hot loops off records.** A collection that a loop visits often
  should keep a plain Integer array of the entries in use, updated by the
  same setter that writes the record's `used` field, so the loop visits
  only live entries instead of reading `used` for every slot.

## 3. Event-based architecture (MVC)

- **Model** modules hold the macro's state and do its work. They never
  touch a widget.
- **View** code changes widgets in response to events. It reads records
  and never changes state.
- **Controller** modules (`*_panel.4dm`) own the panels, read 12d events
  (buttons, keys, time) and call the model. In a panel macro the view is
  the controller's `*_on_event` handler.

Modules report what happened by emitting an event instead of calling each
other:

- Emit with the `emit_*` functions into the event queue record that is
  passed in, e.g. `emit_message(events, "Done")`. Add an `EVT_*` code to
  `include/events.h` for each new kind of event, with a comment saying
  what its payload fields mean.
- The controller's dispatch (`main_panel_dispatch`) takes each event off
  the queue into an event record and passes it to every module's
  `*_on_event(event, ...)` handler. Each handler takes the records it may
  change as parameters.
- A module never calls another module to tell it something happened. It
  may call another module's honest functions to ask a question.
- To add a reaction to something, add a case to the relevant `*_on_event`
  handler. Don't add a call at the place where it happens.
- Widget events are told apart by their command text: give every button
  its own `CMD_*` command and compare `cmd`, not widget ids.

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
  | global      | `g_`   | `g_settings`, `g_table` |
  | parameter   | `p_`   | `Attributes &p_state`   |
  | local       | `l_`   | `Integer l_count = 0;`  |
  | function    | none   | `model_process(...)`    |

- Write constants as object-like macros in the appropriate header:
  `SUCCESS (0)`, `FAILURE (-1)`, field names, sizes.
- Each file includes the headers it uses and has an include guard.
  `src/build.4dm` includes every source file and must work in any order.
- Use the debug macros (`D1`..`D4`, `DVAR1`..`DVAR4`) from
  `include/debug.h`. They compile to nothing unless `DEBUG` is defined.

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
- Every panel loop answers `"CodeShutdown"` with `Set_exit_code(cmd)` and
  returns `SHUTDOWN_CODE`, and every caller of a panel passes
  `SHUTDOWN_CODE` straight up, so 12d can close the macro at once.

## 6. Safety

- `include/safety.h` is the first include of `src/build.4dm`. It
  `#define`s every dangerous 12d call as `illegal_call`, so using one is
  a compile error. Never include anything before it, never `#undef` its
  names, and add any new dangerous call you come across to it.
- If the macro's job needs one of the blocked calls, delete that one line
  and leave a comment in its place saying what is allowed and why.
- Open files only with `safe_file_open()`. It reads anywhere but writes
  only inside `SAFE_WRITE_FOLDER` (set it to the macro's own folder).
- Don't delete files: overwrite them with a marker instead.
