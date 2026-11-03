#ifndef COWS_4DM_INCLUDED
#define COWS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/physics.h"
#include "../include/cows.h"

// ---------------------------------------------------------------- accessors

void cows_clear(Attributes &cows)
// ----------------------------------------------------------------
// Remove every cow
// ----------------------------------------------------------------
{
  Integer cow = 0;

  record_clear   (cows, DATATYPE_COWS);
  record_set_real(cows, ATTR_COW_RESPAWN, 0.0);
  for (cow = 1; cow <= MAX_COWS; ++cow) record_set_integer_at(cows, ATTR_USED, cow, FALSE);
}

Integer cow_alive(Attributes &cows, Integer cow)
// ----------------------------------------------------------------
// TRUE if cow number cow exists
// ----------------------------------------------------------------
{
  if (cow < 1 || cow > MAX_COWS) return FALSE;
  return record_integer_at(cows, ATTR_USED, cow);
}

void cow_position(Attributes &cows, Integer cow, Real &x, Real &y, Real &z)
// ----------------------------------------------------------------
// Where a cow stands (centre of its footprint, y at its feet)
// ----------------------------------------------------------------
{
  x = record_real_at(cows, ATTR_X, cow);
  y = record_real_at(cows, ATTR_Y, cow);
  z = record_real_at(cows, ATTR_Z, cow);
}

void cow_set_position(Attributes &cows, Integer cow, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Move a cow without any collision checks
// ----------------------------------------------------------------
{
  record_set_real_at(cows, ATTR_X, cow, x);
  record_set_real_at(cows, ATTR_Y, cow, y);
  record_set_real_at(cows, ATTR_Z, cow, z);
}

Real cow_yaw(Attributes &cows, Integer cow)
// ----------------------------------------------------------------
// Direction a cow faces
// ----------------------------------------------------------------
{
  return record_real_at(cows, ATTR_YAW, cow);
}

Real cow_flash(Attributes &cows, Integer cow)
// ----------------------------------------------------------------
// Seconds left of the red flash after being hit
// ----------------------------------------------------------------
{
  return record_real_at(cows, ATTR_COW_FLASH, cow);
}

Real cow_step(Attributes &cows, Integer cow)
// ----------------------------------------------------------------
// Leg swing phase
// ----------------------------------------------------------------
{
  return record_real_at(cows, ATTR_COW_STEP, cow);
}

Integer cows_alive_count(Attributes &cows)
// ----------------------------------------------------------------
// Number of living cows
// ----------------------------------------------------------------
{
  Integer cow   = 0;
  Integer count = 0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (cow_alive(cows, cow)) ++count;
  }
  return count;
}

// ---------------------------------------------------------------- behaviour

Integer cows_spawn(Attributes &cows, Attributes &random, Real x, Real y, Real z, Real yaw)
// ----------------------------------------------------------------
// Add a cow standing at (x, y, z); returns its number, 0 if full
// ----------------------------------------------------------------
{
  Integer cow = 0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (cow_alive(cows, cow)) continue;
    record_set_integer_at(cows, ATTR_USED,         cow, TRUE);
    cow_set_position     (cows, cow, x, y, z);
    record_set_real_at   (cows, ATTR_VY,           cow, 0.0);
    record_set_real_at   (cows, ATTR_COW_PUSH_X,   cow, 0.0);
    record_set_real_at   (cows, ATTR_COW_PUSH_Z,   cow, 0.0);
    record_set_real_at   (cows, ATTR_YAW,          cow, yaw);
    record_set_real_at   (cows, ATTR_COW_GOAL_YAW, cow, yaw);
    record_set_integer_at(cows, ATTR_HEALTH,       cow, COW_HEALTH);
    record_set_integer_at(cows, ATTR_COW_WALKING,  cow, FALSE);
    record_set_real_at   (cows, ATTR_TIMER,        cow, random_between(random, 1.0, 4.0));
    record_set_real_at   (cows, ATTR_COW_PANIC,    cow, 0.0);
    record_set_real_at   (cows, ATTR_COW_FLASH,    cow, 0.0);
    record_set_real_at   (cows, ATTR_COW_STEP,     cow, 0.0);
    record_set_integer_at(cows, ATTR_ON_GROUND,    cow, FALSE);
    return cow;
  }
  return 0;
}

Integer cows_spawn_random(Attributes &cows, Attributes &random, Integer count, Real away_x, Real away_z, Real keep_away)
// ----------------------------------------------------------------
// Put up to count cows on random grass blocks at least keep_away
// blocks from (away_x, away_z). Returns how many spawned.
// ----------------------------------------------------------------
{
  Integer spawned = 0;
  Integer tries   = 0;
  Integer x       = 0;
  Integer z       = 0;
  Integer top     = 0;
  Real    dx      = 0.0;
  Real    dz      = 0.0;

  while (spawned < count && tries < count * 60) {
    ++tries;
    x   = random_range(random, 2, WORLD_SIZE_X - 3);
    z   = random_range(random, 2, WORLD_SIZE_Z - 3);
    top = world_top_solid_y(x, z);
    if (top < SEA_LEVEL) continue;
    if (world_get_block(x, top, z) != BLOCK_GRASS) continue;
    dx = x + 0.5 - away_x;
    dz = z + 0.5 - away_z;
    if (dx * dx + dz * dz < keep_away * keep_away) continue;
    if (cows_spawn(cows, random, x + 0.5, top + 1.0 + COLLISION_EPSILON, z + 0.5, random_between(random, 0.0, TWO_PI)) == 0) break;
    ++spawned;
  }
  return spawned;
}

void cow_update(Attributes &cows, Attributes &random, Integer cow, Real dt)
// ----------------------------------------------------------------
// One cow: pick something to do now and then, turn smoothly, walk,
// fall, swim, hop up single blocks and avoid drops and water
// The cow's fields are read into locals and written back at the end
// ----------------------------------------------------------------
{
  Real    x         = record_real_at   (cows, ATTR_X,            cow);
  Real    y         = record_real_at   (cows, ATTR_Y,            cow);
  Real    z         = record_real_at   (cows, ATTR_Z,            cow);
  Real    vy        = record_real_at   (cows, ATTR_VY,           cow);
  Real    push_x    = record_real_at   (cows, ATTR_COW_PUSH_X,   cow);
  Real    push_z    = record_real_at   (cows, ATTR_COW_PUSH_Z,   cow);
  Real    yaw       = record_real_at   (cows, ATTR_YAW,          cow);
  Real    goal_yaw  = record_real_at   (cows, ATTR_COW_GOAL_YAW, cow);
  Integer walking   = record_integer_at(cows, ATTR_COW_WALKING,  cow);
  Real    timer     = record_real_at   (cows, ATTR_TIMER,        cow) - dt;
  Real    panic     = record_real_at   (cows, ATTR_COW_PANIC,    cow) - dt;
  Real    flash     = record_real_at   (cows, ATTR_COW_FLASH,    cow) - dt;
  Real    step_phase= record_real_at   (cows, ATTR_COW_STEP,     cow);
  Integer on_ground = record_integer_at(cows, ATTR_ON_GROUND,    cow);
  Real    speed     = 0.0;
  Real    turn      = 0.0;
  Real    dir_x     = 0.0;
  Real    dir_z     = 0.0;
  Real    move_x    = 0.0;
  Real    move_z    = 0.0;
  Real    fall      = 0.0;
  Integer in_water  = physics_box_in_water(x, y, z, COW_HALF_WIDTH, COW_HEIGHT);
  Integer steps     = 1;
  Integer step      = 0;
  Integer blocked   = FALSE;
  Integer ahead_x   = 0;
  Integer ahead_z   = 0;
  Integer foot_y    = 0;
  Integer hit_x     = FALSE;
  Integer hit_z     = FALSE;
  Integer hit_down  = FALSE;
  Integer hit_up    = FALSE;

  // Decide what to do next
  if (timer <= 0.0) {
    if (panic > 0.0) {
      goal_yaw = yaw + random_between(random, -0.8, 0.8);
      walking  = TRUE;
      timer    = random_between(random, 0.6, 1.2);
    } else if (random_next(random) < 0.45) {
      walking  = FALSE;
      timer    = random_between(random, 2.0, 6.0);
    } else {
      goal_yaw = random_between(random, 0.0, TWO_PI);
      walking  = TRUE;
      timer    = random_between(random, 2.0, 5.0);
    }
  }

  // Turn towards the goal direction by the shortest way round
  turn = wrap_angle(goal_yaw - yaw + PI) - PI;
  if (turn >  dt * 3.0) turn =  dt * 3.0;
  if (turn < -dt * 3.0) turn = -dt * 3.0;
  yaw   = wrap_angle(yaw + turn);
  dir_x = Cos(yaw);
  dir_z = Sin(yaw);

  if (walking) {
    speed = COW_WALK_SPEED;
    if (panic > 0.0) speed = COW_PANIC_SPEED;
    if (in_water) speed = speed * WATER_SPEED_FACTOR;

    // Don't walk off a drop of more than one block or into water
    ahead_x = Floor(x + dir_x * 0.9);
    ahead_z = Floor(z + dir_z * 0.9);
    foot_y  = Floor(y + 0.1);
    if (!in_water && on_ground) {
      if (!world_is_solid(ahead_x, foot_y - 1, ahead_z) && !world_is_solid(ahead_x, foot_y - 2, ahead_z)) {
        speed    = 0.0;
        goal_yaw = yaw + PI;
      }
      if (world_get_block(ahead_x, foot_y - 1, ahead_z) == BLOCK_WATER) {
        speed    = 0.0;
        goal_yaw = yaw + PI;
      }
    }
    step_phase = step_phase + dt * speed * 3.0;
  }

  // Knock-back fades away
  push_x = push_x * (1.0 - min_real(1.0, dt * 4.0));
  push_z = push_z * (1.0 - min_real(1.0, dt * 4.0));

  move_x = (dir_x * speed + push_x) * dt;
  move_z = (dir_z * speed + push_z) * dt;

  if (in_water) {
    vy = vy + (2.0 - vy) * min_real(1.0, dt * 3.0);
  } else {
    vy = vy - GRAVITY * dt;
    if (vy < -TERMINAL_SPEED) vy = -TERMINAL_SPEED;
  }
  fall = vy * dt;

  steps = 1 + Floor(max_real(Absolute(fall), max_real(Absolute(move_x), Absolute(move_z))) / MAX_MOVE_STEP);
  on_ground = FALSE;
  for (step = 1; step <= steps; ++step) {
    physics_move_box(x, y, z, COW_HALF_WIDTH, COW_HEIGHT, move_x / steps, fall / steps, move_z / steps,
                     hit_x, hit_z, hit_down, hit_up);
    if (hit_down) {
      on_ground = TRUE;
      vy        = 0.0;
    }
    if (hit_up) vy = 0.0;
    if (hit_x || hit_z) blocked = TRUE;
  }

  // Walked into a wall: hop if there is room above, else turn away
  if (blocked && walking) {
    if (on_ground && !world_is_solid(floor_integer(x + dir_x * 0.9), floor_integer(y + 1.1), floor_integer(z + dir_z * 0.9))) {
      vy = COW_JUMP_SPEED;
    } else {
      goal_yaw = yaw + PI * 0.5 + random_between(random, 0.0, PI);
    }
  }

  cow_set_position     (cows, cow, x, y, z);
  record_set_real_at   (cows, ATTR_VY,           cow, vy);
  record_set_real_at   (cows, ATTR_COW_PUSH_X,   cow, push_x);
  record_set_real_at   (cows, ATTR_COW_PUSH_Z,   cow, push_z);
  record_set_real_at   (cows, ATTR_YAW,          cow, yaw);
  record_set_real_at   (cows, ATTR_COW_GOAL_YAW, cow, goal_yaw);
  record_set_integer_at(cows, ATTR_COW_WALKING,  cow, walking);
  record_set_real_at   (cows, ATTR_TIMER,        cow, timer);
  record_set_real_at   (cows, ATTR_COW_PANIC,    cow, panic);
  record_set_real_at   (cows, ATTR_COW_FLASH,    cow, flash);
  record_set_real_at   (cows, ATTR_COW_STEP,     cow, step_phase);
  record_set_integer_at(cows, ATTR_ON_GROUND,    cow, on_ground);
}

void cows_update(Attributes &cows, Attributes &random, Real player_x, Real player_z, Real dt)
// ----------------------------------------------------------------
// Move every cow near the player and top the herd back up now and
// then, away from where the player can see it happen
// ----------------------------------------------------------------
{
  Integer cow     = 0;
  Real    x       = 0.0;
  Real    y       = 0.0;
  Real    z       = 0.0;
  Real    respawn = record_real(cows, ATTR_COW_RESPAWN) + dt;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!cow_alive(cows, cow)) continue;
    cow_position(cows, cow, x, y, z);
    if ((x - player_x) * (x - player_x) + (z - player_z) * (z - player_z) > COW_ACTIVE_DISTANCE * COW_ACTIVE_DISTANCE) continue;
    cow_update(cows, random, cow, dt);
  }

  if (respawn > COW_RESPAWN_SECONDS) {
    respawn = 0.0;
    if (cows_alive_count(cows) < COW_TARGET_COUNT) cows_spawn_random(cows, random, 1, player_x, player_z, 24.0);
  }
  record_set_real(cows, ATTR_COW_RESPAWN, respawn);
}

Integer cows_ray_hit(Attributes &cows, Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z,
                     Real max_distance, Real &distance)
// ----------------------------------------------------------------
// Nearest cow the ray hits within max_distance, 0 for none;
// distance is set to how far along the ray it is
// ----------------------------------------------------------------
{
  Integer cow     = 0;
  Integer best    = 0;
  Real    along   = 0.0;
  Real    nearest = max_distance;
  Real    x       = 0.0;
  Real    y       = 0.0;
  Real    z       = 0.0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!cow_alive(cows, cow)) continue;
    cow_position(cows, cow, x, y, z);
    along = physics_ray_box(origin_x, origin_y, origin_z, dir_x, dir_y, dir_z,
                            x - COW_HALF_WIDTH, y             , z - COW_HALF_WIDTH,
                            x + COW_HALF_WIDTH, y + COW_HEIGHT, z + COW_HALF_WIDTH);
    if (along < 0.0 || along > nearest) continue;
    nearest = along;
    best    = cow;
  }

  distance = nearest;
  return best;
}

void cow_damage(Attributes &cows, Attributes &events, Attributes &random, Integer cow, Integer amount, Real push_x, Real push_z)
// ----------------------------------------------------------------
// Hurt a cow and knock it back along (push_x, push_z)
// Emits EVT_COW_HURT, or EVT_COW_KILLED when it runs out of health
// ----------------------------------------------------------------
{
  Integer health = 0;
  Real    x      = 0.0;
  Real    y      = 0.0;
  Real    z      = 0.0;

  if (!cow_alive(cows, cow)) return;

  health = record_integer_at(cows, ATTR_HEALTH, cow) - amount;
  record_set_integer_at(cows, ATTR_HEALTH,       cow, health);
  record_set_real_at   (cows, ATTR_COW_FLASH,    cow, 0.3);
  record_set_real_at   (cows, ATTR_COW_PANIC,    cow, 5.0);
  record_set_real_at   (cows, ATTR_TIMER,        cow, 0.0);
  record_set_real_at   (cows, ATTR_COW_PUSH_X,   cow, push_x * 6.0);
  record_set_real_at   (cows, ATTR_COW_PUSH_Z,   cow, push_z * 6.0);
  record_set_real_at   (cows, ATTR_COW_GOAL_YAW, cow, random_between(random, 0.0, TWO_PI));
  if (record_integer_at(cows, ATTR_ON_GROUND, cow)) record_set_real_at(cows, ATTR_VY, cow, 4.5);

  cow_position(cows, cow, x, y, z);
  if (health <= 0) {
    record_set_integer_at(cows, ATTR_USED, cow, FALSE);
    emit_event(events, EVT_COW_KILLED, cow, 0, 0, 0, x, y + 0.6, z, "");
  } else {
    emit_event(events, EVT_COW_HURT, cow, 0, 0, 0, x, y, z, "");
  }
}

Integer cows_box_overlaps(Attributes &cows, Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z)
// ----------------------------------------------------------------
// TRUE if any cow overlaps the box (blocks can't be placed there)
// ----------------------------------------------------------------
{
  Integer cow = 0;
  Real    x   = 0.0;
  Real    y   = 0.0;
  Real    z   = 0.0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!cow_alive(cows, cow)) continue;
    cow_position(cows, cow, x, y, z);
    if (x + COW_HALF_WIDTH <= min_x || x - COW_HALF_WIDTH >= max_x) continue;
    if (z + COW_HALF_WIDTH <= min_z || z - COW_HALF_WIDTH >= max_z) continue;
    if (y + COW_HEIGHT     <= min_y || y                  >= max_y) continue;
    return TRUE;
  }
  return FALSE;
}

#endif
