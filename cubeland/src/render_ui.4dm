#ifndef RENDER_UI_4DM_INCLUDED
#define RENDER_UI_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/inventory.h"
#include "../include/crafting.h"
#include "../include/furnace.h"
#include "../include/player.h"
#include "../include/render.h"
#include "../include/hud.h"
#include "../include/ui.h"

// ---------------------------------------------------------------- opening and closing

void ui_open(Integer screen, Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Open a screen; for the furnace screen (x, y, z) is the furnace
// ----------------------------------------------------------------
{
  g_ui_screen  = screen;
  g_ui_cell_x  = x;
  g_ui_cell_y  = y;
  g_ui_cell_z  = z;
  g_ui_furnace = 0;

  if (screen == SCREEN_FURNACE) {
    g_ui_furnace = furnace_get_or_create(x, y, z);
    if (g_ui_furnace == 0) {
      g_ui_screen = SCREEN_NONE;
      emit_toast("Too many furnaces in this world");
    }
  }
}

void ui_close()
// ----------------------------------------------------------------
// Close the open screen; a stack still on the cursor goes back
// into the inventory (or onto the ground if there is no room)
// ----------------------------------------------------------------
{
  inventory_return_cursor(g_player_x, player_eye_y() - 0.3, g_player_z);
  g_ui_screen  = SCREEN_NONE;
  g_ui_furnace = 0;
}

void ui_on_event()
// ----------------------------------------------------------------
// Event handler: open screens on request, and close the furnace
// screen if its furnace is broken or the player dies
// ----------------------------------------------------------------
{
  if (g_ev_type == EVT_OPEN_SCREEN) {
    ui_open(g_ev_i1, g_ev_i2, g_ev_i3, g_ev_i4);
  } else if (g_ev_type == EVT_PLAYER_DIED) {
    if (g_ui_screen != SCREEN_NONE) ui_close();
  } else if (g_ev_type == EVT_BLOCK_BROKEN) {
    if (g_ui_screen == SCREEN_FURNACE && g_ev_i1 == g_ui_cell_x && g_ev_i2 == g_ui_cell_y && g_ev_i3 == g_ui_cell_z) ui_close();
  }
}

// ---------------------------------------------------------------- layout

Integer ui_recipe_shown(Integer recipe)
// ----------------------------------------------------------------
// TRUE if a recipe is listed on the open screen: the inventory
// lists hand recipes, the crafting table lists them all
// ----------------------------------------------------------------
{
  if (g_ui_screen == SCREEN_CRAFTING ) return TRUE;
  if (g_ui_screen == SCREEN_INVENTORY) return !g_recipe_needs_table[recipe];
  return FALSE;
}

void ui_layout(Real w, Real h)
// ----------------------------------------------------------------
// Size and place the screen for a w x h view
// From the bottom: hotbar, the 3 rows of the main inventory, then
// the recipe list or the furnace
// ----------------------------------------------------------------
{
  Integer recipe     = 0;
  Real    top_height = 0.0;
  Real    height     = 0.0;
  Real    width      = 0.0;

  g_ui_rows = 0;
  for (recipe = 1; recipe <= g_recipe_count; ++recipe) {
    if (ui_recipe_shown(recipe)) ++g_ui_rows;
  }

  g_ui_slot  = clamp_real(min_real((w - 60.0) / 9.0, (h - STATUS_STRIP_HEIGHT - 60.0) / 10.0), 26.0, 44.0);
  g_ui_row_h = clamp_real(g_ui_slot * 0.9, 26.0, 36.0);

  if (g_ui_screen == SCREEN_FURNACE) {
    top_height = UI_TITLE_HEIGHT + g_ui_slot * 2.6;
  } else {
    top_height = UI_TITLE_HEIGHT + g_ui_rows * g_ui_row_h + 4.0;
  }

  width  = g_ui_slot * 9.0 + UI_PADDING * 2.0;
  height = UI_PADDING + g_ui_slot * 4.0 + 8.0 + 22.0 + top_height + UI_PADDING;

  g_ui_x0 = w / 2.0 - width / 2.0;
  g_ui_x1 = g_ui_x0 + width;
  g_ui_y0 = max_real(STATUS_STRIP_HEIGHT + 4.0, STATUS_STRIP_HEIGHT + (h - STATUS_STRIP_HEIGHT - height) / 2.0);
  g_ui_y1 = g_ui_y0 + height;

  g_ui_inv_x = g_ui_x0 + UI_PADDING;
  g_ui_inv_y = g_ui_y0 + UI_PADDING;
  g_ui_top_y = g_ui_inv_y + g_ui_slot * 4.0 + 8.0 + 22.0;
}

Integer ui_slot_rect(Integer slot)
// ----------------------------------------------------------------
// Bottom left corner and size of a slot in g_ui_rect_*
// Returns FALSE if the slot isn't on the open screen
// ----------------------------------------------------------------
{
  Integer row    = 0;
  Integer column = 0;

  g_ui_rect_w = g_ui_slot;
  g_ui_rect_h = g_ui_slot;

  if (slot >= 1 && slot <= HOTBAR_SLOTS) {
    g_ui_rect_x = g_ui_inv_x + (slot - 1) * g_ui_slot;
    g_ui_rect_y = g_ui_inv_y;
    return TRUE;
  }
  if (slot > HOTBAR_SLOTS && slot <= INVENTORY_SLOTS) {
    // 10..18 is the top row, 28..36 the bottom row
    row    = 3 - floor_divide(slot - 10, 9);
    column = positive_mod(slot - 10, 9);
    g_ui_rect_x = g_ui_inv_x + column * g_ui_slot;
    g_ui_rect_y = g_ui_inv_y + g_ui_slot + 8.0 + (row - 1) * g_ui_slot;
    return TRUE;
  }

  if (g_ui_screen != SCREEN_FURNACE) return FALSE;

  if (slot == UI_SLOT_FURNACE_INPUT) {
    g_ui_rect_x = g_ui_inv_x + g_ui_slot * 2.0;
    g_ui_rect_y = g_ui_top_y + g_ui_slot * 1.5;
    return TRUE;
  }
  if (slot == UI_SLOT_FURNACE_FUEL) {
    g_ui_rect_x = g_ui_inv_x + g_ui_slot * 2.0;
    g_ui_rect_y = g_ui_top_y + g_ui_slot * 0.1;
    return TRUE;
  }
  if (slot == UI_SLOT_FURNACE_OUTPUT) {
    g_ui_rect_x = g_ui_inv_x + g_ui_slot * 5.6;
    g_ui_rect_y = g_ui_top_y + g_ui_slot * 0.8;
    return TRUE;
  }
  return FALSE;
}

Integer ui_recipe_rect(Integer recipe)
// ----------------------------------------------------------------
// Rectangle of a recipe's row in g_ui_rect_*; FALSE if not listed
// ----------------------------------------------------------------
{
  Integer other = 0;
  Integer index = 0;

  if (g_ui_screen == SCREEN_FURNACE) return FALSE;
  if (!ui_recipe_shown(recipe)) return FALSE;

  for (other = 1; other <= recipe; ++other) {
    if (ui_recipe_shown(other)) ++index;
  }

  g_ui_rect_x = g_ui_inv_x;
  g_ui_rect_w = g_ui_slot * 9.0;
  g_ui_rect_h = g_ui_row_h - 3.0;
  g_ui_rect_y = g_ui_y1 - UI_PADDING - UI_TITLE_HEIGHT - index * g_ui_row_h;
  return TRUE;
}

Integer ui_slot_at(Real x, Real y)
// ----------------------------------------------------------------
// Slot under a point, 0 for none
// ----------------------------------------------------------------
{
  Integer slot = 0;

  for (slot = 1; slot <= UI_SLOT_COUNT; ++slot) {
    if (!ui_slot_rect(slot)) continue;
    if (x >= g_ui_rect_x && x < g_ui_rect_x + g_ui_rect_w && y >= g_ui_rect_y && y < g_ui_rect_y + g_ui_rect_h) return slot;
  }
  return 0;
}

Integer ui_recipe_at(Real x, Real y)
// ----------------------------------------------------------------
// Recipe row under a point, 0 for none
// ----------------------------------------------------------------
{
  Integer recipe = 0;

  for (recipe = 1; recipe <= g_recipe_count; ++recipe) {
    if (!ui_recipe_rect(recipe)) continue;
    if (x >= g_ui_rect_x && x < g_ui_rect_x + g_ui_rect_w && y >= g_ui_rect_y && y < g_ui_rect_y + g_ui_rect_h) return recipe;
  }
  return 0;
}

// ---------------------------------------------------------------- clicking

void ui_click(Real x, Real y, Integer right_button, Real w, Real h)
// ----------------------------------------------------------------
// A click on the open screen at (x, y)
// ----------------------------------------------------------------
{
  Integer slot       = 0;
  Integer recipe     = 0;
  Integer take_only  = FALSE;
  Integer old_item   = 0;
  Integer old_count  = 0;
  Integer old_cursor = 0;
  Integer old_held   = 0;

  ui_layout(w, h);

  slot = ui_slot_at(x, y);
  if (slot > 0) {
    if (slot <= INVENTORY_SLOTS) {
      g_click_item  = g_inv_item [slot];
      g_click_count = g_inv_count[slot];
    } else {
      furnace_get_slot(g_ui_furnace, slot - INVENTORY_SLOTS);
    }
    old_item   = g_click_item;
    old_count  = g_click_count;
    old_cursor = g_cursor_item;
    old_held   = g_cursor_count;
    take_only  = slot == UI_SLOT_FURNACE_OUTPUT;

    if (right_button) {
      inventory_click_right(take_only);
    } else {
      inventory_click_left(take_only);
    }

    // Only fuel goes in the fuel slot
    if (slot == UI_SLOT_FURNACE_FUEL && g_click_item != ITEM_NONE && item_fuel_seconds(g_click_item) == 0) {
      g_click_item   = old_item;
      g_click_count  = old_count;
      g_cursor_item  = old_cursor;
      g_cursor_count = old_held;
      emit_toast("Only wood burns in the fuel slot");
    }

    if (slot <= INVENTORY_SLOTS) {
      g_inv_item [slot] = g_click_item;
      g_inv_count[slot] = g_click_count;
    } else {
      furnace_set_slot(g_ui_furnace, slot - INVENTORY_SLOTS);
    }
    return;
  }

  recipe = ui_recipe_at(x, y);
  if (recipe > 0) {
    if (crafting_craft(recipe, g_player_x, player_eye_y() - 0.3, g_player_z) != SUCCESS) {
      emit_toast("Missing ingredients: " + crafting_describe(recipe));
    }
  }
}

// ---------------------------------------------------------------- drawing

void ui_draw_recipe(Draw_Box box, Integer recipe)
// ----------------------------------------------------------------
// One row of the recipe list
// ----------------------------------------------------------------
{
  Integer can_make = crafting_can_craft(recipe);
  Integer hovered  = FALSE;
  Real    x        = 0.0;
  Real    y        = 0.0;
  Real    row_w    = 0.0;
  Real    row_h    = 0.0;
  Text    title    = "";

  if (!ui_recipe_rect(recipe)) return;
  x     = g_ui_rect_x;
  y     = g_ui_rect_y;
  row_w = g_ui_rect_w;
  row_h = g_ui_rect_h;
  hovered = g_ui_mouse_x >= x && g_ui_mouse_x < x + row_w && g_ui_mouse_y >= y && g_ui_mouse_y < y + row_h;

  if (can_make) {
    render_set_colour(box, 52.0, 78.0, 54.0);
    if (hovered) render_set_colour(box, 70.0, 106.0, 72.0);
  } else {
    render_set_colour(box, 50.0, 52.0, 58.0);
  }
  render_fill_rect(box, x, y, x + row_w, y + row_h);

  hud_draw_item_icon(box, g_recipe_output[recipe], x + row_h / 2.0 + 2.0, y + row_h / 2.0, row_h * 0.72);

  title = item_name(g_recipe_output[recipe]);
  if (g_recipe_output_count[recipe] > 1) title = title + "  x" + To_text(g_recipe_output_count[recipe]);
  if (can_make) {
    hud_text(box, x + row_h + 8.0, y + row_h - 5.0, 13.0, TEXT_ALIGN_LEFT, 255, 255, 255, title);
  } else {
    hud_text(box, x + row_h + 8.0, y + row_h - 5.0, 13.0, TEXT_ALIGN_LEFT, 150, 150, 156, title);
  }
  hud_text(box, x + row_w * 0.5, y + row_h - 6.0, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "needs " + crafting_describe(recipe));
}

void ui_draw_furnace(Draw_Box box)
// ----------------------------------------------------------------
// The furnace section: input above fuel, a flame showing the fuel
// left, an arrow showing cooking progress, and the output
// ----------------------------------------------------------------
{
  Integer furnace  = g_ui_furnace;
  Real    flame_x  = g_ui_inv_x + g_ui_slot * 2.0;
  Real    flame_y  = g_ui_top_y + g_ui_slot * 1.12;
  Real    arrow_x  = g_ui_inv_x + g_ui_slot * 3.4;
  Real    arrow_y  = g_ui_top_y + g_ui_slot * 1.2;
  Real    burn     = 0.0;
  Real    progress = 0.0;
  Real    size     = g_ui_slot;

  if (furnace == 0) return;

  if (g_furnace_burn_total[furnace] > 0.0) burn = clamp_real(g_furnace_burn_left[furnace] / g_furnace_burn_total[furnace], 0.0, 1.0);
  progress = clamp_real(g_furnace_progress[furnace] / COOK_SECONDS, 0.0, 1.0);

  // Flame between the input and fuel slots
  render_set_colour(box, 60.0, 60.0, 66.0);
  render_fill_rect (box, flame_x + size * 0.3, flame_y, flame_x + size * 0.7, flame_y + size * 0.34);
  if (burn > 0.0) {
    render_set_colour(box, 240.0, 140.0, 40.0);
    render_fill_rect (box, flame_x + size * 0.3, flame_y, flame_x + size * 0.7, flame_y + size * 0.34 * burn);
    render_set_colour(box, 252.0, 214.0, 90.0);
    render_fill_rect (box, flame_x + size * 0.4, flame_y, flame_x + size * 0.6, flame_y + size * 0.2 * burn);
  }

  // Progress arrow towards the output
  render_set_colour(box, 60.0, 60.0, 66.0);
  render_fill_rect (box, arrow_x, arrow_y - size * 0.12, arrow_x + size * 1.6, arrow_y + size * 0.12);
  g_icon_x[1] = arrow_x + size * 1.6;  g_icon_y[1] = arrow_y - size * 0.3;
  g_icon_x[2] = arrow_x + size * 2.0;  g_icon_y[2] = arrow_y;
  g_icon_x[3] = arrow_x + size * 1.6;  g_icon_y[3] = arrow_y + size * 0.3;
  Draw_polygon(box, 3, g_icon_x, g_icon_y);
  if (progress > 0.0) {
    render_set_colour(box, 236.0, 236.0, 236.0);
    render_fill_rect (box, arrow_x, arrow_y - size * 0.12, arrow_x + size * 1.6 * min_real(1.0, progress * 1.25), arrow_y + size * 0.12);
  }

  hud_text(box, g_ui_inv_x, g_ui_top_y + size * 2.2, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "Cook");
  hud_text(box, g_ui_inv_x, g_ui_top_y + size * 0.8, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "Fuel");
  hud_text(box, g_ui_inv_x + size * 6.8, g_ui_top_y + size * 1.5, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "Result");
}

void ui_draw(Draw_Box box, Real w, Real h)
// ----------------------------------------------------------------
// Draw the open screen. The 3D view isn't drawn behind it, which
// keeps the screen quick to redraw as the mouse moves.
// ----------------------------------------------------------------
{
  Integer slot    = 0;
  Integer recipe  = 0;
  Integer hovered = 0;
  Text    title   = "";
  Text    name    = "";

  ui_layout(w, h);

  render_set_colour(box, 30.0, 34.0, 42.0);
  render_fill_rect (box, 0.0, STATUS_STRIP_HEIGHT, w, h);

  render_set_colour(box, 46.0, 50.0, 58.0);
  render_fill_rect (box, g_ui_x0, g_ui_y0, g_ui_x1, g_ui_y1);
  render_set_colour(box, 140.0, 150.0, 168.0);
  hud_frame(box, g_ui_x0, g_ui_y0, g_ui_x1, g_ui_y1);

  if (g_ui_screen == SCREEN_INVENTORY) title = "Crafting by hand";
  if (g_ui_screen == SCREEN_CRAFTING ) title = "Crafting Table";
  if (g_ui_screen == SCREEN_FURNACE  ) title = "Furnace";
  hud_text(box, g_ui_inv_x, g_ui_y1 - 8.0, 15.0, TEXT_ALIGN_LEFT, 236, 236, 236, title);
  hud_text(box, g_ui_x1 - 150.0, g_ui_y1 - 10.0, 11.0, TEXT_ALIGN_LEFT, 160, 168, 180, "E or Q to close");
  hud_text(box, g_ui_inv_x, g_ui_inv_y + g_ui_slot * 4.0 + 8.0 + 18.0, 13.0, TEXT_ALIGN_LEFT, 220, 220, 220, "Inventory");

  hovered = ui_slot_at(g_ui_mouse_x, g_ui_mouse_y);

  for (slot = 1; slot <= INVENTORY_SLOTS; ++slot) {
    ui_slot_rect(slot);
    hud_draw_slot(box, g_ui_rect_x, g_ui_rect_y, g_ui_slot, g_inv_item[slot], g_inv_count[slot], slot == hovered);
  }

  if (g_ui_screen == SCREEN_FURNACE) {
    ui_draw_furnace(box);
    for (slot = UI_SLOT_FURNACE_INPUT; slot <= UI_SLOT_FURNACE_OUTPUT; ++slot) {
      ui_slot_rect(slot);
      furnace_get_slot(g_ui_furnace, slot - INVENTORY_SLOTS);
      hud_draw_slot(box, g_ui_rect_x, g_ui_rect_y, g_ui_slot, g_click_item, g_click_count, slot == hovered);
    }
  } else {
    for (recipe = 1; recipe <= g_recipe_count; ++recipe) ui_draw_recipe(box, recipe);
  }

  // Name of the item under the mouse
  if (hovered > 0 && g_cursor_item == ITEM_NONE) {
    if (hovered <= INVENTORY_SLOTS) {
      name = item_name(g_inv_item[hovered]);
    } else {
      furnace_get_slot(g_ui_furnace, hovered - INVENTORY_SLOTS);
      name = item_name(g_click_item);
    }
    if (name != "") hud_shadow_text(box, g_ui_mouse_x + 14.0, g_ui_mouse_y + 20.0, 13.0, TEXT_ALIGN_LEFT, 255, 255, 210, name);
  }

  // The stack being carried follows the mouse
  if (g_cursor_item != ITEM_NONE) {
    hud_draw_item_icon(box, g_cursor_item, g_ui_mouse_x, g_ui_mouse_y, g_ui_slot * 0.62);
    if (g_cursor_count > 1) {
      hud_shadow_text(box, g_ui_mouse_x + 6.0, g_ui_mouse_y - 4.0, 12.0, TEXT_ALIGN_LEFT, 255, 255, 255, To_text(g_cursor_count));
    }
  }
}

#endif
