#ifndef MAIN_PANEL_4DM_INCLUDED
#define MAIN_PANEL_4DM_INCLUDED

#include "../include/common.h"
#include "../include/debug.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/model.h"
#include "../include/panels.h"

Integer main_panel_run(Attributes &p_state, Attributes &p_events)
// ----------------------------------------------------------------
// The macro's panel: waits for 12d events, calls the model and
// dispatches what the model reports
// Returns SUCCESS, or SHUTDOWN_CODE if 12d asked the macro to stop
// ----------------------------------------------------------------
{
  Text               l_title          = MACRO_TITLE;
  Panel              l_panel          = Create_panel(l_title);
  Vertical_Group     l_vgroup         = Create_vertical_group(-1);
  Colour_Message_Box l_message        = Create_colour_message_box("");
  Horizontal_Group   l_buttons        = Create_button_group();
  Button             l_process_button = Create_button       ("&Process", CMD_PROCESS);
  Button             l_finish_button  = Create_finish_button("Finish"  , CMD_FINISH);
  Button             l_help_button    = Create_help_button  (l_panel   , "Help");
  Integer            l_result         = SUCCESS;
  Integer            l_doit           = TRUE;
  Integer64          l_id             = 0;
  Text               l_cmd            = "";
  Text               l_msg            = "";

  // TODO: create input widgets, e.g.
  // Integer_Box l_count_box  = Create_integer_box("Input number" , l_message);
  // Choice_Box  l_choice_box = Create_choice_box ("Select choice", l_message);

  Append(l_process_button, l_buttons);
  Append(l_finish_button , l_buttons);
  Append(l_help_button   , l_buttons);

  Append(l_message, l_vgroup);
  Append(l_buttons, l_vgroup);
  Append(l_vgroup , l_panel);

  Show_widget(l_panel);

  while (l_doit) {
    l_id  = 0;
    l_cmd = "";
    l_msg = "";
    if (Wait_on_events(l_id, l_cmd, l_msg) != 0) continue;

    // Key presses and focus changes need no answer
    if (l_cmd == "keystroke" || l_cmd == "set_focus" || l_cmd == "kill_focus") continue;

    if (l_cmd == "CodeShutdown") {
      // 12d is closing the macro: say so and get out at once
      Set_exit_code(l_cmd);
      l_result = SHUTDOWN_CODE;
      l_doit   = FALSE;
    } else if (l_cmd == "Panel Quit" || l_cmd == CMD_FINISH) {
      l_doit   = FALSE;
    } else if (l_cmd == CMD_PROCESS) {
      model_process(p_state, p_events);
    }

    main_panel_dispatch(p_events, p_state, l_message);
  }

  return l_result;
}

void main_panel_dispatch(Attributes &p_events, Attributes &p_state, Colour_Message_Box p_message)
// ----------------------------------------------------------------
// Take every waiting event off the queue and hand it to each
// module's handler. To react to an event, add a case to a handler;
// don't call the reaction from where the event happened.
// ----------------------------------------------------------------
{
  Attributes l_event;

  while (next_event(p_events, l_event)) {
    model_on_event     (l_event, p_state);
    main_panel_on_event(l_event, p_message);
  }
}

void main_panel_on_event(Attributes &p_event, Colour_Message_Box p_message)
// ----------------------------------------------------------------
// The panel's reactions to events (the view)
// ----------------------------------------------------------------
{
  Integer l_type = event_type(p_event);

  if (l_type == EVT_MESSAGE) {
    Set_data(p_message, event_text(p_event));
  } else if (l_type == EVT_PROCESS_FINISHED) {
    Set_data(p_message, "Process finished (run " + To_text(event_integer(p_event, 1)) + ")");
  }
}

#endif
