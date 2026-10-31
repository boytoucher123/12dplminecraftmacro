#ifndef HUD_H_INCLUDED
#define HUD_H_INCLUDED

// ----------------------------------------------------------------
// Everything drawn flat over the 3D view: crosshair, hotbar, health,
// the hand, messages, the status strip and the help / pause / death
// overlays. Also the item icons shared with the inventory screens.
// ----------------------------------------------------------------

#define MAX_TOASTS          4
#define TOAST_SECONDS       3.0
#define TEXT_ALIGN_LEFT     0     // top left of the text at (x, y)
#define TEXT_ALIGN_CENTRE   30    // top centre of the text at (x, y)

/*Global variables*/ {
  Text    g_toast_text [MAX_TOASTS];
  Real    g_toast_until[MAX_TOASTS];
  Real    g_held_name_until = 0.0;
  Integer g_show_help       = TRUE;
  Integer g_show_debug      = FALSE;
  Real    g_hud_now         = 0.0;
  Real    g_frame_ms        = 0.0;

  Real    g_icon_x[8];
  Real    g_icon_y[8];
}

void hud_clear          ();
void hud_toast          (Text text);
void hud_on_event       ();
void hud_text           (Draw_Box box, Real x, Real y, Real size, Integer align, Integer red, Integer green, Integer blue, Text text);
void hud_shadow_text    (Draw_Box box, Real x, Real y, Real size, Integer align, Integer red, Integer green, Integer blue, Text text);
void hud_frame          (Draw_Box box, Real x0, Real y0, Real x1, Real y1);
void hud_draw_item_icon (Draw_Box box, Integer item, Real centre_x, Real centre_y, Real size);
void hud_draw_slot      (Draw_Box box, Real x0, Real y0, Real size, Integer item, Integer count, Integer highlight);
void hud_draw           (Draw_Box box, Real w, Real h, Integer captured, Integer screen_open);

#endif
