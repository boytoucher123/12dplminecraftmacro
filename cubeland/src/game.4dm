#ifndef GAME_4DM_INCLUDED
#define GAME_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/textures.h"
#include "../include/world.h"
#include "../include/mesh.h"
#include "../include/inventory.h"
#include "../include/crafting.h"
#include "../include/furnace.h"
#include "../include/cows.h"
#include "../include/drops.h"
#include "../include/player.h"
#include "../include/render.h"
#include "../include/hud.h"
#include "../include/ui.h"
#include "../include/save.h"
#include "../include/game.h"

void game_init_once()
// ----------------------------------------------------------------
// Work done once per run of the macro: textures, recipes and
// renderer tables
// ----------------------------------------------------------------
{
  Integer seed = 0;

  if (g_game_initialised) return;

  Get_time(seed);
  Set_random_number(seed, 1);

  textures_init();
  crafting_init();
  render_init();

  g_game_initialised = TRUE;
}

void game_reset_state()
// ----------------------------------------------------------------
// Empty every module before a world is created or loaded
// ----------------------------------------------------------------
{
  events_clear();
  save_clear_edits();
  inventory_clear();
  furnaces_clear();
  cows_clear();
  drops_clear();
  hud_clear();
  g_ui_screen       = SCREEN_NONE;
  g_player_selected = 1;
  g_autosave_timer  = 0.0;
  g_show_help       = TRUE;
}

Integer game_new_world(Text name, Integer seed)
// ----------------------------------------------------------------
// Generate a fresh world from a seed, put the player at the spawn
// point with some cows about, and save it straight away
// ----------------------------------------------------------------
{
  Integer time_seed = 0;

  game_reset_state();
  g_world_name = name;

  world_generate(seed);
  mesh_reset();

  player_reset(g_spawn_x, g_spawn_y + COLLISION_EPSILON, g_spawn_z);
  g_player_yaw   = 0.0;
  g_player_pitch = -0.15;

  // Cows come from the seed too, so a seed always starts the same
  Set_random_number(seed, 1);
  cows_spawn_random(COW_TARGET_COUNT, 6.0);
  Get_time(time_seed);
  Set_random_number(time_seed, 1);

  if (save_world() != SUCCESS) return FAILURE;
  events_clear();
  return SUCCESS;
}

Integer game_load_world(Text name)
// ----------------------------------------------------------------
// Load a saved world
// ----------------------------------------------------------------
{
  game_reset_state();
  if (load_world(name) != SUCCESS) return FAILURE;
  events_clear();
  return SUCCESS;
}

void game_build_nearby()
// ----------------------------------------------------------------
// Build the face lists around the player up front, so the first
// frame doesn't stall
// ----------------------------------------------------------------
{
  Integer sx    = 0;
  Integer sy    = 0;
  Integer sz    = 0;
  Integer range = g_render_distance + SECTION_SIZE;
  Integer sx0   = clamp_integer(floor_integer((g_player_x - range) / SECTION_SIZE), 0, SECTIONS_X - 1);
  Integer sx1   = clamp_integer(floor_integer((g_player_x + range) / SECTION_SIZE), 0, SECTIONS_X - 1);
  Integer sz0   = clamp_integer(floor_integer((g_player_z - range) / SECTION_SIZE), 0, SECTIONS_Z - 1);
  Integer sz1   = clamp_integer(floor_integer((g_player_z + range) / SECTION_SIZE), 0, SECTIONS_Z - 1);

  for (sx = sx0; sx <= sx1; ++sx) {
    for (sz = sz0; sz <= sz1; ++sz) {
      for (sy = 0; sy < SECTIONS_Y; ++sy) mesh_ensure_section(sx, sy, sz);
    }
  }
}

void game_respawn()
// ----------------------------------------------------------------
// Back to the spawn point with full health (the inventory is kept)
// ----------------------------------------------------------------
{
  player_reset(g_spawn_x, g_spawn_y + COLLISION_EPSILON, g_spawn_z);
  g_player_pitch = -0.15;
  emit_simple_event(EVT_PLAYER_RESPAWNED);
}

void game_dispatch_events()
// ----------------------------------------------------------------
// Hand every queued event to each module's handler. Handlers may
// emit more events; those are dispatched in the same pass.
// ----------------------------------------------------------------
{
  Integer guard = 0;

  while (next_event()) {
    mesh_on_event();
    save_on_event();
    furnace_on_event();
    drops_on_event();
    hud_on_event();
    ui_on_event();

    ++guard;
    if (guard > EVENT_QUEUE_SIZE * 4) break;
  }
}

void game_update(Real dt, Real real_dt, Real now, Integer running)
// ----------------------------------------------------------------
// Advance the game by dt seconds (capped so a slow frame can't make
// things jump). running is FALSE while paused or in a screen; then
// only furnaces keep going. Furnaces run on real_dt, the actual time
// since the last frame, so they cook while the game is paused too.
// ----------------------------------------------------------------
{
  g_hud_now = now;

  furnaces_update(real_dt);

  if (running) {
    player_update(dt, now);
    cows_update(dt);
    drops_update(dt);

    g_autosave_timer = g_autosave_timer + dt;
    if (g_autosave_timer > AUTOSAVE_SECONDS) {
      g_autosave_timer = 0.0;
      save_world();
    }
  }

  game_dispatch_events();
}

void game_select_slot(Integer slot, Real now)
// ----------------------------------------------------------------
// Choose a hotbar slot and briefly show the item's name
// ----------------------------------------------------------------
{
  g_player_selected = clamp_integer(slot, 1, HOTBAR_SLOTS);
  g_held_name_until = now + 1.5;
}

#endif
