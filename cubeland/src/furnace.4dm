#ifndef FURNACE_4DM_INCLUDED
#define FURNACE_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/records.h"
#include "../include/blocks.h"
#include "../include/events.h"
#include "../include/inventory.h"
#include "../include/furnace.h"

// ---------------------------------------------------------------- accessors

void furnaces_clear(Attributes &furnaces)
// ----------------------------------------------------------------
// Forget every furnace
// ----------------------------------------------------------------
{
  Integer furnace = 0;

  record_clear(furnaces, DATATYPE_FURNACES);
  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) record_set_integer_at(furnaces, ATTR_USED, furnace, FALSE);
}

Integer furnace_slot(Integer furnace, Integer which)
// ----------------------------------------------------------------
// Container slot number of slot which (FURNACE_SLOT_*) of a furnace
// ----------------------------------------------------------------
{
  return (furnace - 1) * FURNACE_SLOTS + which;
}

Integer furnace_used(Attributes &furnaces, Integer furnace)
// ----------------------------------------------------------------
// TRUE if furnace number furnace exists
// ----------------------------------------------------------------
{
  if (furnace < 1 || furnace > MAX_FURNACES) return FALSE;
  return record_integer_at(furnaces, ATTR_USED, furnace);
}

void furnace_cell(Attributes &furnaces, Integer furnace, Integer &x, Integer &y, Integer &z)
// ----------------------------------------------------------------
// Block cell of a furnace
// ----------------------------------------------------------------
{
  x = record_integer_at(furnaces, ATTR_X, furnace);
  y = record_integer_at(furnaces, ATTR_Y, furnace);
  z = record_integer_at(furnaces, ATTR_Z, furnace);
}

Real furnace_burn_left(Attributes &furnaces, Integer furnace)
// ----------------------------------------------------------------
// Seconds of fuel left burning
// ----------------------------------------------------------------
{
  return record_real_at(furnaces, ATTR_FURNACE_BURN, furnace);
}

Real furnace_burn_total(Attributes &furnaces, Integer furnace)
// ----------------------------------------------------------------
// Seconds the current piece of fuel burns for in all
// ----------------------------------------------------------------
{
  return record_real_at(furnaces, ATTR_FURNACE_BURN_TOTAL, furnace);
}

Real furnace_progress(Attributes &furnaces, Integer furnace)
// ----------------------------------------------------------------
// Seconds the current input item has been cooking
// ----------------------------------------------------------------
{
  return record_real_at(furnaces, ATTR_FURNACE_PROGRESS, furnace);
}

void furnace_set_state(Attributes &furnaces, Integer furnace, Real burn_left, Real burn_total, Real progress)
// ----------------------------------------------------------------
// Set the burning and cooking state of a furnace
// ----------------------------------------------------------------
{
  record_set_real_at(furnaces, ATTR_FURNACE_BURN,       furnace, burn_left);
  record_set_real_at(furnaces, ATTR_FURNACE_BURN_TOTAL, furnace, burn_total);
  record_set_real_at(furnaces, ATTR_FURNACE_PROGRESS,   furnace, progress);
}

// ---------------------------------------------------------------- furnaces

Integer furnace_find(Attributes &furnaces, Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Number of the furnace at a cell, 0 if there isn't one
// ----------------------------------------------------------------
{
  Integer furnace = 0;
  Integer fx      = 0;
  Integer fy      = 0;
  Integer fz      = 0;

  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (!furnace_used(furnaces, furnace)) continue;
    furnace_cell(furnaces, furnace, fx, fy, fz);
    if (fx == x && fy == y && fz == z) return furnace;
  }
  return 0;
}

Integer furnace_get_or_create(Attributes &furnaces, Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Number of the furnace at a cell, making an empty one if needed
// Returns 0 if every furnace number is taken
// ----------------------------------------------------------------
{
  Integer furnace = furnace_find(furnaces, x, y, z);
  Integer which   = 0;

  if (furnace > 0) return furnace;

  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (furnace_used(furnaces, furnace)) continue;
    record_set_integer_at(furnaces, ATTR_USED, furnace, TRUE);
    record_set_integer_at(furnaces, ATTR_X,    furnace, x);
    record_set_integer_at(furnaces, ATTR_Y,    furnace, y);
    record_set_integer_at(furnaces, ATTR_Z,    furnace, z);
    for (which = 1; which <= FURNACE_SLOTS; ++which) slot_clear(furnaces, furnace_slot(furnace, which));
    furnace_set_state(furnaces, furnace, 0.0, 0.0, 0.0);
    return furnace;
  }
  return 0;
}

void furnace_remove(Attributes &furnaces, Attributes &events, Integer furnace)
// ----------------------------------------------------------------
// The furnace block is gone: drop whatever it held and free it
// ----------------------------------------------------------------
{
  Integer which = 0;
  Integer slot  = 0;
  Integer x     = 0;
  Integer y     = 0;
  Integer z     = 0;

  if (!furnace_used(furnaces, furnace)) return;

  furnace_cell(furnaces, furnace, x, y, z);
  for (which = 1; which <= FURNACE_SLOTS; ++which) {
    slot = furnace_slot(furnace, which);
    if (!slot_is_empty(furnaces, slot)) {
      emit_drop_event(events, slot_item(furnaces, slot), slot_count(furnaces, slot), slot_damage(furnaces, slot), x + 0.5, y + 0.5, z + 0.5);
    }
    slot_clear(furnaces, slot);
  }

  record_set_integer_at(furnaces, ATTR_USED, furnace, FALSE);
}

Integer furnace_is_lit(Attributes &furnaces, Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// TRUE if the furnace at a cell is burning fuel
// ----------------------------------------------------------------
{
  Integer furnace = furnace_find(furnaces, x, y, z);

  if (furnace == 0) return FALSE;
  if (furnace_burn_left(furnaces, furnace) > 0.0) return TRUE;
  return FALSE;
}

Integer furnace_can_cook(Attributes &furnaces, Integer furnace)
// ----------------------------------------------------------------
// TRUE if the input can be cooked and the output has room for it
// ----------------------------------------------------------------
{
  Integer input  = furnace_slot(furnace, FURNACE_SLOT_INPUT);
  Integer output = furnace_slot(furnace, FURNACE_SLOT_OUTPUT);
  Integer result = ITEM_NONE;

  if (slot_is_empty(furnaces, input)) return FALSE;

  result = item_smelt_result(slot_item(furnaces, input));
  if (result == ITEM_NONE) return FALSE;
  if (slot_is_empty(furnaces, output)) return TRUE;
  if (slot_item(furnaces, output) != result) return FALSE;
  if (slot_count(furnaces, output) >= item_max_stack(result)) return FALSE;
  return TRUE;
}

void furnace_step(Attributes &furnaces, Integer furnace, Real dt)
// ----------------------------------------------------------------
// Advance one furnace by dt seconds (dt should be small)
// A new piece of fuel is only lit when there is something to cook
// ----------------------------------------------------------------
{
  Integer can_cook   = furnace_can_cook(furnaces, furnace);
  Integer input      = furnace_slot(furnace, FURNACE_SLOT_INPUT);
  Integer fuel_slot  = furnace_slot(furnace, FURNACE_SLOT_FUEL);
  Integer output     = furnace_slot(furnace, FURNACE_SLOT_OUTPUT);
  Real    burn_left  = furnace_burn_left (furnaces, furnace);
  Real    burn_total = furnace_burn_total(furnaces, furnace);
  Real    progress   = furnace_progress  (furnaces, furnace);
  Integer fuel       = 0;
  Integer result     = 0;

  if (burn_left <= 0.0 && can_cook && !slot_is_empty(furnaces, fuel_slot)) {
    fuel = item_fuel_seconds(slot_item(furnaces, fuel_slot));
    if (fuel > 0) {
      burn_left  = fuel;
      burn_total = fuel;
      slot_take_one(furnaces, fuel_slot);
    }
  }

  if (burn_left > 0.0) {
    burn_left = burn_left - dt;
    if (burn_left < 0.0) burn_left = 0.0;

    if (can_cook) {
      progress = progress + dt;
      if (progress >= COOK_SECONDS) {
        progress = 0.0;
        result   = item_smelt_result(slot_item(furnaces, input));
        slot_set     (furnaces, output, result, slot_count(furnaces, output) + 1, 0);
        slot_take_one(furnaces, input);
      }
    } else {
      progress = 0.0;
    }
  } else {
    // Cools down without fuel
    progress = progress - dt * 2.0;
    if (progress < 0.0) progress = 0.0;
  }

  furnace_set_state(furnaces, furnace, burn_left, burn_total, progress);
}

void furnaces_update(Attributes &furnaces, Real dt)
// ----------------------------------------------------------------
// Advance every furnace by dt seconds, in small steps so a long
// gap between frames (paused game) still cooks correctly
// ----------------------------------------------------------------
{
  Integer furnace   = 0;
  Real    remaining = dt;
  Real    step      = 0.0;

  if (remaining > 3600.0) remaining = 3600.0;

  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (!furnace_used(furnaces, furnace)) continue;
    remaining = dt;
    if (remaining > 3600.0) remaining = 3600.0;
    while (remaining > 0.0) {
      step = remaining;
      if (step > 0.5) step = 0.5;
      remaining = remaining - step;
      furnace_step(furnaces, furnace, step);
    }
  }
}

void furnace_on_event(Attributes &event, Attributes &furnaces, Attributes &events)
// ----------------------------------------------------------------
// Event handler: furnaces appear and disappear with their blocks
// ----------------------------------------------------------------
{
  Integer type  = event_type(event);
  Integer x     = event_integer(event, 1);
  Integer y     = event_integer(event, 2);
  Integer z     = event_integer(event, 3);
  Integer block = event_integer(event, 4);

  if (!block_is_furnace(block)) return;

  if (type == EVT_BLOCK_PLACED) {
    furnace_get_or_create(furnaces, x, y, z);
  } else if (type == EVT_BLOCK_BROKEN) {
    furnace_remove(furnaces, events, furnace_find(furnaces, x, y, z));
  }
}

#endif
