#ifndef PLAYER_H_INCLUDED
#define PLAYER_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// The player record: position, look direction, health, movement
// input, what the crosshair is on, and the hit / use actions
//
// Every function takes the player record (and whatever else it
// uses) as a parameter. Other modules use the accessors below
// rather than naming fields.
// ----------------------------------------------------------------

#define TARGET_NONE   0
#define TARGET_BLOCK  1
#define TARGET_COW    2

#define DATATYPE_PLAYER          ("player")
#define ATTR_PLAYER_DEAD         ("dead")
#define ATTR_PLAYER_IN_WATER     ("in_water")
#define ATTR_PLAYER_EYE_IN_WATER ("eye_in_water")
#define ATTR_PLAYER_FALL_PEAK    ("fall_peak")
#define ATTR_PLAYER_REGEN        ("regen")
#define ATTR_PLAYER_HURT         ("hurt")
#define ATTR_PLAYER_SWING        ("swing")
#define ATTR_PLAYER_BOB          ("bob")
#define ATTR_PLAYER_SELECTED     ("selected")
#define ATTR_PLAYER_AUTO_WALK    ("auto_walk")
#define ATTR_MOVE_KEY            ("move_key")
#define ATTR_MOVE_UNTIL          ("move_until")
#define ATTR_MOVE_LAST           ("move_last")
#define ATTR_MOVE_START          ("move_start")
#define ATTR_MOVE_HELD           ("move_held")
#define ATTR_JUMP_UNTIL          ("jump_until")
#define ATTR_TARGET_KIND         ("target_kind")
#define ATTR_TARGET_X            ("target_x")
#define ATTR_TARGET_Y            ("target_y")
#define ATTR_TARGET_Z            ("target_z")
#define ATTR_TARGET_NORMAL_X     ("target_normal_x")
#define ATTR_TARGET_NORMAL_Y     ("target_normal_y")
#define ATTR_TARGET_NORMAL_Z     ("target_normal_z")
#define ATTR_TARGET_COW          ("target_cow")
#define ATTR_BREAK_X             ("break_x")
#define ATTR_BREAK_Y             ("break_y")
#define ATTR_BREAK_Z             ("break_z")
#define ATTR_BREAK_HITS          ("break_hits")
#define ATTR_BREAK_TIME          ("break_time")
#define ATTR_BREAK_NEEDED        ("break_needed")

// ---------------------------------------------------------------- accessors
void    player_reset           (Attributes &player, Real x, Real y, Real z);
void    player_position        (Attributes &player, Real &x, Real &y, Real &z);
void    player_set_position    (Attributes &player, Real x, Real y, Real z);
void    player_velocity        (Attributes &player, Real &vx, Real &vy, Real &vz);
void    player_set_velocity    (Attributes &player, Real vx, Real vy, Real vz);
void    player_look            (Attributes &player, Real &yaw, Real &pitch);
void    player_set_look        (Attributes &player, Real yaw, Real pitch);
Real    player_eye_y           (Attributes &player);
void    player_look_direction  (Attributes &player, Real &dir_x, Real &dir_y, Real &dir_z);
Integer player_health          (Attributes &player);
void    player_set_health      (Attributes &player, Integer health);
Integer player_is_dead         (Attributes &player);
Integer player_on_ground       (Attributes &player);
Integer player_in_water        (Attributes &player);
Integer player_eye_in_water    (Attributes &player);
Real    player_hurt_time       (Attributes &player);
Real    player_swing_time      (Attributes &player);
Real    player_bob             (Attributes &player);
Real    player_fall_peak       (Attributes &player);
void    player_set_fall_peak   (Attributes &player, Real peak);
Integer player_selected        (Attributes &player);
void    player_set_selected    (Attributes &player, Integer slot);
Integer player_auto_walk       (Attributes &player);
void    player_set_auto_walk   (Attributes &player, Integer on);
Integer player_held_item       (Attributes &player, Attributes &inventory);
Integer player_target_kind     (Attributes &player);
void    player_target_cell     (Attributes &player, Integer &x, Integer &y, Integer &z);
void    player_target_normal   (Attributes &player, Integer &x, Integer &y, Integer &z);
Integer player_target_cow      (Attributes &player);
Integer player_break_stage     (Attributes &player, Real now);

// ---------------------------------------------------------------- behaviour
void    player_turn            (Attributes &player, Real yaw_change, Real pitch_change);
void    player_key_pressed     (Attributes &player, Text key, Real now);
Integer player_key_active      (Attributes &player, Text key, Real now);
void    player_damage          (Attributes &player, Attributes &events, Integer amount);
void    player_update          (Attributes &player, Attributes &cows, Attributes &events, Integer auto_jump, Real dt, Real now);
void    player_update_target   (Attributes &player, Attributes &cows);
Integer player_overlaps_cell   (Attributes &player, Integer x, Integer y, Integer z);
void    player_wear_tool       (Attributes &player, Attributes &inventory, Attributes &events);
void    player_primary_action  (Attributes &player, Attributes &inventory, Attributes &cows, Attributes &events,
                                Attributes &random, Real now);
void    player_secondary_action(Attributes &player, Attributes &inventory, Attributes &cows, Attributes &events, Real now);
Integer player_furnace_facing  (Real player_x, Real player_z, Integer cell_x, Integer cell_z);

#endif
