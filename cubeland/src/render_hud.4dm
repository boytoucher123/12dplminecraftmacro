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
#include "../include/records.h"
#include "../include/settings.h"
#include "../include/render.h"
#include "../include/hud.h"

// ---------------------------------------------------------------- messages

void hud_clear(Attributes &hud)
// ----------------------------------------------------------------
// Remove every message; the help shows until the player starts
// ----------------------------------------------------------------
{
  Integer toast = 0;

  record_clear(hud, DATATYPE_HUD);
  for (toast = 1; toast <= MAX_TOASTS; ++toast) {
    record_set_text_at(hud, ATTR_TEXT,      toast, "");
    record_set_real_at(hud, ATTR_HUD_UNTIL, toast, 0.0);
  }
  record_set_integer(hud, ATTR_HUD_HELP,       TRUE);
  record_set_real   (hud, ATTR_HUD_NAME_UNTIL, 0.0);
}

void hud_toast(Attributes &hud, Text text, Real now)
// ----------------------------------------------------------------
// Show a short message above the hotbar; newest on top
// ----------------------------------------------------------------
{
  Integer toast = 0;

  for (toast = MAX_TOASTS; toast >= 2; --toast) {
    record_set_text_at(hud, ATTR_TEXT,      toast, record_text_at(hud, ATTR_TEXT,      toast - 1));
    record_set_real_at(hud, ATTR_HUD_UNTIL, toast, record_real_at(hud, ATTR_HUD_UNTIL, toast - 1));
  }
  record_set_text_at(hud, ATTR_TEXT,      1, text);
  record_set_real_at(hud, ATTR_HUD_UNTIL, 1, now + TOAST_SECONDS);
}

void hud_show_name(Attributes &hud, Real now)
// ----------------------------------------------------------------
// Show the selected item's name for a moment (after changing slot)
// ----------------------------------------------------------------
{
  record_set_real(hud, ATTR_HUD_NAME_UNTIL, now + 1.6);
}

Integer hud_help_shown(Attributes &hud)
// ----------------------------------------------------------------
// TRUE while the help panel is showing
// ----------------------------------------------------------------
{
  return record_integer(hud, ATTR_HUD_HELP);
}

void hud_set_help(Attributes &hud, Integer shown)
// ----------------------------------------------------------------
// Show or hide the help panel
// ----------------------------------------------------------------
{
  record_set_integer(hud, ATTR_HUD_HELP, shown);
}

void hud_on_event(Attributes &event, Attributes &hud, Real now)
// ----------------------------------------------------------------
// Event handler: turn things that happened into messages
// ----------------------------------------------------------------
{
  Integer type  = event_type(event);
  Integer item  = event_integer(event, 1);
  Integer count = event_integer(event, 2);

  if (type == EVT_ITEM_PICKED_UP) {
    hud_toast(hud, "+" + To_text(count) + " " + item_name(item), now);
  } else if (type == EVT_ITEM_CRAFTED) {
    hud_toast(hud, "Crafted " + To_text(count) + " " + item_name(item), now);
  } else if (type == EVT_PLAYER_ATE) {
    hud_toast(hud, "Ate " + item_name(item) + "  (+" + To_text(count) + " health)", now);
  } else if (type == EVT_TOAST) {
    hud_toast(hud, event_text(event), now);
  } else if (type == EVT_WORLD_SAVED) {
    hud_toast(hud, "Saved world " + event_text(event), now);
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

void hud_texture_face(Draw_Box box, Integer tex, Real shade, Integer quick,
                      Real origin_x, Real origin_y, Real u_x, Real u_y, Real v_x, Real v_y)
// ----------------------------------------------------------------
// Draw a texture on the parallelogram origin + u * (u_x, u_y) +
// v * (v_x, v_y), with u running left to right and v up the
// texture. quick draws a block face as its 2 x 2 quadrant colours;
// otherwise the base colour and every rectangle are drawn, giving
// all 16 x 16 pixels. Sprites always draw their rectangles.
// ----------------------------------------------------------------
{
  Integer quadrant = 0;
  Integer slot     = 0;
  Integer rect     = 0;
  Integer last     = 0;
  Integer colour   = 0;
  Integer current  = -1;
  Real    u0       = 0.0;
  Real    v0       = 0.0;
  Real    u1       = 0.0;
  Real    v1       = 0.0;

  if (quick && !g_tex_is_sprite[tex]) {
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
    return;
  }

  if (g_tex_base[tex] > 0) {
    slot = texture_palette_index(tex, g_tex_base[tex]);
    render_set_colour(box, g_tex_pal_r[slot] * shade, g_tex_pal_g[slot] * shade, g_tex_pal_b[slot] * shade);
    g_icon_x[1] = origin_x;                    g_icon_y[1] = origin_y;
    g_icon_x[2] = origin_x + u_x;              g_icon_y[2] = origin_y + u_y;
    g_icon_x[3] = origin_x + u_x + v_x;        g_icon_y[3] = origin_y + u_y + v_y;
    g_icon_x[4] = origin_x + v_x;              g_icon_y[4] = origin_y + v_y;
    Draw_polygon(box, 4, g_icon_x, g_icon_y);
  }

  last = g_tex_rect_first[tex] + g_tex_rect_count[tex] - 1;
  for (rect = g_tex_rect_first[tex]; rect <= last; ++rect) {
    colour = g_rect_pal[rect];
    if (colour != current) {
      slot = texture_palette_index(tex, colour);
      render_set_colour(box, g_tex_pal_r[slot] * shade, g_tex_pal_g[slot] * shade, g_tex_pal_b[slot] * shade);
      current = colour;
    }
    u0 = g_rect_u0[rect];
    u1 = g_rect_u1[rect];
    v0 = g_rect_v0[rect];
    v1 = g_rect_v1[rect];
    g_icon_x[1] = origin_x + u0 * u_x + v0 * v_x;  g_icon_y[1] = origin_y + u0 * u_y + v0 * v_y;
    g_icon_x[2] = origin_x + u1 * u_x + v0 * v_x;  g_icon_y[2] = origin_y + u1 * u_y + v0 * v_y;
    g_icon_x[3] = origin_x + u1 * u_x + v1 * v_x;  g_icon_y[3] = origin_y + u1 * u_y + v1 * v_y;
    g_icon_x[4] = origin_x + u0 * u_x + v1 * v_x;  g_icon_y[4] = origin_y + u0 * u_y + v1 * v_y;
    Draw_polygon(box, 4, g_icon_x, g_icon_y);
  }
}

void hud_draw_item_icon(Draw_Box box, Integer item, Real centre_x, Real centre_y, Real size, Integer detail)
// ----------------------------------------------------------------
// Picture of an item about size pixels across, centred on a point
// Blocks are little isometric cubes (ICON_FULL draws every texture
// pixel, ICON_QUICK just 2 x 2 colours per face); every other item
// is its own 16 x 16 pixel-art sprite
// ----------------------------------------------------------------
{
  Real    a       = size * 0.5;
  Real    w       = a * 0.87;
  Integer top_tex = 0;
  Integer side    = 0;
  Integer quick   = detail == ICON_QUICK;
  Integer sprite  = 0;

  if (item == ITEM_NONE) return;

  if (item_is_block(item)) {
    top_tex = item_top_texture(item);
    side    = item_side_texture(item);
    // top: L, T, R, C   left: LB, B, C, L   right: B, RB, R, C
    hud_texture_face(box, top_tex, 1.0 , quick, centre_x - w, centre_y + a * 0.5,  w, -a * 0.5,  w,  a * 0.5);
    hud_texture_face(box, side   , 0.80, quick, centre_x - w, centre_y - a * 0.5,  w, -a * 0.5,  0.0, a);
    hud_texture_face(box, side   , 0.62, quick, centre_x    , centre_y - a      ,  w,  a * 0.5,  0.0, a);
    return;
  }

  sprite = item_sprite_texture(item);
  if (sprite > 0) hud_texture_face(box, sprite, 1.0, FALSE, centre_x - a, centre_y - a, size, 0.0, 0.0, size);
}

void hud_draw_slot(Draw_Box box, Real x0, Real y0, Real size, Integer item, Integer count, Integer damage, Integer highlight)
// ----------------------------------------------------------------
// A square inventory slot with its bottom left at (x0, y0), the
// item's icon, the stack size and, for a worn tool, a wear bar
// ----------------------------------------------------------------
{
  Text    count_text = "";
  Real    text_size  = clamp_real(size * 0.32, 9.0, 14.0);
  Integer uses       = item_max_uses(item);
  Real    left       = 0.0;

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

  hud_draw_item_icon(box, item, x0 + size / 2.0, y0 + size / 2.0 + 1.0, size * 0.62, ICON_QUICK);

  if (count > 1) {
    count_text = To_text(count);
    hud_shadow_text(box, x0 + size - 3.0 - Text_length(count_text) * text_size * 0.58, y0 + text_size + 2.0,
                    text_size, TEXT_ALIGN_LEFT, 255, 255, 255, count_text);
  }

  if (uses > 0 && damage > 0) {
    left = clamp_real(1.0 - damage * 1.0 / uses, 0.0, 1.0);
    render_set_colour(box, 20.0, 20.0, 20.0);
    render_fill_rect (box, x0 + 4.0, y0 + 3.0, x0 + size - 4.0, y0 + 6.0);
    render_set_colour(box, 255.0 * (1.0 - left), 220.0 * left, 40.0);
    render_fill_rect (box, x0 + 4.0, y0 + 3.0, x0 + 4.0 + (size - 8.0) * left, y0 + 6.0);
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
  hud_help_line(box, x, y, "E"              , "inventory and 2 x 2 crafting");
  hud_help_line(box, x, y, "Q"              , "pause and free the mouse, or close a screen");
  hud_help_line(box, x, y, "F / J"          , "auto-walk on/off, auto-jump on/off");
  hud_help_line(box, x, y, "- / ="          , "shorter / longer view distance");
  hud_help_line(box, x, y, "I / H / O"      , "position info, this help, settings");
  hud_help_heading(box, x, y, "GETTING STARTED");
  hud_text(box, x, y, 12.0, TEXT_ALIGN_LEFT, 228, 228, 228, "Your house has a crafting table and a furnace. Punch trees for logs, lay out planks");
  y = y - 15.0;
  hud_text(box, x, y, 12.0, TEXT_ALIGN_LEFT, 228, 228, 228, "and sticks in the grid for a pickaxe - stone only drops if you mine it with one.");

  hud_text(box, centre, middle - panel_h / 2.0 + 22.0, 13.0, TEXT_ALIGN_CENTRE, 250, 215, 90, "Click the view to play");
}

Text hud_facing_name(Real yaw)
// ----------------------------------------------------------------
// Compass direction for a yaw (north is -z)
// ----------------------------------------------------------------
{
  Integer quarter = positive_mod(floor_integer(yaw / HALF_PI + 0.5), 4);

  if (quarter == 0) return "east";
  if (quarter == 1) return "south";
  if (quarter == 2) return "west";
  return "north";
}

void hud_draw_hand(Draw_Box box, Real w, Real view_bottom, Real h, Integer item, Real bob, Real swing_time)
// ----------------------------------------------------------------
// The player's arm in the lower right, holding item; it bobs while
// walking (bob is the walking phase) and swings when used
// ----------------------------------------------------------------
{
  Real swing  = 0.0;
  Real bob_x  = Sin(bob) * 6.0;
  Real bob_y  = Absolute(Cos(bob)) * 5.0;
  Real scale  = (h - view_bottom) / 480.0;
  Real base_x = 0.0;
  Real base_y = 0.0;

  if (swing_time > 0.0) swing = Sin(swing_time / 0.25 * PI);

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
    hud_draw_item_icon(box, item, base_x + 4.0 * scale, base_y + 148.0 * scale, 82.0 * scale, ICON_FULL);
  }
}

void hud_draw_health(Draw_Box box, Real x0, Real y0, Real width, Integer health, Real now)
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

  if (health <= 6 && Floor(now * 4.0) - 2.0 * Floor(now * 2.0) > 0.5) pulse = 0.6;

  render_set_colour(box, 18.0, 16.0, 16.0);
  render_fill_rect (box, x0 - 2.0, y0 - 2.0, x0 + width + 2.0, y0 + 12.0);

  for (segment = 1; segment <= 10; ++segment) {
    sx = x0 + (segment - 1) * (seg_w + gap);
    render_set_colour(box, 70.0, 36.0, 36.0);
    render_fill_rect (box, sx, y0, sx + seg_w, y0 + 10.0);
    fill = clamp_real((health - (segment - 1) * 2.0) / 2.0, 0.0, 1.0);
    if (fill > 0.0) {
      render_set_colour(box, 222.0 * pulse, 48.0 * pulse, 44.0 * pulse);
      render_fill_rect (box, sx, y0, sx + seg_w * fill, y0 + 10.0);
      render_set_colour(box, 250.0 * pulse, 132.0 * pulse, 120.0 * pulse);
      render_fill_rect (box, sx, y0 + 7.0, sx + seg_w * fill, y0 + 10.0);
    }
  }
}

void hud_draw(Draw_Box box, Real w, Real h, Integer captured, Integer screen_open,
              Attributes &hud, Attributes &player, Attributes &inventory, Attributes &settings,
              Integer seed, Real frame_ms, Text render_stats, Real now)
// ----------------------------------------------------------------
// Draw the HUD over the 3D view (or just the status strip behind an
// inventory screen)
// ----------------------------------------------------------------
{
  Real    strip     = STATUS_STRIP_HEIGHT;
  Real    slot_size = clamp_real((w - 40.0) / 9.0, 26.0, 44.0);
  Real    bar_x     = w / 2.0 - slot_size * 4.5;
  Real    bar_y     = strip + 6.0;
  Real    centre_y  = strip + (h - strip) / 2.0;
  Real    edge      = 0.0;
  Real    y         = 0.0;
  Real    px        = 0.0;
  Real    py        = 0.0;
  Real    pz        = 0.0;
  Real    yaw       = 0.0;
  Real    pitch     = 0.0;
  Real    hurt      = player_hurt_time(player);
  Integer dead      = player_is_dead(player);
  Integer held      = player_held_item(player, inventory);
  Integer slot      = 0;
  Integer toast     = 0;
  Text    info      = "";
  Text    message   = "";

  // Status strip along the bottom (the mouse is parked here)
  render_set_colour(box, 22.0, 24.0, 28.0);
  render_fill_rect (box, 0.0, 0.0, w, strip);
  info = GAME_TITLE;
  info = info + "   seed " + To_text(seed) + "   view " + To_text(settings_render_distance(settings))
       + "   " + To_text(frame_ms, 1) + " ms";
  if (player_auto_walk(player)) info = info + "   AUTO-WALK";
  if (!settings_flag(settings, ATTR_SET_AUTO_JUMP)) info = info + "   auto-jump off";
  hud_text(box, 8.0, strip - 5.0, 11.0, TEXT_ALIGN_LEFT, 170, 176, 186, info);

  if (screen_open) return;

  if (settings_flag(settings, ATTR_SET_SHOW_HUD)) {
    // Hand, crosshair, hotbar and health
    if (!dead) hud_draw_hand(box, w, strip, h, held, player_bob(player), player_swing_time(player));

    render_set_colour(box, 240.0, 240.0, 240.0);
    render_line(box, w / 2.0 - 9.0, centre_y, w / 2.0 - 3.0, centre_y);
    render_line(box, w / 2.0 + 3.0, centre_y, w / 2.0 + 9.0, centre_y);
    render_line(box, w / 2.0, centre_y - 9.0, w / 2.0, centre_y - 3.0);
    render_line(box, w / 2.0, centre_y + 3.0, w / 2.0, centre_y + 9.0);

    for (slot = 1; slot <= HOTBAR_SLOTS; ++slot) {
      hud_draw_slot(box, bar_x + (slot - 1) * slot_size, bar_y, slot_size,
                    slot_item(inventory, slot), slot_count(inventory, slot), slot_damage(inventory, slot),
                    slot == player_selected(player));
    }
    hud_draw_health(box, bar_x, bar_y + slot_size + 8.0, slot_size * 4.5 - 4.0, player_health(player), now);

    // Name of the item just selected
    if (now < record_real(hud, ATTR_HUD_NAME_UNTIL) && held != ITEM_NONE) {
      hud_shadow_text(box, w / 2.0, bar_y + slot_size + 40.0, 14.0, TEXT_ALIGN_CENTRE, 255, 255, 255, item_name(held));
    }
  }

  // Messages, newest at the bottom of the list
  y = bar_y + slot_size + 74.0;
  for (toast = MAX_TOASTS; toast >= 1; --toast) {
    message = record_text_at(hud, ATTR_TEXT, toast);
    if (message == "" || now > record_real_at(hud, ATTR_HUD_UNTIL, toast)) continue;
    hud_shadow_text(box, 12.0, y, 13.0, TEXT_ALIGN_LEFT, 250, 238, 190, message);
    y = y + 17.0;
  }

  // Position read-out
  if (settings_flag(settings, ATTR_SET_SHOW_DEBUG)) {
    player_position(player, px, py, pz);
    player_look    (player, yaw, pitch);
    info = "x " + To_text(px, 1) + "   y " + To_text(py, 1) + "   z " + To_text(pz, 1) + "   facing " + hud_facing_name(yaw);
    hud_shadow_text(box, 10.0, h - 8.0, 12.0, TEXT_ALIGN_LEFT, 255, 255, 255, info);
    hud_shadow_text(box, 10.0, h - 24.0, 12.0, TEXT_ALIGN_LEFT, 200, 200, 200, render_stats);
  }

  // Red edge when hurt
  if (hurt > 0.0 && !dead) {
    edge = 4.0 + hurt * 24.0;
    render_set_colour(box, 200.0, 16.0, 16.0);
    render_fill_rect(box, 0.0, strip, w, strip + edge);
    render_fill_rect(box, 0.0, h - edge, w, h);
    render_fill_rect(box, 0.0, strip, edge, h);
    render_fill_rect(box, w - edge, strip, w, h);
  }

  if (dead) {
    hud_banner(box, w / 2.0, centre_y, 210.0, 54.0, "You died", "Press R or click the view to respawn", 230, 60, 50);
  } else if (hud_help_shown(hud)) {
    hud_draw_help(box, w, h);
  } else if (!captured) {
    hud_banner(box, w / 2.0, centre_y, 210.0, 54.0, "Paused", "Click the view to play  -  H for help", 250, 215, 90);
  }
}

#endif
