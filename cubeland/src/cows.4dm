#ifndef COWS_4DM_INCLUDED
#define COWS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/physics.h"
#include "../include/player.h"
#include "../include/cows.h"

void cows_clear()
// ----------------------------------------------------------------
// Remove every cow
// ----------------------------------------------------------------
{
  Integer cow = 0;

  for (cow = 1; cow <= MAX_COWS; ++cow) g_cow_alive[cow] = FALSE;
  g_cow_respawn_timer = 0.0;
}

Integer cows_alive_count()
// ----------------------------------------------------------------
// Number of living cows
// ----------------------------------------------------------------
{
  Integer cow   = 0;
  Integer count = 0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (g_cow_alive[cow]) ++count;
  }
  return count;
}

Integer cows_spawn(Real x, Real y, Real z, Real yaw)
// ----------------------------------------------------------------
// Add a cow standing at (x, y, z); returns its index, 0 if full
// ----------------------------------------------------------------
{
  Integer cow = 0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (g_cow_alive[cow]) continue;
    g_cow_alive    [cow] = TRUE;
    g_cow_x        [cow] = x;
    g_cow_y        [cow] = y;
    g_cow_z        [cow] = z;
    g_cow_vy       [cow] = 0.0;
    g_cow_push_x   [cow] = 0.0;
    g_cow_push_z   [cow] = 0.0;
    g_cow_yaw      [cow] = yaw;
    g_cow_goal_yaw [cow] = yaw;
    g_cow_health   [cow] = COW_HEALTH;
    g_cow_walking  [cow] = FALSE;
    g_cow_timer    [cow] = 1.0 + random_real() * 3.0;
    g_cow_panic    [cow] = 0.0;
    g_cow_flash    [cow] = 0.0;
    g_cow_step     [cow] = 0.0;
    g_cow_on_ground[cow] = FALSE;
    return cow;
  }
  return 0;
}

Integer cows_spawn_random(Integer count, Real keep_away)
// ----------------------------------------------------------------
// Put up to count cows on random grass blocks with open sky at
// least keep_away blocks from the player. Returns how many spawned.
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
    x   = random_integer(2, WORLD_SIZE_X - 3);
    z   = random_integer(2, WORLD_SIZE_Z - 3);
    top = world_top_solid_y(x, z);
    if (top < SEA_LEVEL) continue;
    if (world_get_block(x, top, z) != BLOCK_GRASS) continue;
    dx = x + 0.5 - g_player_x;
    dz = z + 0.5 - g_player_z;
    if (dx * dx + dz * dz < keep_away * keep_away) continue;
    if (cows_spawn(x + 0.5, top + 1.0 + COLLISION_EPSILON, z + 0.5, random_real() * TWO_PI) == 0) break;
    ++spawned;
  }
  return spawned;
}

void cow_update(Integer cow, Real dt)
// ----------------------------------------------------------------
// One cow: pick something to do now and then, turn smoothly, walk,
// fall, swim, hop up single blocks and avoid drops and water
// ----------------------------------------------------------------
{
  Real    speed     = 0.0;
  Real    turn      = 0.0;
  Real    dir_x     = Cos(g_cow_yaw[cow]);
  Real    dir_z     = Sin(g_cow_yaw[cow]);
  Real    move_x    = 0.0;
  Real    move_z    = 0.0;
  Real    x         = g_cow_x[cow];
  Real    y         = g_cow_y[cow];
  Real    z         = g_cow_z[cow];
  Real    fall      = 0.0;
  Integer in_water  = physics_box_in_water(x, y, z, COW_HALF_WIDTH, COW_HEIGHT);
  Integer steps     = 1;
  Integer step      = 0;
  Integer blocked   = FALSE;
  Integer ahead_x   = 0;
  Integer ahead_z   = 0;
  Integer foot_y    = 0;

  g_cow_flash[cow] = g_cow_flash[cow] - dt;
  g_cow_panic[cow] = g_cow_panic[cow] - dt;
  g_cow_timer[cow] = g_cow_timer[cow] - dt;

  // Decide what to do next
  if (g_cow_timer[cow] <= 0.0) {
    if (g_cow_panic[cow] > 0.0) {
      g_cow_goal_yaw[cow] = g_cow_yaw[cow] + (random_real() - 0.5) * 1.6;
      g_cow_walking [cow] = TRUE;
      g_cow_timer   [cow] = 0.6 + random_real() * 0.6;
    } else if (random_real() < 0.45) {
      g_cow_walking [cow] = FALSE;
      g_cow_timer   [cow] = 2.0 + random_real() * 4.0;
    } else {
      g_cow_goal_yaw[cow] = random_real() * TWO_PI;
      g_cow_walking [cow] = TRUE;
      g_cow_timer   [cow] = 2.0 + random_real() * 3.0;
    }
  }

  // Turn towards the goal direction by the shortest way round
  turn = wrap_angle(g_cow_goal_yaw[cow] - g_cow_yaw[cow] + PI) - PI;
  if (turn >  dt * 3.0) turn =  dt * 3.0;
  if (turn < -dt * 3.0) turn = -dt * 3.0;
  g_cow_yaw[cow] = wrap_angle(g_cow_yaw[cow] + turn);
  dir_x = Cos(g_cow_yaw[cow]);
  dir_z = Sin(g_cow_yaw[cow]);

  if (g_cow_walking[cow]) {
    speed = COW_WALK_SPEED;
    if (g_cow_panic[cow] > 0.0) speed = COW_PANIC_SPEED;
    if (in_water) speed = speed * WATER_SPEED_FACTOR;

    // Don't walk off a drop of more than one block or into water
    ahead_x = Floor(x + dir_x * 0.9);
    ahead_z = Floor(z + dir_z * 0.9);
    foot_y  = Floor(y + 0.1);
    if (!in_water && g_cow_on_ground[cow]) {
      if (!world_is_solid(ahead_x, foot_y - 1, ahead_z) && !world_is_solid(ahead_x, foot_y - 2, ahead_z)) {
        speed = 0.0;
        g_cow_goal_yaw[cow] = g_cow_yaw[cow] + PI;
      }
      if (world_get_block(ahead_x, foot_y - 1, ahead_z) == BLOCK_WATER) {
        if (!world_is_solid(ahead_x, foot_y - 1, ahead_z)) {
          speed = 0.0;
          g_cow_goal_yaw[cow] = g_cow_yaw[cow] + PI;
        }
      }
    }
    g_cow_step[cow] = g_cow_step[cow] + dt * speed * 3.0;
  }

  // Knock-back fades away
  g_cow_push_x[cow] = g_cow_push_x[cow] * (1.0 - min_real(1.0, dt * 4.0));
  g_cow_push_z[cow] = g_cow_push_z[cow] * (1.0 - min_real(1.0, dt * 4.0));

  move_x = (dir_x * speed + g_cow_push_x[cow]) * dt;
  move_z = (dir_z * speed + g_cow_push_z[cow]) * dt;

  if (in_water) {
    g_cow_vy[cow] = g_cow_vy[cow] + (2.0 - g_cow_vy[cow]) * min_real(1.0, dt * 3.0);
  } else {
    g_cow_vy[cow] = g_cow_vy[cow] - GRAVITY * dt;
    if (g_cow_vy[cow] < -TERMINAL_SPEED) g_cow_vy[cow] = -TERMINAL_SPEED;
  }
  fall = g_cow_vy[cow] * dt;

  steps = 1 + Floor(max_real(Absolute(fall), max_real(Absolute(move_x), Absolute(move_z))) / MAX_MOVE_STEP);
  g_cow_on_ground[cow] = FALSE;
  for (step = 1; step <= steps; ++step) {
    physics_move_box(x, y, z, COW_HALF_WIDTH, COW_HEIGHT, move_x / steps, fall / steps, move_z / steps);
    if (g_hit_down) {
      g_cow_on_ground[cow] = TRUE;
      g_cow_vy[cow] = 0.0;
    }
    if (g_hit_up) g_cow_vy[cow] = 0.0;
    if (g_hit_x || g_hit_z) blocked = TRUE;
  }

  // Walked into a wall: hop if there is room above, else turn away
  if (blocked && g_cow_walking[cow]) {
    if (g_cow_on_ground[cow] && !world_is_solid(floor_integer(x + dir_x * 0.9), floor_integer(y + 1.1), floor_integer(z + dir_z * 0.9))) {
      g_cow_vy[cow] = COW_JUMP_SPEED;
    } else {
      g_cow_goal_yaw[cow] = g_cow_yaw[cow] + PI * 0.5 + random_real() * PI;
    }
  }

  g_cow_x[cow] = x;
  g_cow_y[cow] = y;
  g_cow_z[cow] = z;
}

void cows_update(Real dt)
// ----------------------------------------------------------------
// Move every cow near the player and top the herd back up now and
// then, away from where the player can see it happen
// ----------------------------------------------------------------
{
  Integer cow = 0;
  Real    dx  = 0.0;
  Real    dz  = 0.0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!g_cow_alive[cow]) continue;
    dx = g_cow_x[cow] - g_player_x;
    dz = g_cow_z[cow] - g_player_z;
    if (dx * dx + dz * dz > COW_ACTIVE_DISTANCE * COW_ACTIVE_DISTANCE) continue;
    cow_update(cow, dt);
  }

  g_cow_respawn_timer = g_cow_respawn_timer + dt;
  if (g_cow_respawn_timer > COW_RESPAWN_SECONDS) {
    g_cow_respawn_timer = 0.0;
    if (cows_alive_count() < COW_TARGET_COUNT) cows_spawn_random(1, 24.0);
  }
}

Integer cows_ray_hit(Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z, Real max_distance)
// ----------------------------------------------------------------
// Nearest cow the ray hits within max_distance, 0 for none
// g_ray_distance is set to its distance
// ----------------------------------------------------------------
{
  Integer cow      = 0;
  Integer best     = 0;
  Real    distance = 0.0;
  Real    nearest  = max_distance;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!g_cow_alive[cow]) continue;
    distance = physics_ray_box(origin_x, origin_y, origin_z, dir_x, dir_y, dir_z,
                               g_cow_x[cow] - COW_HALF_WIDTH, g_cow_y[cow]             , g_cow_z[cow] - COW_HALF_WIDTH,
                               g_cow_x[cow] + COW_HALF_WIDTH, g_cow_y[cow] + COW_HEIGHT, g_cow_z[cow] + COW_HALF_WIDTH);
    if (distance < 0.0 || distance > nearest) continue;
    nearest = distance;
    best    = cow;
  }

  if (best > 0) g_ray_distance = nearest;
  return best;
}

void cow_damage(Integer cow, Integer amount, Real push_x, Real push_z)
// ----------------------------------------------------------------
// Hurt a cow and knock it back along (push_x, push_z)
// Emits EVT_COW_HURT, or EVT_COW_KILLED when it runs out of health
// ----------------------------------------------------------------
{
  if (cow < 1 || cow > MAX_COWS) return;
  if (!g_cow_alive[cow]) return;

  g_cow_health[cow] = g_cow_health[cow] - amount;
  g_cow_flash [cow] = 0.3;
  g_cow_panic [cow] = 5.0;
  g_cow_timer [cow] = 0.0;
  g_cow_push_x[cow] = push_x * 6.0;
  g_cow_push_z[cow] = push_z * 6.0;
  if (g_cow_on_ground[cow]) g_cow_vy[cow] = 4.5;

  if (g_cow_health[cow] <= 0) {
    g_cow_alive[cow] = FALSE;
    emit_event(EVT_COW_KILLED, cow, 0, 0, 0, g_cow_x[cow], g_cow_y[cow] + 0.6, g_cow_z[cow], "");
  } else {
    emit_event(EVT_COW_HURT, cow, 0, 0, 0, g_cow_x[cow], g_cow_y[cow], g_cow_z[cow], "");
  }
}

Integer cows_box_overlaps(Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z)
// ----------------------------------------------------------------
// TRUE if any cow overlaps the box (blocks can't be placed there)
// ----------------------------------------------------------------
{
  Integer cow = 0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!g_cow_alive[cow]) continue;
    if (g_cow_x[cow] + COW_HALF_WIDTH <= min_x || g_cow_x[cow] - COW_HALF_WIDTH >= max_x) continue;
    if (g_cow_z[cow] + COW_HALF_WIDTH <= min_z || g_cow_z[cow] - COW_HALF_WIDTH >= max_z) continue;
    if (g_cow_y[cow] + COW_HEIGHT     <= min_y || g_cow_y[cow]                  >= max_y) continue;
    return TRUE;
  }
  return FALSE;
}

#endif
