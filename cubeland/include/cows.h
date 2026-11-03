#ifndef COWS_H_INCLUDED
#define COWS_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// Cows: wander about on land, run off when hit and drop raw beef
//
// All cows live in one record. Cow c has the fields "used_c" (alive),
// "x_c", "y_c", "z_c", "vy_c", "push_x_c", "push_z_c", "yaw_c",
// "goal_yaw_c", "health_c", "walking_c", "timer_c", "panic_c",
// "flash_c", "step_c" and "on_ground_c". Randomness comes from the
// random record passed in.
// ----------------------------------------------------------------

#define COW_WALK_SPEED       1.1
#define COW_PANIC_SPEED      3.2
#define COW_JUMP_SPEED       7.6
#define COW_RESPAWN_SECONDS  25.0
#define COW_ACTIVE_DISTANCE  64.0

#define DATATYPE_COWS        ("cows")
#define ATTR_COW_PUSH_X      ("push_x")
#define ATTR_COW_PUSH_Z      ("push_z")
#define ATTR_COW_GOAL_YAW    ("goal_yaw")
#define ATTR_COW_WALKING     ("walking")
#define ATTR_COW_PANIC       ("panic")
#define ATTR_COW_FLASH       ("flash")
#define ATTR_COW_STEP        ("step")
#define ATTR_COW_RESPAWN     ("respawn_timer")

void    cows_clear         (Attributes &cows);
Integer cow_alive          (Attributes &cows, Integer cow);
void    cow_position       (Attributes &cows, Integer cow, Real &x, Real &y, Real &z);
void    cow_set_position   (Attributes &cows, Integer cow, Real x, Real y, Real z);
Real    cow_yaw            (Attributes &cows, Integer cow);
Real    cow_flash          (Attributes &cows, Integer cow);
Real    cow_step           (Attributes &cows, Integer cow);
Integer cows_alive_count   (Attributes &cows);
Integer cows_spawn         (Attributes &cows, Attributes &random, Real x, Real y, Real z, Real yaw);
Integer cows_spawn_random  (Attributes &cows, Attributes &random, Integer count, Real away_x, Real away_z, Real keep_away);
void    cow_update         (Attributes &cows, Attributes &random, Integer cow, Real dt);
void    cows_update        (Attributes &cows, Attributes &random, Real player_x, Real player_z, Real dt);
Integer cows_ray_hit       (Attributes &cows, Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z,
                            Real max_distance, Real &distance);
void    cow_damage         (Attributes &cows, Attributes &events, Attributes &random, Integer cow, Integer amount, Real push_x, Real push_z);
Integer cows_box_overlaps  (Attributes &cows, Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z);

#endif
