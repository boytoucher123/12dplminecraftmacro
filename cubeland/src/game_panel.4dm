#ifndef GAME_PANEL_4DM_INCLUDED
#define GAME_PANEL_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/inventory.h"
#include "../include/player.h"
#include "../include/settings.h"
#include "../include/crafting.h"
#include "../include/render.h"
#include "../include/hud.h"
#include "../include/ui.h"
#include "../include/save.h"
#include "../include/game.h"
#include "../include/panels.h"

// ----------------------------------------------------------------
// Real-time play inside a 12d panel
//
// 12dPL has no timer and no key-up events. The game clock is the
// stream of mouse_move events: while the mouse is captured, every
// mouse_move turns the camera by how far the cursor moved from a
// parking spot, then puts the cursor back there (alternating by one
// pixel so each warp makes a fresh event). That gives a steady
// stream of frames with the mouse still. Keys arrive in the Keys
// input box, which keeps the keyboard focus. The mouse is released
// with Q, when a screen opens, when 12d loses focus, or after a
// minute without input.
//
// This is the controller: it is the only place (with the menu and
// settings panels) that names the game's global records, and it
// passes them to the model and view functions it calls.
// ----------------------------------------------------------------

Integer game_panel_split_xy(Text msg, Real &x, Real &y)
// ----------------------------------------------------------------
// Read "x y" from a Draw_Box event message; SUCCESS if found
// ----------------------------------------------------------------
{
  Integer space = Find_text(msg, " ");

  if (space <= 1) return FAILURE;

  From_text(Get_subtext(msg, 1, space - 1), x);
  From_text(Get_subtext(msg, space + 1, Text_length(msg)), y);
  return SUCCESS;
}

Integer game_panel_calibrate(Draw_Box box, Real box_x, Real box_y, Integer width, Integer height, Integer &origin_x, Integer &origin_y)
// ----------------------------------------------------------------
// Work out how Draw_Box coordinates map to the screen from an event
// at box point (box_x, box_y) and the cursor's screen position:
//   screen x = box x + origin_x,  screen y = origin_y - box y
// Checked against the box's position on screen.
// Returns 0 if good, 1 if the point is outside the box, 2 if the
// mapping looks wrong.
// ----------------------------------------------------------------
{
  Integer screen_x = 0;
  Integer screen_y = 0;
  Integer widget_x = 0;
  Integer widget_y = 0;
  Integer guess_x  = 0;
  Integer guess_y  = 0;

  if (box_x < 0.0 || box_x > width || box_y < 0.0 || box_y > height) return 1;

  Get_cursor_position(screen_x, screen_y);
  guess_x = screen_x - Floor(box_x);
  guess_y = screen_y + Floor(box_y);

  Get_position(box, widget_x, widget_y);
  if (Absolute(guess_x - widget_x) > 60 || Absolute(guess_y - widget_y - height) > 80) return 2;

  origin_x = guess_x;
  origin_y = guess_y;
  return 0;
}

void game_panel_notice(Draw_Box box, Text title, Text line)
// ----------------------------------------------------------------
// A plain frame with a message (loading, errors)
// ----------------------------------------------------------------
{
  Integer width  = 0;
  Integer height = 0;
  Real    w      = 0.0;
  Real    h      = 0.0;

  Get_size(box, width, height);
  w = width;
  h = height;

  Start_batch_draw(box);
  render_set_colour(box, 24.0, 28.0, 36.0);
  render_fill_rect (box, 0.0, 0.0, w, h);
  hud_text(box, w / 2.0, h / 2.0 + 30.0, 26.0, TEXT_ALIGN_CENTRE, 132, 220, 116, title);
  hud_text(box, w / 2.0, h / 2.0 - 10.0, 14.0, TEXT_ALIGN_CENTRE, 228, 228, 228, line);
  End_batch_draw(box);
}

void game_panel_dispatch(Real now)
// ----------------------------------------------------------------
// Dispatch the events an action caused, straight away
// ----------------------------------------------------------------
{
  game_dispatch_events(g_events, g_event, g_player, g_inventory, g_grid, g_furnaces, g_drops, g_random, g_hud, g_ui, now);
}

Integer game_panel_save()
// ----------------------------------------------------------------
// Save the world being played
// ----------------------------------------------------------------
{
  return game_save_world(g_game, g_info, g_player, g_inventory, g_furnaces, g_cows, g_drops, g_events);
}

void game_panel_close_screen()
// ----------------------------------------------------------------
// Close the open screen, returning carried and grid items
// ----------------------------------------------------------------
{
  Real x = 0.0;
  Real y = 0.0;
  Real z = 0.0;

  player_position(g_player, x, y, z);
  if (ui_screen(g_ui) != SCREEN_NONE) ui_close(g_ui, g_inventory, g_grid, g_events, x, y + 1.3, z);
}

void game_panel_render(Draw_Box box, Integer captured, Real frame_ms, Real now)
// ----------------------------------------------------------------
// Draw one frame: the 3D view and HUD, or the open screen
// ----------------------------------------------------------------
{
  Integer width  = 0;
  Integer height = 0;
  Real    w      = 0.0;
  Real    h      = 0.0;

  Get_size(box, width, height);
  w = width;
  h = height;

  Start_batch_draw(box);
  if (ui_screen(g_ui) != SCREEN_NONE) {
    hud_draw(box, w, h, captured, TRUE, g_hud, g_player, g_inventory, g_settings, world_info_seed(g_info),
             frame_ms, render_stats_text(), now);
    ui_draw (box, w, h, g_ui, g_inventory, g_grid, g_furnaces, g_book);
  } else {
    render_world(box, w, h, STATUS_STRIP_HEIGHT, g_player, g_cows, g_drops, g_furnaces, g_settings, now);
    hud_draw    (box, w, h, captured, FALSE, g_hud, g_player, g_inventory, g_settings, world_info_seed(g_info),
                 frame_ms, render_stats_text(), now);
  }
  End_batch_draw(box);
}

Integer game_panel_run(Text world_name, Integer create, Integer seed)
// ----------------------------------------------------------------
// Play a world until the player quits to the menu
// create = TRUE generates a new world from seed, otherwise the
// saved world is loaded. Returns 0, or SHUTDOWN_CODE if 12d asked
// the macro to stop.
// ----------------------------------------------------------------
{
  Text               title          = GAME_TITLE;
  Panel              panel          = Create_panel(title + " - " + world_name, 1);
  Vertical_Group     vgroup         = Create_vertical_group(0);
  Colour_Message_Box message        = Create_colour_message_box("");
  Draw_Box           draw_box       = Create_draw_box(GAME_VIEW_WIDTH, GAME_VIEW_HEIGHT, 0);
  Input_Box          key_box        = Create_input_box("Keys (click here if the keys stop working)", message);
  Horizontal_Group   buttons        = Create_button_group();
  Button             save_button    = Create_button("&Save", "save");
  Button             settings_button= Create_button("Se&ttings", "game_settings");
  Button             quit_button    = Create_button("Save and &quit to menu", "quit");

  Integer   result          = 0;
  Integer   running         = TRUE;
  Integer   loaded          = FAILURE;
  Integer64 id              = 0;
  Text      cmd             = "";
  Text      msg             = "";
  Text      key             = "";
  Text      why             = "";
  Real      now             = 0.0;
  Real      frame_start     = 0.0;
  Real      frame_end       = 0.0;
  Real      last_frame      = 0.0;
  Real      real_dt         = 0.0;
  Real      dt              = 0.0;
  Real      box_x           = 0.0;
  Real      box_y           = 0.0;
  Real      move_x          = 0.0;
  Real      move_y          = 0.0;
  Real      leave_window    = 0.0;
  Real      last_input      = 0.0;
  Integer   want_frame      = TRUE;
  Integer   playing         = FALSE;
  Integer   captured        = FALSE;
  Integer   start_request   = FALSE;
  Integer   start_by_click  = FALSE;
  Integer   release         = FALSE;
  Integer   has_xy          = FALSE;
  Integer   width           = 0;
  Integer   height          = 0;
  Integer   last_w          = 0;
  Integer   last_h          = 0;
  Integer   resize_pending  = FALSE;
  Integer   origin_x        = 0;
  Integer   origin_y        = 0;
  Integer   request_x       = 0;
  Integer   request_y       = 0;
  Integer   seen_x          = 0;
  Integer   seen_y          = 0;
  Integer   have_seen       = FALSE;
  Integer   have_origin     = FALSE;
  Integer   warp_x          = 0;
  Integer   warp_y          = 0;
  Integer   jiggle          = 0;
  Integer   confirmed       = FALSE;
  Integer   leaves          = 0;
  Integer   calibration     = 0;
  Real      frame_ms        = 0.0;
  Integer   open_settings   = FALSE;
  Text      problem         = "";

  Append(save_button    , buttons);
  Append(settings_button, buttons);
  Append(quit_button    , buttons);
  Append(draw_box   , vgroup);
  Append(key_box    , vgroup);
  Append(buttons    , vgroup);
  Append(message    , vgroup);
  Append(vgroup     , panel);

  // The view fills the panel when it is resized
  Set_sizing_constraints(draw_box, 2, 2);
  Set_sizing_constraints(vgroup  , 2, 2);
  Set_notify_resizing(panel);
  Show_widget(panel);
  Set_focus(key_box);

  // Generate or load the world
  if (create) {
    Set_data(message, "Generating " + world_name + " from seed " + To_text(seed) + " ...");
    game_panel_notice(draw_box, "Generating world", "Seed " + To_text(seed) + " - this takes a few seconds");
    loaded = game_new_world(world_name, seed, g_game, g_info, g_player, g_inventory, g_grid, g_furnaces, g_cows,
                            g_drops, g_events, g_hud, g_ui);
    problem = "it could not be saved";
  } else {
    Set_data(message, "Loading " + world_name + " ...");
    game_panel_notice(draw_box, "Loading world", world_name);
    loaded = game_load_world(world_name, g_game, g_info, g_player, g_inventory, g_grid, g_furnaces, g_cows,
                             g_drops, g_events, g_hud, g_ui, problem);
  }

  if (loaded != SUCCESS) {
    Set_data(message, "Couldn't open the world " + world_name + ": " + problem + ". Close this panel to go back to the menu.");
    game_panel_notice(draw_box, "Something went wrong", "The world could not be opened: " + problem);
    while (running) {
      id = 0;
      cmd = "";
      msg = "";
      if (Wait_on_events(id, cmd, msg) != 0) continue;
      if (cmd == "CodeShutdown") {
        Set_exit_code(cmd);
        Hide_widget(panel);
        return SHUTDOWN_CODE;
      }
      if (cmd == "Panel Quit" || cmd == "quit") running = FALSE;
    }
    Hide_widget(panel);
    return 0;
  }

  game_panel_notice(draw_box, "Building the view", "Nearly there");
  game_build_nearby(g_player, settings_render_distance(g_settings));

  Set_data(message, "Click the view to play. Press H for help.");
  Get_size(draw_box, last_w, last_h);
  Get_time(now);
  last_frame = now;
  last_input = now;

  while (running) {
    // ------------------------------------------------ frame
    if (want_frame) {
      Get_time(frame_start);
      real_dt = frame_start - last_frame;
      if (real_dt < 0.0) real_dt = 0.0;
      dt = real_dt;
      if (dt > MAX_FRAME_DT) dt = MAX_FRAME_DT;
      last_frame = frame_start;

      playing = captured && ui_screen(g_ui) == SCREEN_NONE && !hud_help_shown(g_hud) && !player_is_dead(g_player);
      game_update(dt, real_dt, frame_start, playing, g_game, g_info, g_player, g_inventory, g_grid, g_furnaces,
                  g_cows, g_drops, g_events, g_event, g_random, g_settings, g_hud, g_ui);

      // A screen is open (crafting table, furnace): free the mouse
      if (ui_screen(g_ui) != SCREEN_NONE && captured) {
        captured = FALSE;
        Set_data(message, "Click slots to move items; lay items out in the grid and click the result to craft. E or Q closes the screen.");
      }
      if (player_is_dead(g_player) && captured) {
        captured = FALSE;
        Set_data(message, "You died. Press R or click the view to respawn.");
      }

      game_panel_render(draw_box, captured, frame_ms, frame_start);
      Get_time(frame_end);
      frame_ms = (frame_end - frame_start) * 1000.0;
      want_frame = FALSE;
    }

    // ------------------------------------------------ next event
    id  = 0;
    cmd = "";
    msg = "";
    if (Wait_on_events(id, cmd, msg) != 0) continue;
    Get_time(now);

    if (cmd == "CodeShutdown") {
      game_panel_close_screen();
      game_panel_save();
      Set_exit_code(cmd);
      Hide_widget(panel);
      return SHUTDOWN_CODE;
    }
    if (cmd == "Panel Quit") {
      game_panel_close_screen();
      game_panel_save();
      running = FALSE;
      continue;
    }

    Get_size(draw_box, width, height);
    release        = FALSE;
    start_request  = FALSE;
    start_by_click = FALSE;
    why            = "";

    // The panel was resized: the parking spot moved with the view
    if (width != last_w || height != last_h) {
      last_w    = width;
      last_h    = height;
      have_seen = FALSE;
      if (captured) {
        release = TRUE;
        why     = "the window was resized";
      }
      resize_pending = TRUE;
    }
    if (cmd == "Panel_Resize") {
      if (now - last_frame >= 0.1) {
        want_frame     = TRUE;
        resize_pending = FALSE;
      }
    } else if (resize_pending) {
      want_frame     = TRUE;
      resize_pending = FALSE;
    }

    if (id == Get_id64(draw_box)) {
      // ------------------------------------------------ mouse
      has_xy = game_panel_split_xy(msg, box_x, box_y) == SUCCESS;

      if (cmd == "mouse_move" && has_xy && captured) {
        move_x = box_x - (warp_x + jiggle);
        move_y = box_y - warp_y;
        if (Absolute(move_x) < 3.0 && Absolute(move_y) < 3.0) confirmed = TRUE;
        if (Absolute(move_x) >= 1.0 || Absolute(move_y) >= 1.0) {
          player_turn(g_player, move_x * settings_mouse_scale(g_settings), move_y * settings_mouse_scale(g_settings));
          last_input = now;
        }
        // Park the cursor again, even if a quick move took it just
        // outside the view (the parking spot is near the bottom edge)
        jiggle = 1 - jiggle;
        Set_cursor_position(origin_x + warp_x + jiggle, origin_y - warp_y);
        want_frame = TRUE;

      } else if (cmd == "mouse_move" && has_xy) {
        // Remember a checked screen mapping so a key or closing a
        // screen can start play without a click
        if (game_panel_calibrate(draw_box, box_x, box_y, width, height, request_x, request_y) == 0) {
          seen_x    = request_x;
          seen_y    = request_y;
          have_seen = TRUE;
        }
        if (ui_screen(g_ui) != SCREEN_NONE) {
          ui_set_mouse(g_ui, box_x, box_y);
          want_frame = TRUE;
        } else if (now - last_frame > PAUSED_FRAME_GAP) {
          want_frame = TRUE;
        }

      } else if (cmd == "mouse_leave" && captured) {
        // A fast flick can leave the view between events: pull the
        // cursor back, unless it keeps happening
        if (now - leave_window > 1.0) {
          leave_window = now;
          leaves       = 0;
        }
        ++leaves;
        if (!confirmed || leaves > 4) {
          release = TRUE;
          why     = "the mouse left the view";
        } else {
          Set_cursor_position(origin_x + warp_x + jiggle, origin_y - warp_y);
        }

      } else if (captured && (cmd == "click_lb_down" || cmd == "double_click_lb")) {
        player_primary_action(g_player, g_inventory, g_cows, g_events, g_random, now);
        game_panel_dispatch(now);
        last_input = now;
        want_frame = TRUE;

      } else if (captured && (cmd == "click_rb" || cmd == "double_click_rb")) {
        player_secondary_action(g_player, g_inventory, g_cows, g_events, now);
        game_panel_dispatch(now);
        if (ui_screen(g_ui) != SCREEN_NONE) release = TRUE;
        last_input = now;
        want_frame = TRUE;

      } else if (!captured && ui_screen(g_ui) != SCREEN_NONE && has_xy) {
        if (cmd == "click_lb" || cmd == "double_click_lb") {
          ui_set_mouse(g_ui, box_x, box_y);
          ui_click(g_ui, g_inventory, g_grid, g_furnaces, g_book, g_events, box_x, box_y, FALSE, width, height);
          game_panel_dispatch(now);
          want_frame = TRUE;
        } else if (cmd == "click_rb" || cmd == "double_click_rb") {
          ui_set_mouse(g_ui, box_x, box_y);
          ui_click(g_ui, g_inventory, g_grid, g_furnaces, g_book, g_events, box_x, box_y, TRUE, width, height);
          game_panel_dispatch(now);
          want_frame = TRUE;
        }

      } else if (!captured && has_xy && (cmd == "click_lb" || cmd == "click_rb")) {
        // Clicking the view starts (or resumes) play
        calibration = game_panel_calibrate(draw_box, box_x, box_y, width, height, request_x, request_y);
        if (calibration == 1) {
          Set_data(message, "Click inside the view to play.");
        } else if (calibration == 2) {
          Set_data(message, "Couldn't grab the mouse - try moving the panel, then click again.");
        } else {
          if (player_is_dead(g_player)) game_respawn(g_info, g_player, g_events);
          start_request  = TRUE;
          start_by_click = TRUE;
        }
        want_frame = TRUE;
      }

    } else if (id == Get_id64(key_box)) {
      // ------------------------------------------------ keyboard
      if (cmd == "keystroke") {
        key = Text_lower(msg);
        last_input = now;

        if (ui_screen(g_ui) != SCREEN_NONE) {
          if (key == "e" || key == "q") {
            game_panel_close_screen();
            game_panel_dispatch(now);
            if (have_origin || have_seen) start_request = TRUE;
          }
        } else if (player_is_dead(g_player)) {
          if (key == "r") {
            game_respawn(g_info, g_player, g_events);
            if (have_origin || have_seen) start_request = TRUE;
          }
        } else {
          if (key == "w" || key == "a" || key == "s" || key == "d" || key == " ") {
            player_key_pressed(g_player, key, now);
            if (!captured && hud_help_shown(g_hud) && (have_origin || have_seen)) start_request = TRUE;
          }
          if (Text_length(key) == 1 && Find_text("123456789", key) > 0) {
            game_select_slot(g_player, g_hud, Find_text("123456789", key), now);
          }
          if (key == "e") {
            emit_event(g_events, EVT_OPEN_SCREEN, SCREEN_INVENTORY, 0, 0, 0, 0.0, 0.0, 0.0, "");
            game_panel_dispatch(now);
            if (captured) release = TRUE;
          }
          if (key == "q" && captured) release = TRUE;
          if (key == "h") {
            hud_set_help(g_hud, !hud_help_shown(g_hud));
            if (hud_help_shown(g_hud) && captured) release = TRUE;
          }
          if (key == "f") player_set_auto_walk(g_player, !player_auto_walk(g_player));
          if (key == "j") {
            settings_toggle(g_settings, ATTR_SET_AUTO_JUMP);
            hud_toast(g_hud, settings_describe(g_settings, ATTR_SET_AUTO_JUMP), now);
            settings_save(g_settings, save_settings_path());
          }
          if (key == "i") {
            settings_toggle(g_settings, ATTR_SET_SHOW_DEBUG);
            settings_save(g_settings, save_settings_path());
          }
          if (key == "-" || key == "=" || key == "+") {
            if (key == "-") {
              settings_change(g_settings, ATTR_SET_RENDER_DISTANCE, -1);
            } else {
              settings_change(g_settings, ATTR_SET_RENDER_DISTANCE, 1);
            }
            hud_toast(g_hud, settings_describe(g_settings, ATTR_SET_RENDER_DISTANCE), now);
            settings_save(g_settings, save_settings_path());
          }
          if (key == "o") open_settings = TRUE;
        }

        Set_data(key_box, "");
        if (!captured) want_frame = TRUE;

      } else if (cmd == "text selected") {
        // Enter takes the focus away; take it back for the game keys
        Set_data(key_box, "");
        Set_focus(key_box);
      } else if (cmd == "kill_focus" && captured) {
        release = TRUE;
        why     = "another window was clicked";
      }

    } else if (cmd == "save") {
      if (game_panel_save() == SUCCESS) {
        Set_data(message, "Saved " + world_name + ".");
      } else {
        Set_data(message, "Couldn't save " + world_name + ".");
      }
      game_panel_dispatch(now);
      Set_focus(key_box);
      want_frame = TRUE;

    } else if (cmd == "game_settings") {
      open_settings = TRUE;

    } else if (cmd == "quit") {
      game_panel_close_screen();
      game_panel_save();
      running = FALSE;
      continue;
    }

    // ------------------------------------------------ settings
    if (open_settings) {
      open_settings = FALSE;
      if (captured) {
        captured    = FALSE;
        have_origin = FALSE;
      }
      if (settings_panel_run(g_settings) == SHUTDOWN_CODE) {
        game_panel_save();
        Set_exit_code("CodeShutdown");
        Hide_widget(panel);
        return SHUTDOWN_CODE;
      }
      game_build_nearby(g_player, settings_render_distance(g_settings));
      Set_data(message, "Settings saved. Click the view to carry on.");
      Set_focus(key_box);
      want_frame = TRUE;
    }

    // ------------------------------------------------ grab / free the mouse
    if (start_request && !captured) {
      // A click carries its own fresh mapping; a key uses the last
      // one seen from the mouse, else the one from the last capture
      if (!start_by_click) {
        if (have_seen) {
          request_x = seen_x;
          request_y = seen_y;
        } else {
          request_x = origin_x;
          request_y = origin_y;
        }
      }
      origin_x    = request_x;
      origin_y    = request_y;
      have_origin = TRUE;
      warp_x      = Floor(width / 2.0);
      warp_y      = Floor(STATUS_STRIP_HEIGHT / 2.0);
      jiggle      = 0;
      confirmed   = FALSE;
      leaves      = 0;
      captured    = TRUE;
      hud_set_help(g_hud, FALSE);
      last_input  = now;
      Set_cursor_position(origin_x + warp_x, origin_y - warp_y);
      Set_focus(key_box);
      Set_data(message, "Playing " + world_name + ". Q frees the mouse, E opens the inventory, O settings, H help.");
      want_frame = TRUE;
    }

    if (captured && now - last_input > IDLE_RELEASE_SECONDS) {
      release = TRUE;
      why     = "no input for a while";
    }
    if (release && captured) {
      captured = FALSE;
      if (why == "") {
        Set_data(message, "Paused. Click the view to carry on.");
      } else {
        Set_data(message, "Paused (" + why + "). Click the view to carry on.");
      }
      // The panel may have moved: check the mapping again next time
      if (why != "") have_origin = FALSE;
      want_frame = TRUE;
    }
  }

  Hide_widget(panel);
  return result;
}

#endif
