#ifndef PANELS_H_INCLUDED
#define PANELS_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Controllers: the 12d panels. They turn widget events into calls
// to the model, then pass the model's events to every *_on_event
// handler (main_panel_dispatch). They are also the views: the
// *_on_event handlers here are the only code that changes widgets.
// ----------------------------------------------------------------

// Button commands (each button sends its own, so the loop can tell
// them apart by cmd alone, without comparing widget ids)
#define CMD_PROCESS          ("process")
#define CMD_FINISH           ("finish")

Integer main_panel_run       (Attributes &p_state, Attributes &p_events);
void    main_panel_dispatch  (Attributes &p_events, Attributes &p_state, Colour_Message_Box p_message);
void    main_panel_on_event  (Attributes &p_event, Colour_Message_Box p_message);

#endif
