#ifndef PLAYER_4DM_INCLUDED
#define PLAYER_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/physics.h"
#include "../include/inventory.h"
#include "../include/cows.h"
#include "../include/player.h"

void player_reset(Real x, Real y, Real z)
// ----------------------------------------------------------------
// Stand the player at (x, y, z), alive and at full health
// ----------------------------------------------------------------
{
  g_player_x            = x;
  g_player_y            = y;
  g_player_z            = z;
  g_player_vx           = 0.0;
  g_player_vy           = 0.0;
  g_player_vz           = 0.0;
  g_player_health       = PLAYER_MAX_HEALTH;
  g_player_dead         = FALSE;
  g_player_on_ground    = FALSE;
  g_player_in_water     = FALSE;
  g_player_eye_in_water = FALSE;
  g_player_fall_peak    = y;
  g_player_regen        = 0.0;
  g_player_hurt         = 0.0;
  g_player_swing        = 0.0;
  g_move_key            = "";
  g_move_until          = 0.0;
  g_jump_until          = 0.0;
  g_auto_walk           = FALSE;
  g_break_hits          = 0;
  g_break_y             = -1;
  g_target_kind         = TARGET_NONE;
}

Real player_eye_y()
// ----------------------------------------------------------------
// Height of the player's eyes
// ----------------------------------------------------------------
{
  return g_player_y + PLAYER_EYE_HEIGHT;
}

void player_look_direction(Real &dir_x, Real &dir_y, Real &dir_z)
// ----------------------------------------------------------------
// Unit vector the player is looking along
// ----------------------------------------------------------------
{
  dir_x = Cos(g_player_pitch) * Cos(g_player_yaw);
  dir_y = Sin(g_player_pitch);
  dir_z = Cos(g_player_pitch) * Sin(g_player_yaw);
}

void player_turn(Real yaw_change, Real pitch_change)
// ----------------------------------------------------------------
// Mouse look; pitch stops just short of straight up and down
// ----------------------------------------------------------------
{
  g_player_yaw   = wrap_angle(g_player_yaw + yaw_change);
  g_player_pitch = clamp_real(g_player_pitch + pitch_change, -MAX_PITCH, MAX_PITCH);
}

void player_key_pressed(Text key, Real now)
// ----------------------------------------------------------------
// A movement key (w a s d, space) arrived from the keyboard box
// Only the last key held down auto-repeats, and there is no key-up
// event, so a fresh press moves for TAP_TIME and every repeat keeps
// the key alive a little longer. Jumping keeps the last movement
// going so you can run and jump.
// ----------------------------------------------------------------
{
  if (key == "w" || key == "a" || key == "s" || key == "d") {
    if (key == g_move_key && now - g_move_last < HELD_KEY_WINDOW) {
      g_move_until = now + HELD_KEY_EXTEND;
      g_move_held  = TRUE;
    } else {
      g_move_until = now + TAP_TIME;
      g_move_start = now;
      g_move_held  = FALSE;
    }
    g_move_key  = key;
    g_move_last = now;
    if (key == "s") g_auto_walk = FALSE;
    return;
  }

  if (key == " ") {
    g_jump_until = now + 0.25;
    if (g_move_until > now - 0.15) {
      g_move_until = max_real(g_move_until, now + 0.55);
      g_move_held  = TRUE;
    }
  }
}

Integer player_key_active(Text key, Real now)
// ----------------------------------------------------------------
// TRUE while a movement key counts as held down
// ----------------------------------------------------------------
{
  if (g_move_key == key && now < g_move_until) return TRUE;
  return FALSE;
}

void player_damage(Integer amount)
// ----------------------------------------------------------------
// Take damage; emits EVT_PLAYER_HURT and EVT_PLAYER_DIED
// ----------------------------------------------------------------
{
  if (g_player_dead || amount <= 0) return;

  g_player_health = g_player_health - amount;
  g_player_hurt   = 0.4;
  g_player_regen  = 0.0;
  emit_item_event(EVT_PLAYER_HURT, amount, 0);

  if (g_player_health <= 0) {
    g_player_health = 0;
    g_player_dead   = TRUE;
    emit_simple_event(EVT_PLAYER_DIED);
  }
}

void player_update(Real dt, Real now)
// ----------------------------------------------------------------
// Walk, jump, swim, fall and collide; fall damage, regeneration
// and what the crosshair points at
// ----------------------------------------------------------------
{
  Real    forward      = 0.0;
  Real    strafe       = 0.0;
  Real    ease         = 1.0;
  Real    speed        = 0.0;
  Real    heading_x    = Cos(g_player_yaw);
  Real    heading_z    = Sin(g_player_yaw);
  Real    wish_x       = 0.0;
  Real    wish_z       = 0.0;
  Real    wish_length  = 0.0;
  Real    blend        = 0.0;
  Real    move_x       = 0.0;
  Real    move_y       = 0.0;
  Real    move_z       = 0.0;
  Real    fall         = 0.0;
  Real    longest      = 0.0;
  Integer steps        = 1;
  Integer step         = 0;
  Integer was_grounded = g_player_on_ground;
  Integer blocked      = FALSE;
  Integer moving       = FALSE;
  Integer ahead_x      = 0;
  Integer ahead_z      = 0;
  Integer feet_y       = 0;

  g_player_hurt  = g_player_hurt  - dt;
  g_player_swing = g_player_swing - dt;
  if (g_player_dead) return;

  g_game_clock = g_game_clock + dt;

  // Movement input
  if (player_key_active("w", now)) forward =  1.0;
  if (player_key_active("s", now)) forward = -1.0;
  if (player_key_active("a", now)) strafe  = -1.0;
  if (player_key_active("d", now)) strafe  =  1.0;
  if (g_auto_walk && forward == 0.0) forward = 1.0;

  if (!g_move_held && !g_auto_walk) {
    ease = TAP_START_SPEED + (1.0 - TAP_START_SPEED) * clamp_real((now - g_move_start) / TAP_RAMP, 0.0, 1.0);
  }
  speed = WALK_SPEED * ease;
  if (g_player_in_water) speed = speed * WATER_SPEED_FACTOR;

  wish_x = heading_x * forward - heading_z * strafe;
  wish_z = heading_z * forward + heading_x * strafe;
  wish_length = Sqrt(wish_x * wish_x + wish_z * wish_z);
  if (wish_length > 0.001) {
    wish_x = wish_x / wish_length;
    wish_z = wish_z / wish_length;
    moving = TRUE;
  }

  if (g_player_on_ground) {
    g_player_vx = wish_x * speed;
    g_player_vz = wish_z * speed;
  } else {
    blend = min_real(1.0, dt * 5.0);
    g_player_vx = g_player_vx + (wish_x * speed - g_player_vx) * blend;
    g_player_vz = g_player_vz + (wish_z * speed - g_player_vz) * blend;
  }

  // Jumping and swimming
  if (now < g_jump_until) {
    if (g_player_in_water) {
      g_player_vy = SWIM_UP_SPEED;
    } else if (g_player_on_ground) {
      g_player_vy  = JUMP_SPEED;
      g_jump_until = 0.0;
    }
  }

  if (g_player_in_water) {
    g_player_vy = g_player_vy - SWIM_GRAVITY * dt;
    if (g_player_vy < -SWIM_SINK_SPEED) g_player_vy = -SWIM_SINK_SPEED;
  } else {
    g_player_vy = g_player_vy - GRAVITY * dt;
    if (g_player_vy < -TERMINAL_SPEED) g_player_vy = -TERMINAL_SPEED;
  }

  // Move in steps short enough not to pass through a block
  move_x  = g_player_vx * dt;
  move_y  = g_player_vy * dt;
  move_z  = g_player_vz * dt;
  longest = max_real(Absolute(move_y), max_real(Absolute(move_x), Absolute(move_z)));
  steps   = 1 + Floor(longest / MAX_MOVE_STEP);

  g_player_on_ground = FALSE;
  for (step = 1; step <= steps; ++step) {
    physics_move_box(g_player_x, g_player_y, g_player_z, PLAYER_HALF_WIDTH, PLAYER_HEIGHT,
                     move_x / steps, move_y / steps, move_z / steps);
    if (g_hit_down) {
      g_player_on_ground = TRUE;
      if (g_player_vy < 0.0) g_player_vy = 0.0;
    }
    if (g_hit_up && g_player_vy > 0.0) g_player_vy = 0.0;
    if (g_hit_x || g_hit_z) blocked = TRUE;
  }

  // Auto-jump: walking into a one block step hops up it, and
  // swimming into the shore climbs out
  if (blocked && moving) {
    ahead_x = Floor(g_player_x + wish_x * 0.6);
    ahead_z = Floor(g_player_z + wish_z * 0.6);
    feet_y  = Floor(g_player_y + 0.05);
    if (!world_is_solid(ahead_x, feet_y + 1, ahead_z) && !world_is_solid(ahead_x, feet_y + 2, ahead_z)) {
      if (g_player_in_water) {
        g_player_vy = SWIM_UP_SPEED * 1.6;
      } else if (g_player_on_ground && g_auto_jump) {
        g_player_vy = JUMP_SPEED;
      }
    }
  }

  // Water
  g_player_in_water     = physics_box_in_water(g_player_x, g_player_y, g_player_z, PLAYER_HALF_WIDTH, PLAYER_HEIGHT);
  g_player_eye_in_water = world_get_block(floor_integer(g_player_x), floor_integer(player_eye_y()), floor_integer(g_player_z)) == BLOCK_WATER;

  // Fall damage: measured from the highest point since leaving the
  // ground; water breaks any fall
  if (g_player_in_water) {
    g_player_fall_peak = g_player_y;
  } else if (g_player_on_ground) {
    if (!was_grounded) {
      fall = g_player_fall_peak - g_player_y;
      if (fall > FALL_DAMAGE_START) player_damage(floor_integer(fall - FALL_DAMAGE_START + 0.5));
    }
    g_player_fall_peak = g_player_y;
  } else if (g_player_y > g_player_fall_peak) {
    g_player_fall_peak = g_player_y;
  }

  if (g_player_on_ground && moving) g_player_bob = g_player_bob + dt * 9.0 * ease;

  // Slow healing
  if (g_player_health < PLAYER_MAX_HEALTH && !g_player_dead) {
    g_player_regen = g_player_regen + dt;
    if (g_player_regen >= REGEN_SECONDS) {
      g_player_regen  = 0.0;
      g_player_health = g_player_health + 1;
    }
  }

  if (now - g_break_time > BREAK_RESET_SECONDS) g_break_hits = 0;

  player_update_target();
}

void player_update_target()
// ----------------------------------------------------------------
// Find what the crosshair is on within reach: a cow or a block
// ----------------------------------------------------------------
{
  Real    eye_x          = g_player_x;
  Real    eye_y          = player_eye_y();
  Real    eye_z          = g_player_z;
  Real    dir_x          = 0.0;
  Real    dir_y          = 0.0;
  Real    dir_z          = 0.0;
  Real    block_distance = PLAYER_REACH;
  Integer block_hit      = FALSE;
  Integer cow            = 0;

  player_look_direction(dir_x, dir_y, dir_z);

  g_target_kind = TARGET_NONE;
  block_hit = physics_raycast_blocks(eye_x, eye_y, eye_z, dir_x, dir_y, dir_z, PLAYER_REACH);
  if (block_hit) {
    block_distance    = g_ray_distance;
    g_target_x        = g_ray_x;
    g_target_y        = g_ray_y;
    g_target_z        = g_ray_z;
    g_target_normal_x = g_ray_normal_x;
    g_target_normal_y = g_ray_normal_y;
    g_target_normal_z = g_ray_normal_z;
  }

  cow = cows_ray_hit(eye_x, eye_y, eye_z, dir_x, dir_y, dir_z, block_distance);
  if (cow > 0) {
    g_target_kind = TARGET_COW;
    g_target_cow  = cow;
  } else if (block_hit) {
    g_target_kind = TARGET_BLOCK;
  }
}

Integer player_held_item()
// ----------------------------------------------------------------
// Item in the selected hotbar slot
// ----------------------------------------------------------------
{
  return g_inv_item[g_player_selected];
}

Integer player_break_stage()
// ----------------------------------------------------------------
// How cracked the block being broken is: 0 (not started) to 4
// ----------------------------------------------------------------
{
  Integer hardness = 0;

  if (g_break_hits <= 0 || g_break_y < 0) return 0;

  hardness = block_hardness(world_get_block(g_break_x, g_break_y, g_break_z));
  if (hardness <= 1) return 0;

  return clamp_integer(1 + floor_integer(3.0 * g_break_hits / hardness), 1, 4);
}

void player_primary_action(Real now)
// ----------------------------------------------------------------
// Left click: hit a cow, or chip away at a block until it breaks
// Harder blocks take more hits; a pause of BREAK_RESET_SECONDS
// starts the count again
// ----------------------------------------------------------------
{
  Integer block    = 0;
  Integer hardness = 0;

  if (g_player_dead) return;

  g_player_swing = 0.25;
  player_update_target();

  if (g_target_kind == TARGET_COW) {
    cow_damage(g_target_cow, 1, Cos(g_player_yaw), Sin(g_player_yaw));
    return;
  }
  if (g_target_kind != TARGET_BLOCK) return;

  block    = world_get_block(g_target_x, g_target_y, g_target_z);
  hardness = block_hardness(block);
  if (hardness <= 0) {
    emit_toast("That is far too hard to break");
    return;
  }

  if (g_target_x == g_break_x && g_target_y == g_break_y && g_target_z == g_break_z && now - g_break_time <= BREAK_RESET_SECONDS) {
    ++g_break_hits;
  } else {
    g_break_x    = g_target_x;
    g_break_y    = g_target_y;
    g_break_z    = g_target_z;
    g_break_hits = 1;
  }
  g_break_time = now;

  if (g_break_hits >= hardness) {
    world_break_block(g_target_x, g_target_y, g_target_z);
    g_break_hits = 0;
    g_break_y    = -1;
    player_update_target();
  }
}

void player_secondary_action(Real now)
// ----------------------------------------------------------------
// Right click: open a crafting table or furnace, eat food, or
// place the held block against the face the crosshair is on
// ----------------------------------------------------------------
{
  Integer block     = 0;
  Integer held      = player_held_item();
  Integer place     = BLOCK_AIR;
  Integer cell_x    = 0;
  Integer cell_y    = 0;
  Integer cell_z    = 0;
  Integer existing  = 0;
  Integer food      = 0;
  Real    toward_x  = 0.0;
  Real    toward_z  = 0.0;

  if (g_player_dead) return;

  player_update_target();

  if (g_target_kind == TARGET_BLOCK) {
    block = world_get_block(g_target_x, g_target_y, g_target_z);
    if (block == BLOCK_CRAFTING_TABLE) {
      emit_event(EVT_OPEN_SCREEN, SCREEN_CRAFTING, g_target_x, g_target_y, g_target_z, 0.0, 0.0, 0.0, "");
      return;
    }
    if (block_is_furnace(block)) {
      emit_event(EVT_OPEN_SCREEN, SCREEN_FURNACE, g_target_x, g_target_y, g_target_z, 0.0, 0.0, 0.0, "");
      return;
    }
  }

  food = item_food_value(held);
  if (food > 0) {
    if (g_player_health >= PLAYER_MAX_HEALTH) {
      emit_toast("You are already at full health");
      return;
    }
    g_player_health = g_player_health + food;
    if (g_player_health > PLAYER_MAX_HEALTH) g_player_health = PLAYER_MAX_HEALTH;
    inventory_take_one(g_player_selected);
    g_player_swing = 0.25;
    emit_item_event(EVT_PLAYER_ATE, held, food);
    return;
  }

  place = item_places_block(held);
  if (place == BLOCK_AIR) return;
  if (g_target_kind != TARGET_BLOCK) return;
  if (g_target_normal_x == 0 && g_target_normal_y == 0 && g_target_normal_z == 0) return;

  cell_x = g_target_x + g_target_normal_x;
  cell_y = g_target_y + g_target_normal_y;
  cell_z = g_target_z + g_target_normal_z;
  if (!world_in_bounds(cell_x, cell_y, cell_z)) return;

  existing = world_get_block(cell_x, cell_y, cell_z);
  if (existing != BLOCK_AIR && existing != BLOCK_WATER) return;

  // Not inside the player or a cow
  if (g_player_x + PLAYER_HALF_WIDTH > cell_x && g_player_x - PLAYER_HALF_WIDTH < cell_x + 1.0 &&
      g_player_z + PLAYER_HALF_WIDTH > cell_z && g_player_z - PLAYER_HALF_WIDTH < cell_z + 1.0 &&
      g_player_y + PLAYER_HEIGHT     > cell_y && g_player_y                     < cell_y + 1.0) return;
  if (cows_box_overlaps(cell_x, cell_y, cell_z, cell_x + 1.0, cell_y + 1.0, cell_z + 1.0)) return;

  // A furnace turns its door towards the player
  if (held == ITEM_FURNACE) {
    toward_x = g_player_x - (cell_x + 0.5);
    toward_z = g_player_z - (cell_z + 0.5);
    if (Absolute(toward_x) >= Absolute(toward_z)) {
      place = BLOCK_FURNACE_NX;
      if (toward_x > 0.0) place = BLOCK_FURNACE_PX;
    } else {
      place = BLOCK_FURNACE_NZ;
      if (toward_z > 0.0) place = BLOCK_FURNACE_PZ;
    }
  }

  world_place_block(cell_x, cell_y, cell_z, place);
  inventory_take_one(g_player_selected);
  g_player_swing = 0.25;
  player_update_target();
}

#endif
