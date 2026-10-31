#ifndef UI_H_INCLUDED
#define UI_H_INCLUDED

// ----------------------------------------------------------------
// Inventory, crafting table and furnace screens
// While a screen is open the mouse is free: slots are clicked to
// pick up / put down stacks and recipes are clicked to craft.
// Slots 1..36 are the inventory, 37..39 the furnace's input, fuel
// and output.
// ----------------------------------------------------------------

#define UI_SLOT_FURNACE_INPUT   37
#define UI_SLOT_FURNACE_FUEL    38
#define UI_SLOT_FURNACE_OUTPUT  39
#define UI_SLOT_COUNT           39
#define UI_PADDING              14.0
#define UI_TITLE_HEIGHT         30.0

/*Global variables*/ {
  Integer g_ui_screen  = SCREEN_NONE;
  Integer g_ui_furnace = 0;
  Integer g_ui_cell_x  = 0;
  Integer g_ui_cell_y  = 0;
  Integer g_ui_cell_z  = 0;
  Real    g_ui_mouse_x = -1000.0;
  Real    g_ui_mouse_y = -1000.0;

  // Layout, worked out by ui_layout for the current view size
  Real    g_ui_slot     = 40.0;
  Real    g_ui_x0       = 0.0;
  Real    g_ui_y0       = 0.0;
  Real    g_ui_x1       = 0.0;
  Real    g_ui_y1       = 0.0;
  Real    g_ui_inv_x    = 0.0;
  Real    g_ui_inv_y    = 0.0;
  Real    g_ui_top_y    = 0.0;
  Real    g_ui_row_h    = 30.0;
  Integer g_ui_rows     = 0;

  // Result of ui_slot_rect / ui_recipe_rect
  Real    g_ui_rect_x = 0.0;
  Real    g_ui_rect_y = 0.0;
  Real    g_ui_rect_w = 0.0;
  Real    g_ui_rect_h = 0.0;
}

void    ui_open          (Integer screen, Integer x, Integer y, Integer z);
void    ui_close         ();
void    ui_on_event      ();
Integer ui_recipe_shown  (Integer recipe);
void    ui_layout        (Real w, Real h);
Integer ui_slot_rect     (Integer slot);
Integer ui_recipe_rect   (Integer recipe);
Integer ui_slot_at       (Real x, Real y);
Integer ui_recipe_at     (Real x, Real y);
void    ui_click         (Real x, Real y, Integer right_button, Real w, Real h);
void    ui_draw          (Draw_Box box, Real w, Real h);

#endif
