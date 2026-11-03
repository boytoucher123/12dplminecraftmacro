#ifndef PANELS_H_INCLUDED
#define PANELS_H_INCLUDED

#include "records.h"

// ----------------------------------------------------------------
// The 12d panels: the world menu, the settings and the game itself
// (the controllers that turn 12d events into game actions). These
// are the only functions that name the global records in game.h.
// ----------------------------------------------------------------

#define MENU_RESULT_QUIT     0
#define MENU_RESULT_PLAY     1   // load the world named ATTR_MENU_WORLD
#define MENU_RESULT_CREATE   2   // create it from ATTR_MENU_SEED

#define GAME_VIEW_WIDTH      860
#define GAME_VIEW_HEIGHT     520
#define PAUSED_FRAME_GAP     0.25

// The menu's choice is left in the game record
#define ATTR_MENU_WORLD      ("menu_world")
#define ATTR_MENU_SEED       ("menu_seed")

Integer menu_panel_run       (Attributes &game, Attributes &random, Attributes &settings);
Integer settings_panel_run   (Attributes &settings);
void    settings_panel_show  (Attributes &settings, Colour_Message_Box render_row, Colour_Message_Box detail_row,
                              Colour_Message_Box fov_row, Colour_Message_Box mouse_row, Colour_Message_Box plants_row,
                              Colour_Message_Box shading_row, Colour_Message_Box jump_row, Colour_Message_Box hud_row,
                              Colour_Message_Box debug_row);
Integer menu_refresh_worlds  (List_Box world_list);
Integer game_panel_split_xy  (Text msg, Real &x, Real &y);
Integer game_panel_calibrate (Draw_Box box, Real box_x, Real box_y, Integer width, Integer height, Integer &origin_x, Integer &origin_y);
void    game_panel_notice    (Draw_Box box, Text title, Text line);
void    game_panel_dispatch  (Real now);
Integer game_panel_save      ();
void    game_panel_close_screen();
void    game_panel_render    (Draw_Box box, Integer captured, Real frame_ms, Real now);
Integer game_panel_run       (Text world_name, Integer create, Integer seed);

#endif
