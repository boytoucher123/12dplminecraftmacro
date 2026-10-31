#ifndef SCAFFOLD_PANEL_4DM_INCLUDED
#define SCAFFOLD_PANEL_4DM_INCLUDED

#include "../include/scaffold_panel.h"
#include "../include/event_id_registry.h"
#include "../include/scaffold.h"

Integer main_panel()
// --------------------------------------------------------
// Scaffold for a basic 12dPL GUI panel
// --------------------------------------------------------
{
  Text panel_name = "Change me"; //TODO: Change panel name

  Panel              panel   = Create_panel             (panel_name, 1);
  Vertical_Group     vgroup  = Create_vertical_group    (-1);
  Colour_Message_Box msg_box = Create_colour_message_box("");
  Horizontal_Group   bgroup  = Create_button_group      ();


  //////////////////// CREATE INPUT WIDGETS ////////////////////

  // TODO: Create input widgets for the panel
  // e.g.
  // Integer_Box widget1 = Create_integer_box("Input number" , msg_box);
  // Choice_Box  widget2 = Create_choice_box ("Select choice", msg_box);


  //////////////////// ADDING BUTTONS ALONG THE BOTTOM ////////////////////

  Button process_button = Create_button       ("&Process", "Process");
  Button finish_button  = Create_finish_button("Finish"  , "Finish");
  Button help_button    = Create_help_button  (panel     , "Help");

  Append(vgroup , panel);
  {
    Append(msg_box, vgroup);
    Append(bgroup , vgroup);
    {
      Append(process_button, bgroup);
      Append(finish_button , bgroup);
      Append(help_button   , bgroup);
    }
  }

  // Define local ID macro
  #undef ID
  #define ID(I01) G_ID(MAIN_PANEL(I01))
  // Populate event ID values
  ID(panel         ) = Get_id64(panel);
  ID(process_button) = Get_id64(process_button);
  ID(finish_button ) = Get_id64(finish_button);
  ID(help_button   ) = Get_id64(help_button);


  Show_widget(panel);

  Integer doit = 1;
  Integer shutdown = 0;

  while(doit) {
    Integer64 id = 0LL;
    Text cmd = "", msg = "";
    Integer ret = Wait_on_custom_events(id, cmd, msg);
    if (ret != 0) {
      continue;
    }

    switch(cmd) {

      case "keystroke"  :   // When a key is pressed
      case "set_focus"  :   // When 12d Model has gained focus
      case "kill_focus" : { // When 12d Model has lost focus

        continue;

      } break;

      case "CodeShutdown" : { // Allows 12d Model to shutdown this macro automatically

        Set_exit_code(cmd);
        doit = 0;

      } break;
    }


    switch(id) {

      case ID(panel) : {

        if (cmd == "Panel Quit") {

          doit = 0;
        }
        else if (cmd == "Panel About") {

          about_panel(panel);
        }

      } break;

      case ID(finish_button) : {

        if(cmd != "Finish") {
            break;
        }

        doit = 0;

      } break;

      case ID(process_button) : {

        if (cmd != "Process") {
            break;
        }

        emit_event(ID(Process), "Process", "");

      } break;

      case ID(message_box) : {
        switch (cmd) {
          case "Set_data" : {
            Set_data(msg_box, msg);
          }
        }
      } break;

      default : {
        handle(id, cmd, msg);
      }
    }
  }

  if (shutdown == Shutdown_code) {
    // Get out quick
  }

  return 0;
}


#endif