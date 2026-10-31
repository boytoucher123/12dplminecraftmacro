#ifndef RENDER_HUD_4DM_INCLUDED
#define RENDER_HUD_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/textures.h"
#include "../include/world.h"
#include "../include/inventory.h"
#include "../include/player.h"
#include "../include/render.h"
#include "../include/hud.h"

// ---------------------------------------------------------------- messages

void hud_clear()
// ----------------------------------------------------------------
// Remove every message
// ----------------------------------------------------------------
{
  Integer toast = 0;

  for (toast = 1; toast <= MAX_TOASTS; ++toast) {
    g_toast_text [toast] = "";
    g_toast_until[toast] = 0.0;
  }
}

void hud_toast(Text text)
// ----------------------------------------------------------------
// Show a short message above the hotbar; newest on top
// ----------------------------------------------------------------
{
  Integer toast = 0;

  for (toast = MAX_TOASTS; toast >= 2; --toast) {
    g_toast_text [toast] = g_toast_text [toast - 1];
    g_toast_until[toast] = g_toast_until[toast - 1];
  }
  g_toast_text [1] = text;
  g_toast_until[1] = g_hud_now + TOAST_SECONDS;
}

void hud_on_event()
// ----------------------------------------------------------------
// Event handler: turn things that happened into messages
// ----------------------------------------------------------------
{
  if (g_ev_type == EVT_ITEM_PICKED_UP) {
    hud_toast("+" + To_text(g_ev_i2) + " " + item_name(g_ev_i1));
  } else if (g_ev_type == EVT_ITEM_CRAFTED) {
    hud_toast("Crafted " + To_text(g_ev_i2) + " " + item_name(g_ev_i1));
  } else if (g_ev_type == EVT_PLAYER_ATE) {
    hud_toast("Ate " + item_name(g_ev_i1) + "  (+" + To_text(g_ev_i2) + " health)");
  } else if (g_ev_type == EVT_TOAST) {
    hud_toast(g_ev_text);
  } else if (g_ev_type == EVT_WORLD_SAVED) {
    hud_toast("Saved world " + g_ev_text);
  }
}

// ---------------------------------------------------------------- drawing helpers

void hud_text(Draw_Box box, Real x, Real y, Real size, Integer align, Integer red, Integer green, Integer blue, Text text)
// ----------------------------------------------------------------
// Draw text with its top left (or top centre) at (x, y)
// ----------------------------------------------------------------
{
  Set_bk_mode    (box, 1);
  Set_text_align (box, align);
  Set_text_colour(box, red, green, blue);
  Draw_text      (box, x, y, size, 0.0, text);
}

void hud_shadow_text(Draw_Box box, Real x, Real y, Real size, Integer align, Integer red, Integer green, Integer blue, Text text)
// ----------------------------------------------------------------
// Text with a dark drop shadow so it reads over the world
// ----------------------------------------------------------------
{
  hud_text(box, x + 1.0, y - 1.0, size, align, 24, 24, 24, text);
  hud_text(box, x, y, size, align, red, green, blue, text);
}

void hud_frame(Draw_Box box, Real x0, Real y0, Real x1, Real y1)
// ----------------------------------------------------------------
// Outline of a rectangle in the current pen colour
// ----------------------------------------------------------------
{
  render_line(box, x0, y0, x1, y0);
  render_line(box, x1, y0, x1, y1);
  render_line(box, x1, y1, x0, y1);
  render_line(box, x0, y1, x0, y0);
}

void hud_icon_face(Draw_Box box, Integer tex, Real shade, Real origin_x, Real origin_y, Real u_x, Real u_y, Real v_x, Real v_y)
// ----------------------------------------------------------------
// One face of an icon cube, split 2 x 2 using the texture's
// quadrant colours; the face is origin + u * (u_x, u_y) + v * (...)
// with v running up the texture
// ----------------------------------------------------------------
{
  Integer quadrant = 0;
  Integer slot     = 0;
  Real    u0       = 0.0;
  Real    v0       = 0.0;

  for (quadrant = 1; quadrant <= 4; ++quadrant) {
    // quadrant 1 top left, 2 top right, 3 bottom left, 4 bottom right
    u0 = 0.0;
    v0 = 0.5;
    if (quadrant == 2 || quadrant == 4) u0 = 0.5;
    if (quadrant >= 3) v0 = 0.0;
    slot = (tex - 1) * 4 + quadrant;
    render_set_colour(box, g_tex_quad_r[slot] * shade, g_tex_quad_g[slot] * shade, g_tex_quad_b[slot] * shade);

    g_icon_x[1] = origin_x + u0 * u_x + v0 * v_x;
    g_icon_y[1] = origin_y + u0 * u_y + v0 * v_y;
    g_icon_x[2] = origin_x + (u0 + 0.5) * u_x + v0 * v_x;
    g_icon_y[2] = origin_y + (u0 + 0.5) * u_y + v0 * v_y;
    g_icon_x[3] = origin_x + (u0 + 0.5) * u_x + (v0 + 0.5) * v_x;
    g_icon_y[3] = origin_y + (u0 + 0.5) * u_y + (v0 + 0.5) * v_y;
    g_icon_x[4] = origin_x + u0 * u_x + (v0 + 0.5) * v_x;
    g_icon_y[4] = origin_y + u0 * u_y + (v0 + 0.5) * v_y;
    Draw_polygon(box, 4, g_icon_x, g_icon_y);
  }
}

void hud_draw_item_icon(Draw_Box box, Integer item, Real centre_x, Real centre_y, Real size)
// ----------------------------------------------------------------
// Picture of an item about size pixels across, centred on a point
// Blocks are little isometric cubes; other items are flat shapes
// ----------------------------------------------------------------
{
  Real    a       = size * 0.5;
  Real    w       = a * 0.87;
  Integer top_tex = 0;
  Integer side    = 0;

  if (item == ITEM_NONE) return;

  if (item_is_block(item)) {
    top_tex = item_top_texture(item);
    side    = item_side_texture(item);
    // top: L, T, R, C   left: LB, B, C, L   right: B, RB, R, C
    hud_icon_face(box, top_tex, 1.0 , centre_x - w, centre_y + a * 0.5,  w,  a * 0.5,  w, -a * 0.5);
    hud_icon_face(box, side   , 0.80, centre_x - w, centre_y - a * 0.5,  w, -a * 0.5,  0.0, a);
    hud_icon_face(box, side   , 0.62, centre_x    , centre_y - a      ,  w,  a * 0.5,  0.0, a);
    return;
  }

  if (item == ITEM_STICK) {
    render_set_colour(box, 104.0, 76.0, 44.0);
    g_icon_x[1] = centre_x - a * 0.80;  g_icon_y[1] = centre_y - a * 0.62;
    g_icon_x[2] = centre_x - a * 0.62;  g_icon_y[2] = centre_y - a * 0.80;
    g_icon_x[3] = centre_x + a * 0.80;  g_icon_y[3] = centre_y + a * 0.62;
    g_icon_x[4] = centre_x + a * 0.62;  g_icon_y[4] = centre_y + a * 0.80;
    Draw_polygon(box, 4, g_icon_x, g_icon_y);
    render_set_colour(box, 150.0, 114.0, 68.0);
    g_icon_x[1] = centre_x - a * 0.70;  g_icon_y[1] = centre_y - a * 0.62;
    g_icon_x[2] = centre_x - a * 0.62;  g_icon_y[2] = centre_y - a * 0.70;
    g_icon_x[3] = centre_x + a * 0.70;  g_icon_y[3] = centre_y + a * 0.62;
    g_icon_x[4] = centre_x + a * 0.62;  g_icon_y[4] = centre_y + a * 0.70;
    Draw_polygon(box, 4, g_icon_x, g_icon_y);
    return;
  }

  // Beef: a rounded slab of meat with a stripe of fat or char
  if (item == ITEM_RAW_BEEF) {
    render_set_colour(box, 192.0, 56.0, 52.0);
  } else {
    render_set_colour(box, 132.0, 80.0, 46.0);
  }
  g_icon_x[1] = centre_x - a * 0.85;  g_icon_y[1] = centre_y + a * 0.10;
  g_icon_x[2] = centre_x - a * 0.55;  g_icon_y[2] = centre_y + a * 0.62;
  g_icon_x[3] = centre_x + a * 0.10;  g_icon_y[3] = centre_y + a * 0.78;
  g_icon_x[4] = centre_x + a * 0.75;  g_icon_y[4] = centre_y + a * 0.45;
  g_icon_x[5] = centre_x + a * 0.88;  g_icon_y[5] = centre_y - a * 0.15;
  g_icon_x[6] = centre_x + a * 0.45;  g_icon_y[6] = centre_y - a * 0.70;
  g_icon_x[7] = centre_x - a * 0.20;  g_icon_y[7] = centre_y - a * 0.78;
  g_icon_x[8] = centre_x - a * 0.72;  g_icon_y[8] = centre_y - a * 0.45;
  Draw_polygon(box, 8, g_icon_x, g_icon_y);

  if (item == ITEM_RAW_BEEF) {
    render_set_colour(box, 236.0, 178.0, 168.0);
  } else {
    render_set_colour(box, 84.0, 48.0, 28.0);
  }
  g_icon_x[1] = centre_x - a * 0.60;  g_icon_y[1] = centre_y + a * 0.30;
  g_icon_x[2] = centre_x + a * 0.55;  g_icon_y[2] = centre_y - a * 0.10;
  g_icon_x[3] = centre_x + a * 0.50;  g_icon_y[3] = centre_y - a * 0.28;
  g_icon_x[4] = centre_x - a * 0.65;  g_icon_y[4] = centre_y + a * 0.12;
  Draw_polygon(box, 4, g_icon_x, g_icon_y);
}

void hud_draw_slot(Draw_Box box, Real x0, Real y0, Real size, Integer item, Integer count, Integer highlight)
// ----------------------------------------------------------------
// A square inventory slot with its bottom left at (x0, y0), the
// item's icon and the stack size
// ----------------------------------------------------------------
{
  Text count_text = "";
  Real text_size  = clamp_real(size * 0.32, 9.0, 14.0);

  render_set_colour(box, 26.0, 27.0, 32.0);
  render_fill_rect (box, x0, y0, x0 + size, y0 + size);
  render_set_colour(box, 70.0, 74.0, 84.0);
  render_fill_rect (box, x0 + 2.0, y0 + 2.0, x0 + size - 2.0, y0 + size - 2.0);
  if (highlight) {
    render_set_colour(box, 250.0, 246.0, 220.0);
    hud_frame(box, x0, y0, x0 + size, y0 + size);
    hud_frame(box, x0 + 1.0, y0 + 1.0, x0 + size - 1.0, y0 + size - 1.0);
  }

  if (item == ITEM_NONE) return;

  hud_draw_item_icon(box, item, x0 + size / 2.0, y0 + size / 2.0 + 1.0, size * 0.62);

  if (count > 1) {
    count_text = To_text(count);
    hud_shadow_text(box, x0 + size - 3.0 - Text_length(count_text) * text_size * 0.58, y0 + text_size + 2.0,
                    text_size, TEXT_ALIGN_LEFT, 255, 255, 255, count_text);
  }
}

// ---------------------------------------------------------------- the HUD

void hud_banner(Draw_Box box, Real centre_x, Real centre_y, Real half_w, Real half_h, Text title, Text line,
                Integer red, Integer green, Integer blue)
// ----------------------------------------------------------------
// Dark box with a coloured title and a line of white text
// ----------------------------------------------------------------
{
  render_set_colour(box, 22.0, 22.0, 28.0);
  render_fill_rect (box, centre_x - half_w, centre_y - half_h, centre_x + half_w, centre_y + half_h);
  render_set_colour(box, red, green, blue);
  hud_frame(box, centre_x - half_w, centre_y - half_h, centre_x + half_w, centre_y + half_h);

  hud_text(box, centre_x, centre_y + half_h - 10.0, 26.0, TEXT_ALIGN_CENTRE, red, green, blue, title);
  hud_text(box, centre_x, centre_y - half_h + 30.0, 13.0, TEXT_ALIGN_CENTRE, 225, 225, 225, line);
}

void hud_help_line(Draw_Box box, Real x, Real &y, Text key, Text what)
// ----------------------------------------------------------------
// One line of the help: key in yellow, description in white
// ----------------------------------------------------------------
{
  hud_text(box, x        , y, 12.0, TEXT_ALIGN_LEFT, 250, 215, 90 , key);
  hud_text(box, x + 140.0, y, 12.0, TEXT_ALIGN_LEFT, 228, 228, 228, what);
  y = y - 15.0;
}

void hud_help_heading(Draw_Box box, Real x, Real &y, Text text)
// ----------------------------------------------------------------
// A heading in the help
// ----------------------------------------------------------------
{
  y = y - 4.0;
  hud_text(box, x, y, 13.0, TEXT_ALIGN_LEFT, 120, 210, 110, text);
  y = y - 17.0;
}

void hud_draw_help(Draw_Box box, Real w, Real h)
// ----------------------------------------------------------------
// The controls, shown at the start and with H
// ----------------------------------------------------------------
{
  Real panel_w = min_real(620.0, w - 30.0);
  Real panel_h = min_real(370.0, h - STATUS_STRIP_HEIGHT - 16.0);
  Real centre  = w / 2.0;
  Real middle  = STATUS_STRIP_HEIGHT + (h - STATUS_STRIP_HEIGHT) / 2.0;
  Real left    = centre - panel_w / 2.0;
  Real top     = middle + panel_h / 2.0;
  Real x       = left + 22.0;
  Real y       = top - 50.0;
  Text title   = GAME_TITLE;

  render_set_colour(box, 20.0, 22.0, 26.0);
  render_fill_rect (box, left, middle - panel_h / 2.0, left + panel_w, top);
  render_set_colour(box, 92.0, 168.0, 80.0);
  hud_frame(box, left, middle - panel_h / 2.0, left + panel_w, top);

  hud_text(box, centre, top - 12.0, 22.0, TEXT_ALIGN_CENTRE, 132, 220, 116, title + " - how to play");

  hud_help_heading(box, x, y, "MOUSE");
  hud_help_line(box, x, y, "Click the view" , "start playing (the mouse turns the camera)");
  hud_help_line(box, x, y, "Left click"     , "break blocks (harder blocks take more hits), hit cows");
  hud_help_line(box, x, y, "Right click"    , "place blocks, eat, use crafting tables and furnaces");
  hud_help_heading(box, x, y, "KEYBOARD");
  hud_help_line(box, x, y, "W A S D"        , "walk (hold one key at a time)");
  hud_help_line(box, x, y, "Space"          , "jump, swim up");
  hud_help_line(box, x, y, "1 - 9"          , "choose a hotbar slot");
  hud_help_line(box, x, y, "E"              , "inventory and hand crafting");
  hud_help_line(box, x, y, "Q"              , "pause and free the mouse, or close a screen");
  hud_help_line(box, x, y, "F / J"          , "auto-walk on/off, auto-jump on/off");
  hud_help_line(box, x, y, "- / ="          , "shorter / longer view distance");
  hud_help_line(box, x, y, "I / H"          , "position info, this help");
  hud_help_heading(box, x, y, "GETTING STARTED");
  hud_text(box, x, y, 12.0, TEXT_ALIGN_LEFT, 228, 228, 228, "Punch a tree for logs, make planks and a crafting table, dig stone for cobblestone");
  y = y - 15.0;
  hud_text(box, x, y, 12.0, TEXT_ALIGN_LEFT, 228, 228, 228, "and build a furnace to cook beef from cows. Keys go to the Keys box below the view.");

  hud_text(box, centre, middle - panel_h / 2.0 + 22.0, 13.0, TEXT_ALIGN_CENTRE, 250, 215, 90, "Click the view to play");
}

Text hud_facing_name()
// ----------------------------------------------------------------
// Compass direction the player faces (north is -z)
// ----------------------------------------------------------------
{
  Integer quarter = positive_mod(floor_integer(g_player_yaw / HALF_PI + 0.5), 4);

  if (quarter == 0) return "east";
  if (quarter == 1) return "south";
  if (quarter == 2) return "west";
  return "north";
}

void hud_draw_hand(Draw_Box box, Real w, Real view_bottom, Real h)
// ----------------------------------------------------------------
// The player's arm in the lower right, holding the selected item;
// it bobs while walking and swings when used
// ----------------------------------------------------------------
{
  Real    swing   = 0.0;
  Real    bob_x   = Sin(g_player_bob) * 6.0;
  Real    bob_y   = Absolute(Cos(g_player_bob)) * 5.0;
  Real    scale   = (h - view_bottom) / 480.0;
  Real    base_x  = 0.0;
  Real    base_y  = 0.0;
  Integer item    = player_held_item();

  if (g_player_swing > 0.0) swing = Sin(g_player_swing / 0.25 * PI);

  base_x = w * 0.80 + bob_x - swing * 60.0 * scale;
  base_y = view_bottom + bob_y + swing * 40.0 * scale;

  // Sleeve and hand
  render_set_colour(box, 64.0, 96.0, 168.0);
  g_icon_x[1] = base_x + 30.0 * scale;   g_icon_y[1] = base_y - 10.0 * scale;
  g_icon_x[2] = base_x + 120.0 * scale;  g_icon_y[2] = base_y - 10.0 * scale;
  g_icon_x[3] = base_x + 64.0 * scale;   g_icon_y[3] = base_y + 96.0 * scale;
  g_icon_x[4] = base_x - 4.0 * scale;    g_icon_y[4] = base_y + 84.0 * scale;
  Draw_polygon(box, 4, g_icon_x, g_icon_y);
  render_set_colour(box, 214.0, 164.0, 124.0);
  g_icon_x[1] = base_x - 4.0 * scale;    g_icon_y[1] = base_y + 84.0 * scale;
  g_icon_x[2] = base_x + 64.0 * scale;   g_icon_y[2] = base_y + 96.0 * scale;
  g_icon_x[3] = base_x + 46.0 * scale;   g_icon_y[3] = base_y + 134.0 * scale;
  g_icon_x[4] = base_x - 18.0 * scale;   g_icon_y[4] = base_y + 120.0 * scale;
  Draw_polygon(box, 4, g_icon_x, g_icon_y);

  if (item != ITEM_NONE) {
    hud_draw_item_icon(box, item, base_x + 4.0 * scale, base_y + 148.0 * scale, 82.0 * scale);
  }
}

void hud_draw_health(Draw_Box box, Real x0, Real y0, Real width)
// ----------------------------------------------------------------
// Health bar of ten segments, each worth two points, flashing when
// low
// ----------------------------------------------------------------
{
  Integer segment = 0;
  Real    gap     = 2.0;
  Real    seg_w   = (width - 9.0 * gap) / 10.0;
  Real    sx      = 0.0;
  Real    fill    = 0.0;
  Real    pulse   = 1.0;

  if (g_player_health <= 6 && Floor(g_hud_now * 4.0) - 2.0 * Floor(g_hud_now * 2.0) > 0.5) pulse = 0.6;

  render_set_colour(box, 18.0, 16.0, 16.0);
  render_fill_rect (box, x0 - 2.0, y0 - 2.0, x0 + width + 2.0, y0 + 12.0);

  for (segment = 1; segment <= 10; ++segment) {
    sx = x0 + (segment - 1) * (seg_w + gap);
    render_set_colour(box, 70.0, 36.0, 36.0);
    render_fill_rect (box, sx, y0, sx + seg_w, y0 + 10.0);
    fill = clamp_real((g_player_health - (segment - 1) * 2.0) / 2.0, 0.0, 1.0);
    if (fill > 0.0) {
      render_set_colour(box, 222.0 * pulse, 48.0 * pulse, 44.0 * pulse);
      render_fill_rect (box, sx, y0, sx + seg_w * fill, y0 + 10.0);
      render_set_colour(box, 250.0 * pulse, 132.0 * pulse, 120.0 * pulse);
      render_fill_rect (box, sx, y0 + 7.0, sx + seg_w * fill, y0 + 10.0);
    }
  }
}

void hud_draw(Draw_Box box, Real w, Real h, Integer captured, Integer screen_open)
// ----------------------------------------------------------------
// Draw the HUD over the 3D view (or behind an inventory screen)
// ----------------------------------------------------------------
{
  Real    strip     = STATUS_STRIP_HEIGHT;
  Real    slot_size = clamp_real((w - 40.0) / 9.0, 26.0, 44.0);
  Real    bar_x     = w / 2.0 - slot_size * 4.5;
  Real    bar_y     = strip + 6.0;
  Real    centre_y  = strip + (h - strip) / 2.0;
  Real    edge      = 0.0;
  Real    y         = 0.0;
  Integer slot      = 0;
  Integer toast     = 0;
  Text    info      = "";

  // Status strip along the bottom (the mouse is parked here)
  render_set_colour(box, 22.0, 24.0, 28.0);
  render_fill_rect (box, 0.0, 0.0, w, strip);
  info = GAME_TITLE;
  info = info + "   seed " + To_text(g_world_seed) + "   view " + To_text(g_render_distance)
       + "   " + To_text(g_frame_ms, 1) + " ms";
  if (g_auto_walk) info = info + "   AUTO-WALK";
  if (!g_auto_jump) info = info + "   auto-jump off";
  hud_text(box, 8.0, strip - 5.0, 11.0, TEXT_ALIGN_LEFT, 170, 176, 186, info);

  if (screen_open) return;

  // Hand, crosshair, hotbar and health
  if (!g_player_dead) hud_draw_hand(box, w, strip, h);

  render_set_colour(box, 240.0, 240.0, 240.0);
  render_line(box, w / 2.0 - 9.0, centre_y, w / 2.0 - 3.0, centre_y);
  render_line(box, w / 2.0 + 3.0, centre_y, w / 2.0 + 9.0, centre_y);
  render_line(box, w / 2.0, centre_y - 9.0, w / 2.0, centre_y - 3.0);
  render_line(box, w / 2.0, centre_y + 3.0, w / 2.0, centre_y + 9.0);

  for (slot = 1; slot <= HOTBAR_SLOTS; ++slot) {
    hud_draw_slot(box, bar_x + (slot - 1) * slot_size, bar_y, slot_size, g_inv_item[slot], g_inv_count[slot],
                  slot == g_player_selected);
  }
  hud_draw_health(box, bar_x, bar_y + slot_size + 8.0, slot_size * 4.5 - 4.0);

  // Name of the item just selected
  if (g_hud_now < g_held_name_until && player_held_item() != ITEM_NONE) {
    hud_shadow_text(box, w / 2.0, bar_y + slot_size + 40.0, 14.0, TEXT_ALIGN_CENTRE, 255, 255, 255,
                    item_name(player_held_item()));
  }

  // Messages, newest at the bottom of the list
  y = bar_y + slot_size + 74.0;
  for (toast = MAX_TOASTS; toast >= 1; --toast) {
    if (g_toast_text[toast] == "" || g_hud_now > g_toast_until[toast]) continue;
    hud_shadow_text(box, 12.0, y, 13.0, TEXT_ALIGN_LEFT, 250, 238, 190, g_toast_text[toast]);
    y = y + 17.0;
  }

  // Position read-out
  if (g_show_debug) {
    info = "x " + To_text(g_player_x, 1) + "   y " + To_text(g_player_y, 1) + "   z " + To_text(g_player_z, 1)
         + "   facing " + hud_facing_name();
    hud_shadow_text(box, 10.0, h - 8.0, 12.0, TEXT_ALIGN_LEFT, 255, 255, 255, info);
    info = "faces " + To_text(g_stat_faces) + "   polygons " + To_text(g_stat_polygons)
         + "   sections " + To_text(g_stat_sections);
    hud_shadow_text(box, 10.0, h - 24.0, 12.0, TEXT_ALIGN_LEFT, 200, 200, 200, info);
  }

  // Red edge when hurt
  if (g_player_hurt > 0.0 && !g_player_dead) {
    edge = 4.0 + g_player_hurt * 24.0;
    render_set_colour(box, 200.0, 16.0, 16.0);
    render_fill_rect(box, 0.0, strip, w, strip + edge);
    render_fill_rect(box, 0.0, h - edge, w, h);
    render_fill_rect(box, 0.0, strip, edge, h);
    render_fill_rect(box, w - edge, strip, w, h);
  }

  if (g_player_dead) {
    hud_banner(box, w / 2.0, centre_y, 210.0, 54.0, "You died", "Press R or click the view to respawn", 230, 60, 50);
  } else if (g_show_help) {
    hud_draw_help(box, w, h);
  } else if (!captured) {
    hud_banner(box, w / 2.0, centre_y, 210.0, 54.0, "Paused", "Click the view to play  -  H for help", 250, 215, 90);
  }
}

#endif
