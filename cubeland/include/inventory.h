#ifndef INVENTORY_H_INCLUDED
#define INVENTORY_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// The player's 36 slots: 1..9 are the hotbar, 10..36 the 9 x 3
// main inventory. The cursor stack is what the mouse is carrying
// while an inventory screen is open.
// ----------------------------------------------------------------

/*Global variables*/ {
  Integer g_inv_item [INVENTORY_SLOTS];
  Integer g_inv_count[INVENTORY_SLOTS];

  Integer g_cursor_item  = 0;
  Integer g_cursor_count = 0;

  // The slot being clicked, see inventory_click_left/right
  Integer g_click_item  = 0;
  Integer g_click_count = 0;
}

void    inventory_clear       ();
Integer inventory_add         (Integer item, Integer count);
Integer inventory_count_item  (Integer item);
Integer inventory_remove_item (Integer item, Integer count);
void    inventory_take_one    (Integer slot);
void    inventory_click_left  (Integer take_only);
void    inventory_click_right (Integer take_only);
void    inventory_return_cursor(Real x, Real y, Real z);

#endif
