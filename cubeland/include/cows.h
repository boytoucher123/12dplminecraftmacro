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

void    cows_clear         (Attributes &p_cows);
Integer cow_alive          (Attributes &p_cows, Integer p_cow);
void    cow_position       (Attributes &p_cows, Integer p_cow, Real &p_x, Real &p_y, Real &p_z);
void    cow_set_position   (Attributes &p_cows, Integer p_cow, Real p_x, Real p_y, Real p_z);
Real    cow_yaw            (Attributes &p_cows, Integer p_cow);
Real    cow_flash          (Attributes &p_cows, Integer p_cow);
Real    cow_step           (Attributes &p_cows, Integer p_cow);
Integer cows_alive_count   (Attributes &p_cows);
Integer cows_spawn         (Attributes &p_cows, Attributes &p_random, Real p_x, Real p_y, Real p_z, Real p_yaw);
Integer cows_spawn_random  (Attributes &p_cows, Attributes &p_random, Integer p_count, Real p_away_x, Real p_away_z, Real p_keep_away);
void    cow_update         (Attributes &p_cows, Attributes &p_random, Integer p_cow, Real p_dt);
void    cows_update        (Attributes &p_cows, Attributes &p_random, Real p_player_x, Real p_player_z, Real p_dt);
Integer cows_ray_hit       (Attributes &p_cows, Real p_origin_x, Real p_origin_y, Real p_origin_z, Real p_dir_x, Real p_dir_y, Real p_dir_z,
                            Real p_max_distance, Real &p_distance);
void    cow_damage         (Attributes &p_cows, Attributes &p_events, Attributes &p_random, Integer p_cow, Integer p_amount, Real p_push_x, Real p_push_z);
Integer cows_box_overlaps  (Attributes &p_cows, Real p_min_x, Real p_min_y, Real p_min_z, Real p_max_x, Real p_max_y, Real p_max_z);

#endif
