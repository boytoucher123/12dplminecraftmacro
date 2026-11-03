#ifndef HUD_H_INCLUDED
#define HUD_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// Everything drawn flat over the 3D view: crosshair, hotbar, health,
// the hand, messages, the status strip and the help / pause / death
// overlays. Also the item icons shared with the inventory screens.
//
// The HUD record keeps the messages ("text_n", "until_n" for
// n = 1..MAX_TOASTS, newest first), whether the help is showing and
// until when the selected item's name is shown.
// ----------------------------------------------------------------

#define MAX_TOASTS          4
#define TOAST_SECONDS       3.0
#define TEXT_ALIGN_LEFT     0     // top left of the text at (x, y)
#define TEXT_ALIGN_CENTRE   30    // top centre of the text at (x, y)
#define ICON_QUICK          0     // block icons as 2 x 2 colours (hotbar, hand)
#define ICON_FULL           1     // block icons with their whole 16 x 16 texture

#define DATATYPE_HUD        ("hud")
#define ATTR_HUD_UNTIL      ("until")
#define ATTR_HUD_HELP       ("show_help")
#define ATTR_HUD_NAME_UNTIL ("name_until")

/*Global variables*/ {
  // Polygon scratch for icons
  Real    g_icon_x[8];
  Real    g_icon_y[8];
}

void hud_clear          (Attributes &hud);
void hud_toast          (Attributes &hud, Text text, Real now);
void hud_show_name      (Attributes &hud, Real now);
Integer hud_help_shown  (Attributes &hud);
void hud_set_help       (Attributes &hud, Integer shown);
void hud_on_event       (Attributes &event, Attributes &hud, Real now);
void hud_text           (Draw_Box box, Real x, Real y, Real size, Integer align, Integer red, Integer green, Integer blue, Text text);
void hud_shadow_text    (Draw_Box box, Real x, Real y, Real size, Integer align, Integer red, Integer green, Integer blue, Text text);
void hud_frame          (Draw_Box box, Real x0, Real y0, Real x1, Real y1);
void hud_texture_face   (Draw_Box box, Integer tex, Real shade, Integer quick,
                         Real origin_x, Real origin_y, Real u_x, Real u_y, Real v_x, Real v_y);
void hud_draw_item_icon (Draw_Box box, Integer item, Real centre_x, Real centre_y, Real size, Integer detail);
void hud_draw_slot      (Draw_Box box, Real x0, Real y0, Real size, Integer item, Integer count, Integer damage, Integer highlight);
Text hud_facing_name    (Real yaw);
void hud_draw_hand      (Draw_Box box, Real w, Real view_bottom, Real h, Integer item, Real bob, Real swing_time);
void hud_draw_health    (Draw_Box box, Real x0, Real y0, Real width, Integer health, Real now);
void hud_draw_help      (Draw_Box box, Real w, Real h);
void hud_draw           (Draw_Box box, Real w, Real h, Integer captured, Integer screen_open,
                         Attributes &hud, Attributes &player, Attributes &inventory, Attributes &settings,
                         Integer seed, Real frame_ms, Text render_stats, Real now);

#endif
