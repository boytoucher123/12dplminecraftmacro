#ifndef INVENTORY_4DM_INCLUDED
#define INVENTORY_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/blocks.h"
#include "../include/events.h"
#include "../include/inventory.h"

void inventory_clear()
// ----------------------------------------------------------------
// Empty every slot and the cursor
// ----------------------------------------------------------------
{
  Integer slot = 0;

  for (slot = 1; slot <= INVENTORY_SLOTS; ++slot) {
    g_inv_item [slot] = ITEM_NONE;
    g_inv_count[slot] = 0;
  }
  g_cursor_item  = ITEM_NONE;
  g_cursor_count = 0;
}

Integer inventory_add(Integer item, Integer count)
// ----------------------------------------------------------------
// Put items into the inventory: first topping up stacks of the
// same item, then into empty slots (hotbar first)
// Returns how many did not fit
// ----------------------------------------------------------------
{
  Integer left  = count;
  Integer slot  = 0;
  Integer space = 0;
  Integer moved = 0;

  if (item == ITEM_NONE || count <= 0) return 0;

  for (slot = 1; slot <= INVENTORY_SLOTS; ++slot) {
    if (left <= 0) break;
    if (g_inv_item[slot] != item) continue;
    space = MAX_STACK - g_inv_count[slot];
    if (space <= 0) continue;
    moved = left;
    if (moved > space) moved = space;
    g_inv_count[slot] = g_inv_count[slot] + moved;
    left = left - moved;
  }

  for (slot = 1; slot <= INVENTORY_SLOTS; ++slot) {
    if (left <= 0) break;
    if (g_inv_item[slot] != ITEM_NONE) continue;
    moved = left;
    if (moved > MAX_STACK) moved = MAX_STACK;
    g_inv_item [slot] = item;
    g_inv_count[slot] = moved;
    left = left - moved;
  }

  return left;
}

Integer inventory_count_item(Integer item)
// ----------------------------------------------------------------
// Total number of an item across all slots
// ----------------------------------------------------------------
{
  Integer slot  = 0;
  Integer total = 0;

  for (slot = 1; slot <= INVENTORY_SLOTS; ++slot) {
    if (g_inv_item[slot] == item) total = total + g_inv_count[slot];
  }
  return total;
}

Integer inventory_remove_item(Integer item, Integer count)
// ----------------------------------------------------------------
// Take count of an item out of the inventory, from the last slots
// first so the hotbar is used up last
// Returns FALSE (and removes nothing) if there are not enough
// ----------------------------------------------------------------
{
  Integer left  = count;
  Integer slot  = 0;
  Integer taken = 0;

  if (inventory_count_item(item) < count) return FALSE;

  for (slot = INVENTORY_SLOTS; slot >= 1; --slot) {
    if (left <= 0) break;
    if (g_inv_item[slot] != item) continue;
    taken = left;
    if (taken > g_inv_count[slot]) taken = g_inv_count[slot];
    g_inv_count[slot] = g_inv_count[slot] - taken;
    left = left - taken;
    if (g_inv_count[slot] <= 0) {
      g_inv_item [slot] = ITEM_NONE;
      g_inv_count[slot] = 0;
    }
  }
  return TRUE;
}

void inventory_take_one(Integer slot)
// ----------------------------------------------------------------
// Use up one item from a slot (placing a block, eating)
// ----------------------------------------------------------------
{
  if (slot < 1 || slot > INVENTORY_SLOTS) return;
  if (g_inv_count[slot] <= 0) return;

  g_inv_count[slot] = g_inv_count[slot] - 1;
  if (g_inv_count[slot] <= 0) {
    g_inv_item [slot] = ITEM_NONE;
    g_inv_count[slot] = 0;
  }
}

void inventory_click_left(Integer take_only)
// ----------------------------------------------------------------
// Left click on the slot held in g_click_item / g_click_count:
//  - empty cursor: pick the whole stack up
//  - same item:    drop as much of the cursor in as fits
//  - otherwise:    swap the cursor and the slot
// take_only slots (furnace output) can only be emptied, and only
// into an empty or matching cursor
// ----------------------------------------------------------------
{
  Integer swap_item  = 0;
  Integer swap_count = 0;
  Integer moved      = 0;

  if (take_only) {
    if (g_click_item == ITEM_NONE) return;
    if (g_cursor_item == ITEM_NONE) {
      g_cursor_item  = g_click_item;
      g_cursor_count = g_click_count;
      g_click_item   = ITEM_NONE;
      g_click_count  = 0;
    } else if (g_cursor_item == g_click_item) {
      moved = MAX_STACK - g_cursor_count;
      if (moved > g_click_count) moved = g_click_count;
      g_cursor_count = g_cursor_count + moved;
      g_click_count  = g_click_count - moved;
      if (g_click_count <= 0) {
        g_click_item  = ITEM_NONE;
        g_click_count = 0;
      }
    }
    return;
  }

  if (g_cursor_item != ITEM_NONE && g_cursor_item == g_click_item) {
    moved = MAX_STACK - g_click_count;
    if (moved > g_cursor_count) moved = g_cursor_count;
    g_click_count  = g_click_count  + moved;
    g_cursor_count = g_cursor_count - moved;
    if (g_cursor_count <= 0) {
      g_cursor_item  = ITEM_NONE;
      g_cursor_count = 0;
    }
    return;
  }

  swap_item      = g_click_item;
  swap_count     = g_click_count;
  g_click_item   = g_cursor_item;
  g_click_count  = g_cursor_count;
  g_cursor_item  = swap_item;
  g_cursor_count = swap_count;
}

void inventory_click_right(Integer take_only)
// ----------------------------------------------------------------
// Right click on the slot in g_click_item / g_click_count:
//  - empty cursor: pick up half the stack (rounded up)
//  - otherwise:    put one item from the cursor into the slot
// ----------------------------------------------------------------
{
  Integer half = 0;

  if (g_cursor_item == ITEM_NONE) {
    if (g_click_item == ITEM_NONE) return;
    half = g_click_count - floor_divide(g_click_count, 2);
    g_cursor_item  = g_click_item;
    g_cursor_count = half;
    g_click_count  = g_click_count - half;
    if (g_click_count <= 0) {
      g_click_item  = ITEM_NONE;
      g_click_count = 0;
    }
    return;
  }

  if (take_only) return;
  if (g_click_item != ITEM_NONE && g_click_item != g_cursor_item) return;
  if (g_click_count >= MAX_STACK) return;

  g_click_item   = g_cursor_item;
  g_click_count  = g_click_count + 1;
  g_cursor_count = g_cursor_count - 1;
  if (g_cursor_count <= 0) {
    g_cursor_item  = ITEM_NONE;
    g_cursor_count = 0;
  }
}

void inventory_return_cursor(Real x, Real y, Real z)
// ----------------------------------------------------------------
// Put the cursor stack back into the inventory when a screen
// closes; anything that does not fit is dropped at (x, y, z)
// ----------------------------------------------------------------
{
  Integer left = 0;

  if (g_cursor_item == ITEM_NONE) return;

  left = inventory_add(g_cursor_item, g_cursor_count);
  if (left > 0) emit_drop_event(g_cursor_item, left, x, y, z);

  g_cursor_item  = ITEM_NONE;
  g_cursor_count = 0;
}

#endif
