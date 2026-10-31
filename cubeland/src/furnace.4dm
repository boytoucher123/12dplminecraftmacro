#ifndef FURNACE_4DM_INCLUDED
#define FURNACE_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/blocks.h"
#include "../include/events.h"
#include "../include/inventory.h"
#include "../include/furnace.h"

void furnaces_clear()
// ----------------------------------------------------------------
// Forget every furnace
// ----------------------------------------------------------------
{
  Integer furnace = 0;

  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) g_furnace_used[furnace] = FALSE;
}

Integer furnace_find(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Index of the furnace at a cell, 0 if there isn't one
// ----------------------------------------------------------------
{
  Integer furnace = 0;

  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (!g_furnace_used[furnace]) continue;
    if (g_furnace_x[furnace] == x && g_furnace_y[furnace] == y && g_furnace_z[furnace] == z) return furnace;
  }
  return 0;
}

Integer furnace_get_or_create(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Index of the furnace at a cell, making an empty one if needed
// Returns 0 if every furnace slot is taken
// ----------------------------------------------------------------
{
  Integer furnace = furnace_find(x, y, z);

  if (furnace > 0) return furnace;

  for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
    if (g_furnace_used[furnace]) continue;
    g_furnace_used      [furnace] = TRUE;
    g_furnace_x         [furnace] = x;
    g_furnace_y         [furnace] = y;
    g_furnace_z         [furnace] = z;
    g_furnace_in_item   [furnace] = ITEM_NONE;
    g_furnace_in_count  [furnace] = 0;
    g_furnace_fuel_item [furnace] = ITEM_NONE;
    g_furnace_fuel_count[furnace] = 0;
    g_furnace_out_item  [furnace] = ITEM_NONE;
    g_furnace_out_count [furnace] = 0;
    g_furnace_burn_left [furnace] = 0.0;
    g_furnace_burn_total[furnace] = 0.0;
    g_furnace_progress  [furnace] = 0.0;
    return furnace;
  }
  return 0;
}

void furnace_remove(Integer furnace)
// ----------------------------------------------------------------
// The furnace block is gone: drop whatever it held and free it
// ----------------------------------------------------------------
{
  Real x = 0.0;
  Real y = 0.0;
  Real z = 0.0;

  if (furnace < 1 || furnace > MAX_FURNACES) return;
  if (!g_furnace_used[furnace]) return;

  x = g_furnace_x[furnace] + 0.5;
  y = g_furnace_y[furnace] + 0.5;
  z = g_furnace_z[furnace] + 0.5;
  if (g_furnace_in_count  [furnace] > 0) emit_drop_event(g_furnace_in_item  [furnace], g_furnace_in_count  [furnace], x, y, z);
  if (g_furnace_fuel_count[furnace] > 0) emit_drop_event(g_furnace_fuel_item[furnace], g_furnace_fuel_count[furnace], x, y, z);
  if (g_furnace_out_count [furnace] > 0) emit_drop_event(g_furnace_out_item [furnace], g_furnace_out_count [furnace], x, y, z);

  g_furnace_used[furnace] = FALSE;
}

Integer furnace_is_lit(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// TRUE if the furnace at a cell is burning fuel
// ----------------------------------------------------------------
{
  Integer furnace = furnace_find(x, y, z);

  if (furnace == 0) return FALSE;
  if (g_furnace_burn_left[furnace] > 0.0) return TRUE;
  return FALSE;
}

Integer furnace_can_cook(Integer furnace)
// ----------------------------------------------------------------
// TRUE if the input can be cooked and the output has room for it
// ----------------------------------------------------------------
{
  Integer result = ITEM_NONE;

  if (g_furnace_in_count[furnace] <= 0) return FALSE;

  result = item_smelt_result(g_furnace_in_item[furnace]);
  if (result == ITEM_NONE) return FALSE;
  if (g_furnace_out_count[furnace] == 0) return TRUE;
  if (g_furnace_out_item[furnace] != result) return FALSE;
  if (g_furnace_out_count[furnace] >= MAX_STACK) return FALSE;
  return TRUE;
}

void furnace_step(Integer furnace, Real dt)
// ----------------------------------------------------------------
// Advance one furnace by dt seconds (dt should be small)
// A new piece of fuel is only lit when there is something to cook
// ----------------------------------------------------------------
{
  Integer can_cook = furnace_can_cook(furnace);
  Integer fuel     = 0;

  if (g_furnace_burn_left[furnace] <= 0.0 && can_cook && g_furnace_fuel_count[furnace] > 0) {
    fuel = item_fuel_seconds(g_furnace_fuel_item[furnace]);
    if (fuel > 0) {
      g_furnace_burn_left [furnace] = fuel;
      g_furnace_burn_total[furnace] = fuel;
      g_furnace_fuel_count[furnace] = g_furnace_fuel_count[furnace] - 1;
      if (g_furnace_fuel_count[furnace] <= 0) {
        g_furnace_fuel_item [furnace] = ITEM_NONE;
        g_furnace_fuel_count[furnace] = 0;
      }
    }
  }

  if (g_furnace_burn_left[furnace] > 0.0) {
    g_furnace_burn_left[furnace] = g_furnace_burn_left[furnace] - dt;
    if (g_furnace_burn_left[furnace] < 0.0) g_furnace_burn_left[furnace] = 0.0;

    if (can_cook) {
      g_furnace_progress[furnace] = g_furnace_progress[furnace] + dt;
      if (g_furnace_progress[furnace] >= COOK_SECONDS) {
        g_furnace_progress[furnace] = 0.0;
        g_furnace_out_item  [furnace] = item_smelt_result(g_furnace_in_item[furnace]);
        g_furnace_out_count [furnace] = g_furnace_out_count[furnace] + 1;
        g_furnace_in_count  [furnace] = g_furnace_in_count[furnace] - 1;
        if (g_furnace_in_count[furnace] <= 0) {
          g_furnace_in_item [furnace] = ITEM_NONE;
          g_furnace_in_count[furnace] = 0;
        }
      }
    } else {
      g_furnace_progress[furnace] = 0.0;
    }
  } else {
    // Cools down without fuel
    g_furnace_progress[furnace] = g_furnace_progress[furnace] - dt * 2.0;
    if (g_furnace_progress[furnace] < 0.0) g_furnace_progress[furnace] = 0.0;
  }
}

void furnaces_update(Real dt)
// ----------------------------------------------------------------
// Advance every furnace by dt seconds, in small steps so a long
// gap between frames (paused game) still cooks correctly
// ----------------------------------------------------------------
{
  Integer furnace   = 0;
  Real    remaining = dt;
  Real    step      = 0.0;

  if (remaining > 3600.0) remaining = 3600.0;

  while (remaining > 0.0) {
    step = remaining;
    if (step > 0.5) step = 0.5;
    remaining = remaining - step;

    for (furnace = 1; furnace <= MAX_FURNACES; ++furnace) {
      if (g_furnace_used[furnace]) furnace_step(furnace, step);
    }
  }
}

void furnace_get_slot(Integer furnace, Integer slot)
// ----------------------------------------------------------------
// Copy a furnace slot into g_click_item / g_click_count
// ----------------------------------------------------------------
{
  g_click_item  = ITEM_NONE;
  g_click_count = 0;

  if (slot == FURNACE_SLOT_INPUT) {
    g_click_item  = g_furnace_in_item  [furnace];
    g_click_count = g_furnace_in_count [furnace];
  } else if (slot == FURNACE_SLOT_FUEL) {
    g_click_item  = g_furnace_fuel_item [furnace];
    g_click_count = g_furnace_fuel_count[furnace];
  } else if (slot == FURNACE_SLOT_OUTPUT) {
    g_click_item  = g_furnace_out_item  [furnace];
    g_click_count = g_furnace_out_count [furnace];
  }
}

void furnace_set_slot(Integer furnace, Integer slot)
// ----------------------------------------------------------------
// Copy g_click_item / g_click_count back into a furnace slot
// ----------------------------------------------------------------
{
  if (slot == FURNACE_SLOT_INPUT) {
    g_furnace_in_item  [furnace] = g_click_item;
    g_furnace_in_count [furnace] = g_click_count;
  } else if (slot == FURNACE_SLOT_FUEL) {
    g_furnace_fuel_item [furnace] = g_click_item;
    g_furnace_fuel_count[furnace] = g_click_count;
  } else if (slot == FURNACE_SLOT_OUTPUT) {
    g_furnace_out_item  [furnace] = g_click_item;
    g_furnace_out_count [furnace] = g_click_count;
  }
}

void furnace_on_event()
// ----------------------------------------------------------------
// Event handler: furnaces appear and disappear with their blocks
// ----------------------------------------------------------------
{
  if (g_ev_type == EVT_BLOCK_PLACED) {
    if (block_is_furnace(g_ev_i4)) furnace_get_or_create(g_ev_i1, g_ev_i2, g_ev_i3);
  } else if (g_ev_type == EVT_BLOCK_BROKEN) {
    if (block_is_furnace(g_ev_i4)) furnace_remove(furnace_find(g_ev_i1, g_ev_i2, g_ev_i3));
  }
}

#endif
