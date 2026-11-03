#ifndef INVENTORY_H_INCLUDED
#define INVENTORY_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// Containers: records with numbered slots
// Slot n of a container record has the fields "item_n", "count_n"
// and "damage_n" (how worn a tool is). The same functions work on
// the player's inventory, a crafting grid and the furnaces.
//
// The inventory record: slots 1..9 are the hotbar, 10..36 the 9 x 3
// main inventory and slot CURSOR_SLOT (0) is the stack the mouse
// is carrying while a screen is open.
// ----------------------------------------------------------------

#define DATATYPE_INVENTORY   ("inventory")
#define ATTR_DAMAGE          ("damage")
#define CURSOR_SLOT          0

// ---------------------------------------------------------------- slots
Integer slot_item            (Attributes &container, Integer slot);
Integer slot_count           (Attributes &container, Integer slot);
Integer slot_damage          (Attributes &container, Integer slot);
Integer slot_is_empty        (Attributes &container, Integer slot);
void    slot_set             (Attributes &container, Integer slot, Integer item, Integer count, Integer damage);
void    slot_clear           (Attributes &container, Integer slot);
void    slot_take_one        (Attributes &container, Integer slot);
Integer slot_wear            (Attributes &container, Integer slot);
void    slot_click_left      (Attributes &holder, Attributes &container, Integer slot, Integer take_only);
void    slot_click_right     (Attributes &holder, Attributes &container, Integer slot, Integer take_only);
void    slot_move_all        (Attributes &from, Integer from_slot, Attributes &to, Integer first, Integer last);

// ---------------------------------------------------------------- containers
void    container_clear      (Attributes &container, Text datatype, Integer first, Integer last);
Integer container_add        (Attributes &container, Integer first, Integer last, Integer item, Integer count, Integer damage);
Integer container_count_item (Attributes &container, Integer first, Integer last, Integer item);
Integer container_remove_item(Attributes &container, Integer first, Integer last, Integer item, Integer count);

// ---------------------------------------------------------------- the player's inventory
void    inventory_clear      (Attributes &inventory);
Integer inventory_add        (Attributes &inventory, Integer item, Integer count);
Integer inventory_add_worn   (Attributes &inventory, Integer item, Integer count, Integer damage);
Integer inventory_count_item (Attributes &inventory, Integer item);
Integer inventory_remove_item(Attributes &inventory, Integer item, Integer count);
void    inventory_return_cursor(Attributes &inventory, Attributes &events, Real x, Real y, Real z);

#endif
