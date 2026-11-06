#ifndef MODEL_H_INCLUDED
#define MODEL_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Model: the macro's state and the work it does
// Everything here is honest: it reads and writes only the records
// passed in, and reports what happened by emitting events, never by
// touching a widget. TODO: replace the example with the real work.
// ----------------------------------------------------------------

#define DATATYPE_STATE     ("state")
#define ATTR_STATE_RUNS    ("runs")

void    model_clear        (Attributes &p_state);
Integer model_runs         (Attributes &p_state);
Integer model_process      (Attributes &p_state, Attributes &p_events);
void    model_on_event     (Attributes &p_event, Attributes &p_state);

#endif
