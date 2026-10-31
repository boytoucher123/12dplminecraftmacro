#ifndef GAME_H_INCLUDED
#define GAME_H_INCLUDED

// ----------------------------------------------------------------
// Game model glue: starting worlds, the per-frame update and the
// event dispatcher that hands each event to every module
// ----------------------------------------------------------------

/*Global variables*/ {
  Integer g_game_initialised = FALSE;
  Real    g_autosave_timer   = 0.0;
}

void    game_init_once        ();
void    game_reset_state      ();
Integer game_new_world        (Text name, Integer seed);
Integer game_load_world       (Text name);
void    game_build_nearby     ();
void    game_respawn          ();
void    game_dispatch_events  ();
void    game_update           (Real dt, Real real_dt, Real now, Integer running);
void    game_select_slot      (Integer slot, Real now);

#endif
