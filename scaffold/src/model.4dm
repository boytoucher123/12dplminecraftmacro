#ifndef MODEL_4DM_INCLUDED
#define MODEL_4DM_INCLUDED

#include "../include/common.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/model.h"

void model_clear(Attributes &p_state)
// ----------------------------------------------------------------
// Start with an empty state record
// ----------------------------------------------------------------
{
  record_clear      (p_state, DATATYPE_STATE);
  record_set_integer(p_state, ATTR_STATE_RUNS, 0);
}

Integer model_runs(Attributes &p_state)
// ----------------------------------------------------------------
// How many times Process has run
// ----------------------------------------------------------------
{
  return record_integer(p_state, ATTR_STATE_RUNS);
}

Integer model_process(Attributes &p_state, Attributes &p_events)
// ----------------------------------------------------------------
// The work behind the Process button
// Emits EVT_PROCESS_FINISHED when done; returns SUCCESS or FAILURE
// ----------------------------------------------------------------
{
  Integer l_runs = model_runs(p_state) + 1;

  // TODO: do the real work here

  record_set_integer(p_state, ATTR_STATE_RUNS, l_runs);
  emit_event(p_events, EVT_PROCESS_FINISHED, l_runs, 0, 0, 0, 0.0, 0.0, 0.0, "");

  return SUCCESS;
}

void model_on_event(Attributes &p_event, Attributes &p_state)
// ----------------------------------------------------------------
// The model's reactions to events (add a case per reaction)
// ----------------------------------------------------------------
{
  Integer l_type = event_type(p_event);

  if (l_type == EVT_NONE) return;
}

#endif
