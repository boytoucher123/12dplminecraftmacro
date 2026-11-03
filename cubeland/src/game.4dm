#ifndef GAME_4DM_INCLUDED
#define GAME_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/textures.h"
#include "../include/world.h"
#include "../include/mesh.h"
#include "../include/physics.h"
#include "../include/inventory.h"
#include "../include/crafting.h"
#include "../include/furnace.h"
#include "../include/cows.h"
#include "../include/drops.h"
#include "../include/player.h"
#include "../include/settings.h"
#include "../include/render.h"
#include "../include/hud.h"
#include "../include/ui.h"
#include "../include/save.h"
#include "../include/game.h"

void game_init_once(Attributes &game, Attributes &book, Attributes &settings, Attributes &random, Integer time_seed)
// ----------------------------------------------------------------
// Work done once per run of the macro: textures, recipes, renderer
// tables, the settings and the random sequence for gameplay
// ----------------------------------------------------------------
{
  if (record_integer(game, ATTR_GAME_READY)) return;

  record_clear(game, DATATYPE_GAME);
  random_seed(random, time_seed);

  textures_init();
  crafting_init_book(book);
  render_init();
  settings_load(settings, save_settings_path());

  record_set_integer(game, ATTR_GAME_READY, TRUE);
}

void game_reset_state(Attributes &game, Attributes &player, Attributes &inventory, Attributes &grid,
                      Attributes &furnaces, Attributes &cows, Attributes &drops, Attributes &events,
                      Attributes &hud, Attributes &ui)
// ----------------------------------------------------------------
// Empty every record before a world is created or loaded
// ----------------------------------------------------------------
{
  events_clear    (events);
  save_clear_edits();
  inventory_clear (inventory);
  grid_clear      (grid, GRID_INVENTORY_WIDTH);
  furnaces_clear  (furnaces);
  cows_clear      (cows);
  drops_clear     (drops);
  hud_clear       (hud);
  ui_clear        (ui);
  player_reset    (player, 0.0, 0.0, 0.0);
  record_set_real (game, ATTR_GAME_AUTOSAVE, 0.0);
}

Text game_world_name(Attributes &game)
// ----------------------------------------------------------------
// Name of the world being played
// ----------------------------------------------------------------
{
  return record_text(game, ATTR_GAME_WORLD_NAME);
}

Integer game_new_world(Text name, Integer seed, Attributes &game, Attributes &info, Attributes &player,
                       Attributes &inventory, Attributes &grid, Attributes &furnaces, Attributes &cows,
                       Attributes &drops, Attributes &events, Attributes &hud, Attributes &ui)
// ----------------------------------------------------------------
// Generate a fresh world from a seed, put the player in the starter
// house with some cows about, and save it straight away
// ----------------------------------------------------------------
{
  Attributes cow_random;
  Real       spawn_x = 0.0;
  Real       spawn_y = 0.0;
  Real       spawn_z = 0.0;

  game_reset_state(game, player, inventory, grid, furnaces, cows, drops, events, hud, ui);
  record_set_text (game, ATTR_GAME_WORLD_NAME, name);

  world_generate(info, seed);
  mesh_reset();

  world_info_spawn(info, spawn_x, spawn_y, spawn_z);
  player_reset    (player, spawn_x, spawn_y + COLLISION_EPSILON, spawn_z);
  player_set_look (player, HALF_PI * 3.0, -0.1);

  // Cows come from the seed too, so a seed always starts the same
  random_seed      (cow_random, seed);
  cows_spawn_random(cows, cow_random, COW_TARGET_COUNT, spawn_x, spawn_z, 10.0);

  if (game_save_world(game, info, player, inventory, furnaces, cows, drops, events) != SUCCESS) return FAILURE;
  events_clear(events);
  return SUCCESS;
}

Integer game_load_world(Text name, Attributes &game, Attributes &info, Attributes &player,
                        Attributes &inventory, Attributes &grid, Attributes &furnaces, Attributes &cows,
                        Attributes &drops, Attributes &events, Attributes &hud, Attributes &ui, Text &problem)
// ----------------------------------------------------------------
// Load a saved world; problem says why if it fails
// ----------------------------------------------------------------
{
  game_reset_state(game, player, inventory, grid, furnaces, cows, drops, events, hud, ui);
  record_set_text (game, ATTR_GAME_WORLD_NAME, name);
  if (load_world(name, info, player, inventory, furnaces, cows, drops, problem) != SUCCESS) return FAILURE;
  events_clear(events);
  return SUCCESS;
}

Integer game_save_world(Attributes &game, Attributes &info, Attributes &player, Attributes &inventory,
                        Attributes &furnaces, Attributes &cows, Attributes &drops, Attributes &events)
// ----------------------------------------------------------------
// Save the world being played
// ----------------------------------------------------------------
{
  return save_world(game_world_name(game), info, player, inventory, furnaces, cows, drops, events);
}

void game_build_nearby(Attributes &player, Integer range)
// ----------------------------------------------------------------
// Build the face lists within range of the player up front, so the
// first frame doesn't stall
// ----------------------------------------------------------------
{
  Integer sx    = 0;
  Integer sy    = 0;
  Integer sz    = 0;
  Integer reach = range + SECTION_SIZE;
  Real    x     = 0.0;
  Real    y     = 0.0;
  Real    z     = 0.0;
  Integer sx0   = 0;
  Integer sx1   = 0;
  Integer sz0   = 0;
  Integer sz1   = 0;

  player_position(player, x, y, z);
  sx0 = clamp_integer(floor_integer((x - reach) / SECTION_SIZE), 0, SECTIONS_X - 1);
  sx1 = clamp_integer(floor_integer((x + reach) / SECTION_SIZE), 0, SECTIONS_X - 1);
  sz0 = clamp_integer(floor_integer((z - reach) / SECTION_SIZE), 0, SECTIONS_Z - 1);
  sz1 = clamp_integer(floor_integer((z + reach) / SECTION_SIZE), 0, SECTIONS_Z - 1);

  for (sx = sx0; sx <= sx1; ++sx) {
    for (sz = sz0; sz <= sz1; ++sz) {
      for (sy = 0; sy < SECTIONS_Y; ++sy) mesh_ensure_section(sx, sy, sz);
    }
  }
}

void game_respawn(Attributes &info, Attributes &player, Attributes &events)
// ----------------------------------------------------------------
// Back to the spawn point with full health (the inventory is kept)
// ----------------------------------------------------------------
{
  Real x = 0.0;
  Real y = 0.0;
  Real z = 0.0;

  world_info_spawn(info, x, y, z);
  player_reset    (player, x, y + COLLISION_EPSILON, z);
  player_set_look (player, HALF_PI * 3.0, -0.1);
  emit_simple_event(events, EVT_PLAYER_RESPAWNED);
}

void game_dispatch_events(Attributes &events, Attributes &event, Attributes &player, Attributes &inventory,
                          Attributes &grid, Attributes &furnaces, Attributes &drops, Attributes &random,
                          Attributes &hud, Attributes &ui, Real now)
// ----------------------------------------------------------------
// Hand every queued event to each module's handler. Handlers may
// emit more events; those are dispatched in the same pass.
// ----------------------------------------------------------------
{
  Integer guard = 0;
  Real    x     = 0.0;
  Real    y     = 0.0;
  Real    z     = 0.0;

  player_position(player, x, y, z);

  while (next_event(events, event)) {
    mesh_on_event   (event);
    save_on_event   (event);
    furnace_on_event(event, furnaces, events);
    drops_on_event  (event, drops, random);
    hud_on_event    (event, hud, now);
    ui_on_event     (event, ui, inventory, grid, furnaces, events, x, y + 1.3, z);

    ++guard;
    if (guard > EVENT_QUEUE_SIZE * 4) break;
  }
}

void game_update(Real dt, Real real_dt, Real now, Integer running,
                 Attributes &game, Attributes &info, Attributes &player, Attributes &inventory,
                 Attributes &grid, Attributes &furnaces, Attributes &cows, Attributes &drops,
                 Attributes &events, Attributes &event, Attributes &random, Attributes &settings,
                 Attributes &hud, Attributes &ui)
// ----------------------------------------------------------------
// Advance the game by dt seconds (capped so a slow frame can't make
// things jump). running is FALSE while paused or in a screen; then
// only furnaces keep going. Furnaces run on real_dt, the actual time
// since the last frame, so they cook while the game is paused too.
// ----------------------------------------------------------------
{
  Real x        = 0.0;
  Real y        = 0.0;
  Real z        = 0.0;
  Real autosave = record_real(game, ATTR_GAME_AUTOSAVE);

  furnaces_update(furnaces, real_dt);

  if (running) {
    player_update(player, cows, events, settings_flag(settings, ATTR_SET_AUTO_JUMP), dt, now);
    player_position(player, x, y, z);
    cows_update (cows, random, x, z, dt);
    drops_update(drops, inventory, events, x, y, z, player_is_dead(player), dt);

    autosave = autosave + dt;
    if (autosave > AUTOSAVE_SECONDS) {
      autosave = 0.0;
      game_save_world(game, info, player, inventory, furnaces, cows, drops, events);
    }
    record_set_real(game, ATTR_GAME_AUTOSAVE, autosave);
  }

  game_dispatch_events(events, event, player, inventory, grid, furnaces, drops, random, hud, ui, now);
}

void game_select_slot(Attributes &player, Attributes &hud, Integer slot, Real now)
// ----------------------------------------------------------------
// Choose a hotbar slot and briefly show the item's name
// ----------------------------------------------------------------
{
  player_set_selected(player, slot);
  hud_show_name      (hud, now);
}

#endif
