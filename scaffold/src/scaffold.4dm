#ifndef SCAFFOLD_4DM_INCLUDED
#define SCAFFOLD_4DM_INCLUDED

#include "../include/event_id_registry.h"
#include "../include/scaffold.h"

Integer handle(Integer64 id, Text cmd, Text msg)
// ---------------------------------------
// ---------------------------------------
{
  switch(id) {
    case G_ID(MAIN_PANEL(Process)) : {
      // consume_event()?

      emit_event(G_ID(MAIN_PANEL(message_box)), "Set_data", "Process finished");

    } break;

    default : {
      // Assert
      // Drop event to dead queue?
    }
  }

  return 0;
}

#endif