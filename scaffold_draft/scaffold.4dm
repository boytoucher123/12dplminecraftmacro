//------------------------------------------------------------
// Change me (TODO: macro name)
//
// What the macro does, in a few lines.
//
// Structure
//   scaffold.4dm      this file: main()
//   src/build.4dm     includes include/safety.h (which blocks every
//                     dangerous 12d call) and then every source file
//   include/*.h       constants, record field names and prototypes
//   src/*.4dm         model (model.4dm) and controllers/views
//                     (*_panel.4dm)
// Modules don't report to each other directly: they emit events
// (include/events.h) and main_panel_dispatch() passes each event to
// every module's *_on_event() handler. State lives in records (12d
// Attributes used like structs) that are passed to every function
// that uses them; see CODING_RULES.md.
//------------------------------------------------------------

#ifdef SCAFFOLD_BASE_FILE_4DM_INCLUDED
#error Do not include the base file!
#endif
#define SCAFFOLD_BASE_FILE_4DM_INCLUDED

#include "src/build.4dm"

void main()
// --------------------------------------------------------
// Entry point: set up the records, then run the panel
// --------------------------------------------------------
{
  Attributes l_state;
  Attributes l_events;

  model_clear (l_state);
  events_clear(l_events);

  main_panel_run(l_state, l_events);
}
