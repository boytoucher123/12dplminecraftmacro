#ifndef UI_H_INCLUDED
#define UI_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Inventory, crafting table and furnace screens
// While a screen is open the mouse is free: slots are clicked to
// pick up / put down stacks. The inventory screen has a 2 x 2
// crafting grid, the crafting table a 3 x 3 one; clicking the
// output slot crafts.
//
// The UI record holds which screen is open ("screen"), the furnace
// being used ("furnace"), the block that opened it ("x", "y", "z")
// and where the mouse is ("mouse_x", "mouse_y").
//
// Slot numbers on screen: 1..36 the inventory, UI_SLOT_GRID + n
// grid slot n (1..9), UI_SLOT_OUTPUT the crafting result, and
// UI_SLOT_FURNACE + FURNACE_SLOT_* the furnace's slots.
// ----------------------------------------------------------------

#define DATATYPE_UI             ("ui")
#define ATTR_UI_SCREEN          ("screen")
#define ATTR_UI_FURNACE         ("furnace")
#define ATTR_UI_MOUSE_X         ("mouse_x")
#define ATTR_UI_MOUSE_Y         ("mouse_y")

#define UI_SLOT_GRID            40
#define UI_SLOT_OUTPUT          50
#define UI_SLOT_FURNACE         50   // + FURNACE_SLOT_INPUT .. FURNACE_SLOT_OUTPUT (51..53)
#define UI_SLOT_LAST            53
#define UI_PADDING              14.0
#define UI_TITLE_HEIGHT         30.0

void    ui_clear          (Attributes &ui);
Integer ui_screen         (Attributes &ui);
Integer ui_furnace        (Attributes &ui);
void    ui_mouse          (Attributes &ui, Real &x, Real &y);
void    ui_set_mouse      (Attributes &ui, Real x, Real y);
void    ui_open           (Attributes &ui, Attributes &grid, Attributes &furnaces, Attributes &events,
                           Integer screen, Integer x, Integer y, Integer z);
void    ui_close          (Attributes &ui, Attributes &inventory, Attributes &grid, Attributes &events,
                           Real drop_x, Real drop_y, Real drop_z);
void    ui_on_event       (Attributes &event, Attributes &ui, Attributes &inventory, Attributes &grid,
                           Attributes &furnaces, Attributes &events, Real drop_x, Real drop_y, Real drop_z);
void    ui_layout         (Integer screen, Real w, Real h, Real &slot_size, Real &x0, Real &y0, Real &x1, Real &y1,
                           Real &inv_x, Real &inv_y, Real &top_y);
Integer ui_slot_rect      (Integer screen, Integer grid_width, Integer slot, Real w, Real h, Real &x, Real &y, Real &size);
Integer ui_slot_at        (Integer screen, Integer grid_width, Real px, Real py, Real w, Real h);
void    ui_click          (Attributes &ui, Attributes &inventory, Attributes &grid, Attributes &furnaces,
                           Attributes &book, Attributes &events, Real x, Real y, Integer right_button, Real w, Real h);
void    ui_draw_arrow     (Draw_Box box, Real x, Real y, Real length, Real size, Real progress);
void    ui_draw_furnace   (Draw_Box box, Attributes &furnaces, Integer furnace, Real w, Real h);
void    ui_draw           (Draw_Box box, Real w, Real h, Attributes &ui, Attributes &inventory, Attributes &grid,
                           Attributes &furnaces, Attributes &book);

#endif
