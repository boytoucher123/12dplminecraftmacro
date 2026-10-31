#ifndef PANELS_H_INCLUDED
#define PANELS_H_INCLUDED

// ----------------------------------------------------------------
// The two 12d panels: the world menu and the game itself
// (the controllers that turn 12d events into game actions)
// ----------------------------------------------------------------

#define MENU_RESULT_QUIT     0
#define MENU_RESULT_PLAY     1   // load g_menu_world_name
#define MENU_RESULT_CREATE   2   // create g_menu_world_name from g_menu_seed

#define GAME_VIEW_WIDTH      860
#define GAME_VIEW_HEIGHT     520
#define PAUSED_FRAME_GAP     0.25

/*Global variables*/ {
  Text    g_menu_world_name = "";
  Integer g_menu_seed       = 0;
}

Integer menu_panel_run       ();
Integer menu_refresh_worlds  (List_Box world_list);
Integer game_panel_split_xy  (Text msg, Real &x, Real &y);
Integer game_panel_calibrate (Draw_Box box, Real box_x, Real box_y, Integer width, Integer height, Integer &origin_x, Integer &origin_y);
void    game_panel_notice    (Draw_Box box, Text title, Text line);
void    game_panel_render    (Draw_Box box, Integer captured);
Integer game_panel_run       (Text world_name, Integer create, Integer seed);

#endif
