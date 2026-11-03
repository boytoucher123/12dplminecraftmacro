#ifndef PLAYER_4DM_INCLUDED
#define PLAYER_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/physics.h"
#include "../include/inventory.h"
#include "../include/cows.h"
#include "../include/player.h"

// ---------------------------------------------------------------- accessors

void player_reset(Attributes &player, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Stand the player at (x, y, z), alive and at full health, keeping
// the look direction and selected slot
// ----------------------------------------------------------------
{
  Real    yaw      = record_real   (player, ATTR_YAW);
  Real    pitch    = record_real   (player, ATTR_PITCH);
  Integer selected = record_integer(player, ATTR_PLAYER_SELECTED);

  if (selected < 1) selected = 1;

  record_clear(player, DATATYPE_PLAYER);
  player_set_position (player, x, y, z);
  player_set_velocity (player, 0.0, 0.0, 0.0);
  player_set_look     (player, yaw, pitch);
  player_set_health   (player, PLAYER_MAX_HEALTH);
  player_set_selected (player, selected);
  player_set_fall_peak(player, y);
  player_set_auto_walk(player, FALSE);

  record_set_integer(player, ATTR_PLAYER_DEAD,         FALSE);
  record_set_integer(player, ATTR_ON_GROUND,           FALSE);
  record_set_integer(player, ATTR_PLAYER_IN_WATER,     FALSE);
  record_set_integer(player, ATTR_PLAYER_EYE_IN_WATER, FALSE);
  record_set_real   (player, ATTR_PLAYER_REGEN,        0.0);
  record_set_real   (player, ATTR_PLAYER_HURT,         0.0);
  record_set_real   (player, ATTR_PLAYER_SWING,        0.0);
  record_set_real   (player, ATTR_PLAYER_BOB,          0.0);
  record_set_text   (player, ATTR_MOVE_KEY,            "");
  record_set_real   (player, ATTR_MOVE_UNTIL,          0.0);
  record_set_real   (player, ATTR_MOVE_LAST,           0.0);
  record_set_real   (player, ATTR_MOVE_START,          0.0);
  record_set_integer(player, ATTR_MOVE_HELD,           FALSE);
  record_set_real   (player, ATTR_JUMP_UNTIL,          0.0);
  record_set_integer(player, ATTR_TARGET_KIND,         TARGET_NONE);
  record_set_integer(player, ATTR_TARGET_X,            0);
  record_set_integer(player, ATTR_TARGET_Y,            0);
  record_set_integer(player, ATTR_TARGET_Z,            0);
  record_set_integer(player, ATTR_TARGET_NORMAL_X,     0);
  record_set_integer(player, ATTR_TARGET_NORMAL_Y,     0);
  record_set_integer(player, ATTR_TARGET_NORMAL_Z,     0);
  record_set_integer(player, ATTR_TARGET_COW,          0);
  record_set_integer(player, ATTR_BREAK_X,             0);
  record_set_integer(player, ATTR_BREAK_Y,             -1);
  record_set_integer(player, ATTR_BREAK_Z,             0);
  record_set_integer(player, ATTR_BREAK_HITS,          0);
  record_set_integer(player, ATTR_BREAK_NEEDED,        0);
  record_set_real   (player, ATTR_BREAK_TIME,          0.0);
}

void player_position(Attributes &player, Real &x, Real &y, Real &z)
// ----------------------------------------------------------------
// Feet position (x, z centre of the footprint, y the soles)
// ----------------------------------------------------------------
{
  x = record_real(player, ATTR_X);
  y = record_real(player, ATTR_Y);
  z = record_real(player, ATTR_Z);
}

void player_set_position(Attributes &player, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Move the player without any collision checks
// ----------------------------------------------------------------
{
  record_set_real(player, ATTR_X, x);
  record_set_real(player, ATTR_Y, y);
  record_set_real(player, ATTR_Z, z);
}

void player_velocity(Attributes &player, Real &vx, Real &vy, Real &vz)
// ----------------------------------------------------------------
// Velocity in blocks per second
// ----------------------------------------------------------------
{
  vx = record_real(player, ATTR_VX);
  vy = record_real(player, ATTR_VY);
  vz = record_real(player, ATTR_VZ);
}

void player_set_velocity(Attributes &player, Real vx, Real vy, Real vz)
// ----------------------------------------------------------------
// Set the velocity in blocks per second
// ----------------------------------------------------------------
{
  record_set_real(player, ATTR_VX, vx);
  record_set_real(player, ATTR_VY, vy);
  record_set_real(player, ATTR_VZ, vz);
}

void player_look(Attributes &player, Real &yaw, Real &pitch)
// ----------------------------------------------------------------
// Look direction: yaw around the vertical, pitch up (+) and down
// ----------------------------------------------------------------
{
  yaw   = record_real(player, ATTR_YAW);
  pitch = record_real(player, ATTR_PITCH);
}

void player_set_look(Attributes &player, Real yaw, Real pitch)
// ----------------------------------------------------------------
// Set the look direction
// ----------------------------------------------------------------
{
  record_set_real(player, ATTR_YAW,   yaw);
  record_set_real(player, ATTR_PITCH, pitch);
}

Real player_eye_y(Attributes &player)
// ----------------------------------------------------------------
// Height of the player's eyes
// ----------------------------------------------------------------
{
  return record_real(player, ATTR_Y) + PLAYER_EYE_HEIGHT;
}

void player_look_direction(Attributes &player, Real &dir_x, Real &dir_y, Real &dir_z)
// ----------------------------------------------------------------
// Unit vector the player is looking along
// ----------------------------------------------------------------
{
  Real yaw   = 0.0;
  Real pitch = 0.0;

  player_look(player, yaw, pitch);
  dir_x = Cos(pitch) * Cos(yaw);
  dir_y = Sin(pitch);
  dir_z = Cos(pitch) * Sin(yaw);
}

Integer player_health(Attributes &player)
// ----------------------------------------------------------------
// Health points, 0..PLAYER_MAX_HEALTH
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_HEALTH);
}

void player_set_health(Attributes &player, Integer health)
// ----------------------------------------------------------------
// Set health, kept within 0..PLAYER_MAX_HEALTH
// ----------------------------------------------------------------
{
  record_set_integer(player, ATTR_HEALTH, clamp_integer(health, 0, PLAYER_MAX_HEALTH));
}

Integer player_is_dead(Attributes &player)
// ----------------------------------------------------------------
// TRUE between dying and respawning
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_PLAYER_DEAD);
}

Integer player_on_ground(Attributes &player)
// ----------------------------------------------------------------
// TRUE when standing on something
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_ON_GROUND);
}

Integer player_in_water(Attributes &player)
// ----------------------------------------------------------------
// TRUE when the body is in water (swimming)
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_PLAYER_IN_WATER);
}

Integer player_eye_in_water(Attributes &player)
// ----------------------------------------------------------------
// TRUE when the eyes are under water (the view turns blue)
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_PLAYER_EYE_IN_WATER);
}

Real player_hurt_time(Attributes &player)
// ----------------------------------------------------------------
// Seconds left of the red "hurt" flash
// ----------------------------------------------------------------
{
  return record_real(player, ATTR_PLAYER_HURT);
}

Real player_swing_time(Attributes &player)
// ----------------------------------------------------------------
// Seconds left of the arm swing
// ----------------------------------------------------------------
{
  return record_real(player, ATTR_PLAYER_SWING);
}

Real player_bob(Attributes &player)
// ----------------------------------------------------------------
// Walking phase, used to bob the held item
// ----------------------------------------------------------------
{
  return record_real(player, ATTR_PLAYER_BOB);
}

Real player_fall_peak(Attributes &player)
// ----------------------------------------------------------------
// Highest point since leaving the ground (for fall damage)
// ----------------------------------------------------------------
{
  return record_real(player, ATTR_PLAYER_FALL_PEAK);
}

void player_set_fall_peak(Attributes &player, Real peak)
// ----------------------------------------------------------------
// Set the highest point since leaving the ground
// ----------------------------------------------------------------
{
  record_set_real(player, ATTR_PLAYER_FALL_PEAK, peak);
}

Integer player_selected(Attributes &player)
// ----------------------------------------------------------------
// Selected hotbar slot, 1..HOTBAR_SLOTS
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_PLAYER_SELECTED);
}

void player_set_selected(Attributes &player, Integer slot)
// ----------------------------------------------------------------
// Select a hotbar slot
// ----------------------------------------------------------------
{
  record_set_integer(player, ATTR_PLAYER_SELECTED, clamp_integer(slot, 1, HOTBAR_SLOTS));
}

Integer player_auto_walk(Attributes &player)
// ----------------------------------------------------------------
// TRUE while auto-walk is on
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_PLAYER_AUTO_WALK);
}

void player_set_auto_walk(Attributes &player, Integer on)
// ----------------------------------------------------------------
// Turn auto-walk on or off
// ----------------------------------------------------------------
{
  record_set_integer(player, ATTR_PLAYER_AUTO_WALK, on);
}

Integer player_held_item(Attributes &player, Attributes &inventory)
// ----------------------------------------------------------------
// Item in the selected hotbar slot
// ----------------------------------------------------------------
{
  return slot_item(inventory, player_selected(player));
}

Integer player_target_kind(Attributes &player)
// ----------------------------------------------------------------
// TARGET_NONE, TARGET_BLOCK or TARGET_COW
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_TARGET_KIND);
}

void player_target_cell(Attributes &player, Integer &x, Integer &y, Integer &z)
// ----------------------------------------------------------------
// Cell of the targeted block
// ----------------------------------------------------------------
{
  x = record_integer(player, ATTR_TARGET_X);
  y = record_integer(player, ATTR_TARGET_Y);
  z = record_integer(player, ATTR_TARGET_Z);
}

void player_target_normal(Attributes &player, Integer &x, Integer &y, Integer &z)
// ----------------------------------------------------------------
// Outward normal of the targeted face (where a block would go)
// ----------------------------------------------------------------
{
  x = record_integer(player, ATTR_TARGET_NORMAL_X);
  y = record_integer(player, ATTR_TARGET_NORMAL_Y);
  z = record_integer(player, ATTR_TARGET_NORMAL_Z);
}

Integer player_target_cow(Attributes &player)
// ----------------------------------------------------------------
// Number of the targeted cow
// ----------------------------------------------------------------
{
  return record_integer(player, ATTR_TARGET_COW);
}

Integer player_break_stage(Attributes &player, Real now)
// ----------------------------------------------------------------
// How cracked the block being broken is: 0 (not started) to 4
// ----------------------------------------------------------------
{
  Integer hits   = record_integer(player, ATTR_BREAK_HITS);
  Integer needed = record_integer(player, ATTR_BREAK_NEEDED);

  if (hits <= 0 || record_integer(player, ATTR_BREAK_Y) < 0) return 0;
  if (now - record_real(player, ATTR_BREAK_TIME) > BREAK_RESET_SECONDS) return 0;
  if (needed <= 1) return 0;

  return clamp_integer(1 + floor_integer(3.0 * hits / needed), 1, 4);
}

// ---------------------------------------------------------------- behaviour

void player_turn(Attributes &player, Real yaw_change, Real pitch_change)
// ----------------------------------------------------------------
// Mouse look; pitch stops just short of straight up and down
// ----------------------------------------------------------------
{
  Real yaw   = 0.0;
  Real pitch = 0.0;

  player_look    (player, yaw, pitch);
  player_set_look(player, wrap_angle(yaw + yaw_change), clamp_real(pitch + pitch_change, -MAX_PITCH, MAX_PITCH));
}

void player_key_pressed(Attributes &player, Text key, Real now)
// ----------------------------------------------------------------
// A movement key (w a s d, space) arrived from the keyboard box
// Only the last key held down auto-repeats, and there is no key-up
// event, so a fresh press moves for TAP_TIME and every repeat keeps
// the key alive a little longer. Jumping keeps the last movement
// going so you can run and jump.
// ----------------------------------------------------------------
{
  Text move_key   = record_text(player, ATTR_MOVE_KEY);
  Real move_last  = record_real(player, ATTR_MOVE_LAST);
  Real move_until = record_real(player, ATTR_MOVE_UNTIL);

  if (key == "w" || key == "a" || key == "s" || key == "d") {
    if (key == move_key && now - move_last < HELD_KEY_WINDOW) {
      record_set_real   (player, ATTR_MOVE_UNTIL, now + HELD_KEY_EXTEND);
      record_set_integer(player, ATTR_MOVE_HELD,  TRUE);
    } else {
      record_set_real   (player, ATTR_MOVE_UNTIL, now + TAP_TIME);
      record_set_real   (player, ATTR_MOVE_START, now);
      record_set_integer(player, ATTR_MOVE_HELD,  FALSE);
    }
    record_set_text(player, ATTR_MOVE_KEY,  key);
    record_set_real(player, ATTR_MOVE_LAST, now);
    if (key == "s") player_set_auto_walk(player, FALSE);
    return;
  }

  if (key == " ") {
    record_set_real(player, ATTR_JUMP_UNTIL, now + 0.25);
    if (move_until > now - 0.15) {
      record_set_real   (player, ATTR_MOVE_UNTIL, max_real(move_until, now + 0.55));
      record_set_integer(player, ATTR_MOVE_HELD,  TRUE);
    }
  }
}

Integer player_key_active(Attributes &player, Text key, Real now)
// ----------------------------------------------------------------
// TRUE while a movement key counts as held down
// ----------------------------------------------------------------
{
  if (record_text(player, ATTR_MOVE_KEY) == key && now < record_real(player, ATTR_MOVE_UNTIL)) return TRUE;
  return FALSE;
}

void player_damage(Attributes &player, Attributes &events, Integer amount)
// ----------------------------------------------------------------
// Take damage; emits EVT_PLAYER_HURT and EVT_PLAYER_DIED
// ----------------------------------------------------------------
{
  Integer health = player_health(player) - amount;

  if (player_is_dead(player) || amount <= 0) return;

  player_set_health(player, health);
  record_set_real  (player, ATTR_PLAYER_HURT,  0.4);
  record_set_real  (player, ATTR_PLAYER_REGEN, 0.0);
  emit_item_event(events, EVT_PLAYER_HURT, amount, 0);

  if (health <= 0) {
    record_set_integer(player, ATTR_PLAYER_DEAD, TRUE);
    emit_simple_event(events, EVT_PLAYER_DIED);
  }
}

void player_update(Attributes &player, Attributes &cows, Attributes &events, Integer auto_jump, Real dt, Real now)
// ----------------------------------------------------------------
// Walk, jump, swim, fall and collide; fall damage, regeneration
// and what the crosshair points at
// The record is read into locals at the start and written back at
// the end, since a frame uses each field many times.
// ----------------------------------------------------------------
{
  Real    x            = 0.0;
  Real    y            = 0.0;
  Real    z            = 0.0;
  Real    vx           = 0.0;
  Real    vy           = 0.0;
  Real    vz           = 0.0;
  Real    yaw          = 0.0;
  Real    pitch        = 0.0;
  Integer on_ground    = player_on_ground(player);
  Integer in_water     = player_in_water(player);
  Integer auto_walk    = player_auto_walk(player);
  Integer move_held    = record_integer(player, ATTR_MOVE_HELD);
  Real    move_start   = record_real   (player, ATTR_MOVE_START);
  Real    jump_until   = record_real   (player, ATTR_JUMP_UNTIL);
  Real    fall_peak    = player_fall_peak(player);
  Real    regen        = record_real   (player, ATTR_PLAYER_REGEN);
  Integer health       = player_health(player);
  Real    forward      = 0.0;
  Real    strafe       = 0.0;
  Real    ease         = 1.0;
  Real    speed        = 0.0;
  Real    heading_x    = 0.0;
  Real    heading_z    = 0.0;
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
  Integer was_grounded = on_ground;
  Integer blocked      = FALSE;
  Integer moving       = FALSE;
  Integer ahead_x      = 0;
  Integer ahead_z      = 0;
  Integer feet_y       = 0;
  Integer hit_x        = FALSE;
  Integer hit_z        = FALSE;
  Integer hit_down     = FALSE;
  Integer hit_up       = FALSE;

  record_set_real(player, ATTR_PLAYER_HURT,  player_hurt_time (player) - dt);
  record_set_real(player, ATTR_PLAYER_SWING, player_swing_time(player) - dt);
  if (player_is_dead(player)) return;

  player_position(player, x, y, z);
  player_velocity(player, vx, vy, vz);
  player_look    (player, yaw, pitch);
  heading_x = Cos(yaw);
  heading_z = Sin(yaw);

  // Movement input
  if (player_key_active(player, "w", now)) forward =  1.0;
  if (player_key_active(player, "s", now)) forward = -1.0;
  if (player_key_active(player, "a", now)) strafe  = -1.0;
  if (player_key_active(player, "d", now)) strafe  =  1.0;
  if (auto_walk && forward == 0.0) forward = 1.0;

  if (!move_held && !auto_walk) {
    ease = TAP_START_SPEED + (1.0 - TAP_START_SPEED) * clamp_real((now - move_start) / TAP_RAMP, 0.0, 1.0);
  }
  speed = WALK_SPEED * ease;
  if (in_water) speed = speed * WATER_SPEED_FACTOR;

  wish_x = heading_x * forward - heading_z * strafe;
  wish_z = heading_z * forward + heading_x * strafe;
  wish_length = Sqrt(wish_x * wish_x + wish_z * wish_z);
  if (wish_length > 0.001) {
    wish_x = wish_x / wish_length;
    wish_z = wish_z / wish_length;
    moving = TRUE;
  }

  if (on_ground) {
    vx = wish_x * speed;
    vz = wish_z * speed;
  } else {
    blend = min_real(1.0, dt * 5.0);
    vx = vx + (wish_x * speed - vx) * blend;
    vz = vz + (wish_z * speed - vz) * blend;
  }

  // Jumping and swimming
  if (now < jump_until) {
    if (in_water) {
      vy = SWIM_UP_SPEED;
    } else if (on_ground) {
      vy         = JUMP_SPEED;
      jump_until = 0.0;
    }
  }

  if (in_water) {
    vy = vy - SWIM_GRAVITY * dt;
    if (vy < -SWIM_SINK_SPEED) vy = -SWIM_SINK_SPEED;
  } else {
    vy = vy - GRAVITY * dt;
    if (vy < -TERMINAL_SPEED) vy = -TERMINAL_SPEED;
  }

  // Move in steps short enough not to pass through a block
  move_x  = vx * dt;
  move_y  = vy * dt;
  move_z  = vz * dt;
  longest = max_real(Absolute(move_y), max_real(Absolute(move_x), Absolute(move_z)));
  steps   = 1 + Floor(longest / MAX_MOVE_STEP);

  on_ground = FALSE;
  for (step = 1; step <= steps; ++step) {
    physics_move_box(x, y, z, PLAYER_HALF_WIDTH, PLAYER_HEIGHT, move_x / steps, move_y / steps, move_z / steps,
                     hit_x, hit_z, hit_down, hit_up);
    if (hit_down) {
      on_ground = TRUE;
      if (vy < 0.0) vy = 0.0;
    }
    if (hit_up && vy > 0.0) vy = 0.0;
    if (hit_x || hit_z) blocked = TRUE;
  }

  // Auto-jump: walking into a one block step hops up it, and
  // swimming into the shore climbs out
  if (blocked && moving) {
    ahead_x = Floor(x + wish_x * 0.6);
    ahead_z = Floor(z + wish_z * 0.6);
    feet_y  = Floor(y + 0.05);
    if (!world_is_solid(ahead_x, feet_y + 1, ahead_z) && !world_is_solid(ahead_x, feet_y + 2, ahead_z)) {
      if (in_water) {
        vy = SWIM_UP_SPEED * 1.6;
      } else if (on_ground && auto_jump) {
        vy = JUMP_SPEED;
      }
    }
  }

  // Water
  in_water = physics_box_in_water(x, y, z, PLAYER_HALF_WIDTH, PLAYER_HEIGHT);
  record_set_integer(player, ATTR_PLAYER_IN_WATER,     in_water);
  record_set_integer(player, ATTR_PLAYER_EYE_IN_WATER, world_get_block(floor_integer(x), floor_integer(y + PLAYER_EYE_HEIGHT), floor_integer(z)) == BLOCK_WATER);

  player_set_position(player, x, y, z);
  player_set_velocity(player, vx, vy, vz);
  record_set_integer (player, ATTR_ON_GROUND,  on_ground);
  record_set_real    (player, ATTR_JUMP_UNTIL, jump_until);

  // Fall damage: measured from the highest point since leaving the
  // ground; water breaks any fall
  if (in_water) {
    fall_peak = y;
  } else if (on_ground) {
    if (!was_grounded) {
      fall = fall_peak - y;
      if (fall > FALL_DAMAGE_START) player_damage(player, events, floor_integer(fall - FALL_DAMAGE_START + 0.5));
    }
    fall_peak = y;
  } else if (y > fall_peak) {
    fall_peak = y;
  }
  player_set_fall_peak(player, fall_peak);

  if (on_ground && moving) record_set_real(player, ATTR_PLAYER_BOB, player_bob(player) + dt * 9.0 * ease);

  // Slow healing
  health = player_health(player);
  if (health < PLAYER_MAX_HEALTH && !player_is_dead(player)) {
    regen = regen + dt;
    if (regen >= REGEN_SECONDS) {
      regen = 0.0;
      player_set_health(player, health + 1);
    }
  }
  record_set_real(player, ATTR_PLAYER_REGEN, regen);

  if (now - record_real(player, ATTR_BREAK_TIME) > BREAK_RESET_SECONDS) record_set_integer(player, ATTR_BREAK_HITS, 0);

  player_update_target(player, cows);
}

void player_update_target(Attributes &player, Attributes &cows)
// ----------------------------------------------------------------
// Find what the crosshair is on within reach: a cow or a block
// ----------------------------------------------------------------
{
  Real    eye_x          = record_real(player, ATTR_X);
  Real    eye_y          = player_eye_y(player);
  Real    eye_z          = record_real(player, ATTR_Z);
  Real    dir_x          = 0.0;
  Real    dir_y          = 0.0;
  Real    dir_z          = 0.0;
  Real    block_distance = PLAYER_REACH;
  Real    cow_distance   = 0.0;
  Integer block_hit      = FALSE;
  Integer hit_x          = 0;
  Integer hit_y          = 0;
  Integer hit_z          = 0;
  Integer normal_x       = 0;
  Integer normal_y       = 0;
  Integer normal_z       = 0;
  Integer cow            = 0;
  Integer kind           = TARGET_NONE;

  player_look_direction(player, dir_x, dir_y, dir_z);

  block_hit = physics_raycast_blocks(eye_x, eye_y, eye_z, dir_x, dir_y, dir_z, PLAYER_REACH,
                                     hit_x, hit_y, hit_z, normal_x, normal_y, normal_z, block_distance);
  if (block_hit) {
    record_set_integer(player, ATTR_TARGET_X,        hit_x);
    record_set_integer(player, ATTR_TARGET_Y,        hit_y);
    record_set_integer(player, ATTR_TARGET_Z,        hit_z);
    record_set_integer(player, ATTR_TARGET_NORMAL_X, normal_x);
    record_set_integer(player, ATTR_TARGET_NORMAL_Y, normal_y);
    record_set_integer(player, ATTR_TARGET_NORMAL_Z, normal_z);
    kind = TARGET_BLOCK;
  } else {
    block_distance = PLAYER_REACH;
  }

  cow = cows_ray_hit(cows, eye_x, eye_y, eye_z, dir_x, dir_y, dir_z, block_distance, cow_distance);
  if (cow > 0) {
    kind = TARGET_COW;
    record_set_integer(player, ATTR_TARGET_COW, cow);
  }
  record_set_integer(player, ATTR_TARGET_KIND, kind);
}

Integer player_overlaps_cell(Attributes &player, Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// TRUE if the player's body overlaps block cell (x, y, z)
// ----------------------------------------------------------------
{
  Real px = 0.0;
  Real py = 0.0;
  Real pz = 0.0;

  player_position(player, px, py, pz);
  if (px + PLAYER_HALF_WIDTH <= x || px - PLAYER_HALF_WIDTH >= x + 1.0) return FALSE;
  if (pz + PLAYER_HALF_WIDTH <= z || pz - PLAYER_HALF_WIDTH >= z + 1.0) return FALSE;
  if (py + PLAYER_HEIGHT     <= y || py                     >= y + 1.0) return FALSE;
  return TRUE;
}

void player_wear_tool(Attributes &player, Attributes &inventory, Attributes &events)
// ----------------------------------------------------------------
// The held item was used once; tools wear and may break
// ----------------------------------------------------------------
{
  Integer slot = player_selected(player);
  Integer item = slot_item(inventory, slot);

  if (slot_wear(inventory, slot)) {
    emit_toast(events, item_name(item) + " broke");
  }
}

void player_primary_action(Attributes &player, Attributes &inventory, Attributes &cows, Attributes &events,
                           Attributes &random, Real now)
// ----------------------------------------------------------------
// Left click: hit a cow, or chip away at a block until it breaks
// Harder blocks take more hits, the right tool takes fewer; a pause
// of BREAK_RESET_SECONDS starts the count again
// ----------------------------------------------------------------
{
  Integer held   = player_held_item(player, inventory);
  Integer block  = 0;
  Integer needed = 0;
  Integer hits   = 0;
  Integer x      = 0;
  Integer y      = 0;
  Integer z      = 0;
  Real    yaw    = 0.0;
  Real    pitch  = 0.0;

  if (player_is_dead(player)) return;

  record_set_real     (player, ATTR_PLAYER_SWING, 0.25);
  player_update_target(player, cows);
  player_look         (player, yaw, pitch);

  if (player_target_kind(player) == TARGET_COW) {
    cow_damage(cows, events, random, player_target_cow(player), item_attack_damage(held), Cos(yaw), Sin(yaw));
    if (item_tool_kind(held) != TOOL_NONE) player_wear_tool(player, inventory, events);
    return;
  }
  if (player_target_kind(player) != TARGET_BLOCK) return;

  player_target_cell(player, x, y, z);
  block  = world_get_block(x, y, z);
  needed = block_hits_with(block, held);
  if (needed <= 0) {
    emit_toast(events, "That is far too hard to break");
    return;
  }

  hits = record_integer(player, ATTR_BREAK_HITS);
  if (x == record_integer(player, ATTR_BREAK_X) && y == record_integer(player, ATTR_BREAK_Y) &&
      z == record_integer(player, ATTR_BREAK_Z) && now - record_real(player, ATTR_BREAK_TIME) <= BREAK_RESET_SECONDS && hits > 0) {
    ++hits;
  } else {
    record_set_integer(player, ATTR_BREAK_X, x);
    record_set_integer(player, ATTR_BREAK_Y, y);
    record_set_integer(player, ATTR_BREAK_Z, z);
    hits = 1;
  }
  record_set_integer(player, ATTR_BREAK_HITS, hits);
  record_set_integer(player, ATTR_BREAK_NEEDED, needed);
  record_set_real   (player, ATTR_BREAK_TIME, now);

  if (hits >= needed) {
    if (block_needs_tool(block) && item_tool_kind(held) != block_tool_kind(block)) {
      emit_toast(events, "You need a pickaxe to collect that");
    }
    world_break_block(events, x, y, z, held);
    if (item_tool_kind(held) != TOOL_NONE) player_wear_tool(player, inventory, events);
    record_set_integer(player, ATTR_BREAK_HITS, 0);
    record_set_integer(player, ATTR_BREAK_Y,    -1);
    player_update_target(player, cows);
  }
}

Integer player_furnace_facing(Real player_x, Real player_z, Integer cell_x, Integer cell_z)
// ----------------------------------------------------------------
// The furnace block that turns its door towards the player
// ----------------------------------------------------------------
{
  Real toward_x = player_x - (cell_x + 0.5);
  Real toward_z = player_z - (cell_z + 0.5);

  if (Absolute(toward_x) >= Absolute(toward_z)) {
    if (toward_x > 0.0) return BLOCK_FURNACE_PX;
    return BLOCK_FURNACE_NX;
  }
  if (toward_z > 0.0) return BLOCK_FURNACE_PZ;
  return BLOCK_FURNACE_NZ;
}

void player_secondary_action(Attributes &player, Attributes &inventory, Attributes &cows, Attributes &events, Real now)
// ----------------------------------------------------------------
// Right click: open a crafting table or furnace, eat food, or
// place the held block against the face the crosshair is on
// (a plant there is replaced)
// ----------------------------------------------------------------
{
  Integer held     = player_held_item(player, inventory);
  Integer slot     = player_selected(player);
  Integer block    = 0;
  Integer place    = BLOCK_AIR;
  Integer x        = 0;
  Integer y        = 0;
  Integer z        = 0;
  Integer normal_x = 0;
  Integer normal_y = 0;
  Integer normal_z = 0;
  Integer cell_x   = 0;
  Integer cell_y   = 0;
  Integer cell_z   = 0;
  Integer existing = 0;
  Integer food     = 0;
  Real    px       = 0.0;
  Real    py       = 0.0;
  Real    pz       = 0.0;

  if (player_is_dead(player)) return;

  player_update_target(player, cows);
  player_target_cell  (player, x, y, z);
  player_target_normal(player, normal_x, normal_y, normal_z);

  if (player_target_kind(player) == TARGET_BLOCK) {
    block = world_get_block(x, y, z);
    if (block == BLOCK_CRAFTING_TABLE) {
      emit_event(events, EVT_OPEN_SCREEN, SCREEN_CRAFTING, x, y, z, 0.0, 0.0, 0.0, "");
      return;
    }
    if (block_is_furnace(block)) {
      emit_event(events, EVT_OPEN_SCREEN, SCREEN_FURNACE, x, y, z, 0.0, 0.0, 0.0, "");
      return;
    }
  }

  food = item_food_value(held);
  if (food > 0) {
    if (player_health(player) >= PLAYER_MAX_HEALTH) {
      emit_toast(events, "You are already at full health");
      return;
    }
    player_set_health(player, player_health(player) + food);
    slot_take_one    (inventory, slot);
    record_set_real  (player, ATTR_PLAYER_SWING, 0.25);
    emit_item_event(events, EVT_PLAYER_ATE, held, food);
    return;
  }

  place = item_places_block(held);
  if (place == BLOCK_AIR) return;
  if (player_target_kind(player) != TARGET_BLOCK) return;

  // Clicking a plant replaces it; otherwise the block goes against
  // the face that was clicked
  cell_x = x + normal_x;
  cell_y = y + normal_y;
  cell_z = z + normal_z;
  if (block_is_plant(world_get_block(x, y, z))) {
    cell_x = x;
    cell_y = y;
    cell_z = z;
  } else if (normal_x == 0 && normal_y == 0 && normal_z == 0) {
    return;
  }
  if (!world_in_bounds(cell_x, cell_y, cell_z)) return;

  existing = world_get_block(cell_x, cell_y, cell_z);
  if (existing != BLOCK_AIR && existing != BLOCK_WATER && !block_is_plant(existing)) return;

  // Plants need ground to stand on
  if (block_is_plant(place)) {
    if (world_get_block(cell_x, cell_y - 1, cell_z) != BLOCK_GRASS && world_get_block(cell_x, cell_y - 1, cell_z) != BLOCK_DIRT) return;
  } else {
    // Not inside the player or a cow
    if (player_overlaps_cell(player, cell_x, cell_y, cell_z)) return;
    if (cows_box_overlaps(cows, cell_x, cell_y, cell_z, cell_x + 1.0, cell_y + 1.0, cell_z + 1.0)) return;
  }

  if (held == ITEM_FURNACE) {
    player_position(player, px, py, pz);
    place = player_furnace_facing(px, pz, cell_x, cell_z);
  }

  world_place_block(events, cell_x, cell_y, cell_z, place);
  slot_take_one    (inventory, slot);
  record_set_real  (player, ATTR_PLAYER_SWING, 0.25);
  player_update_target(player, cows);
}

#endif
