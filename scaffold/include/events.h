#ifndef EVENTS_H_INCLUDED
#define EVENTS_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Event queue
// Modules never call each other to report what happened, they emit
// an event instead. The controller's dispatch takes each event off
// the queue into an event record and hands it to every module's
// *_on_event() handler. The queue and the event are both records
// (see records.h): the queue keeps entry n in fields "type_n",
// "i1_n", ... and the event has fields "type", "i1", ... "text".
// ----------------------------------------------------------------

#define EVENT_QUEUE_SIZE      256

// Event types and their payloads (add your own below)
#define EVT_NONE              0
#define EVT_MESSAGE           1    // text: show it in the panel's message box
#define EVT_PROCESS_FINISHED  2    // i1 number of runs so far

#define DATATYPE_EVENT_QUEUE  ("event_queue")
#define DATATYPE_EVENT        ("event")
#define ATTR_EVENT_HEAD       ("head")
#define ATTR_EVENT_LOST       ("lost")
#define ATTR_EVENT_I1         ("i1")
#define ATTR_EVENT_I2         ("i2")
#define ATTR_EVENT_I3         ("i3")
#define ATTR_EVENT_I4         ("i4")
#define ATTR_EVENT_R1         ("r1")
#define ATTR_EVENT_R2         ("r2")
#define ATTR_EVENT_R3         ("r3")

void    events_clear     (Attributes &p_events);
void    emit_event       (Attributes &p_events, Integer p_type, Integer p_i1, Integer p_i2, Integer p_i3, Integer p_i4, Real p_r1, Real p_r2, Real p_r3, Text p_text);
void    emit_simple_event(Attributes &p_events, Integer p_type);
void    emit_message     (Attributes &p_events, Text p_text);
Integer events_pending   (Attributes &p_events);
Integer next_event       (Attributes &p_events, Attributes &p_event);
Integer event_type       (Attributes &p_event);
Integer event_integer    (Attributes &p_event, Integer p_which);
Real    event_real       (Attributes &p_event, Integer p_which);
Text    event_text       (Attributes &p_event);

#endif
