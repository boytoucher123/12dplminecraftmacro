#ifndef GAME_H_INCLUDED
#define GAME_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Game model glue: starting worlds, the per-frame update and the
// event dispatcher that hands each event to every module
//
// The game's records are declared here. Only the controllers
// (*_panel.4dm) name these globals; they pass the records to the
// functions below, which pass them on, so every function's
// signature shows what it uses.
// ----------------------------------------------------------------

#define DATATYPE_GAME        ("game")
#define ATTR_GAME_WORLD_NAME ("world_name")
#define ATTR_GAME_AUTOSAVE   ("autosave_timer")
#define ATTR_GAME_READY      ("initialised")

/*Global variables*/ {
  Attributes g_game;        // world name, autosave timer
  Attributes g_info;        // the world: seed, spawn point, house
  Attributes g_player;
  Attributes g_inventory;
  Attributes g_grid;        // the crafting grid of the open screen
  Attributes g_furnaces;
  Attributes g_cows;
  Attributes g_drops;
  Attributes g_events;      // queue of events waiting to be dispatched
  Attributes g_event;       // the event being dispatched
  Attributes g_random;
  Attributes g_settings;
  Attributes g_hud;
  Attributes g_ui;
  Attributes g_book;        // recipes
}

void    game_init_once        (Attributes &game, Attributes &book, Attributes &settings, Attributes &random, Integer time_seed);
void    game_reset_state      (Attributes &game, Attributes &player, Attributes &inventory, Attributes &grid,
                               Attributes &furnaces, Attributes &cows, Attributes &drops, Attributes &events,
                               Attributes &hud, Attributes &ui);
Text    game_world_name       (Attributes &game);
Integer game_new_world        (Text name, Integer seed, Attributes &game, Attributes &info, Attributes &player,
                               Attributes &inventory, Attributes &grid, Attributes &furnaces, Attributes &cows,
                               Attributes &drops, Attributes &events, Attributes &hud, Attributes &ui);
Integer game_load_world       (Text name, Attributes &game, Attributes &info, Attributes &player,
                               Attributes &inventory, Attributes &grid, Attributes &furnaces, Attributes &cows,
                               Attributes &drops, Attributes &events, Attributes &hud, Attributes &ui, Text &problem);
Integer game_save_world       (Attributes &game, Attributes &info, Attributes &player, Attributes &inventory,
                               Attributes &furnaces, Attributes &cows, Attributes &drops, Attributes &events);
void    game_build_nearby     (Attributes &player, Integer range);
void    game_respawn          (Attributes &info, Attributes &player, Attributes &events);
void    game_dispatch_events  (Attributes &events, Attributes &event, Attributes &player, Attributes &inventory,
                               Attributes &grid, Attributes &furnaces, Attributes &drops, Attributes &random,
                               Attributes &hud, Attributes &ui, Real now);
void    game_update           (Real dt, Real real_dt, Real now, Integer running,
                               Attributes &game, Attributes &info, Attributes &player, Attributes &inventory,
                               Attributes &grid, Attributes &furnaces, Attributes &cows, Attributes &drops,
                               Attributes &events, Attributes &event, Attributes &random, Attributes &settings,
                               Attributes &hud, Attributes &ui);
void    game_select_slot      (Attributes &player, Attributes &hud, Integer slot, Real now);

#endif
