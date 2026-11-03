#ifndef DROPS_4DM_INCLUDED
#define DROPS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/physics.h"
#include "../include/inventory.h"
#include "../include/drops.h"

// ---------------------------------------------------------------- accessors

void drops_clear(Attributes &drops)
// ----------------------------------------------------------------
// Remove every dropped item
// ----------------------------------------------------------------
{
  Integer drop = 0;

  record_clear(drops, DATATYPE_DROPS);
  for (drop = 1; drop <= MAX_DROPS; ++drop) record_set_integer_at(drops, ATTR_USED, drop, FALSE);
}

Integer drop_used(Attributes &drops, Integer drop)
// ----------------------------------------------------------------
// TRUE if drop number drop is lying in the world
// ----------------------------------------------------------------
{
  return record_integer_at(drops, ATTR_USED, drop);
}

Integer drop_item(Attributes &drops, Integer drop)
// ----------------------------------------------------------------
// Item of a drop
// ----------------------------------------------------------------
{
  return record_integer_at(drops, ATTR_ITEM, drop);
}

Integer drop_count(Attributes &drops, Integer drop)
// ----------------------------------------------------------------
// Number of items in a drop
// ----------------------------------------------------------------
{
  return record_integer_at(drops, ATTR_COUNT, drop);
}

Integer drop_damage(Attributes &drops, Integer drop)
// ----------------------------------------------------------------
// Wear of a dropped tool
// ----------------------------------------------------------------
{
  return record_integer_at(drops, ATTR_DAMAGE, drop);
}

Real drop_age(Attributes &drops, Integer drop)
// ----------------------------------------------------------------
// Seconds since the drop appeared
// ----------------------------------------------------------------
{
  return record_real_at(drops, ATTR_AGE, drop);
}

void drop_position(Attributes &drops, Integer drop, Real &x, Real &y, Real &z)
// ----------------------------------------------------------------
// Centre of the bottom of a drop
// ----------------------------------------------------------------
{
  x = record_real_at(drops, ATTR_X, drop);
  y = record_real_at(drops, ATTR_Y, drop);
  z = record_real_at(drops, ATTR_Z, drop);
}

// ---------------------------------------------------------------- behaviour

Integer drops_restore(Attributes &drops, Integer item, Integer count, Integer damage, Real x, Real y, Real z, Real age)
// ----------------------------------------------------------------
// Put a stack down at rest with its bottom at (x, y, z). If every
// drop number is in use the oldest drop is replaced. Returns the
// drop's number.
// ----------------------------------------------------------------
{
  Integer drop   = 0;
  Integer chosen = 0;
  Real    oldest = -1.0;

  if (item == ITEM_NONE || count <= 0) return 0;

  for (drop = 1; drop <= MAX_DROPS; ++drop) {
    if (!drop_used(drops, drop)) {
      chosen = drop;
      break;
    }
    if (drop_age(drops, drop) > oldest) {
      oldest = drop_age(drops, drop);
      chosen = drop;
    }
  }

  record_set_integer_at(drops, ATTR_USED,   chosen, TRUE);
  record_set_integer_at(drops, ATTR_ITEM,   chosen, item);
  record_set_integer_at(drops, ATTR_COUNT,  chosen, count);
  record_set_integer_at(drops, ATTR_DAMAGE, chosen, damage);
  record_set_real_at   (drops, ATTR_X,      chosen, x);
  record_set_real_at   (drops, ATTR_Y,      chosen, y);
  record_set_real_at   (drops, ATTR_Z,      chosen, z);
  record_set_real_at   (drops, ATTR_VX,     chosen, 0.0);
  record_set_real_at   (drops, ATTR_VY,     chosen, 0.0);
  record_set_real_at   (drops, ATTR_VZ,     chosen, 0.0);
  record_set_real_at   (drops, ATTR_AGE,    chosen, age);

  return chosen;
}

Integer drops_spawn(Attributes &drops, Attributes &random, Integer item, Integer count, Integer damage, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Drop a stack centred on (x, y, z) with a little pop upwards
// Returns the drop's number
// ----------------------------------------------------------------
{
  Integer drop = drops_restore(drops, item, count, damage, x, y - DROP_HALF_SIZE, z, 0.0);

  if (drop == 0) return 0;

  record_set_real_at(drops, ATTR_VX, drop, random_between(random, -1.0, 1.0));
  record_set_real_at(drops, ATTR_VY, drop, random_between(random, 3.5, 5.0));
  record_set_real_at(drops, ATTR_VZ, drop, random_between(random, -1.0, 1.0));

  return drop;
}

void drops_update(Attributes &drops, Attributes &inventory, Attributes &events,
                  Real player_x, Real player_y, Real player_z, Integer player_dead, Real dt)
// ----------------------------------------------------------------
// Drops fall, slide to a stop, drift towards a nearby player and
// are picked up when close enough. Emits EVT_ITEM_PICKED_UP.
// ----------------------------------------------------------------
{
  Integer drop     = 0;
  Integer item     = 0;
  Integer count    = 0;
  Integer left     = 0;
  Integer steps    = 0;
  Integer step     = 0;
  Integer hit_x    = FALSE;
  Integer hit_z    = FALSE;
  Integer hit_down = FALSE;
  Integer hit_up   = FALSE;
  Integer landed   = FALSE;
  Real    age      = 0.0;
  Real    x        = 0.0;
  Real    y        = 0.0;
  Real    z        = 0.0;
  Real    vx       = 0.0;
  Real    vy       = 0.0;
  Real    vz       = 0.0;
  Real    dx       = 0.0;
  Real    dy       = 0.0;
  Real    dz       = 0.0;
  Real    distance = 0.0;
  Real    friction = 0.0;
  Real    longest  = 0.0;

  for (drop = 1; drop <= MAX_DROPS; ++drop) {
    if (!drop_used(drops, drop)) continue;

    age = drop_age(drops, drop) + dt;
    if (age > DROP_LIFETIME) {
      record_set_integer_at(drops, ATTR_USED, drop, FALSE);
      continue;
    }

    drop_position(drops, drop, x, y, z);
    vx = record_real_at(drops, ATTR_VX, drop);
    vy = record_real_at(drops, ATTR_VY, drop);
    vz = record_real_at(drops, ATTR_VZ, drop);

    // Pull towards the player once it can be picked up
    dx = player_x - x;
    dy = player_y + 0.9 - (y + DROP_HALF_SIZE);
    dz = player_z - z;
    distance = Sqrt(dx * dx + dy * dy + dz * dz);
    if (!player_dead && age > DROP_PICKUP_DELAY && distance < DROP_PULL_DISTANCE && distance > 0.01) {
      vx = dx / distance * 5.0;
      vz = dz / distance * 5.0;
      if (dy > 0.3) vy = max_real(vy, 2.0);
    }

    if (physics_box_in_water(x, y, z, DROP_HALF_SIZE, DROP_HALF_SIZE * 2.0)) {
      vy = vy + (1.0 - vy) * min_real(1.0, dt * 3.0);
    } else {
      vy = vy - GRAVITY * 0.7 * dt;
      if (vy < -TERMINAL_SPEED) vy = -TERMINAL_SPEED;
    }

    landed  = FALSE;
    longest = max_real(Absolute(vy), max_real(Absolute(vx), Absolute(vz))) * dt;
    steps   = 1 + Floor(longest / MAX_MOVE_STEP);
    for (step = 1; step <= steps; ++step) {
      physics_move_box(x, y, z, DROP_HALF_SIZE, DROP_HALF_SIZE * 2.0, vx * dt / steps, vy * dt / steps, vz * dt / steps,
                       hit_x, hit_z, hit_down, hit_up);
      if (hit_down || hit_up) vy = 0.0;
      if (hit_x) vx = 0.0;
      if (hit_z) vz = 0.0;
      if (hit_down) landed = TRUE;
    }
    if (landed) {
      friction = 1.0 - min_real(1.0, dt * 8.0);
      vx = vx * friction;
      vz = vz * friction;
    }

    record_set_real_at(drops, ATTR_X,   drop, x);
    record_set_real_at(drops, ATTR_Y,   drop, y);
    record_set_real_at(drops, ATTR_Z,   drop, z);
    record_set_real_at(drops, ATTR_VX,  drop, vx);
    record_set_real_at(drops, ATTR_VY,  drop, vy);
    record_set_real_at(drops, ATTR_VZ,  drop, vz);
    record_set_real_at(drops, ATTR_AGE, drop, age);

    if (player_dead) continue;
    if (age <= DROP_PICKUP_DELAY) continue;
    if (distance > DROP_PICKUP_DISTANCE) continue;

    item  = drop_item (drops, drop);
    count = drop_count(drops, drop);
    left  = inventory_add_worn(inventory, item, count, drop_damage(drops, drop));
    if (left < count) emit_item_event(events, EVT_ITEM_PICKED_UP, item, count - left);
    record_set_integer_at(drops, ATTR_COUNT, drop, left);
    if (left <= 0) record_set_integer_at(drops, ATTR_USED, drop, FALSE);
  }
}

void drops_on_event(Attributes &event, Attributes &drops, Attributes &random)
// ----------------------------------------------------------------
// Event handler: broken blocks (depending on the tool used) and
// killed cows leave items behind, and anyone can ask for a drop
// with EVT_SPAWN_DROP
// ----------------------------------------------------------------
{
  Integer type = event_type(event);
  Integer item = ITEM_NONE;
  Integer tool = 0;

  if (type == EVT_BLOCK_BROKEN) {
    tool = floor_integer(event_real(event, 1) + 0.5);
    item = block_drop_item(event_integer(event, 4), tool);
    if (item != ITEM_NONE) {
      drops_spawn(drops, random, item, 1, 0, event_integer(event, 1) + 0.5, event_integer(event, 2) + 0.5, event_integer(event, 3) + 0.5);
    }
  } else if (type == EVT_COW_KILLED) {
    drops_spawn(drops, random, ITEM_RAW_BEEF, random_range(random, 1, 3), 0, event_real(event, 1), event_real(event, 2), event_real(event, 3));
  } else if (type == EVT_SPAWN_DROP) {
    drops_spawn(drops, random, event_integer(event, 1), event_integer(event, 2), event_integer(event, 3),
                event_real(event, 1), event_real(event, 2), event_real(event, 3));
  }
}

#endif
