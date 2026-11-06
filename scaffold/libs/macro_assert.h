#ifndef MACRO_ASSERT_H_INCLUDED
#define MACRO_ASSERT_H_INCLUDED

// ----------------------------------------------------------------
// Assert panel
// ASSERT(condition, info) shows a panel with the line number and the
// lines of info (a Dynamic_Text) when condition is FALSE. It compiles
// to nothing unless DEBUG is defined in build.4dm.
//
// The panel returns one of
//   MACRO_ASSERT_RETRY   not implemented yet, carries on like Ignore
//   MACRO_ASSERT_IGNORE  carry on
//   MACRO_ASSERT_STOP    the caller should stop the macro
//   SHUTDOWN_CODE        12d asked the macro to stop
// ----------------------------------------------------------------

#include "../include/common.h"

#define MACRO_ASSERT_RETRY   1
#define MACRO_ASSERT_IGNORE  2
#define MACRO_ASSERT_STOP    3
#define MACRO_ASSERT_LINES   12   // height of the information box

#define CMD_ASSERT_RETRY     ("assert_retry")
#define CMD_ASSERT_IGNORE    ("assert_ignore")
#define CMD_ASSERT_STOP      ("assert_stop")

Integer macro_assert_panel(Integer p_line, Dynamic_Text &p_info)
// ----------------------------------------------------------------
// Show the assert information and wait for Retry, Ignore or Stop
// Closing the panel counts as Ignore
// ----------------------------------------------------------------
{
  Integer          l_choice        = MACRO_ASSERT_IGNORE;
  Integer          l_doit          = TRUE;
  Integer64        l_id            = 0;
  Text             l_cmd           = "";
  Text             l_msg           = "";
  Dynamic_Text     l_shown;
  Panel            l_panel         = Create_panel("Assert failed");
  Vertical_Group   l_vgroup        = Create_vertical_group(-1);
  Message_Box      l_message       = Create_message_box("");
  Text_Edit_Box    l_info_box      = Create_text_edit_box("Assert information", l_message, MACRO_ASSERT_LINES);
  Horizontal_Group l_buttons       = Create_button_group();
  Button           l_retry_button  = Create_button("Retry" , CMD_ASSERT_RETRY);
  Button           l_ignore_button = Create_button("Ignore", CMD_ASSERT_IGNORE);
  Button           l_stop_button   = Create_button("Stop"  , CMD_ASSERT_STOP);

  Append(l_retry_button , l_buttons);
  Append(l_ignore_button, l_buttons);
  Append(l_stop_button  , l_buttons);

  Append(l_info_box, l_vgroup);
  Append(l_message , l_vgroup);
  Append(l_buttons , l_vgroup);
  Append(l_vgroup  , l_panel);

  Append("Line " + To_text(p_line), l_shown);
  Append(p_info, l_shown);
  Set_data(l_info_box, l_shown);

  Show_widget(l_panel);

  while (l_doit) {
    l_id  = 0;
    l_cmd = "";
    l_msg = "";
    if (Wait_on_events(l_id, l_cmd, l_msg) != 0) continue;

    if (l_cmd == "keystroke" || l_cmd == "set_focus" || l_cmd == "kill_focus") continue;

    if (l_cmd == "CodeShutdown") {
      Set_exit_code(l_cmd);
      l_choice = SHUTDOWN_CODE;
      l_doit   = FALSE;
    } else if (l_cmd == "Panel Quit" || l_cmd == CMD_ASSERT_IGNORE) {
      l_choice = MACRO_ASSERT_IGNORE;
      l_doit   = FALSE;
    } else if (l_cmd == CMD_ASSERT_RETRY) {
      l_choice = MACRO_ASSERT_RETRY;
      l_doit   = FALSE;
    } else if (l_cmd == CMD_ASSERT_STOP) {
      l_choice = MACRO_ASSERT_STOP;
      l_doit   = FALSE;
    }
  }

  Hide_widget(l_panel);

  return l_choice;
}

Integer macro_assert(Integer p_condition, Integer p_line, Dynamic_Text &p_info)
// ----------------------------------------------------------------
// Don't call directly, call via ASSERT
// Returns MACRO_ASSERT_IGNORE when the condition holds
// ----------------------------------------------------------------
{
  if (p_condition) return MACRO_ASSERT_IGNORE;
  return macro_assert_panel(p_line, p_info);
}

#ifdef DEBUG
#define ASSERT(I01, I02)  macro_assert(I01, __LINE__, I02)
#else
#define ASSERT(I01, I02)  MACRO_ASSERT_IGNORE
#endif

#endif
