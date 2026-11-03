#ifndef PHYSICS_H_INCLUDED
#define PHYSICS_H_INCLUDED

// ----------------------------------------------------------------
// Box collision against the block grid and ray casting
// A moving body is an upright box: (x, z) is the centre of its
// footprint, y is the bottom, half_width and height its size
// ----------------------------------------------------------------

#define COLLISION_EPSILON  0.0005
#define MAX_MOVE_STEP      0.4

// Table functions: these read the block grid through world_get_block.
// Results come back through reference parameters.

Integer physics_box_collides  (Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z);
void    physics_move_box      (Real &x, Real &y, Real &z, Real half_width, Real height, Real dx, Real dy, Real dz,
                               Integer &hit_x, Integer &hit_z, Integer &hit_down, Integer &hit_up);
Integer physics_box_in_water  (Real x, Real y, Real z, Real half_width, Real height);
Integer physics_raycast_blocks(Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z, Real max_distance,
                               Integer &hit_x, Integer &hit_y, Integer &hit_z,
                               Integer &normal_x, Integer &normal_y, Integer &normal_z, Real &distance);
Real    physics_ray_box       (Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z,
                               Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z);

#endif
