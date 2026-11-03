#ifndef SETTINGS_PANEL_4DM_INCLUDED
#define SETTINGS_PANEL_4DM_INCLUDED

#include "../include/common.h"
#include "../include/records.h"
#include "../include/settings.h"
#include "../include/save.h"
#include "../include/panels.h"

// ----------------------------------------------------------------
// The settings panel: every setting is a line showing its value and
// a row of buttons that change it. 12d buttons can't change their
// own text, so the value is shown in a message box above them.
// Button replies start with "set_" so they can't be confused with
// the other panels' buttons.
// ----------------------------------------------------------------

void settings_panel_show(Attributes &settings, Colour_Message_Box render_row, Colour_Message_Box detail_row,
                         Colour_Message_Box fov_row, Colour_Message_Box mouse_row, Colour_Message_Box plants_row,
                         Colour_Message_Box shading_row, Colour_Message_Box jump_row, Colour_Message_Box hud_row,
                         Colour_Message_Box debug_row)
// ----------------------------------------------------------------
// Show the current value of every setting
// ----------------------------------------------------------------
{
  Set_data(render_row , settings_describe(settings, ATTR_SET_RENDER_DISTANCE));
  Set_data(detail_row , settings_describe(settings, ATTR_SET_DETAIL));
  Set_data(fov_row    , settings_describe(settings, ATTR_SET_FOV));
  Set_data(mouse_row  , settings_describe(settings, ATTR_SET_SENSITIVITY));
  Set_data(plants_row , settings_describe(settings, ATTR_SET_PLANTS));
  Set_data(shading_row, settings_describe(settings, ATTR_SET_SHADING));
  Set_data(jump_row   , settings_describe(settings, ATTR_SET_AUTO_JUMP));
  Set_data(hud_row    , settings_describe(settings, ATTR_SET_SHOW_HUD));
  Set_data(debug_row  , settings_describe(settings, ATTR_SET_SHOW_DEBUG));
}

Integer settings_panel_run(Attributes &settings)
// ----------------------------------------------------------------
// Show the settings until Done is pressed; changes apply straight
// away and are saved to the settings file when the panel closes
// Returns 0, or SHUTDOWN_CODE if 12d asked the macro to stop
// ----------------------------------------------------------------
{
  Text               title          = GAME_TITLE;
  Panel              panel          = Create_panel(title + " - settings");
  Vertical_Group     vgroup         = Create_vertical_group(0);
  Colour_Message_Box message        = Create_colour_message_box("");

  Colour_Message_Box render_row     = Create_colour_message_box("");
  Horizontal_Group   render_buttons = Create_button_group();
  Button             render_less    = Create_button("- Shorter view", "set_render_down");
  Button             render_more    = Create_button("Longer view +", "set_render_up");
  Button             render_most    = Create_button("Furthest", "set_render_max");

  Colour_Message_Box detail_row     = Create_colour_message_box("");
  Horizontal_Group   detail_buttons = Create_button_group();
  Button             detail_low     = Create_button("Low", "set_detail_low");
  Button             detail_normal  = Create_button("Normal", "set_detail_normal");
  Button             detail_high    = Create_button("High", "set_detail_high");

  Colour_Message_Box fov_row        = Create_colour_message_box("");
  Horizontal_Group   fov_buttons    = Create_button_group();
  Button             fov_less       = Create_button("- Narrower", "set_fov_down");
  Button             fov_more       = Create_button("Wider +", "set_fov_up");

  Colour_Message_Box mouse_row      = Create_colour_message_box("");
  Horizontal_Group   mouse_buttons  = Create_button_group();
  Button             mouse_less     = Create_button("- Slower", "set_mouse_down");
  Button             mouse_more     = Create_button("Faster +", "set_mouse_up");

  Colour_Message_Box plants_row     = Create_colour_message_box("");
  Colour_Message_Box shading_row    = Create_colour_message_box("");
  Colour_Message_Box jump_row       = Create_colour_message_box("");
  Colour_Message_Box hud_row        = Create_colour_message_box("");
  Colour_Message_Box debug_row      = Create_colour_message_box("");
  Horizontal_Group   toggle_buttons = Create_button_group();
  Button             plants_toggle  = Create_button("Grass and flowers", "set_plants");
  Button             shading_toggle = Create_button("Shadows", "set_shading");
  Button             jump_toggle    = Create_button("Auto-jump", "set_jump");
  Button             hud_toggle     = Create_button("HUD", "set_hud");
  Button             debug_toggle   = Create_button("Statistics", "set_debug");

  Horizontal_Group   end_buttons    = Create_button_group();
  Button             reset_button   = Create_button("Reset to defaults", "set_defaults");
  Button             done_button    = Create_finish_button("Done", "set_done");

  Integer            result         = 0;
  Integer            doit           = TRUE;
  Integer64          id             = 0;
  Text               cmd            = "";
  Text               msg            = "";

  Append(render_less, render_buttons);
  Append(render_more, render_buttons);
  Append(render_most, render_buttons);
  Append(detail_low   , detail_buttons);
  Append(detail_normal, detail_buttons);
  Append(detail_high  , detail_buttons);
  Append(fov_less, fov_buttons);
  Append(fov_more, fov_buttons);
  Append(mouse_less, mouse_buttons);
  Append(mouse_more, mouse_buttons);
  Append(plants_toggle , toggle_buttons);
  Append(shading_toggle, toggle_buttons);
  Append(jump_toggle   , toggle_buttons);
  Append(hud_toggle    , toggle_buttons);
  Append(debug_toggle  , toggle_buttons);
  Append(reset_button, end_buttons);
  Append(done_button , end_buttons);

  Append(render_row    , vgroup);
  Append(render_buttons, vgroup);
  Append(detail_row    , vgroup);
  Append(detail_buttons, vgroup);
  Append(fov_row       , vgroup);
  Append(fov_buttons   , vgroup);
  Append(mouse_row     , vgroup);
  Append(mouse_buttons , vgroup);
  Append(plants_row    , vgroup);
  Append(shading_row   , vgroup);
  Append(jump_row      , vgroup);
  Append(hud_row       , vgroup);
  Append(debug_row     , vgroup);
  Append(toggle_buttons, vgroup);
  Append(end_buttons   , vgroup);
  Append(message       , vgroup);
  Append(vgroup        , panel);

  Show_widget(panel);
  settings_panel_show(settings, render_row, detail_row, fov_row, mouse_row, plants_row, shading_row, jump_row, hud_row, debug_row);
  Set_data(message, "Longer views and higher detail look better but draw more slowly.");

  while (doit) {
    id  = 0;
    cmd = "";
    msg = "";
    if (Wait_on_events(id, cmd, msg) != 0) continue;

    if (cmd == "CodeShutdown") {
      Set_exit_code(cmd);
      result = SHUTDOWN_CODE;
      doit   = FALSE;
    } else if (cmd == "Panel Quit" || cmd == "set_done") {
      doit = FALSE;
    } else if (cmd == "set_render_down") {
      settings_change(settings, ATTR_SET_RENDER_DISTANCE, -1);
    } else if (cmd == "set_render_up") {
      settings_change(settings, ATTR_SET_RENDER_DISTANCE, 1);
    } else if (cmd == "set_render_max") {
      record_set_integer(settings, ATTR_SET_RENDER_DISTANCE, RENDER_DISTANCE_MAX);
    } else if (cmd == "set_detail_low") {
      record_set_integer(settings, ATTR_SET_DETAIL, DETAIL_LOW);
    } else if (cmd == "set_detail_normal") {
      record_set_integer(settings, ATTR_SET_DETAIL, DETAIL_NORMAL);
    } else if (cmd == "set_detail_high") {
      record_set_integer(settings, ATTR_SET_DETAIL, DETAIL_HIGH);
    } else if (cmd == "set_fov_down") {
      settings_change(settings, ATTR_SET_FOV, -1);
    } else if (cmd == "set_fov_up") {
      settings_change(settings, ATTR_SET_FOV, 1);
    } else if (cmd == "set_mouse_down") {
      settings_change(settings, ATTR_SET_SENSITIVITY, -1);
    } else if (cmd == "set_mouse_up") {
      settings_change(settings, ATTR_SET_SENSITIVITY, 1);
    } else if (cmd == "set_plants") {
      settings_toggle(settings, ATTR_SET_PLANTS);
    } else if (cmd == "set_shading") {
      settings_toggle(settings, ATTR_SET_SHADING);
    } else if (cmd == "set_jump") {
      settings_toggle(settings, ATTR_SET_AUTO_JUMP);
    } else if (cmd == "set_hud") {
      settings_toggle(settings, ATTR_SET_SHOW_HUD);
    } else if (cmd == "set_debug") {
      settings_toggle(settings, ATTR_SET_SHOW_DEBUG);
    } else if (cmd == "set_defaults") {
      settings_defaults(settings);
    } else {
      continue;
    }
    settings_panel_show(settings, render_row, detail_row, fov_row, mouse_row, plants_row, shading_row, jump_row, hud_row, debug_row);
  }

  save_ensure_folder();
  if (settings_save(settings, save_settings_path()) != SUCCESS) {
    Set_data(message, "Couldn't save the settings file.");
  }
  Hide_widget(panel);
  return result;
}

#endif
