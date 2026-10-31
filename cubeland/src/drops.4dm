#ifndef DROPS_4DM_INCLUDED
#define DROPS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/physics.h"
#include "../include/inventory.h"
#include "../include/player.h"
#include "../include/drops.h"

void drops_clear()
// ----------------------------------------------------------------
// Remove every dropped item
// ----------------------------------------------------------------
{
  Integer drop = 0;

  for (drop = 1; drop <= MAX_DROPS; ++drop) g_drop_used[drop] = FALSE;
}

Integer drops_spawn(Integer item, Integer count, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Drop a stack centred on (x, y, z) with a little pop upwards
// If every slot is in use the oldest drop is replaced
// Returns the drop's index
// ----------------------------------------------------------------
{
  Integer drop   = 0;
  Integer chosen = 0;
  Real    oldest = -1.0;

  if (item == ITEM_NONE || count <= 0) return 0;

  for (drop = 1; drop <= MAX_DROPS; ++drop) {
    if (!g_drop_used[drop]) {
      chosen = drop;
      break;
    }
    if (g_drop_age[drop] > oldest) {
      oldest = g_drop_age[drop];
      chosen = drop;
    }
  }

  g_drop_used [chosen] = TRUE;
  g_drop_item [chosen] = item;
  g_drop_count[chosen] = count;
  g_drop_x    [chosen] = x;
  g_drop_y    [chosen] = y - DROP_HALF_SIZE;
  g_drop_z    [chosen] = z;
  g_drop_vx   [chosen] = (random_real() - 0.5) * 2.0;
  g_drop_vy   [chosen] = 3.5 + random_real() * 1.5;
  g_drop_vz   [chosen] = (random_real() - 0.5) * 2.0;
  g_drop_age  [chosen] = 0.0;

  return chosen;
}

void drops_update(Real dt)
// ----------------------------------------------------------------
// Drops fall, slide to a stop, drift towards a nearby player and
// are picked up when close enough. Emits EVT_ITEM_PICKED_UP.
// ----------------------------------------------------------------
{
  Integer drop     = 0;
  Integer left     = 0;
  Integer steps    = 0;
  Integer step     = 0;
  Real    x        = 0.0;
  Real    y        = 0.0;
  Real    z        = 0.0;
  Real    dx       = 0.0;
  Real    dy       = 0.0;
  Real    dz       = 0.0;
  Real    distance = 0.0;
  Real    friction = 0.0;
  Real    longest  = 0.0;

  for (drop = 1; drop <= MAX_DROPS; ++drop) {
    if (!g_drop_used[drop]) continue;

    g_drop_age[drop] = g_drop_age[drop] + dt;
    if (g_drop_age[drop] > DROP_LIFETIME) {
      g_drop_used[drop] = FALSE;
      continue;
    }

    x = g_drop_x[drop];
    y = g_drop_y[drop];
    z = g_drop_z[drop];

    // Pull towards the player once it can be picked up
    dx = g_player_x - x;
    dy = g_player_y + 0.9 - (y + DROP_HALF_SIZE);
    dz = g_player_z - z;
    distance = Sqrt(dx * dx + dy * dy + dz * dz);
    if (!g_player_dead && g_drop_age[drop] > DROP_PICKUP_DELAY && distance < DROP_PULL_DISTANCE && distance > 0.01) {
      g_drop_vx[drop] = dx / distance * 5.0;
      g_drop_vz[drop] = dz / distance * 5.0;
      if (dy > 0.3) g_drop_vy[drop] = max_real(g_drop_vy[drop], 2.0);
    }

    if (physics_box_in_water(x, y, z, DROP_HALF_SIZE, DROP_HALF_SIZE * 2.0)) {
      g_drop_vy[drop] = g_drop_vy[drop] + (1.0 - g_drop_vy[drop]) * min_real(1.0, dt * 3.0);
    } else {
      g_drop_vy[drop] = g_drop_vy[drop] - GRAVITY * 0.7 * dt;
      if (g_drop_vy[drop] < -TERMINAL_SPEED) g_drop_vy[drop] = -TERMINAL_SPEED;
    }

    longest = max_real(Absolute(g_drop_vy[drop]), max_real(Absolute(g_drop_vx[drop]), Absolute(g_drop_vz[drop]))) * dt;
    steps   = 1 + Floor(longest / MAX_MOVE_STEP);
    for (step = 1; step <= steps; ++step) {
      physics_move_box(x, y, z, DROP_HALF_SIZE, DROP_HALF_SIZE * 2.0,
                       g_drop_vx[drop] * dt / steps, g_drop_vy[drop] * dt / steps, g_drop_vz[drop] * dt / steps);
      if (g_hit_down || g_hit_up) g_drop_vy[drop] = 0.0;
      if (g_hit_x) g_drop_vx[drop] = 0.0;
      if (g_hit_z) g_drop_vz[drop] = 0.0;
    }
    if (g_hit_down) {
      friction = 1.0 - min_real(1.0, dt * 8.0);
      g_drop_vx[drop] = g_drop_vx[drop] * friction;
      g_drop_vz[drop] = g_drop_vz[drop] * friction;
    }

    g_drop_x[drop] = x;
    g_drop_y[drop] = y;
    g_drop_z[drop] = z;

    if (g_player_dead) continue;
    if (g_drop_age[drop] <= DROP_PICKUP_DELAY) continue;
    if (distance > DROP_PICKUP_DISTANCE) continue;

    left = inventory_add(g_drop_item[drop], g_drop_count[drop]);
    if (left < g_drop_count[drop]) {
      emit_item_event(EVT_ITEM_PICKED_UP, g_drop_item[drop], g_drop_count[drop] - left);
    }
    g_drop_count[drop] = left;
    if (left <= 0) g_drop_used[drop] = FALSE;
  }
}

void drops_on_event()
// ----------------------------------------------------------------
// Event handler: broken blocks and killed cows leave items behind,
// and anyone can ask for a drop with EVT_SPAWN_DROP
// ----------------------------------------------------------------
{
  Integer item = ITEM_NONE;

  if (g_ev_type == EVT_BLOCK_BROKEN) {
    item = block_drop_item(g_ev_i4);
    if (item != ITEM_NONE) drops_spawn(item, 1, g_ev_i1 + 0.5, g_ev_i2 + 0.5, g_ev_i3 + 0.5);
  } else if (g_ev_type == EVT_COW_KILLED) {
    drops_spawn(ITEM_RAW_BEEF, random_integer(1, 3), g_ev_r1, g_ev_r2, g_ev_r3);
  } else if (g_ev_type == EVT_SPAWN_DROP) {
    drops_spawn(g_ev_i1, g_ev_i2, g_ev_r1, g_ev_r2, g_ev_r3);
  }
}

#endif
