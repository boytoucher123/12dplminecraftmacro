#ifndef RENDER_H_INCLUDED
#define RENDER_H_INCLUDED

// ----------------------------------------------------------------
// First person 3D view drawn with Draw_Box polygons
//
// Every visible face is projected through a pinhole camera and
// painted far to near (painter's algorithm). For unit cubes on a
// grid, ordering by the distance from the eye to each cube's centre
// is a valid back to front order, so faces are bucket sorted by the
// squared distance of the cube (or entity box) they belong to.
//
// Close faces are drawn with their full 16 x 16 texture (base
// colour plus merged rectangles), faces a little further away with
// just the larger patches, distant faces as one average colour. Colours are shaded per face direction and fade into the
// sky with distance.
// ----------------------------------------------------------------

#define MAX_DRAW_FACES     7000
#define MAX_BUCKETS        2048
#define BUCKETS_PER_UNIT   2.0     // buckets per unit of squared distance
#define NEAR_PLANE         0.05
#define FIELD_OF_VIEW      1.22    // horizontal, radians (about 70 degrees)
#define GUARD_BAND         3000.0  // screen clipping only past this many pixels
#define MAX_POLY_POINTS    24
#define WATER_TOP          0.875   // height of a water surface in its cell
#define CUBE_RADIUS        0.87    // half the diagonal of a block
#define SECTION_RADIUS     13.9    // half the diagonal of a section
#define DETAIL_FLAT        0       // one average colour
#define DETAIL_MAJOR       1       // base colour and the larger patches
#define DETAIL_FULL        2       // every pixel of the texture
#define MAJOR_RECT_AREA    3       // patches of fewer pixels are left out at DETAIL_MAJOR

/*Global variables*/ {
  // Settings
  Integer g_render_distance  = 18;
  Real    g_lod_full_pixels  = 110.0;  // faces bigger than this get the whole texture
  Real    g_lod_major_pixels = 44.0;   // faces bigger than this get its larger patches
  Integer g_detail_level     = 2;      // 1 low, 2 normal, 3 high

  // Camera, rebuilt every frame
  Real    g_cam_x = 0.0;
  Real    g_cam_y = 0.0;
  Real    g_cam_z = 0.0;
  Real    g_right_x = 0.0;
  Real    g_right_z = 0.0;
  Real    g_up_x = 0.0;
  Real    g_up_y = 0.0;
  Real    g_up_z = 0.0;
  Real    g_fwd_x = 0.0;
  Real    g_fwd_y = 0.0;
  Real    g_fwd_z = 0.0;
  Real    g_focal    = 400.0;
  Real    g_screen_w = 800.0;
  Real    g_screen_h = 480.0;
  Real    g_centre_x = 400.0;
  Real    g_centre_y = 240.0;
  Real    g_view_bottom = 0.0;
  Real    g_cull_cos_x = 0.0;
  Real    g_cull_sin_x = 0.0;
  Real    g_cull_cos_y = 0.0;
  Real    g_cull_sin_y = 0.0;

  // Fog and sky
  Real    g_fog_start = 10.0;
  Real    g_fog_end   = 18.0;
  Real    g_fog_r = 170.0;
  Real    g_fog_g = 205.0;
  Real    g_fog_b = 245.0;

  // Face buffer for one frame
  Integer g_face_total = 0;
  Real    g_df_c0x[MAX_DRAW_FACES];
  Real    g_df_c0y[MAX_DRAW_FACES];
  Real    g_df_c0z[MAX_DRAW_FACES];
  Real    g_df_e1x[MAX_DRAW_FACES];
  Real    g_df_e1y[MAX_DRAW_FACES];
  Real    g_df_e1z[MAX_DRAW_FACES];
  Real    g_df_e2x[MAX_DRAW_FACES];
  Real    g_df_e2y[MAX_DRAW_FACES];
  Real    g_df_e2z[MAX_DRAW_FACES];
  Integer g_df_tex    [MAX_DRAW_FACES];
  Real    g_df_shade  [MAX_DRAW_FACES];
  Real    g_df_fog    [MAX_DRAW_FACES];
  Real    g_df_tint   [MAX_DRAW_FACES];
  Integer g_df_detail [MAX_DRAW_FACES];
  Integer g_df_front  [MAX_DRAW_FACES];
  Integer g_df_crack  [MAX_DRAW_FACES];
  Integer g_df_next   [MAX_DRAW_FACES];
  Integer g_bucket_head[MAX_BUCKETS];

  // The face being drawn
  Real    g_q_c0x = 0.0;
  Real    g_q_c0y = 0.0;
  Real    g_q_c0z = 0.0;
  Real    g_q_e1x = 0.0;
  Real    g_q_e1y = 0.0;
  Real    g_q_e1z = 0.0;
  Real    g_q_e2x = 0.0;
  Real    g_q_e2y = 0.0;
  Real    g_q_e2z = 0.0;
  Integer g_q_front = 0;
  Integer g_q_safe  = 0;
  Real    g_q_keep  = 1.0;
  Real    g_q_add_r = 0.0;
  Real    g_q_add_g = 0.0;
  Real    g_q_add_b = 0.0;

  // Result of render_to_camera
  Real    g_tc_x = 0.0;
  Real    g_tc_y = 0.0;
  Real    g_tc_z = 0.0;

  // Polygon scratch: camera space input, clipped output, screen
  Integer g_clip_count = 0;
  Real    g_clip_x[MAX_POLY_POINTS];
  Real    g_clip_y[MAX_POLY_POINTS];
  Real    g_clip_z[MAX_POLY_POINTS];
  Real    g_poly_x[MAX_POLY_POINTS];
  Real    g_poly_y[MAX_POLY_POINTS];
  Real    g_temp_x[MAX_POLY_POINTS];
  Real    g_temp_y[MAX_POLY_POINTS];
  Real    g_temp_z[MAX_POLY_POINTS];

  // Crack pattern drawn over a block being broken (face u, v)
  Real    g_crack_u0[8];
  Real    g_crack_v0[8];
  Real    g_crack_u1[8];
  Real    g_crack_v1[8];

  // Statistics for the frame
  Integer g_stat_faces    = 0;
  Integer g_stat_polygons = 0;
  Integer g_stat_sections = 0;
}

void    render_init            ();
void    render_set_detail      (Integer level);
void    render_set_colour      (Draw_Box box, Real red, Real green, Real blue);
void    render_set_face_colour (Draw_Box box, Real red, Real green, Real blue);
void    render_fill_rect       (Draw_Box box, Real x0, Real y0, Real x1, Real y1);
void    render_line            (Draw_Box box, Real x0, Real y0, Real x1, Real y1);
void    render_setup_camera    (Real w, Real h, Real view_bottom);
void    render_to_camera       (Real rel_x, Real rel_y, Real rel_z);
Integer render_sphere_visible  (Real rel_x, Real rel_y, Real rel_z, Real radius);
void    render_add_face        (Real c0x, Real c0y, Real c0z, Real e1x, Real e1y, Real e1z, Real e2x, Real e2y, Real e2z,
                                Integer tex, Real shade, Real distance_squared, Real size, Real tint, Integer crack);
void    render_add_block_face  (Integer x, Integer y, Integer z, Integer direction, Integer block, Real distance_squared, Integer crack);
void    render_collect_blocks  ();
void    render_add_box         (Real centre_x, Real centre_y, Real centre_z, Real yaw, Real half_f, Real half_y, Real half_s,
                                Integer tex_side, Integer tex_top, Integer tex_front, Real tint);
void    render_collect_cows    ();
void    render_collect_drops   ();
Integer render_clip_and_draw   (Draw_Box box);
void    render_quad            (Draw_Box box, Real u0, Real v0, Real u1, Real v1);
void    render_draw_face       (Draw_Box box, Integer face);
void    render_draw_faces      (Draw_Box box);
void    render_sky             (Draw_Box box);
void    render_target_outline  (Draw_Box box);
void    render_world           (Draw_Box box, Real w, Real h, Real view_bottom);

#endif
