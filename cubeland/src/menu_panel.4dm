#ifndef MENU_PANEL_4DM_INCLUDED
#define MENU_PANEL_4DM_INCLUDED

#include "../include/common.h"
#include "../include/util.h"
#include "../include/save.h"
#include "../include/panels.h"

Integer menu_refresh_worlds(List_Box world_list)
// ----------------------------------------------------------------
// Fill the list box with the saved worlds; returns how many
// ----------------------------------------------------------------
{
  Dynamic_Text names;
  Integer      count    = 0;
  Integer      existing = 0;
  Integer      index    = 0;
  Text         name     = "";

  Get_number_of_items(world_list, existing);
  for (index = existing; index >= 1; --index) Delete_item(world_list, index);

  count = save_list_worlds(names);
  for (index = 1; index <= count; ++index) {
    Get_item(names, index, name);
    Add_item(world_list, name);
  }
  if (count > 0) Set_selection(world_list, 1);

  return count;
}

Integer menu_panel_run()
// ----------------------------------------------------------------
// The world menu: pick a saved world to play, delete one, or make
// a new one with a name and an optional seed
// Returns a MENU_RESULT_* code (or SHUTDOWN_CODE) and leaves the
// chosen world in g_menu_world_name / g_menu_seed
// ----------------------------------------------------------------
{
  Text               title          = GAME_TITLE;
  Panel              panel          = Create_panel(title + " - worlds");
  Vertical_Group     vgroup         = Create_vertical_group(0);
  Colour_Message_Box message        = Create_colour_message_box("");
  List_Box           world_list     = Create_list_box("Saved worlds", message, 8);
  Input_Box          name_box       = Create_input_box("New world name", message);
  Input_Box          seed_box       = Create_input_box("Seed (blank for random)", message);
  Horizontal_Group   buttons        = Create_button_group();
  Button             play_button    = Create_button("&Play selected", "play");
  Button             create_button  = Create_button("&Create new world", "create");
  Button             delete_button  = Create_button("&Delete selected", "delete");
  Button             quit_button    = Create_finish_button("Quit", "quit");
  Integer            result         = MENU_RESULT_QUIT;
  Integer            doit           = TRUE;
  Integer            count          = 0;
  Integer            selected       = 0;
  Integer64          id             = 0;
  Text               cmd            = "";
  Text               msg            = "";
  Text               name           = "";
  Text               seed_text      = "";
  Text               pending_delete = "";

  Append(play_button  , buttons);
  Append(create_button, buttons);
  Append(delete_button, buttons);
  Append(quit_button  , buttons);

  Append(world_list, vgroup);
  Append(name_box  , vgroup);
  Append(seed_box  , vgroup);
  Append(buttons   , vgroup);
  Append(message   , vgroup);
  Append(vgroup    , panel);

  Show_widget(panel);

  count = menu_refresh_worlds(world_list);
  Set_data(name_box, "World " + To_text(count + 1));
  if (count == 0) {
    Set_data(message, "No saved worlds yet - type a name (and a seed if you like) and press Create new world.");
  } else {
    Set_data(message, "Pick a world and press Play, or make a new one.");
  }

  while (doit) {
    id  = 0;
    cmd = "";
    msg = "";
    if (Wait_on_events(id, cmd, msg) != 0) continue;

    if (cmd == "keystroke" || cmd == "set_focus" || cmd == "kill_focus") continue;

    if (cmd == "CodeShutdown") {
      Set_exit_code(cmd);
      result = SHUTDOWN_CODE;
      doit   = FALSE;
    } else if (cmd == "Panel Quit" || cmd == "quit") {
      result = MENU_RESULT_QUIT;
      doit   = FALSE;
    } else if (cmd == "play") {
      selected = 0;
      Get_selection(world_list, selected);
      if (selected < 1) {
        Set_data(message, "Select a world in the list first.");
      } else {
        Get_item(world_list, selected, name);
        g_menu_world_name = name;
        result = MENU_RESULT_PLAY;
        doit   = FALSE;
      }
    } else if (cmd == "create") {
      Get_data(name_box, name);
      name = Text_justify(name);
      Get_data(seed_box, seed_text);
      seed_text = Text_justify(seed_text);
      if (!text_is_safe_name(name)) {
        Set_data(message, "World names can use letters, numbers, spaces, - and _ (up to 40 characters).");
      } else if (save_world_exists(name)) {
        Set_data(message, "There is already a world called " + name + ".");
      } else {
        g_menu_world_name = name;
        if (seed_text == "") {
          g_menu_seed = random_integer(1, 999999999);
        } else {
          g_menu_seed = text_to_seed(seed_text);
        }
        result = MENU_RESULT_CREATE;
        doit   = FALSE;
      }
    } else if (cmd == "delete") {
      selected = 0;
      Get_selection(world_list, selected);
      if (selected < 1) {
        Set_data(message, "Select a world in the list first.");
      } else {
        Get_item(world_list, selected, name);
        if (pending_delete != name) {
          pending_delete = name;
          Set_data(message, "Press Delete selected again to delete " + name + " for good.");
        } else {
          pending_delete = "";
          if (save_delete_world(name) == SUCCESS) {
            Set_data(message, "Deleted " + name + ".");
          } else {
            Set_data(message, "Couldn't delete " + name + ".");
          }
          menu_refresh_worlds(world_list);
        }
      }
    }
  }

  Hide_widget(panel);
  return result;
}

#endif
