#ifndef INVENTORY_4DM_INCLUDED
#define INVENTORY_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/blocks.h"
#include "../include/events.h"
#include "../include/inventory.h"

// ---------------------------------------------------------------- slots

Integer slot_item(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// Item in a slot, ITEM_NONE if it is empty
// ----------------------------------------------------------------
{
  return record_integer_at(container, ATTR_ITEM, slot);
}

Integer slot_count(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// Number of items in a slot
// ----------------------------------------------------------------
{
  return record_integer_at(container, ATTR_COUNT, slot);
}

Integer slot_damage(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// How many uses the tool in a slot has had
// ----------------------------------------------------------------
{
  return record_integer_at(container, ATTR_DAMAGE, slot);
}

Integer slot_is_empty(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// TRUE if nothing is in a slot
// ----------------------------------------------------------------
{
  if (slot_item(container, slot) == ITEM_NONE) return TRUE;
  if (slot_count(container, slot) <= 0) return TRUE;
  return FALSE;
}

void slot_set(Attributes &container, Integer slot, Integer item, Integer count, Integer damage)
// ----------------------------------------------------------------
// Put a stack into a slot; a count of 0 or less empties it
// ----------------------------------------------------------------
{
  Integer stored_item   = item;
  Integer stored_count  = count;
  Integer stored_damage = damage;

  if (item == ITEM_NONE || count <= 0) {
    stored_item   = ITEM_NONE;
    stored_count  = 0;
    stored_damage = 0;
  }
  record_set_integer_at(container, ATTR_ITEM,   slot, stored_item);
  record_set_integer_at(container, ATTR_COUNT,  slot, stored_count);
  record_set_integer_at(container, ATTR_DAMAGE, slot, stored_damage);
}

void slot_clear(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// Empty a slot
// ----------------------------------------------------------------
{
  slot_set(container, slot, ITEM_NONE, 0, 0);
}

void slot_take_one(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// Use up one item from a slot (placing a block, eating)
// ----------------------------------------------------------------
{
  slot_set(container, slot, slot_item(container, slot), slot_count(container, slot) - 1, slot_damage(container, slot));
}

Integer slot_wear(Attributes &container, Integer slot)
// ----------------------------------------------------------------
// Use a tool in a slot once. Returns TRUE if that wore it out (the
// slot is then empty). Items that don't wear are left alone.
// ----------------------------------------------------------------
{
  Integer item   = slot_item(container, slot);
  Integer uses   = item_max_uses(item);
  Integer damage = slot_damage(container, slot) + 1;

  if (uses <= 0) return FALSE;

  if (damage >= uses) {
    slot_clear(container, slot);
    return TRUE;
  }
  record_set_integer_at(container, ATTR_DAMAGE, slot, damage);

  return FALSE;
}

void slot_click_left(Attributes &holder, Attributes &container, Integer slot, Integer take_only)
// ----------------------------------------------------------------
// Left click on a slot of container while holder's cursor slot
// holds what the mouse carries:
//  - empty cursor: pick the whole stack up
//  - same item:    drop as much of the cursor in as fits
//  - otherwise:    swap the cursor and the slot
// take_only slots (outputs) can only be emptied, and only into an
// empty or matching cursor
// ----------------------------------------------------------------
{
  Integer cursor_item   = slot_item  (holder, CURSOR_SLOT);
  Integer cursor_count  = slot_count (holder, CURSOR_SLOT);
  Integer cursor_damage = slot_damage(holder, CURSOR_SLOT);
  Integer item          = slot_item  (container, slot);
  Integer count         = slot_count (container, slot);
  Integer damage        = slot_damage(container, slot);
  Integer limit         = item_max_stack(item);
  Integer moved         = 0;

  if (take_only) {
    if (item == ITEM_NONE) return;
    if (cursor_item == ITEM_NONE) {
      slot_set  (holder, CURSOR_SLOT, item, count, damage);
      slot_clear(container, slot);
    } else if (cursor_item == item) {
      moved = limit - cursor_count;
      if (moved > count) moved = count;
      if (moved <= 0) return;
      slot_set(holder,    CURSOR_SLOT, item, cursor_count + moved, cursor_damage);
      slot_set(container, slot,        item, count - moved,        damage);
    }
    return;
  }

  if (cursor_item != ITEM_NONE && cursor_item == item && limit > 1) {
    moved = limit - count;
    if (moved > cursor_count) moved = cursor_count;
    slot_set(container, slot,        item, count + moved,        damage);
    slot_set(holder,    CURSOR_SLOT, item, cursor_count - moved, cursor_damage);
    return;
  }

  slot_set(container, slot,        cursor_item, cursor_count, cursor_damage);
  slot_set(holder,    CURSOR_SLOT, item,        count,        damage);
}

void slot_click_right(Attributes &holder, Attributes &container, Integer slot, Integer take_only)
// ----------------------------------------------------------------
// Right click on a slot of container:
//  - empty cursor: pick up half the stack (rounded up)
//  - otherwise:    put one item from the cursor into the slot
// ----------------------------------------------------------------
{
  Integer cursor_item   = slot_item  (holder, CURSOR_SLOT);
  Integer cursor_count  = slot_count (holder, CURSOR_SLOT);
  Integer cursor_damage = slot_damage(holder, CURSOR_SLOT);
  Integer item          = slot_item  (container, slot);
  Integer count         = slot_count (container, slot);
  Integer damage        = slot_damage(container, slot);
  Integer half          = 0;

  if (cursor_item == ITEM_NONE) {
    if (item == ITEM_NONE) return;
    half = count - floor_divide(count, 2);
    slot_set(holder,    CURSOR_SLOT, item, half,         damage);
    slot_set(container, slot,        item, count - half, damage);
    return;
  }

  if (take_only) return;
  if (item != ITEM_NONE && item != cursor_item) return;
  if (count >= item_max_stack(cursor_item)) return;

  slot_set(container, slot,        cursor_item, count + 1,        cursor_damage);
  slot_set(holder,    CURSOR_SLOT, cursor_item, cursor_count - 1, cursor_damage);
}

void slot_move_all(Attributes &from, Integer from_slot, Attributes &to, Integer first, Integer last)
// ----------------------------------------------------------------
// Move as much of a stack as fits into slots first..last of
// another container (shift-click style); the rest stays put
// ----------------------------------------------------------------
{
  Integer left = container_add(to, first, last, slot_item(from, from_slot), slot_count(from, from_slot), slot_damage(from, from_slot));

  slot_set(from, from_slot, slot_item(from, from_slot), left, slot_damage(from, from_slot));
}

// ---------------------------------------------------------------- containers

void container_clear(Attributes &container, Text datatype, Integer first, Integer last)
// ----------------------------------------------------------------
// Make container an empty record of the given datatype whose slots
// first..last exist and are empty
// ----------------------------------------------------------------
{
  Integer slot = 0;

  record_clear(container, datatype);
  for (slot = first; slot <= last; ++slot) slot_clear(container, slot);
}

Integer container_add(Attributes &container, Integer first, Integer last, Integer item, Integer count, Integer damage)
// ----------------------------------------------------------------
// Put items into slots first..last: first topping up stacks of the
// same item, then into empty slots in order
// Returns how many did not fit
// ----------------------------------------------------------------
{
  Integer left  = count;
  Integer limit = item_max_stack(item);
  Integer slot  = 0;
  Integer space = 0;
  Integer moved = 0;

  if (item == ITEM_NONE || count <= 0) return 0;

  if (limit > 1) {
    for (slot = first; slot <= last; ++slot) {
      if (left <= 0) break;
      if (slot_item(container, slot) != item) continue;
      space = limit - slot_count(container, slot);
      if (space <= 0) continue;
      moved = left;
      if (moved > space) moved = space;
      slot_set(container, slot, item, slot_count(container, slot) + moved, 0);
      left = left - moved;
    }
  }

  for (slot = first; slot <= last; ++slot) {
    if (left <= 0) break;
    if (!slot_is_empty(container, slot)) continue;
    moved = left;
    if (moved > limit) moved = limit;
    slot_set(container, slot, item, moved, damage);
    left = left - moved;
  }

  return left;
}

Integer container_count_item(Attributes &container, Integer first, Integer last, Integer item)
// ----------------------------------------------------------------
// Total number of an item across slots first..last
// ----------------------------------------------------------------
{
  Integer slot  = 0;
  Integer total = 0;

  for (slot = first; slot <= last; ++slot) {
    if (slot_item(container, slot) == item) total = total + slot_count(container, slot);
  }
  return total;
}

Integer container_remove_item(Attributes &container, Integer first, Integer last, Integer item, Integer count)
// ----------------------------------------------------------------
// Take count of an item out of slots first..last, from the last
// slot backwards. Returns FALSE (and removes nothing) if there are
// not enough.
// ----------------------------------------------------------------
{
  Integer left  = count;
  Integer slot  = 0;
  Integer taken = 0;
  Integer have  = 0;

  if (container_count_item(container, first, last, item) < count) return FALSE;

  for (slot = last; slot >= first; --slot) {
    if (left <= 0) break;
    if (slot_item(container, slot) != item) continue;
    have  = slot_count(container, slot);
    taken = left;
    if (taken > have) taken = have;
    slot_set(container, slot, item, have - taken, slot_damage(container, slot));
    left = left - taken;
  }
  return TRUE;
}

// ---------------------------------------------------------------- the player's inventory

void inventory_clear(Attributes &inventory)
// ----------------------------------------------------------------
// Empty every slot and the cursor
// ----------------------------------------------------------------
{
  container_clear(inventory, DATATYPE_INVENTORY, CURSOR_SLOT, INVENTORY_SLOTS);
}

Integer inventory_add(Attributes &inventory, Integer item, Integer count)
// ----------------------------------------------------------------
// Add new items, hotbar first. Returns how many did not fit.
// ----------------------------------------------------------------
{
  return container_add(inventory, 1, INVENTORY_SLOTS, item, count, 0);
}

Integer inventory_add_worn(Attributes &inventory, Integer item, Integer count, Integer damage)
// ----------------------------------------------------------------
// Add items that keep their wear (a tool coming back from a
// crafting grid or being picked up). Returns how many did not fit.
// ----------------------------------------------------------------
{
  return container_add(inventory, 1, INVENTORY_SLOTS, item, count, damage);
}

Integer inventory_count_item(Attributes &inventory, Integer item)
// ----------------------------------------------------------------
// Total number of an item in the inventory
// ----------------------------------------------------------------
{
  return container_count_item(inventory, 1, INVENTORY_SLOTS, item);
}

Integer inventory_remove_item(Attributes &inventory, Integer item, Integer count)
// ----------------------------------------------------------------
// Take items out, main inventory before hotbar. FALSE if there are
// not enough (nothing is removed then).
// ----------------------------------------------------------------
{
  return container_remove_item(inventory, 1, INVENTORY_SLOTS, item, count);
}

void inventory_return_cursor(Attributes &inventory, Attributes &events, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Put the cursor stack back into the inventory when a screen
// closes; anything that does not fit is dropped at (x, y, z)
// ----------------------------------------------------------------
{
  Integer item = slot_item(inventory, CURSOR_SLOT);
  Integer left = 0;

  if (item == ITEM_NONE) return;

  left = inventory_add_worn(inventory, item, slot_count(inventory, CURSOR_SLOT), slot_damage(inventory, CURSOR_SLOT));
  if (left > 0) emit_drop_event(events, item, left, slot_damage(inventory, CURSOR_SLOT), x, y, z);

  slot_clear(inventory, CURSOR_SLOT);
}

#endif
