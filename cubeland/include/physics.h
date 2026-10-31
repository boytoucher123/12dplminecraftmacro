#ifndef PHYSICS_H_INCLUDED
#define PHYSICS_H_INCLUDED

// ----------------------------------------------------------------
// Box collision against the block grid and ray casting
// A moving body is an upright box: (x, z) is the centre of its
// footprint, y is the bottom, half_width and height its size
// ----------------------------------------------------------------

#define COLLISION_EPSILON  0.0005
#define MAX_MOVE_STEP      0.4

/*Global variables*/ {
  // Set by physics_move_box
  Integer g_hit_x    = 0;
  Integer g_hit_z    = 0;
  Integer g_hit_down = 0;
  Integer g_hit_up   = 0;

  // Set by physics_raycast_blocks
  Integer g_ray_x        = 0;
  Integer g_ray_y        = 0;
  Integer g_ray_z        = 0;
  Integer g_ray_normal_x = 0;
  Integer g_ray_normal_y = 0;
  Integer g_ray_normal_z = 0;
  Real    g_ray_distance = 0.0;
}

Integer physics_box_collides  (Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z);
void    physics_move_box      (Real &x, Real &y, Real &z, Real half_width, Real height, Real dx, Real dy, Real dz);
Integer physics_box_in_water  (Real x, Real y, Real z, Real half_width, Real height);
Integer physics_raycast_blocks(Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z, Real max_distance);
Real    physics_ray_box       (Real origin_x, Real origin_y, Real origin_z, Real dir_x, Real dir_y, Real dir_z,
                               Real min_x, Real min_y, Real min_z, Real max_x, Real max_y, Real max_z);

#endif
