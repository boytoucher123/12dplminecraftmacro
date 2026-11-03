#ifndef RENDER_UI_4DM_INCLUDED
#define RENDER_UI_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/inventory.h"
#include "../include/crafting.h"
#include "../include/furnace.h"
#include "../include/render.h"
#include "../include/hud.h"
#include "../include/ui.h"

// ---------------------------------------------------------------- the UI record

void ui_clear(Attributes &ui)
// ----------------------------------------------------------------
// No screen open
// ----------------------------------------------------------------
{
  record_clear      (ui, DATATYPE_UI);
  record_set_integer(ui, ATTR_UI_SCREEN,  SCREEN_NONE);
  record_set_integer(ui, ATTR_UI_FURNACE, 0);
  record_set_integer(ui, ATTR_X,          0);
  record_set_integer(ui, ATTR_Y,          0);
  record_set_integer(ui, ATTR_Z,          0);
  ui_set_mouse(ui, -1000.0, -1000.0);
}

Integer ui_screen(Attributes &ui)
// ----------------------------------------------------------------
// SCREEN_* that is open
// ----------------------------------------------------------------
{
  return record_integer(ui, ATTR_UI_SCREEN);
}

Integer ui_furnace(Attributes &ui)
// ----------------------------------------------------------------
// Number of the furnace whose screen is open, 0 if none
// ----------------------------------------------------------------
{
  return record_integer(ui, ATTR_UI_FURNACE);
}

void ui_mouse(Attributes &ui, Real &x, Real &y)
// ----------------------------------------------------------------
// Last mouse position over the screen
// ----------------------------------------------------------------
{
  x = record_real(ui, ATTR_UI_MOUSE_X);
  y = record_real(ui, ATTR_UI_MOUSE_Y);
}

void ui_set_mouse(Attributes &ui, Real x, Real y)
// ----------------------------------------------------------------
// Remember where the mouse is (for highlighting and the carried
// stack)
// ----------------------------------------------------------------
{
  record_set_real(ui, ATTR_UI_MOUSE_X, x);
  record_set_real(ui, ATTR_UI_MOUSE_Y, y);
}

// ---------------------------------------------------------------- opening and closing

void ui_open(Attributes &ui, Attributes &grid, Attributes &furnaces, Attributes &events,
             Integer screen, Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Open a screen; (x, y, z) is the block that was used (the furnace
// or crafting table)
// ----------------------------------------------------------------
{
  Integer furnace = 0;

  record_set_integer(ui, ATTR_UI_SCREEN,  screen);
  record_set_integer(ui, ATTR_UI_FURNACE, 0);
  record_set_integer(ui, ATTR_X,          x);
  record_set_integer(ui, ATTR_Y,          y);
  record_set_integer(ui, ATTR_Z,          z);

  if (screen == SCREEN_INVENTORY) grid_clear(grid, GRID_INVENTORY_WIDTH);
  if (screen == SCREEN_CRAFTING ) grid_clear(grid, GRID_TABLE_WIDTH);

  if (screen == SCREEN_FURNACE) {
    furnace = furnace_get_or_create(furnaces, x, y, z);
    record_set_integer(ui, ATTR_UI_FURNACE, furnace);
    if (furnace == 0) {
      record_set_integer(ui, ATTR_UI_SCREEN, SCREEN_NONE);
      emit_toast(events, "Too many furnaces in this world");
    }
  }
}

void ui_close(Attributes &ui, Attributes &inventory, Attributes &grid, Attributes &events,
              Real drop_x, Real drop_y, Real drop_z)
// ----------------------------------------------------------------
// Close the open screen; the carried stack and anything left in the
// crafting grid go back into the inventory (or onto the ground at
// the drop point if there is no room)
// ----------------------------------------------------------------
{
  inventory_return_cursor(inventory, events, drop_x, drop_y, drop_z);
  grid_return_items      (grid, inventory, events, drop_x, drop_y, drop_z);
  record_set_integer(ui, ATTR_UI_SCREEN,  SCREEN_NONE);
  record_set_integer(ui, ATTR_UI_FURNACE, 0);
}

void ui_on_event(Attributes &event, Attributes &ui, Attributes &inventory, Attributes &grid,
                 Attributes &furnaces, Attributes &events, Real drop_x, Real drop_y, Real drop_z)
// ----------------------------------------------------------------
// Event handler: open screens on request; close the open screen if
// the player dies or its block is broken
// ----------------------------------------------------------------
{
  Integer type = event_type(event);

  if (type == EVT_OPEN_SCREEN) {
    ui_open(ui, grid, furnaces, events, event_integer(event, 1), event_integer(event, 2), event_integer(event, 3), event_integer(event, 4));
  } else if (type == EVT_CLOSE_SCREEN || type == EVT_PLAYER_DIED) {
    if (ui_screen(ui) != SCREEN_NONE) ui_close(ui, inventory, grid, events, drop_x, drop_y, drop_z);
  } else if (type == EVT_BLOCK_BROKEN) {
    if (ui_screen(ui) == SCREEN_FURNACE || ui_screen(ui) == SCREEN_CRAFTING) {
      if (event_integer(event, 1) == record_integer(ui, ATTR_X) && event_integer(event, 2) == record_integer(ui, ATTR_Y) &&
          event_integer(event, 3) == record_integer(ui, ATTR_Z)) {
        ui_close(ui, inventory, grid, events, drop_x, drop_y, drop_z);
      }
    }
  }
}

// ---------------------------------------------------------------- layout

void ui_layout(Integer screen, Real w, Real h, Real &slot_size, Real &x0, Real &y0, Real &x1, Real &y1,
               Real &inv_x, Real &inv_y, Real &top_y)
// ----------------------------------------------------------------
// Size and place a screen in a w x h view
// From the bottom: the hotbar, the 3 rows of the main inventory,
// then (from top_y up) the crafting grid or the furnace
// ----------------------------------------------------------------
{
  Real width  = 0.0;
  Real height = 0.0;

  slot_size = clamp_real(min_real((w - 60.0) / 9.0, (h - STATUS_STRIP_HEIGHT - 60.0) / 8.4), 26.0, 44.0);

  width  = slot_size * 9.0 + UI_PADDING * 2.0;
  height = UI_PADDING + slot_size * 4.0 + 8.0 + 22.0 + slot_size * 3.0 + 10.0 + UI_TITLE_HEIGHT;

  x0 = w / 2.0 - width / 2.0;
  x1 = x0 + width;
  y0 = max_real(STATUS_STRIP_HEIGHT + 4.0, STATUS_STRIP_HEIGHT + (h - STATUS_STRIP_HEIGHT - height) / 2.0);
  y1 = y0 + height;

  inv_x = x0 + UI_PADDING;
  inv_y = y0 + UI_PADDING;
  top_y = inv_y + slot_size * 4.0 + 8.0 + 22.0;
}

Integer ui_slot_rect(Integer screen, Integer grid_width, Integer slot, Real w, Real h, Real &x, Real &y, Real &size)
// ----------------------------------------------------------------
// Bottom left corner (x, y) and size of a slot on a screen
// Returns FALSE if the slot isn't on that screen
// ----------------------------------------------------------------
{
  Real    x0     = 0.0;
  Real    y0     = 0.0;
  Real    x1     = 0.0;
  Real    y1     = 0.0;
  Real    inv_x  = 0.0;
  Real    inv_y  = 0.0;
  Real    top_y  = 0.0;
  Real    grid_x = 0.0;
  Real    grid_y = 0.0;
  Integer row    = 0;
  Integer column = 0;
  Integer cell   = 0;

  ui_layout(screen, w, h, size, x0, y0, x1, y1, inv_x, inv_y, top_y);

  if (slot >= 1 && slot <= HOTBAR_SLOTS) {
    x = inv_x + (slot - 1) * size;
    y = inv_y;
    return TRUE;
  }
  if (slot > HOTBAR_SLOTS && slot <= INVENTORY_SLOTS) {
    // 10..18 is the top row, 28..36 the bottom row
    row    = 3 - floor_divide(slot - 10, 9);
    column = positive_mod(slot - 10, 9);
    x = inv_x + column * size;
    y = inv_y + size + 8.0 + (row - 1) * size;
    return TRUE;
  }

  if (screen == SCREEN_INVENTORY || screen == SCREEN_CRAFTING) {
    // The grid, centred in the three slot rows above the inventory,
    // then an arrow and the output slot
    grid_x = inv_x + size * 1.5;
    grid_y = top_y + (3 - grid_width) * size * 0.5;
    if (slot > UI_SLOT_GRID && slot <= UI_SLOT_GRID + GRID_SLOTS) {
      cell   = slot - UI_SLOT_GRID;
      column = positive_mod(cell - 1, 3) + 1;
      row    = floor_divide(cell - 1, 3) + 1;
      if (column > grid_width || row > grid_width) return FALSE;
      x = grid_x + (column - 1) * size;
      y = grid_y + (grid_width - row) * size;
      return TRUE;
    }
    if (slot == UI_SLOT_OUTPUT) {
      x = grid_x + grid_width * size + size * 1.9;
      y = top_y + size;
      return TRUE;
    }
    return FALSE;
  }

  if (screen == SCREEN_FURNACE) {
    if (slot == UI_SLOT_FURNACE + FURNACE_SLOT_INPUT) {
      x = inv_x + size * 2.0;
      y = top_y + size * 2.0;
      return TRUE;
    }
    if (slot == UI_SLOT_FURNACE + FURNACE_SLOT_FUEL) {
      x = inv_x + size * 2.0;
      y = top_y;
      return TRUE;
    }
    if (slot == UI_SLOT_FURNACE + FURNACE_SLOT_OUTPUT) {
      x = inv_x + size * 5.6;
      y = top_y + size;
      return TRUE;
    }
  }
  return FALSE;
}

Integer ui_slot_at(Integer screen, Integer grid_width, Real px, Real py, Real w, Real h)
// ----------------------------------------------------------------
// Slot under the point (px, py), 0 if none
// ----------------------------------------------------------------
{
  Integer slot = 0;
  Real    x    = 0.0;
  Real    y    = 0.0;
  Real    size = 0.0;

  for (slot = 1; slot <= UI_SLOT_LAST; ++slot) {
    if (!ui_slot_rect(screen, grid_width, slot, w, h, x, y, size)) continue;
    if (px >= x && px < x + size && py >= y && py < y + size) return slot;
  }
  return 0;
}

// ---------------------------------------------------------------- clicking

void ui_click(Attributes &ui, Attributes &inventory, Attributes &grid, Attributes &furnaces,
              Attributes &book, Attributes &events, Real x, Real y, Integer right_button, Real w, Real h)
// ----------------------------------------------------------------
// A click on the open screen at (x, y)
// ----------------------------------------------------------------
{
  Integer screen    = ui_screen(ui);
  Integer furnace   = ui_furnace(ui);
  Integer slot      = ui_slot_at(screen, grid_width(grid), x, y, w, h);
  Integer target    = 0;
  Integer carried   = slot_item(inventory, CURSOR_SLOT);

  if (slot == 0) return;

  if (slot <= INVENTORY_SLOTS) {
    if (right_button) {
      slot_click_right(inventory, inventory, slot, FALSE);
    } else {
      slot_click_left(inventory, inventory, slot, FALSE);
    }
    return;
  }

  if (slot == UI_SLOT_OUTPUT) {
    crafting_take_output(book, grid, inventory, events);
    return;
  }

  if (slot > UI_SLOT_GRID && slot <= UI_SLOT_GRID + GRID_SLOTS) {
    target = slot - UI_SLOT_GRID;
    if (right_button) {
      slot_click_right(inventory, grid, target, FALSE);
    } else {
      slot_click_left(inventory, grid, target, FALSE);
    }
    return;
  }

  if (screen == SCREEN_FURNACE && furnace > 0) {
    target = furnace_slot(furnace, slot - UI_SLOT_FURNACE);

    // Only fuel goes in the fuel slot
    if (slot == UI_SLOT_FURNACE + FURNACE_SLOT_FUEL && carried != ITEM_NONE && item_fuel_seconds(carried) == 0) {
      emit_toast(events, "Only wood and coal burn in the fuel slot");
      return;
    }

    if (right_button) {
      slot_click_right(inventory, furnaces, target, slot == UI_SLOT_FURNACE + FURNACE_SLOT_OUTPUT);
    } else {
      slot_click_left(inventory, furnaces, target, slot == UI_SLOT_FURNACE + FURNACE_SLOT_OUTPUT);
    }
  }
}

// ---------------------------------------------------------------- drawing

void ui_draw_arrow(Draw_Box box, Real x, Real y, Real length, Real size, Real progress)
// ----------------------------------------------------------------
// A right-pointing arrow centred vertically on y, filled white up to
// progress (0..1)
// ----------------------------------------------------------------
{
  render_set_colour(box, 60.0, 60.0, 66.0);
  render_fill_rect (box, x, y - size * 0.12, x + length, y + size * 0.12);
  g_icon_x[1] = x + length;               g_icon_y[1] = y - size * 0.3;
  g_icon_x[2] = x + length + size * 0.4;  g_icon_y[2] = y;
  g_icon_x[3] = x + length;               g_icon_y[3] = y + size * 0.3;
  Draw_polygon(box, 3, g_icon_x, g_icon_y);
  if (progress > 0.0) {
    render_set_colour(box, 236.0, 236.0, 236.0);
    render_fill_rect (box, x, y - size * 0.12, x + length * min_real(1.0, progress), y + size * 0.12);
  }
}

void ui_draw_furnace(Draw_Box box, Attributes &furnaces, Integer furnace, Real w, Real h)
// ----------------------------------------------------------------
// The furnace section: input above fuel, a flame showing the fuel
// left, an arrow showing cooking progress, and the output
// ----------------------------------------------------------------
{
  Real slot_size = 0.0;
  Real x0        = 0.0;
  Real y0        = 0.0;
  Real x1        = 0.0;
  Real y1        = 0.0;
  Real inv_x     = 0.0;
  Real inv_y     = 0.0;
  Real top_y     = 0.0;
  Real flame_x   = 0.0;
  Real flame_y   = 0.0;
  Real burn      = 0.0;
  Real total     = 0.0;
  Real progress  = 0.0;

  if (furnace == 0) return;

  ui_layout(SCREEN_FURNACE, w, h, slot_size, x0, y0, x1, y1, inv_x, inv_y, top_y);
  flame_x = inv_x + slot_size * 2.0;
  flame_y = top_y + slot_size * 1.2;

  total = furnace_burn_total(furnaces, furnace);
  if (total > 0.0) burn = clamp_real(furnace_burn_left(furnaces, furnace) / total, 0.0, 1.0);
  progress = clamp_real(furnace_progress(furnaces, furnace) / COOK_SECONDS, 0.0, 1.0);

  // Flame between the input and fuel slots
  render_set_colour(box, 60.0, 60.0, 66.0);
  render_fill_rect (box, flame_x + slot_size * 0.3, flame_y, flame_x + slot_size * 0.7, flame_y + slot_size * 0.5);
  if (burn > 0.0) {
    render_set_colour(box, 240.0, 140.0, 40.0);
    render_fill_rect (box, flame_x + slot_size * 0.3, flame_y, flame_x + slot_size * 0.7, flame_y + slot_size * 0.5 * burn);
    render_set_colour(box, 252.0, 214.0, 90.0);
    render_fill_rect (box, flame_x + slot_size * 0.4, flame_y, flame_x + slot_size * 0.6, flame_y + slot_size * 0.3 * burn);
  }

  ui_draw_arrow(box, inv_x + slot_size * 3.4, top_y + slot_size * 1.5, slot_size * 1.6, slot_size, progress);

  hud_text(box, inv_x, top_y + slot_size * 2.7, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "Cook");
  hud_text(box, inv_x, top_y + slot_size * 0.7, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "Fuel");
  hud_text(box, inv_x + slot_size * 6.9, top_y + slot_size * 1.7, 11.0, TEXT_ALIGN_LEFT, 196, 196, 170, "Result");
}

void ui_draw(Draw_Box box, Real w, Real h, Attributes &ui, Attributes &inventory, Attributes &grid,
             Attributes &furnaces, Attributes &book)
// ----------------------------------------------------------------
// Draw the open screen. The 3D view isn't drawn behind it, which
// keeps the screen quick to redraw as the mouse moves.
// ----------------------------------------------------------------
{
  Integer screen    = ui_screen(ui);
  Integer furnace   = ui_furnace(ui);
  Integer width     = grid_width(grid);
  Integer slot      = 0;
  Integer hovered   = 0;
  Integer item      = 0;
  Integer count     = 0;
  Integer damage    = 0;
  Integer recipe    = 0;
  Integer target    = 0;
  Integer carried   = slot_item(inventory, CURSOR_SLOT);
  Real    mouse_x   = 0.0;
  Real    mouse_y   = 0.0;
  Real    slot_size = 0.0;
  Real    x0        = 0.0;
  Real    y0        = 0.0;
  Real    x1        = 0.0;
  Real    y1        = 0.0;
  Real    inv_x     = 0.0;
  Real    inv_y     = 0.0;
  Real    top_y     = 0.0;
  Real    x         = 0.0;
  Real    y         = 0.0;
  Real    size      = 0.0;
  Text    title     = "";
  Text    name      = "";

  ui_mouse (ui, mouse_x, mouse_y);
  ui_layout(screen, w, h, slot_size, x0, y0, x1, y1, inv_x, inv_y, top_y);
  hovered = ui_slot_at(screen, width, mouse_x, mouse_y, w, h);
  recipe  = crafting_match(book, grid);

  render_set_colour(box, 30.0, 34.0, 42.0);
  render_fill_rect (box, 0.0, STATUS_STRIP_HEIGHT, w, h);

  render_set_colour(box, 46.0, 50.0, 58.0);
  render_fill_rect (box, x0, y0, x1, y1);
  render_set_colour(box, 140.0, 150.0, 168.0);
  hud_frame(box, x0, y0, x1, y1);

  if (screen == SCREEN_INVENTORY) title = "Inventory - crafting (2 x 2)";
  if (screen == SCREEN_CRAFTING ) title = "Crafting Table (3 x 3)";
  if (screen == SCREEN_FURNACE  ) title = "Furnace";
  hud_text(box, inv_x, y1 - 8.0, 15.0, TEXT_ALIGN_LEFT, 236, 236, 236, title);
  hud_text(box, x1 - 150.0, y1 - 10.0, 11.0, TEXT_ALIGN_LEFT, 160, 168, 180, "E or Q to close");
  hud_text(box, inv_x, inv_y + slot_size * 4.0 + 8.0 + 18.0, 13.0, TEXT_ALIGN_LEFT, 220, 220, 220, "Inventory");

  for (slot = 1; slot <= UI_SLOT_LAST; ++slot) {
    if (!ui_slot_rect(screen, width, slot, w, h, x, y, size)) continue;
    item   = ITEM_NONE;
    count  = 0;
    damage = 0;
    if (slot <= INVENTORY_SLOTS) {
      item   = slot_item  (inventory, slot);
      count  = slot_count (inventory, slot);
      damage = slot_damage(inventory, slot);
    } else if (slot == UI_SLOT_OUTPUT) {
      if (recipe > 0) {
        item  = crafting_recipe_output(book, recipe);
        count = record_integer_at(book, ATTR_RECIPE_OUT_COUNT, recipe);
      }
    } else if (slot > UI_SLOT_GRID && slot <= UI_SLOT_GRID + GRID_SLOTS) {
      item   = slot_item  (grid, slot - UI_SLOT_GRID);
      count  = slot_count (grid, slot - UI_SLOT_GRID);
      damage = slot_damage(grid, slot - UI_SLOT_GRID);
    } else if (furnace > 0) {
      target = furnace_slot(furnace, slot - UI_SLOT_FURNACE);
      item   = slot_item  (furnaces, target);
      count  = slot_count (furnaces, target);
      damage = slot_damage(furnaces, target);
    }
    hud_draw_slot(box, x, y, size, item, count, damage, slot == hovered);
    if (slot == hovered && carried == ITEM_NONE) name = item_name(item);
  }

  if (screen == SCREEN_FURNACE) {
    ui_draw_furnace(box, furnaces, furnace, w, h);
  } else {
    // Arrow from the grid to the output slot
    if (ui_slot_rect(screen, width, UI_SLOT_OUTPUT, w, h, x, y, size)) {
      if (recipe > 0) {
        ui_draw_arrow(box, x - size * 1.5, y + size * 0.5, size * 0.9, size, 1.0);
      } else {
        ui_draw_arrow(box, x - size * 1.5, y + size * 0.5, size * 0.9, size, 0.0);
      }
    }
    if (screen == SCREEN_INVENTORY) {
      hud_text(box, inv_x + slot_size * 6.7, top_y + slot_size * 2.2, 11.0, TEXT_ALIGN_LEFT, 170, 176, 190, "Bigger things need");
      hud_text(box, inv_x + slot_size * 6.7, top_y + slot_size * 2.2 - 14.0, 11.0, TEXT_ALIGN_LEFT, 170, 176, 190, "a crafting table");
    }
  }

  // Name of the item under the mouse
  if (name != "") hud_shadow_text(box, mouse_x + 14.0, mouse_y + 20.0, 13.0, TEXT_ALIGN_LEFT, 255, 255, 210, name);

  // The stack being carried follows the mouse
  if (carried != ITEM_NONE) {
    hud_draw_item_icon(box, carried, mouse_x, mouse_y, slot_size * 0.62, ICON_FULL);
    if (slot_count(inventory, CURSOR_SLOT) > 1) {
      hud_shadow_text(box, mouse_x + 6.0, mouse_y - 4.0, 12.0, TEXT_ALIGN_LEFT, 255, 255, 255, To_text(slot_count(inventory, CURSOR_SLOT)));
    }
  }
}

#endif
