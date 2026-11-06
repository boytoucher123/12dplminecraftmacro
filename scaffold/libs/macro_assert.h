#ifndef macro_assert_h_included
#define macro_assert_h_included

#define RETURN_MACRO_ASSERT_RETRY  1
#define RETURN_MACRO_ASSERT_IGNORE 2
#define RETURN_MACRO_ASSERT_STOP   3

Integer macro_assert_panel(Dynamic_Text &dt_assert_info)
// ------------------------------------------------
// Pops ups a panel, displaying assert information
// 3 buttons
// Retry - Not implemented
// Ignore - Return and continue executing program
// Stop - Shut down macro
// ------------------------------------------------
{
  Integer macro_assert_choice = 0;

  Integer num_lines_teb = 0;
  Get_number_of_items(dt_assert_info, num_lines_teb);

  Panel          panel   = Create_panel("Assert");
  Message_Box    message = Create_message_box("");
  Vertical_Group vgroup  = Create_vertical_group(-1);

  Text_Edit_Box teb_assert_info = Create_text_edit_box("Assert Information", message, num_lines_teb);

  Horizontal_Group bgroup = Create_button_group();
  Button bn_retry  = Create_button("Retry", "Retry");
  Button bn_ignore = Create_button("Ignore", "Ignore");
  Button bn_stop   = Create_button("Stop", "Stop");

  Append(vgroup, panel);
  {
    Append(teb_assert_info, vgroup);
    Append(messsage       , vgroup);
    Append(bgroup         , vgroup);
    {
      Append(bn_retry , bgroup);
      Append(bn_ignore, bgroup);
      Append(bn_stop  , bgroup);
    }
  }

  Show_widget(panel);

  Integer doit = 1;
  Integer shutdown = 0;

  while (doit)
  {
    Integer64 id = 0LL;
    Text cmd = "", msg = "";
    Integer ret = Wait_on_events(id, cmd, msg);
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

      case Get_id64(panel) : {

        if (cmd == "Panel Quit") {

          macro_assert_choice = RETURN_MACRO_ASSERT_IGNORE;
          doit = 0;
        }
        else if (cmd == "Panel About") {

          about_panel(panel);
        }

      } break;

      case Get_id64(retry_button) : {

        if (cmd != "Retry") {
          break;
        }

        macro_assert_choice = RETURN_MACRO_ASSERT_RETRY;
        doit = 0;

      } break;

      case Get_id64(ignore_button) : {

        if (cmd != "Ignore") {
          break;
        }

        macro_assert_choice = RETURN_MACRO_ASSERT_IGNORE;
        doit = 0;

      } break;

      case Get_id64(stop_button) : {

        if (cmd != "Stop") {
          break;
        }

        macro_assert_choice = RETURN_MACRO_ASSERT_STOP;
        doit = 0;

      } break;

      default : {
      }
    }
  }

  if (shutdown == Shutdown_code) {
    // Get out quick
    return Shutdown_code;
  }

  return macro_assert_choice;
}


Integer assert(Integer line_num, Dynamic_Text &dt_assert_info)
// ----------------------------------------------------
// Don't call directly, call via ASSERT
// Need to build dynamic text beforehand and pass it in
// ----------------------------------------------------
{
  return macro_assert_panel(dt_assert_info);
}

#define ASSERT(I01) assert(__LINE__, I01)

#endif