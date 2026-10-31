#ifndef PLAYER_H_INCLUDED
#define PLAYER_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// The player: position, look direction, health, movement input,
// what the crosshair is on, and the hit / use actions
// ----------------------------------------------------------------

#define TARGET_NONE   0
#define TARGET_BLOCK  1
#define TARGET_COW    2

/*Global variables*/ {
  Real    g_player_x      = 64.5;
  Real    g_player_y      = 70.0;
  Real    g_player_z      = 64.5;
  Real    g_player_vx     = 0.0;
  Real    g_player_vy     = 0.0;
  Real    g_player_vz     = 0.0;
  Real    g_player_yaw    = 0.0;
  Real    g_player_pitch  = 0.0;

  Integer g_player_health       = PLAYER_MAX_HEALTH;
  Integer g_player_dead         = FALSE;
  Integer g_player_on_ground    = FALSE;
  Integer g_player_in_water     = FALSE;
  Integer g_player_eye_in_water = FALSE;
  Real    g_player_fall_peak    = 0.0;
  Real    g_player_regen        = 0.0;
  Real    g_player_hurt         = 0.0;
  Real    g_player_swing        = 0.0;
  Real    g_player_bob          = 0.0;
  Integer g_player_selected     = 1;

  Integer g_auto_jump = TRUE;
  Integer g_auto_walk = FALSE;

  // Movement input (only the last key auto-repeats, no key-up)
  Text    g_move_key       = "";
  Real    g_move_until     = 0.0;
  Real    g_move_last      = 0.0;
  Real    g_move_start     = 0.0;
  Integer g_move_held      = FALSE;
  Real    g_jump_until     = 0.0;

  // What the crosshair is pointing at
  Integer g_target_kind     = TARGET_NONE;
  Integer g_target_x        = 0;
  Integer g_target_y        = 0;
  Integer g_target_z        = 0;
  Integer g_target_normal_x = 0;
  Integer g_target_normal_y = 0;
  Integer g_target_normal_z = 0;
  Integer g_target_cow      = 0;

  // Block being broken
  Integer g_break_x    = 0;
  Integer g_break_y    = -1;
  Integer g_break_z    = 0;
  Integer g_break_hits = 0;
  Real    g_break_time = 0.0;

  Real    g_game_clock = 0.0;
}

void    player_reset           (Real x, Real y, Real z);
Real    player_eye_y           ();
void    player_look_direction  (Real &dir_x, Real &dir_y, Real &dir_z);
void    player_turn            (Real yaw_change, Real pitch_change);
void    player_key_pressed     (Text key, Real now);
Integer player_key_active      (Text key, Real now);
void    player_update          (Real dt, Real now);
void    player_update_target   ();
void    player_damage          (Integer amount);
void    player_primary_action  (Real now);
void    player_secondary_action(Real now);
Integer player_break_stage     ();
Integer player_held_item       ();

#endif
