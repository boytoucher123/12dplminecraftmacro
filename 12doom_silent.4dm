//------------------------------------------------------------
// Programmer   Paul Mashford
// Date         26/9/26
// Description of Macro
// 12dOOM, by Paul Mashford -- a Wolfenstein-style raycaster shooter drawn entirely
// with Draw_Box polygons.
//
// Resizable: drag the panel's edges or corner and the game view grows
// or shrinks with it.
//   - Create_panel(title, 1) makes the panel resizable, and
//     Set_sizing_constraints(.., 2, 2) on the view and its group makes
//     the view fill it. 12d won't shrink a panel below its widgets'
//     created size, so the 760 x 460 view (the original fixed size) is the
//     minimum -- probed with bridge/tests/resize_probe.4dm.
//   - Set_notify_resizing(panel) sends Panel_Resize events during a
//     resize; any change in the view's size pauses play (the mouse's
//     parking spot and screen mapping move with the view) and redraws.
//     A resize sends hundreds of these events, so frames for them are
//     limited to 10 a second (drawing one per event queued seconds of
//     work).
//   - Performance: the cost is per raycast column, not per pixel, so
//     columns are capped at MAX_RAYS (320). Up to 1280 px wide (at the
//     default 4 px columns) you get full detail; wider windows just get
//     wider columns, so a full-screen window costs about the same as a
//     1280 px one. Measured: ~4.5 ms/frame at 760 x 460, ~8.5 ms at
//     1568 x 757 (60 fps needs < 16 ms). The frame time is shown top
//     right, and the Output Window logs it every 300 frames along with
//     the view size.
//
//   Right click view -> start / stop mouselook (captures the mouse, 60 fps clock)
//   Mouse            -> turn
//   W / S            -> forward / back
//   A / D            -> strafe
//   Left click / F / Space -> fire
//   M                -> map          1 / 2 / 3 -> detail
//   Q                -> stop mouselook   N -> new random map
//   R                -> restart
//   H                -> help screen (shown at start; pauses the game)
//
// Levels: the built-in E1M1, or a random map from a seed (Random map
// button / N): rooms with wall themes and pillars, L-shaped corridors
// plus extra links, the exit on the wall by the floor cell farthest
// from the start by walking distance. Restart (R) replays the same map.
//
// Find the green exit switch. Grunts (green) charge you, imps
// (brown) throw fireballs. Keys go to the "Keys" box, which keeps
// focus -- clicking the view doesn't take it (see domain-notes.md
// "Real-time input for Draw_Box games" for the probed rules behind
// all of this).
//
// Game clock: 12dPL has no timer. While the mouse is captured, each
// Draw_Box mouse_move turns the view by the offset from a fixed warp
// point, then Set_cursor_position puts the cursor back there,
// alternating by 1 px so every warp generates a fresh mouse_move --
// a steady ~60 events/s with the mouse untouched. Every frame runs
// off that stream, and the game is paused whenever it is off. Capture
// is released (pausing) on RB, Q, loss of focus,
// repeated leaving of the box, or 45 s without real input.
//
// Rendering: DDA raycast per screen column (distance fog, side
// shading, panel seams and mortar lines), z-buffered pixel-art
// sprites drawn column by column as runs of colour, a bobbing
// shotgun, HUD and an optional map. One Start/End batch per frame.
//
// Usage
//   12doom_silent.4do [-random | -seed <n>]
//------------------------------------------------------------

#define MW 24
#define MH 24
#define MCELLS 576
#define MAXENT 48
#define MAXSHOT 24
#define MAXCOL 400
// Most raycast columns per frame. Beyond MAX_RAYS * column width,
// columns just get wider, so a huge window costs about the same as a
// 1280 px one (see the performance note in the header).
#define MAX_RAYS 320

// Movement feel. A fresh key press moves for TAP_TIME s (a held key only
// starts auto-repeating after ~0.5 s, and there are no key-up events),
// starting at TAP_START_SPEED x full speed and reaching full speed
// after TAP_RAMP s: 0.6 / 0.3 / 0.36 s make one tap move ~1 cell at
// WALK_SPEED 3.3 cells/s. A TAP_TIME shorter than the ~0.5 s repeat
// delay leaves a short hitch early in a held key; longer taps go
// further but move smoothly (0.52 s = no hitch, ~1.4 cells a tap).
#define WALK_SPEED 3.3
#define TAP_START_SPEED 0.6
#define TAP_RAMP 0.3
#define TAP_TIME 0.36
#define MAXVIS 80
#define SPR_W 12
#define SPR_H 16
#define SPR_N 6
#define SPR_PIX 1152
#define NPAL 15

#define ENT_GRUNT 1
#define ENT_IMP 2
#define ENT_HEALTH 3
#define ENT_AMMO 4

#define IMG_GRUNT 1
#define IMG_IMP 2
#define IMG_HEALTH 3
#define IMG_AMMO 4
#define IMG_FIRE 5
#define IMG_CORPSE 6

#define ST_IDLE 0
#define ST_CHASE 1
#define ST_DEAD 2

#define GAME_PLAY 1
#define GAME_DEAD 2
#define GAME_WON 3

#define WALL_EXIT 4
#define MAXROOM 12

{
   Real g_pi = 3.14159265358979;
   Real g_hud_h = 46.;

   Integer g_map[MCELLS];
   Text g_rows[MH];

   // Player.
   Real g_px = 1.5;
   Real g_py = 1.5;
   Real g_pa = 0.;
   Integer g_health = 100;
   Real g_health_ghost = 100.;
   Integer g_ammo = 30;
   Integer g_kills = 0;
   Integer g_enemies = 0;
   Integer g_game = GAME_PLAY;
   Real g_time = 0.;
   Real g_fire_cool = 0.;
   Integer g_fire_queued = 0;
   Real g_flash = 0.;
   Real g_hurt = 0.;
   Real g_pickup = 0.;
   Real g_bob = 0.;
   Text g_msg = "";
   Real g_msg_until = 0.;
   Integer g_show_map = 0;
   Integer g_show_help = 1;

   // Level: seed 0 = the built-in E1M1, otherwise a generated map.
   Integer g_seed = 0;
   Text g_level_name = "E1M1";
   Integer g_nroom = 0;
   Integer g_rx[MAXROOM];
   Integer g_ry[MAXROOM];
   Integer g_rw[MAXROOM];
   Integer g_rh[MAXROOM];
   Integer g_dist[MCELLS];
   Integer g_queue[MCELLS];
   Integer g_colw = 4;
   Integer g_captured = 0;

   // Movement key (only the last key pressed auto-repeats, and there
   // are no key-up events, so one movement key is active at a time).
   Real g_now = 0.;
   Text g_key = "";
   Real g_key_until = 0.;
   Real g_key_last = 0.;
   Real g_key_start = 0.;
   Integer g_key_held = 0;

   // Entities: enemies and pickups.
   Integer g_ne = 0;
   Integer g_ek[MAXENT];
   Real g_ex[MAXENT];
   Real g_ey[MAXENT];
   Integer g_ehp[MAXENT];
   Integer g_est[MAXENT];
   Real g_ecool[MAXENT];
   Real g_eflash[MAXENT];
   Real g_elos_t[MAXENT];
   Integer g_esee[MAXENT];

   // Fireballs.
   Integer g_ns = 0;
   Real g_sx[MAXSHOT];
   Real g_sy[MAXSHOT];
   Real g_svx[MAXSHOT];
   Real g_svy[MAXSHOT];
   Real g_slife[MAXSHOT];

   // Sprites: SPR_N images of SPR_W x SPR_H palette indices (0 = clear).
   Integer g_pix[SPR_PIX];
   Real g_spr_scale[SPR_N];
   Real g_spr_lift[SPR_N];
   Text g_pal_chars = "krdoysbnglwxtup";
   Integer g_pal_r[NPAL];
   Integer g_pal_g[NPAL];
   Integer g_pal_b[NPAL];

   // Per-frame render state.
   Real g_zbuf[MAXCOL];
   Integer g_nvis = 0;
   Real g_vdepth[MAXVIS];
   Real g_vsx[MAXVIS];
   Integer g_vimg[MAXVIS];
   Integer g_vflip[MAXVIS];
   Real g_vtint[MAXVIS];
   Real g_qx[4];
   Real g_qy[4];
   Real g_fx[16];
   Real g_fy[16];
   Integer g_vord[MAXVIS];
}

//---------------------------------------------------------------- helpers

Real clampr(Real v, Real lo, Real hi)
{
   Real r = v;
   if (r < lo) r = lo;
   if (r > hi) r = hi;
   return r;
}

Integer to_byte(Real v)
{
   Real c = clampr(v, 0., 255.);
   Integer i = Floor(c);
   return i;
}

Real rnd()
{
   Real r = Get_random_number_closed();
   return r;
}

void set_rgb(Draw_Box box, Real r, Real g, Real b)
{
   Integer ir = to_byte(r);
   Integer ig = to_byte(g);
   Integer ib = to_byte(b);
   Set_colour(box, ir, ig, ib);
   Set_fill_colour(box, ir, ig, ib);
}

void fill_quad(Draw_Box box, Real x1, Real y1, Real x2, Real y2, Real x3, Real y3, Real x4, Real y4)
{
   g_qx[1] = x1;
   g_qy[1] = y1;
   g_qx[2] = x2;
   g_qy[2] = y2;
   g_qx[3] = x3;
   g_qy[3] = y3;
   g_qx[4] = x4;
   g_qy[4] = y4;
   Draw_polygon(box, 4, g_qx, g_qy);
}

void fill_rect(Draw_Box box, Real x1, Real y1, Real x2, Real y2)
{
   fill_quad(box, x1, y1, x2, y1, x2, y2, x1, y2);
}

void draw_line(Draw_Box box, Real x1, Real y1, Real x2, Real y2)
{
   Move_to(box, x1, y1);
   Draw_to(box, x2, y2);
}

// Distance fog: 1 up close, fading towards 0.12.
Real fog(Real d)
{
   Real f = clampr(1.2 - d * 0.085, 0.12, 1.);
   return f;
}

void show_msg(Text msg, Real seconds)
{
   g_msg = msg;
   g_msg_until = g_now + seconds;
}

//---------------------------------------------------------------- map

// Wall type at a cell (0-based), 1 outside the map.
Integer cell(Integer mx, Integer my)
{
   if (mx < 0 || my < 0 || mx >= MW || my >= MH) return 1;
   Integer c = g_map[my * MW + mx + 1];
   return c;
}

Integer cell_at(Real x, Real y)
{
   Integer mx = Floor(x);
   Integer my = Floor(y);
   Integer c = cell(mx, my);
   return c;
}

// Wall type touching a circle of radius r at (x, y), 0 if clear.
Integer blocked(Real x, Real y, Real r)
{
   Integer c = cell_at(x - r, y - r);
   if (c > 0) return c;
   c = cell_at(x + r, y - r);
   if (c > 0) return c;
   c = cell_at(x - r, y + r);
   if (c > 0) return c;
   c = cell_at(x + r, y + r);
   return c;
}

// 1 if nothing solid lies between the two points.
Integer line_of_sight(Real x1, Real y1, Real x2, Real y2)
{
   Real dx = x2 - x1;
   Real dy = y2 - y1;
   Real d = Sqrt(dx * dx + dy * dy);
   Integer steps = Floor(d / 0.2) + 1;
   for (Integer k = 1; k < steps; ++k) {
      Real t = 1. * k / steps;
      if (cell_at(x1 + dx * t, y1 + dy * t) > 0) return 0;
   }
   return 1;
}

void add_entity(Integer kind, Real x, Real y)
{
   if (g_ne >= MAXENT) return;
   ++g_ne;
   g_ek[g_ne] = kind;
   g_ex[g_ne] = x;
   g_ey[g_ne] = y;
   g_est[g_ne] = ST_IDLE;
   g_ecool[g_ne] = 0.5 + rnd();
   g_eflash[g_ne] = 0.;
   g_elos_t[g_ne] = rnd() * 0.3;
   g_esee[g_ne] = 0;
   g_ehp[g_ne] = 0;
   if (kind == ENT_GRUNT) g_ehp[g_ne] = 45;
   if (kind == ENT_IMP) g_ehp[g_ne] = 70;
   if (kind == ENT_GRUNT || kind == ENT_IMP) ++g_enemies;
}

// '#' stone, 'B' brick, 'M' metal, 'E' exit switch, 'P' start (facing
// east), 'g' grunt, 'i' imp, 'h' medkit, 'a' ammo.
void load_level()
{
   g_rows[1]  = "########################";
   g_rows[2]  = "#P.....#......#........#";
   g_rows[3]  = "#......#..g...#..i.....#";
   g_rows[4]  = "#...a.........#....h...#";
   g_rows[5]  = "#......#......#........#";
   g_rows[6]  = "###.####...h..#..#######";
   g_rows[7]  = "#......###..###........#";
   g_rows[8]  = "#..g...#........i.....a#";
   g_rows[9]  = "#......#..M..M.........#";
   g_rows[10] = "#......#...............#";
   g_rows[11] = "#..h.......M..M...g....#";
   g_rows[12] = "#......#...............#";
   g_rows[13] = "####.###.......##.######";
   g_rows[14] = "#......#..i....#.......#";
   g_rows[15] = "#.a....BBBB.BBBB...i...#";
   g_rows[16] = "#......B.......B.......#";
   g_rows[17] = "#..g...B...h...B..MMM..#";
   g_rows[18] = "#......B.......B..MEM..#";
   g_rows[19] = "##.#####...i...B.......#";
   g_rows[20] = "#.....g........B...h...#";
   g_rows[21] = "#.h...........i........#";
   g_rows[22] = "#..a...................#";
   g_rows[23] = "#......................#";
   g_rows[24] = "########################";

   g_ne = 0;
   g_enemies = 0;
   for (Integer r = 1; r <= MH; ++r) {
      for (Integer c = 1; c <= MW; ++c) {
         Text ch = Get_subtext(g_rows[r], c, c);
         Integer v = 0;
         Real x = c - 0.5;
         Real y = r - 0.5;
         if (ch == "#") v = 1;
         if (ch == "B") v = 2;
         if (ch == "M") v = 3;
         if (ch == "E") v = WALL_EXIT;
         if (ch == "P") {
            g_px = x;
            g_py = y;
            g_pa = 0.;
         }
         if (ch == "g") add_entity(ENT_GRUNT, x, y);
         if (ch == "i") add_entity(ENT_IMP, x, y);
         if (ch == "h") add_entity(ENT_HEALTH, x, y);
         if (ch == "a") add_entity(ENT_AMMO, x, y);
         g_map[(r - 1) * MW + c] = v;
      }
   }
}

//---------------------------------------------------------------- random maps

Integer rnd_int(Integer lo, Integer hi)
{
   Integer v = lo + Floor(rnd() * (hi - lo + 1));
   if (v > hi) v = hi;
   return v;
}

void set_cell(Integer mx, Integer my, Integer v)
{
   if (mx < 0 || my < 0 || mx >= MW || my >= MH) return;
   g_map[my * MW + mx + 1] = v;
}

// Carve an L-shaped corridor between two cells, randomly
// horizontal-first or vertical-first.
void carve_corridor(Integer x1, Integer y1, Integer x2, Integer y2)
{
   Integer cx = x1;
   Integer cy = y1;
   Integer horizontal_first = rnd() < 0.5;
   Integer leg = 1;
   while (leg <= 2) {
      Integer do_x = horizontal_first;
      if (leg == 2) do_x = !horizontal_first;
      if (do_x) {
         while (cx != x2) {
            set_cell(cx, cy, 0);
            if (cx < x2) ++cx;
            if (cx > x2) --cx;
         }
      } else {
         while (cy != y2) {
            set_cell(cx, cy, 0);
            if (cy < y2) ++cy;
            if (cy > y2) --cy;
         }
      }
      ++leg;
   }
   set_cell(x2, y2, 0);
}

// 1 if cell (mx, my) is floor with no entity on it or the player.
Integer spot_free(Integer mx, Integer my)
{
   if (cell(mx, my) != 0) return 0;
   Real x = mx + 0.5;
   Real y = my + 0.5;
   if (Absolute(x - g_px) < 1.5 && Absolute(y - g_py) < 1.5) return 0;
   for (Integer i = 1; i <= g_ne; ++i) {
      if (Absolute(g_ex[i] - x) < 0.9 && Absolute(g_ey[i] - y) < 0.9) return 0;
   }
   return 1;
}

// Put an entity on a free cell inside room r (a few tries).
void place_in_room(Integer kind, Integer r)
{
   for (Integer t = 1; t <= 12; ++t) {
      Integer mx = rnd_int(g_rx[r], g_rx[r] + g_rw[r] - 1);
      Integer my = rnd_int(g_ry[r], g_ry[r] + g_rh[r] - 1);
      if (spot_free(mx, my)) {
         add_entity(kind, mx + 0.5, my + 0.5);
         return;
      }
   }
}

// Rooms and corridors from a seed: non-overlapping rooms (each with a
// wall theme, big ones with pillars) joined in order by L-shaped
// corridors plus a couple of extra links for loops. The player starts
// in room 1; the exit switch goes on the wall next to the floor cell
// that's farthest from the start by walking distance.
void gen_level(Integer seed)
{
   Set_random_number(seed, 1);
   for (Integer i = 1; i <= MCELLS; ++i) g_map[i] = 1;
   g_ne = 0;
   g_enemies = 0;

   // Rooms: interior cells [rx, rx + rw - 1] x [ry, ry + rh - 1],
   // kept at least one wall apart and off the outer wall.
   g_nroom = 0;
   for (Integer a = 1; a <= 300 && g_nroom < MAXROOM; ++a) {
      Integer w = rnd_int(3, 7);
      Integer h = rnd_int(3, 7);
      Integer x = rnd_int(1, MW - 1 - w);
      Integer y = rnd_int(1, MH - 1 - h);
      Integer ok = 1;
      for (Integer r = 1; r <= g_nroom; ++r) {
         if (!(x > g_rx[r] + g_rw[r] || g_rx[r] > x + w || y > g_ry[r] + g_rh[r] || g_ry[r] > y + h)) ok = 0;
      }
      if (!ok) continue;
      ++g_nroom;
      g_rx[g_nroom] = x;
      g_ry[g_nroom] = y;
      g_rw[g_nroom] = w;
      g_rh[g_nroom] = h;
      Integer theme = rnd_int(1, 3);
      for (Integer yy = y - 1; yy <= y + h; ++yy) {
         for (Integer xx = x - 1; xx <= x + w; ++xx) {
            if (xx >= x && xx < x + w && yy >= y && yy < y + h) {
               set_cell(xx, yy, 0);
            } else if (xx > 0 && yy > 0 && xx < MW - 1 && yy < MH - 1) {
               set_cell(xx, yy, theme);
            }
         }
      }
   }

   // Corridors between room centres.
   for (Integer c = 2; c <= g_nroom; ++c) {
      carve_corridor(g_rx[c - 1] + Floor(g_rw[c - 1] / 2.), g_ry[c - 1] + Floor(g_rh[c - 1] / 2.),
         g_rx[c] + Floor(g_rw[c] / 2.), g_ry[c] + Floor(g_rh[c] / 2.));
   }
   for (Integer e = 1; e <= 2 && g_nroom >= 3; ++e) {
      Integer r1 = rnd_int(1, g_nroom);
      Integer r2 = rnd_int(1, g_nroom);
      if (r1 != r2) {
         carve_corridor(g_rx[r1] + Floor(g_rw[r1] / 2.), g_ry[r1] + Floor(g_rh[r1] / 2.),
            g_rx[r2] + Floor(g_rw[r2] / 2.), g_ry[r2] + Floor(g_rh[r2] / 2.));
      }
   }

   // Player in the middle of room 1, facing a random way.
   g_px = g_rx[1] + Floor(g_rw[1] / 2.) + 0.5;
   g_py = g_ry[1] + Floor(g_rh[1] / 2.) + 0.5;
   g_pa = rnd() * 2. * g_pi;

   // Metal pillars in big rooms (not room 1), kept off the room's
   // edge cells so the room stays connected around them.
   for (Integer p = 2; p <= g_nroom; ++p) {
      if (g_rw[p] >= 5 && g_rh[p] >= 5 && rnd() < 0.7) {
         Integer np = rnd_int(1, 2);
         for (Integer q = 1; q <= np; ++q) {
            set_cell(rnd_int(g_rx[p] + 1, g_rx[p] + g_rw[p] - 2), rnd_int(g_ry[p] + 1, g_ry[p] + g_rh[p] - 2), 3);
         }
      }
   }

   // Walking distance from the start (breadth-first).
   for (Integer d = 1; d <= MCELLS; ++d) g_dist[d] = -1;
   Integer start = Floor(g_py) * MW + Floor(g_px) + 1;
   Integer head = 1;
   Integer tail = 1;
   g_queue[1] = start;
   g_dist[start] = 0;
   while (head <= tail) {
      Integer cur = g_queue[head];
      ++head;
      Integer cx0 = (cur - 1) - Floor((cur - 1) / (1. * MW)) * MW;
      Integer cy0 = Floor((cur - 1) / (1. * MW));
      for (Integer k = 1; k <= 4; ++k) {
         Integer nx = cx0;
         Integer ny = cy0;
         if (k == 1) ++nx;
         if (k == 2) --nx;
         if (k == 3) ++ny;
         if (k == 4) --ny;
         if (cell(nx, ny) != 0) continue;
         Integer ni = ny * MW + nx + 1;
         if (g_dist[ni] >= 0) continue;
         g_dist[ni] = g_dist[cur] + 1;
         ++tail;
         g_queue[tail] = ni;
      }
   }

   // Exit switch: the wall next to the farthest reachable floor cell.
   Integer best = -1;
   Integer exit_x = 0;
   Integer exit_y = 0;
   for (Integer my = 1; my < MH - 1; ++my) {
      for (Integer mx = 1; mx < MW - 1; ++mx) {
         Integer di = g_dist[my * MW + mx + 1];
         if (di <= best) continue;
         for (Integer kk = 1; kk <= 4; ++kk) {
            Integer wx = mx;
            Integer wy = my;
            if (kk == 1) ++wx;
            if (kk == 2) --wx;
            if (kk == 3) ++wy;
            if (kk == 4) --wy;
            if (cell(wx, wy) > 0) {
               best = di;
               exit_x = wx;
               exit_y = wy;
            }
         }
      }
   }
   set_cell(exit_x, exit_y, WALL_EXIT);

   // Monsters and pickups in every room but the first.
   for (Integer m = 2; m <= g_nroom; ++m) {
      Integer area = g_rw[m] * g_rh[m];
      Integer n = rnd_int(1, 1 + Floor(area / 14.));
      if (n > 3) n = 3;
      for (Integer j = 1; j <= n; ++j) {
         Integer kind = ENT_GRUNT;
         if (rnd() < 0.4) kind = ENT_IMP;
         place_in_room(kind, m);
      }
      if (rnd() < 0.4) place_in_room(ENT_HEALTH, m);
      if (rnd() < 0.45) place_in_room(ENT_AMMO, m);
   }
   place_in_room(ENT_AMMO, 1);

   // Back to unpredictable gameplay.
   Integer tseed = 0;
   Get_time(tseed);
   Set_random_number(tseed, 1);
}

void reset_game()
{
   if (g_seed == 0) {
      load_level();
      g_level_name = "E1M1";
   } else {
      gen_level(g_seed);
      g_level_name = "Random map " + To_text(g_seed);
   }
   g_health = 100;
   g_health_ghost = 100.;
   g_ammo = 30;
   g_kills = 0;
   g_ns = 0;
   g_game = GAME_PLAY;
   g_time = 0.;
   g_fire_cool = 0.;
   g_fire_queued = 0;
   g_flash = 0.;
   g_hurt = 0.;
   g_pickup = 0.;
   g_key = "";
   show_msg(g_level_name + ": find the green exit switch", 4.);
}

// Print the current map to the Output Window in load_level's notation.
void print_map()
{
   Print("[12doom] " + g_level_name + ": " + To_text(g_nroom) + " rooms, " + To_text(g_enemies)
      + " enemies\n");
   for (Integer my = 0; my < MH; ++my) {
      Text row = "";
      for (Integer mx = 0; mx < MW; ++mx) {
         Integer c = cell(mx, my);
         Text ch = ".";
         if (c == 1) ch = "#";
         if (c == 2) ch = "B";
         if (c == 3) ch = "M";
         if (c == WALL_EXIT) ch = "E";
         if (Floor(g_px) == mx && Floor(g_py) == my) ch = "P";
         for (Integer i = 1; i <= g_ne; ++i) {
            if (Floor(g_ex[i]) == mx && Floor(g_ey[i]) == my) {
               if (g_ek[i] == ENT_GRUNT) ch = "g";
               if (g_ek[i] == ENT_IMP) ch = "i";
               if (g_ek[i] == ENT_HEALTH) ch = "h";
               if (g_ek[i] == ENT_AMMO) ch = "a";
            }
         }
         row = row + ch;
      }
      Print("[12doom]   " + row + "\n");
   }
}

void new_random_map()
{
   g_seed = rnd_int(1, 99999);
   reset_game();
   print_map();
}

//---------------------------------------------------------------- sprites

void set_pal(Integer i, Integer r, Integer g, Integer b)
{
   g_pal_r[i] = r;
   g_pal_g[i] = g;
   g_pal_b[i] = b;
}

// One row of pixel art; characters not in g_pal_chars are clear.
void set_row(Integer img, Integer row, Text s)
{
   for (Integer c = 1; c <= SPR_W; ++c) {
      Text ch = Get_subtext(s, c, c);
      Integer p = 0;
      if (ch != ".") p = Find_text(g_pal_chars, ch);
      g_pix[((img - 1) * SPR_H + (row - 1)) * SPR_W + c] = p;
   }
}

void clear_image(Integer img)
{
   for (Integer r = 1; r <= SPR_H; ++r) {
      set_row(img, r, "............");
   }
}

// Row r of two images, side by side.
void set_rows(Integer img1, Integer img2, Integer r, Text s1, Text s2)
{
   set_row(img1, r, s1);
   set_row(img2, r, s2);
}

void set_size(Integer img, Real scale, Real lift)
{
   g_spr_scale[img] = scale;
   g_spr_lift[img] = lift;
}

void init_sprites()
{
   // k black, r red, d dark red, o orange, y yellow, s skin, b brown,
   // n dark brown, g green, l dark green, w white, x grey, t dark
   // grey, u blue, p pink.
   set_pal(1, 25, 25, 25);
   set_pal(2, 200, 35, 30);
   set_pal(3, 120, 20, 15);
   set_pal(4, 240, 140, 30);
   set_pal(5, 250, 220, 70);
   set_pal(6, 225, 175, 125);
   set_pal(7, 140, 85, 45);
   set_pal(8, 80, 50, 25);
   set_pal(9, 70, 150, 55);
   set_pal(10, 35, 85, 30);
   set_pal(11, 240, 240, 240);
   set_pal(12, 150, 150, 150);
   set_pal(13, 75, 75, 80);
   set_pal(14, 70, 100, 210);
   set_pal(15, 210, 100, 90);

   set_rows(IMG_GRUNT, IMG_IMP,  1, "....nnnn....", "..b......b..");
   set_rows(IMG_GRUNT, IMG_IMP,  2, "...nssssn...", "..bb....bb..");
   set_rows(IMG_GRUNT, IMG_IMP,  3, "...skssks...", "...bbbbbb...");
   set_rows(IMG_GRUNT, IMG_IMP,  4, "...ssssss...", "..bbbbbbbb..");
   set_rows(IMG_GRUNT, IMG_IMP,  5, "....sdds....", "..bybbbbyb..");
   set_rows(IMG_GRUNT, IMG_IMP,  6, "..llggggll..", "..bbbddbbb..");
   set_rows(IMG_GRUNT, IMG_IMP,  7, ".lgllggllgl.", ".bbbwwwwbbb.");
   set_rows(IMG_GRUNT, IMG_IMP,  8, ".slglgglgls.", "bb.bbbbbb.bb");
   set_rows(IMG_GRUNT, IMG_IMP,  9, ".sllgggglls.", "b..bbbbbb..b");
   set_rows(IMG_GRUNT, IMG_IMP, 10, ".s.llllll.s.", "w..bnbbnb..w");
   set_rows(IMG_GRUNT, IMG_IMP, 11, "...tttttt...", "...bbbbbb...");
   set_rows(IMG_GRUNT, IMG_IMP, 12, "...lll.lll..", "...bb..bb...");
   set_rows(IMG_GRUNT, IMG_IMP, 13, "...ll...ll..", "...bb..bb...");
   set_rows(IMG_GRUNT, IMG_IMP, 14, "...ll...ll..", "..bbb..bbb..");
   set_rows(IMG_GRUNT, IMG_IMP, 15, "..nnn...nnn.", "..nn....nn..");
   set_rows(IMG_GRUNT, IMG_IMP, 16, "..nnn...nnn.", "..nn....nn..");

   clear_image(IMG_HEALTH);
   clear_image(IMG_AMMO);
   set_rows(IMG_HEALTH, IMG_AMMO,  7, "..wwwwwwww..", "...yy..yy...");
   set_rows(IMG_HEALTH, IMG_AMMO,  8, "..wwwrrwww..", "...yy..yy...");
   set_rows(IMG_HEALTH, IMG_AMMO,  9, "..wwwrrwww..", "...oo..oo...");
   set_rows(IMG_HEALTH, IMG_AMMO, 10, "..wrrrrrrw..", "..llllllll..");
   set_rows(IMG_HEALTH, IMG_AMMO, 11, "..wrrrrrrw..", "..lyyllyyl..");
   set_rows(IMG_HEALTH, IMG_AMMO, 12, "..wwwrrwww..", "..llllllll..");
   set_rows(IMG_HEALTH, IMG_AMMO, 13, "..wwwrrwww..", "..llllllll..");
   set_rows(IMG_HEALTH, IMG_AMMO, 14, "..wwwwwwww..", "..llllllll..");
   set_rows(IMG_HEALTH, IMG_AMMO, 15, "..xxxxxxxx..", "..tttttttt..");

   clear_image(IMG_FIRE);
   set_row(IMG_FIRE, 5, "....oooo....");
   set_row(IMG_FIRE, 6, "...oyyyyo...");
   set_row(IMG_FIRE, 7, "..oyywwyyo..");
   set_row(IMG_FIRE, 8, "..oywwwwyo..");
   set_row(IMG_FIRE, 9, "..oywwwwyo..");
   set_row(IMG_FIRE, 10, "..oyywwyyo..");
   set_row(IMG_FIRE, 11, "...oyyyyo...");
   set_row(IMG_FIRE, 12, "....oooo....");

   clear_image(IMG_CORPSE);
   set_row(IMG_CORPSE, 13, "...dd.......");
   set_row(IMG_CORPSE, 14, ".rdrrdd.ddr.");
   set_row(IMG_CORPSE, 15, "rrdddrrdrrdd");
   set_row(IMG_CORPSE, 16, ".nnrrrddrnn.");

   // Height as a fraction of a wall, and lift of the bottom edge.
   set_size(IMG_GRUNT, 0.78, 0.);
   set_size(IMG_IMP, 0.8, 0.);
   set_size(IMG_HEALTH, 0.45, 0.);
   set_size(IMG_AMMO, 0.45, 0.);
   set_size(IMG_FIRE, 0.5, 0.22);
   set_size(IMG_CORPSE, 0.7, 0.);
}

//---------------------------------------------------------------- game logic

void hurt_player(Real amount)
{
   if (g_game != GAME_PLAY) return;
   Integer a = Floor(amount);
   g_health = g_health - a;
   g_hurt = 0.35;
   if (g_health <= 0) {
      g_health = 0;
      g_game = GAME_DEAD;
      show_msg("", 0.);
   }
}

void fire()
{
   if (g_game != GAME_PLAY || g_show_help || !g_captured) return;
   if (g_fire_cool > 0.) {
      // Pressed just before the gun is ready: fire as soon as it is.
      if (g_fire_cool < 0.25) g_fire_queued = 1;
      return;
   }
   g_fire_queued = 0;
   if (g_ammo <= 0) {
      show_msg("Out of ammo", 1.5);
      g_fire_cool = 0.25;
      return;
   }
   --g_ammo;
   g_fire_cool = 0.4;
   g_flash = 0.1;

   Real ca = Cos(g_pa);
   Real sa = Sin(g_pa);
   Integer best = 0;
   Real best_d = 1000.;
   for (Integer i = 1; i <= g_ne; ++i) {
      if (g_ek[i] > ENT_IMP || g_est[i] == ST_DEAD) continue;
      Real rx = g_ex[i] - g_px;
      Real ry = g_ey[i] - g_py;
      Real depth = rx * ca + ry * sa;
      Real side = -rx * sa + ry * ca;
      if (depth < 0.2 || depth > best_d) continue;
      if (Absolute(side) > 0.34 + depth * 0.035) continue;
      if (!line_of_sight(g_px, g_py, g_ex[i], g_ey[i])) continue;
      best = i;
      best_d = depth;
   }
   if (best == 0) return;

   Real dmg = 22. + rnd() * 22.;
   if (best_d > 8.) dmg = dmg * 0.6;
   Integer idmg = Floor(dmg);
   g_ehp[best] = g_ehp[best] - idmg;
   g_eflash[best] = 0.15;
   g_est[best] = ST_CHASE;
   g_ecool[best] = g_ecool[best] + 0.25;
   if (g_ehp[best] <= 0) {
      g_est[best] = ST_DEAD;
      ++g_kills;
      if (g_kills == g_enemies) show_msg("All enemies dead -- now find the exit", 3.);
   }
}

// Move entity i by (dx, dy), sliding along walls.
void move_entity(Integer i, Real dx, Real dy)
{
   Real nx = g_ex[i] + dx;
   if (blocked(nx, g_ey[i], 0.28) == 0) g_ex[i] = nx;
   Real ny = g_ey[i] + dy;
   if (blocked(g_ex[i], ny, 0.28) == 0) g_ey[i] = ny;
}

void win_game()
{
   if (g_game != GAME_PLAY) return;
   g_game = GAME_WON;
   show_msg("", 0.);
}

void move_player(Real dx, Real dy)
{
   Real nx = g_px + dx;
   Integer w = blocked(nx, g_py, 0.22);
   if (w == 0) g_px = nx;
   if (w == WALL_EXIT) win_game();
   Real ny = g_py + dy;
   w = blocked(g_px, ny, 0.22);
   if (w == 0) g_py = ny;
   if (w == WALL_EXIT) win_game();
}

Integer key_down(Text k)
{
   Integer a = 0;
   if (g_key == k && g_now < g_key_until) a = 1;
   return a;
}

void update(Real dt)
{
   g_fire_cool = g_fire_cool - dt;
   g_flash = g_flash - dt;
   g_hurt = g_hurt - dt;
   g_pickup = g_pickup - dt;
   // HUD: lost health drains out of the gauge rather than vanishing.
   if (g_health_ghost < g_health) g_health_ghost = g_health;
   if (g_health_ghost > g_health) g_health_ghost = g_health_ghost - 45. * dt;
   // Paused while the help is up or mouselook is off (right click).
   if (g_game != GAME_PLAY || g_show_help || !g_captured) return;
   g_time = g_time + dt;
   if (g_fire_queued && g_fire_cool <= 0.) fire();

   // Player movement.
   Real fwd = 0.;
   Real str = 0.;
   if (key_down("w")) fwd = 1.;
   if (key_down("s")) fwd = -1.;
   if (key_down("a")) str = -1.;
   if (key_down("d")) str = 1.;
   Real ca = Cos(g_pa);
   Real sa = Sin(g_pa);
   if (fwd != 0. || str != 0.) {
      Real mvx = ca * fwd - sa * str;
      Real mvy = sa * fwd + ca * str;
      // A fresh press starts at TAP_START_SPEED and reaches full speed
      // after TAP_RAMP s; once the key is repeating (held), it's full
      // speed.
      Real ease = 1.;
      if (!g_key_held) {
         ease = TAP_START_SPEED + (1. - TAP_START_SPEED) * clampr((g_now - g_key_start) / TAP_RAMP, 0., 1.);
      }
      Real step = WALK_SPEED * ease * dt;
      move_player(mvx * step, mvy * step);
      g_bob = g_bob + dt * 9. * ease;
   }

   // Enemies and pickups.
   for (Integer i = 1; i <= g_ne; ++i) {
      if (g_est[i] == ST_DEAD) continue;
      Real dx = g_px - g_ex[i];
      Real dy = g_py - g_ey[i];
      Real dist = Sqrt(dx * dx + dy * dy);
      Integer kind = g_ek[i];

      if (kind == ENT_HEALTH || kind == ENT_AMMO) {
         // Medkits are left alone at full health.
         if (dist < 0.6 && (kind == ENT_AMMO || g_health < 100)) {
            Text what = "shells";
            if (kind == ENT_AMMO) g_ammo = g_ammo + 12;
            if (kind == ENT_HEALTH) {
               g_health = g_health + 25;
               if (g_health > 100) g_health = 100;
               what = "a medkit";
            }
            g_est[i] = ST_DEAD;
            g_pickup = 0.25;
            show_msg("Picked up " + what, 1.5);
         }
         continue;
      }

      g_eflash[i] = g_eflash[i] - dt;
      g_ecool[i] = g_ecool[i] - dt;
      g_elos_t[i] = g_elos_t[i] - dt;
      if (g_elos_t[i] <= 0.) {
         g_esee[i] = 0;
         if (dist < 16.) g_esee[i] = line_of_sight(g_ex[i], g_ey[i], g_px, g_py);
         g_elos_t[i] = 0.2 + rnd() * 0.15;
      }
      if (g_est[i] == ST_IDLE && g_esee[i]) g_est[i] = ST_CHASE;
      if (g_est[i] != ST_CHASE || dist < 0.01) continue;

      Real speed = 1.9;
      Real keep = 0.85;
      if (kind == ENT_IMP) {
         speed = 1.15;
         keep = 0.9;
         if (g_esee[i]) keep = 3.5;
      }
      if (dist > keep) move_entity(i, dx / dist * speed * dt, dy / dist * speed * dt);

      if (kind == ENT_GRUNT && dist < 1.15 && g_ecool[i] <= 0.) {
         hurt_player(6. + rnd() * 8.);
         g_ecool[i] = 0.9;
      }
      if (kind == ENT_IMP && g_esee[i] && dist < 12. && g_ecool[i] <= 0.) {
         if (g_ns < MAXSHOT) {
            ++g_ns;
            g_sx[g_ns] = g_ex[i] + dx / dist * 0.35;
            g_sy[g_ns] = g_ey[i] + dy / dist * 0.35;
            g_svx[g_ns] = dx / dist * 4.5;
            g_svy[g_ns] = dy / dist * 4.5;
            g_slife[g_ns] = 4.;
         }
         g_ecool[i] = 1.6 + rnd() * 1.2;
      }
   }

   // Fireballs.
   Integer s = 1;
   while (s <= g_ns) {
      g_sx[s] = g_sx[s] + g_svx[s] * dt;
      g_sy[s] = g_sy[s] + g_svy[s] * dt;
      g_slife[s] = g_slife[s] - dt;
      Real fdx = g_sx[s] - g_px;
      Real fdy = g_sy[s] - g_py;
      Integer gone = 0;
      if (g_slife[s] <= 0. || cell_at(g_sx[s], g_sy[s]) > 0) gone = 1;
      if (!gone && fdx * fdx + fdy * fdy < 0.13) {
         hurt_player(9. + rnd() * 9.);
         gone = 1;
      }
      if (gone) {
         g_sx[s] = g_sx[g_ns];
         g_sy[s] = g_sy[g_ns];
         g_svx[s] = g_svx[g_ns];
         g_svy[s] = g_svy[g_ns];
         g_slife[s] = g_slife[g_ns];
         --g_ns;
      } else {
         ++s;
      }
   }
}

//---------------------------------------------------------------- rendering

void render_backdrop(Draw_Box box, Real w, Real h, Real mid)
{
   Real half = (h - g_hud_h) / 2.;
   for (Integer b = 1; b <= 8; ++b) {
      Real t = (b - 1.) / 7.;
      set_rgb(box, 38. + 50. * t, 38. + 44. * t, 46. + 40. * t);
      fill_rect(box, 0., h - (b - 1.) * half / 8., w, h - b * half / 8.);
   }
   for (Integer f = 1; f <= 8; ++f) {
      Real u = (f - 1.) / 7.;
      set_rgb(box, 50. + 70. * u, 42. + 56. * u, 34. + 40. * u);
      fill_rect(box, 0., mid - (f - 1.) * half / 8., w, mid - f * half / 8.);
   }
}

// Raycast one column per g_colw pixels; fills g_zbuf. Returns the
// number of columns.
Integer render_walls(Draw_Box box, Real w, Real h, Real mid)
{
   Integer ncols = Floor(w / g_colw);
   if (ncols > MAX_RAYS) ncols = MAX_RAYS;
   Real cw = w / ncols;
   Real view_h = h - g_hud_h;
   Real dir_x = Cos(g_pa);
   Real dir_y = Sin(g_pa);
   Real plane_x = -dir_y * 0.66;
   Real plane_y = dir_x * 0.66;
   Integer map_x0 = Floor(g_px);
   Integer map_y0 = Floor(g_py);

   for (Integer col = 1; col <= ncols; ++col) {
      Real cam = 2. * (col - 0.5) / ncols - 1.;
      Real rdx = dir_x + plane_x * cam;
      Real rdy = dir_y + plane_y * cam;
      Integer map_x = map_x0;
      Integer map_y = map_y0;
      Real ddx = 1000000.;
      Real ddy = 1000000.;
      if (rdx != 0.) ddx = Absolute(1. / rdx);
      if (rdy != 0.) ddy = Absolute(1. / rdy);
      Integer step_x = 1;
      Integer step_y = 1;
      Real side_x = (map_x + 1. - g_px) * ddx;
      Real side_y = (map_y + 1. - g_py) * ddy;
      if (rdx < 0.) {
         step_x = -1;
         side_x = (g_px - map_x) * ddx;
      }
      if (rdy < 0.) {
         step_y = -1;
         side_y = (g_py - map_y) * ddy;
      }
      Integer side = 0;
      Integer hit = 0;
      Integer guard = 0;
      while (hit == 0 && guard < 64) {
         if (side_x < side_y) {
            side_x = side_x + ddx;
            map_x = map_x + step_x;
            side = 0;
         } else {
            side_y = side_y + ddy;
            map_y = map_y + step_y;
            side = 1;
         }
         hit = cell(map_x, map_y);
         ++guard;
      }
      Real perp = side_y - ddy;
      Real wall_x = g_px + perp * rdx;
      if (side == 0) {
         perp = side_x - ddx;
         wall_x = g_py + perp * rdy;
      }
      if (perp < 0.05) perp = 0.05;
      wall_x = wall_x - Floor(wall_x);
      g_zbuf[col] = perp;

      Real lh = view_h / perp;
      Real top = mid + lh / 2.;
      Real bot = mid - lh / 2.;
      if (top > h) top = h;
      if (bot < g_hud_h) bot = g_hud_h;

      Real r = 128.;
      Real g = 126.;
      Real b = 120.;
      if (hit == 2) {
         r = 150.;
         g = 62.;
         b = 42.;
      }
      if (hit == 3) {
         r = 88.;
         g = 100.;
         b = 122.;
      }
      if (hit == WALL_EXIT) {
         r = 40.;
         g = 185.;
         b = 70.;
         if (wall_x > 0.3 && wall_x < 0.7) {
            r = 230.;
            g = 230.;
            b = 60.;
         }
      }
      Real k = fog(perp);
      if (side == 1) k = k * 0.72;
      Real seam = wall_x * 2. - Floor(wall_x * 2.);
      if (hit != WALL_EXIT && seam < 0.06) k = k * 0.6;
      if (hit == 3 && seam > 0.45 && seam < 0.52) k = k * 1.25;
      set_rgb(box, r * k, g * k, b * k);
      Real x0 = (col - 1) * cw;
      Real x1 = col * cw;
      fill_rect(box, x0, bot, x1, top);

      // Mortar courses on close stone and brick.
      if (lh > 70. && (hit == 1 || hit == 2)) {
         set_rgb(box, r * k * 0.55, g * k * 0.55, b * k * 0.55);
         for (Integer m = 1; m <= 3; ++m) {
            Real ym = mid - lh / 2. + lh * m / 4.;
            if (ym > g_hud_h && ym < h) draw_line(box, x0, ym, x1, ym);
         }
      }
   }
   return ncols;
}

void add_vis(Real wx, Real wy, Integer img, Integer flip, Real tint, Real inv_det, Real dir_x,
   Real dir_y, Real plane_x, Real plane_y, Real w)
{
   if (g_nvis >= MAXVIS) return;
   Real rx = wx - g_px;
   Real ry = wy - g_py;
   Real tx = inv_det * (dir_y * rx - dir_x * ry);
   Real ty = inv_det * (-plane_y * rx + plane_x * ry);
   if (ty < 0.15) return;
   ++g_nvis;
   g_vdepth[g_nvis] = ty;
   g_vsx[g_nvis] = (w / 2.) * (1. + tx / ty);
   g_vimg[g_nvis] = img;
   g_vflip[g_nvis] = flip;
   g_vtint[g_nvis] = tint;
}

// Draw one sprite column by column, each column as runs of colour,
// hidden where a wall column is nearer.
void draw_sprite(Draw_Box box, Integer v, Integer ncols, Real w, Real h, Real mid)
{
   Real ty = g_vdepth[v];
   Integer img = g_vimg[v];
   Real view_h = h - g_hud_h;
   Real cw = w / ncols;
   Real lh = view_h / ty;
   Real sh = lh * g_spr_scale[img];
   Real sw = sh * SPR_W / SPR_H;
   Real bottom = mid - lh / 2. + g_spr_lift[img] * lh;
   Real top = bottom + sh;
   Real left = g_vsx[v] - sw / 2.;
   Real px_h = sh / SPR_H;
   Integer c0 = Floor(left / cw) + 1;
   Integer c1 = Floor((left + sw) / cw) + 1;
   if (c0 < 1) c0 = 1;
   if (c1 > ncols) c1 = ncols;
   Real k = fog(ty);
   if (img == IMG_FIRE) k = 1.;
   Real fk = k * (1. - g_vtint[v]);
   Real wash = 255. * g_vtint[v];
   Integer base = (img - 1) * SPR_H * SPR_W;

   for (Integer c = c0; c <= c1; ++c) {
      if (ty >= g_zbuf[c]) continue;
      Real xc = (c - 0.5) * cw;
      Real u = (xc - left) / sw;
      if (u < 0. || u >= 1.) continue;
      Integer tu = Floor(u * SPR_W) + 1;
      if (g_vflip[v]) tu = SPR_W + 1 - tu;
      Real x0 = (c - 1) * cw;
      Real x1 = c * cw;
      Integer run_p = 0;
      Integer run_start = 1;
      for (Integer r = 1; r <= SPR_H + 1; ++r) {
         Integer p = -1;
         if (r <= SPR_H) p = g_pix[base + (r - 1) * SPR_W + tu];
         if (p == run_p) continue;
         if (run_p > 0) {
            Real y_top = top - (run_start - 1) * px_h;
            Real y_bot = top - (r - 1) * px_h;
            if (y_top > h) y_top = h;
            if (y_bot < g_hud_h) y_bot = g_hud_h;
            if (y_top > y_bot) {
               // Fogged palette colour, washed towards white by tint.
               set_rgb(box, g_pal_r[run_p] * fk + wash, g_pal_g[run_p] * fk + wash, g_pal_b[run_p] * fk + wash);
               fill_rect(box, x0, y_bot, x1, y_top);
            }
         }
         run_p = p;
         run_start = r;
      }
   }
}

void render_sprites(Draw_Box box, Integer ncols, Real w, Real h, Real mid)
{
   Real dir_x = Cos(g_pa);
   Real dir_y = Sin(g_pa);
   Real plane_x = -dir_y * 0.66;
   Real plane_y = dir_x * 0.66;
   Real inv_det = 1. / (plane_x * dir_y - dir_x * plane_y);

   g_nvis = 0;
   for (Integer i = 1; i <= g_ne; ++i) {
      Integer kind = g_ek[i];
      if (kind == ENT_HEALTH || kind == ENT_AMMO) {
         if (g_est[i] != ST_DEAD) {
            Integer pimg = IMG_HEALTH;
            if (kind == ENT_AMMO) pimg = IMG_AMMO;
            add_vis(g_ex[i], g_ey[i], pimg, 0, 0., inv_det, dir_x, dir_y, plane_x, plane_y, w);
         }
         continue;
      }
      Integer img = IMG_GRUNT;
      if (kind == ENT_IMP) img = IMG_IMP;
      Integer flip = 0;
      Real tint = 0.;
      if (g_est[i] == ST_DEAD) {
         img = IMG_CORPSE;
      } else {
         // Walk cycle: mirror the image a few times a second.
         if (g_est[i] == ST_CHASE) {
            Real ph = Floor(g_time * 4. + i * 0.37);
            if (ph - 2. * Floor(ph / 2.) > 0.5) flip = 1;
         }
         if (g_eflash[i] > 0.) tint = 0.65;
      }
      add_vis(g_ex[i], g_ey[i], img, flip, tint, inv_det, dir_x, dir_y, plane_x, plane_y, w);
   }
   for (Integer s = 1; s <= g_ns; ++s) {
      add_vis(g_sx[s], g_sy[s], IMG_FIRE, 0, 0., inv_det, dir_x, dir_y, plane_x, plane_y, w);
   }

   // Insertion sort of g_vord, far to near. (&& doesn't short-circuit,
   // so the loop breaks before g_vord[0] would be read.)
   for (Integer o = 1; o <= g_nvis; ++o) g_vord[o] = o;
   for (Integer a = 2; a <= g_nvis; ++a) {
      Integer cur = g_vord[a];
      Integer j = a - 1;
      while (g_vdepth[g_vord[j]] < g_vdepth[cur]) {
         g_vord[j + 1] = g_vord[j];
         --j;
         if (j < 1) break;
      }
      g_vord[j + 1] = cur;
   }

   for (Integer v = 1; v <= g_nvis; ++v) draw_sprite(box, g_vord[v], ncols, w, h, mid);
}

void render_gun(Draw_Box box, Real w)
{
   Real gx = w / 2. + Sin(g_bob) * 9.;
   Real gy = g_hud_h - 8. + Absolute(Cos(g_bob)) * 6.;
   if (g_fire_cool > 0.28) gy = gy - 14.;

   if (g_flash > 0.) {
      Real fx = gx;
      Real fy = gy + 138.;
      for (Integer i = 1; i <= 16; ++i) {
         Real a = (i - 1.) * g_pi / 8.;
         Real rad = 16.;
         if (i - 2 * Floor(i / 2.) == 1) rad = 38.;
         g_fx[i] = fx + Cos(a) * rad;
         g_fy[i] = fy + Sin(a) * rad * 0.8;
      }
      set_rgb(box, 255., 200., 60.);
      Draw_polygon(box, 16, g_fx, g_fy);
      set_rgb(box, 255., 250., 200.);
      fill_rect(box, fx - 8., fy - 7., fx + 8., fy + 7.);
   }

   // Twin barrels.
   set_rgb(box, 52., 52., 58.);
   fill_rect(box, gx - 13., gy + 40., gx + 13., gy + 128.);
   set_rgb(box, 95., 95., 105.);
   fill_rect(box, gx - 10., gy + 45., gx - 3., gy + 128.);
   fill_rect(box, gx + 3., gy + 45., gx + 10., gy + 128.);
   set_rgb(box, 20., 20., 22.);
   fill_rect(box, gx - 9., gy + 122., gx - 4., gy + 128.);
   fill_rect(box, gx + 4., gy + 122., gx + 9., gy + 128.);
   // Wooden fore-end and stock.
   set_rgb(box, 112., 70., 34.);
   fill_rect(box, gx - 19., gy + 44., gx + 19., gy + 78.);
   set_rgb(box, 82., 50., 24.);
   fill_rect(box, gx - 19., gy + 44., gx + 19., gy + 50.);
   fill_rect(box, gx - 26., gy, gx + 26., gy + 44.);
   // Hand.
   set_rgb(box, 205., 150., 105.);
   fill_quad(box, gx - 40., gy, gx - 6., gy, gx - 12., gy + 62., gx - 30., gy + 56.);
}

// A 10-segment gauge, filled to frac in colour (r, g, b). Between frac
// and ghost (>= frac) it's pale: recently lost health draining away.
// blink flashes the fill for a low reading.
void draw_gauge(Draw_Box box, Real x, Real y, Real bw, Real bh, Real frac, Real ghost, Real r,
   Real g, Real b, Integer blink)
{
   set_rgb(box, 18., 16., 14.);
   fill_rect(box, x - 2., y - 2., x + bw + 2., y + bh + 2.);
   Real gap = 2.;
   Real seg = (bw - 9. * gap) / 10.;
   Real k = 1.;
   if (blink && Floor(g_now * 5.) - 2. * Floor(g_now * 5. / 2.) > 0.5) k = 0.45;
   for (Integer s = 1; s <= 10; ++s) {
      Real sx = x + (s - 1) * (seg + gap);
      set_rgb(box, 58., 52., 46.);
      fill_rect(box, sx, y, sx + seg, y + bh);
      Real lg = clampr(ghost * 10. - (s - 1), 0., 1.);
      if (lg > 0.) {
         set_rgb(box, 235., 225., 200.);
         fill_rect(box, sx, y, sx + seg * lg, y + bh);
      }
      Real lf = clampr(frac * 10. - (s - 1), 0., 1.);
      if (lf > 0.) {
         set_rgb(box, r * k, g * k, b * k);
         fill_rect(box, sx, y, sx + seg * lf, y + bh);
         // Highlight along the top edge.
         set_rgb(box, (r + (255. - r) * 0.45) * k, (g + (255. - g) * 0.45) * k, (b + (255. - b) * 0.45) * k);
         fill_rect(box, sx, y + bh - 3., sx + seg * lf, y + bh);
      }
   }
}

void render_hud(Draw_Box box, Real w, Real h, Real ms)
{
   Real hh = g_hud_h;
   set_rgb(box, 38., 34., 30.);
   fill_rect(box, 0., 0., w, hh);
   set_rgb(box, 100., 88., 70.);
   draw_line(box, 0., hh, w, hh);

   // Health on the left half, ammo on the right, kills/time far right;
   // the middle stays clear (the cursor is parked there while playing).
   Real half = w / 2.;
   Real ax = half + 40.;
   Real bw = half - 40. - 88. - 10.;
   Real right_room = (w - 132.) - (ax + 74.);
   if (right_room < bw) bw = right_room;
   if (bw < 60.) bw = 60.;

   // Health: red -> yellow -> green.
   Real hf = clampr(g_health / 100., 0., 1.);
   Real hr = 220.;
   Real hg = 45.;
   Real hb = 35.;
   if (hf < 0.5) {
      Real t = hf / 0.5;
      hr = 220. + 15. * t;
      hg = 45. + 160. * t;
      hb = 35. + 15. * t;
   } else {
      Real u = (hf - 0.5) / 0.5;
      hr = 235. - 170. * u;
      hg = 205. - 5. * u;
      hb = 50. + 20. * u;
   }
   Real ghost = clampr(g_health_ghost / 100., hf, 1.);
   Integer low_health = g_health > 0 && g_health <= 25;

   // Ammo: amber, red when nearly out. The gauge's scale grows with
   // what you carry (never below 50 shells).
   Real cap = 50.;
   if (g_ammo > cap) cap = g_ammo;
   Real af = clampr(g_ammo / cap, 0., 1.);
   Real ar = 240.;
   Real ag = 175.;
   Real ab = 50.;
   Integer low_ammo = g_ammo <= 5;
   if (low_ammo) {
      ar = 225.;
      ag = 60.;
      ab = 40.;
   }

   Set_bk_mode(box, 1);
   Set_text_align(box, 0);
   Set_text_colour(box, to_byte(hr), to_byte(hg), to_byte(hb));
   Draw_text(box, 14., hh - 4., 24., 0., To_text(g_health) + "%");
   Set_text_colour(box, to_byte(ar), to_byte(ag), to_byte(ab));
   Draw_text(box, ax, hh - 4., 24., 0., To_text(g_ammo));

   Set_text_colour(box, 150, 140, 120);
   Draw_text(box, 88., hh - 3., 10., 0., "HEALTH");
   Draw_text(box, ax + 74., hh - 3., 10., 0., "AMMO");
   draw_gauge(box, 88., 9., bw, 15., hf, ghost, hr, hg, hb, low_health);
   draw_gauge(box, ax + 74., 9., bw, 15., af, af, ar, ag, ab, low_ammo);

   Integer secs = Floor(g_time);
   Integer mins = Floor(secs / 60.);
   Integer rem = secs - mins * 60;
   Text rem_t = To_text(rem);
   if (rem < 10) rem_t = "0" + rem_t;
   Set_text_colour(box, 150, 140, 120);
   Draw_text(box, w - 122., hh - 5., 12., 0., "KILLS");
   Draw_text(box, w - 122., hh - 25., 12., 0., "TIME");
   Set_text_colour(box, 225, 225, 225);
   Draw_text(box, w - 70., hh - 5., 12., 0., To_text(g_kills) + "/" + To_text(g_enemies));
   Draw_text(box, w - 70., hh - 25., 12., 0., To_text(mins) + ":" + rem_t);

   Set_text_colour(box, 120, 115, 105);
   Integer fps = 0;
   if (ms > 0.) fps = Floor(1000. / ms);
   Draw_text(box, w - 110., h - 6., 10., 0., To_text(ms, 1) + " ms  cols " + To_text(g_colw) + "px");
   Draw_text(box, 10., h - 6., 10., 0., g_level_name + "  --  12dOOM by Paul Mashford");
   if (!g_captured) {
      Set_text_colour(box, 250, 230, 120);
      Set_text_align(box, 30);
      Draw_text(box, w / 2., h - 22., 14., 0., "PAUSED  --  right click to play  --  H for help");
      Set_text_align(box, 0);
   }
}

void render_map(Draw_Box box, Real w, Real h)
{
   Real cs = 5.;
   Real ox = w - MW * cs - 8.;
   Real oy = h - 22.;
   set_rgb(box, 15., 15., 18.);
   fill_rect(box, ox - 3., oy + 3., ox + MW * cs + 3., oy - MH * cs - 3.);
   for (Integer my = 0; my < MH; ++my) {
      Integer mx = 0;
      while (mx < MW) {
         Integer c = cell(mx, my);
         if (c == 0) {
            ++mx;
            continue;
         }
         Integer run_end = mx;
         while (run_end + 1 < MW && cell(run_end + 1, my) == c) ++run_end;
         if (c == WALL_EXIT) {
            set_rgb(box, 60., 220., 90.);
         } else {
            set_rgb(box, 120., 115., 110.);
         }
         fill_rect(box, ox + mx * cs, oy - my * cs, ox + (run_end + 1) * cs, oy - (my + 1) * cs);
         mx = run_end + 1;
      }
   }
   for (Integer i = 1; i <= g_ne; ++i) {
      if (g_est[i] == ST_DEAD) continue;
      if (g_ek[i] <= ENT_IMP) {
         set_rgb(box, 230., 50., 40.);
      } else {
         set_rgb(box, 240., 220., 80.);
      }
      fill_rect(box, ox + g_ex[i] * cs - 1.5, oy - g_ey[i] * cs - 1.5, ox + g_ex[i] * cs + 1.5,
         oy - g_ey[i] * cs + 1.5);
   }
   Real mx0 = ox + g_px * cs;
   Real my0 = oy - g_py * cs;
   set_rgb(box, 90., 200., 255.);
   fill_rect(box, mx0 - 2., my0 - 2., mx0 + 2., my0 + 2.);
   draw_line(box, mx0, my0, mx0 + Cos(g_pa) * 9., my0 - Sin(g_pa) * 9.);
}

// A dark box 2 hw wide and 2 hh tall centred on (cx, cy), edged top and
// bottom in (r, g, b), with a title in that colour ty above the centre
// and a line of text under it.
void banner(Draw_Box box, Real cx, Real cy, Real hw, Real hh, Text title, Real size, Real ty,
   Text sub, Integer r, Integer g, Integer b)
{
   set_rgb(box, 20., 18., 16.);
   fill_rect(box, cx - hw, cy - hh, cx + hw, cy + hh);
   set_rgb(box, r, g, b);
   draw_line(box, cx - hw, cy + hh, cx + hw, cy + hh);
   draw_line(box, cx - hw, cy - hh, cx + hw, cy - hh);
   Set_bk_mode(box, 1);
   Set_text_align(box, 30);
   Set_text_colour(box, r, g, b);
   Draw_text(box, cx, cy + ty, size, 0., title);
   Set_text_colour(box, 220, 220, 220);
   Draw_text(box, cx, cy - ty - 22., 13., 0., sub);
   Set_text_align(box, 0);
}

void render_overlays(Draw_Box box, Real w, Real h, Real mid)
{
   // Crosshair.
   Real cx = w / 2.;
   set_rgb(box, 235., 235., 235.);
   draw_line(box, cx - 10., mid, cx - 4., mid);
   draw_line(box, cx + 4., mid, cx + 10., mid);
   draw_line(box, cx, mid - 10., cx, mid - 4.);
   draw_line(box, cx, mid + 4., cx, mid + 10.);

   // Edge flash: red when hurt, yellow for a pickup.
   Real hh = g_hud_h;
   Real t = 0.;
   if (g_hurt > 0.) {
      t = 6. + g_hurt * 30.;
      set_rgb(box, 200., 10., 10.);
   } else if (g_pickup > 0.) {
      t = 4.;
      set_rgb(box, 240., 220., 80.);
   }
   if (t > 0.) {
      fill_rect(box, 0., hh, w, hh + t);
      fill_rect(box, 0., h - t, w, h);
      fill_rect(box, 0., hh, t, h);
      fill_rect(box, w - t, hh, w, h);
   }

   Set_bk_mode(box, 1);
   if (g_msg != "" && g_now < g_msg_until) {
      Set_text_align(box, 30);
      Set_text_colour(box, 20, 20, 20);
      Draw_text(box, w / 2. + 1., h - 41., 15., 0., g_msg);
      Set_text_colour(box, 250, 235, 180);
      Draw_text(box, w / 2., h - 40., 15., 0., g_msg);
      Set_text_align(box, 0);
   }

   if (g_game != GAME_PLAY) {
      Text title = "YOU DIED";
      Text sub = "Press R to try again";
      Integer tr = 230;
      Integer tg = 40;
      Integer tb = 30;
      if (g_game == GAME_WON) {
         Integer secs = Floor(g_time);
         title = "LEVEL COMPLETE";
         sub = "Kills " + To_text(g_kills) + "/" + To_text(g_enemies) + "   Time " + To_text(secs)
            + " s   --   press R to play again";
         tr = 90;
         tg = 230;
         tb = 110;
      }
      banner(box, w / 2., mid, 220., 50., title, 34., 8., sub, tr, tg, tb);
   }
}

// Help text, each moving y down a line. help_line: key in yellow at x,
// description in white at x + 150.
void help_line(Draw_Box box, Real x, Real &y, Text key, Text what)
{
   Set_text_colour(box, 250, 215, 90);
   Draw_text(box, x, y, 12., 0., key);
   Set_text_colour(box, 225, 225, 225);
   Draw_text(box, x + 150., y, 12., 0., what);
   y = y - 15.;
}

void help_text(Draw_Box box, Real x, Real &y, Text text)
{
   Set_text_colour(box, 225, 225, 225);
   Draw_text(box, x, y, 12., 0., text);
   y = y - 15.;
}

// A heading, with a gap above it unless it's the first.
void help_heading(Draw_Box box, Real x, Real &y, Text text, Integer first)
{
   if (!first) y = y - 6.;
   Set_text_colour(box, 230, 70, 50);
   Draw_text(box, x, y, 13., 0., text);
   y = y - 17.;
}

// Help overlay (H). The game is paused while it's up.
void render_help(Draw_Box box, Real w, Real h)
{
   Real pw = 600.;
   if (pw > w - 30.) pw = w - 30.;
   Real ph = 400.;
   if (ph > h - g_hud_h - 16.) ph = h - g_hud_h - 16.;
   Real cx = w / 2.;
   Real cy = g_hud_h + (h - g_hud_h) / 2.;
   Real x0 = cx - pw / 2.;
   Real top = cy + ph / 2.;
   set_rgb(box, 18., 16., 14.);
   fill_rect(box, x0, cy - ph / 2., x0 + pw, top);
   set_rgb(box, 150., 40., 30.);
   draw_line(box, x0, top, x0 + pw, top);
   draw_line(box, x0, cy - ph / 2., x0 + pw, cy - ph / 2.);
   draw_line(box, x0, top, x0, cy - ph / 2.);
   draw_line(box, x0 + pw, top, x0 + pw, cy - ph / 2.);

   Set_bk_mode(box, 1);
   Set_text_align(box, 30);
   Set_text_colour(box, 235, 60, 40);
   Draw_text(box, cx, top - 30., 24., 0., "12dOOM -- HOW TO PLAY");
   Set_text_colour(box, 200, 190, 170);
   Draw_text(box, cx, top - 48., 12., 0., "by Paul Mashford");
   Set_text_align(box, 0);

   Real x = x0 + 24.;
   Real y = top - 62.;
   help_heading(box, x, y, "MOUSE", 1);
   help_line(box, x, y, "Right click", "start playing / pause");
   help_line(box, x, y, "Move the mouse", "look left and right");
   help_line(box, x, y, "Left click", "shoot");
   help_heading(box, x, y, "KEYBOARD", 0);
   help_line(box, x, y, "W / S", "walk forward / back");
   help_line(box, x, y, "A / D", "step left / right");
   help_line(box, x, y, "F or Space", "shoot (hold to keep shooting)");
   help_line(box, x, y, "Q", "pause");
   help_line(box, x, y, "M", "map on and off");
   help_line(box, x, y, "R / N", "restart the level / new random level");
   help_line(box, x, y, "1 / 2 / 3", "picture detail: high / normal / low");
   help_line(box, x, y, "H", "this help screen");
   help_heading(box, x, y, "YOUR MISSION", 0);
   help_text(box, x, y, "Fight your way to the green exit switch and walk into it. Grunts (green) rush you,");
   help_text(box, x, y, "imps (brown) throw fireballs. Pick up medkits for health and boxes of shells for ammo.");
   help_text(box, x, y, "Tips: hold one movement key at a time. If the keys stop working, click the Keys box.");

   Set_text_align(box, 30);
   Set_text_colour(box, 250, 215, 90);
   Draw_text(box, cx, cy - ph / 2. + 14., 13., 0., "Click, or press W A S D, F or Space, to play");
   Set_text_align(box, 0);
}

void render(Draw_Box box, Real ms)
{
   Integer iw = 0;
   Integer ih = 0;
   Get_size(box, iw, ih);
   Real w = iw;
   Real h = ih;
   Real mid = g_hud_h + (h - g_hud_h) / 2.;

   Start_batch_draw(box);
   render_backdrop(box, w, h, mid);
   Integer ncols = render_walls(box, w, h, mid);
   render_sprites(box, ncols, w, h, mid);
   if (g_game == GAME_PLAY) render_gun(box, w);
   render_hud(box, w, h, ms);
   if (g_show_map) render_map(box, w, h);
   render_overlays(box, w, h, mid);
   if (g_show_help) {
      render_help(box, w, h);
   } else if (!g_captured && g_game == GAME_PLAY) {
      // Paused: mouselook is off.
      banner(box, w / 2., mid, 190., 38., "PAUSED", 30., 4., "Right click to play  --  H for help", 250, 215, 90);
   }
   End_batch_draw(box);
}

//---------------------------------------------------------------- panel

Integer split_xy(Text msg, Real &x, Real &y)
{
   Integer space = Find_text(msg, " ");
   if (space <= 1) return 1;
   From_text(Get_subtext(msg, 1, space - 1), x);
   From_text(Get_subtext(msg, space + 1, Text_length(msg)), y);
   return 0;
}

// Screen mapping from a Draw_Box event at box point (bx, by):
// screen = (box_x + ox, oy - box_y). Checked against Get_position (the
// view starts ~8 px right of it and h + 30 px below it). Returns 0 if
// good, 1 if the point is outside the box, 2 if the mapping disagrees.
Integer calibrate(Draw_Box box, Real bx, Real by, Integer bw, Integer bh, Integer &ox, Integer &oy)
{
   if (bx < 0. || bx > bw || by < 0. || by > bh) return 1;
   Integer sx = 0;
   Integer sy = 0;
   Get_cursor_position(sx, sy);
   Integer cox = sx - bx;
   Integer coy = sy + by;
   Integer gx = 0;
   Integer gy = 0;
   Get_position(box, gx, gy);
   if (Absolute(cox - gx) > 60 || Absolute(coy - gy - bh) > 80) return 2;
   ox = cox;
   oy = coy;
   return 0;
}

Integer run_gui_mode()
{
   // Resizable panel (sizing_enable = 1); the view fills it. It can't be
   // made smaller than the view's created size, so 760 x 460 is the
   // minimum.
   Panel panel = Create_panel("12dOOM - by Paul Mashford", 1);
   Vertical_Group vgroup = Create_vertical_group(0);
   Colour_Message_Box message_box = Create_colour_message_box("Status");
   Draw_Box draw_box = Create_draw_box(760, 460, 0);
   Input_Box key_box = Create_input_box("Keys (click here if the keys stop working)", message_box);
   Button restart_button = Create_button("&Restart", "restart");
   Button random_button = Create_button("Random &map", "random");
   Button original_button = Create_button("&Original map", "original");
   Horizontal_Group buttons = Create_button_group();

   Append(restart_button, buttons);
   Append(random_button, buttons);
   Append(original_button, buttons);
   Append(draw_box, vgroup);
   Append(key_box, vgroup);
   Append(buttons, vgroup);
   Append(message_box, vgroup);
   Append(vgroup, panel);
   Set_sizing_constraints(draw_box, 2, 2);
   Set_sizing_constraints(vgroup, 2, 2);
   // Sends Panel_Resize events (msg "0 - 0") while the panel is resized.
   Set_notify_resizing(panel);
   Show_widget(panel);
   Set_focus(key_box);

   Integer seed = 0;
   Get_time(seed);
   Set_random_number(seed, 1);
   init_sprites();
   Get_time(g_now);
   // 12doom_silent.4do -random  or  12doom_silent.4do -seed <n>: start on a generated map.
   Text arg1 = "";
   if (Get_number_of_command_arguments() >= 1) Get_command_argument(1, arg1);
   if (arg1 == "-seed" && Get_number_of_command_arguments() >= 2) {
      Text arg2 = "";
      Get_command_argument(2, arg2);
      From_text(arg2, g_seed);
   }
   if (arg1 == "-random") g_seed = rnd_int(1, 99999);
   reset_game();
   if (g_seed != 0) print_map();

   // Mouse capture: warp point in the HUD bar (so the cursor isn't over
   // the crosshair), screen = (box_x + ox, oy - box_y).
   Integer ox = 0;
   Integer oy = 0;
   Integer last_w = 0;
   Integer last_h = 0;
   Integer resize_pending = 0;
   Get_size(draw_box, last_w, last_h);
   Integer seen_ox = 0;
   Integer seen_oy = 0;
   Integer have_seen = 0;
   Integer warp_x = 0;
   Integer warp_y = 0;
   Integer jig = 0;
   Integer confirmed = 0;
   Integer leaves = 0;
   Real leave_window = 0.;
   Real last_input = 0.;

   Real last_frame = g_now;
   Real frame_ms = 0.;
   Integer frames = 0;
   Real sum_ms = 0.;
   Integer want_frame = 1;

   Set_data(message_box, "Right click the game to start playing. Press H for help.");

   while (1) {
      if (want_frame) {
         Real t0 = 0.;
         Get_time(t0);
         Real dt = t0 - last_frame;
         if (dt > 0.1) dt = 0.1;
         if (dt < 0.) dt = 0.;
         last_frame = t0;
         g_now = t0;
         update(dt);
         render(draw_box, frame_ms);
         Real t1 = 0.;
         Get_time(t1);
         frame_ms = (t1 - t0) * 1000.;
         ++frames;
         sum_ms = sum_ms + frame_ms;
         if (frames % 300 == 0) {
            Print("[12doom] frames " + To_text(frames - 299) + "-" + To_text(frames) + ": avg "
               + To_text(sum_ms / 300., 1) + " ms/frame, " + To_text(g_colw) + " px columns, "
               + To_text(g_nvis) + " sprites, view " + To_text(last_w) + "x" + To_text(last_h) + "\n");
            sum_ms = 0.;
         }
         want_frame = 0;
      }

      Integer64 id;
      Text cmd;
      Text msg;
      Integer res = Wait_on_events(id, cmd, msg);
      Get_time(g_now);
      if (res != 0) continue;

      switch (cmd) {
         case "Panel Quit": {
            return 0;
         }
         case "CodeShutdown": {
            Set_exit_code("CodeShutdown");
            return (424242);
         }
      }

      Integer bw = 0;
      Integer bh = 0;
      Get_size(draw_box, bw, bh);
      Integer release = 0;
      Text why = "";

      // The window was resized: the view (and so the screen mapping
      // and the mouse's parking spot) changed. Draw at the new size.
      if (bw != last_w || bh != last_h) {
         Print("[12doom] view resized to " + To_text(bw) + " x " + To_text(bh) + "\n");
         last_w = bw;
         last_h = bh;
         have_seen = 0;
         if (g_captured) {
            release = 1;
            why = "the window was resized";
         }
         resize_pending = 1;
      }
      // A resize sends hundreds of Panel_Resize events; drawing a frame
      // for every one queued seconds of work. Draw at most 10 a second
      // while they arrive, and once more on the next other event.
      if (cmd == "Panel_Resize") {
         if (g_now - last_frame >= 0.1) {
            want_frame = 1;
            resize_pending = 0;
         } else {
            resize_pending = 1;
         }
      } else if (resize_pending) {
         want_frame = 1;
         resize_pending = 0;
      }
      Integer start_req = 0;
      Integer req_ox = 0;
      Integer req_oy = 0;

      if (id == Get_id64(draw_box)) {
         Real bx = 0.;
         Real by = 0.;
         Integer has_xy = split_xy(msg, bx, by) == 0;
         if (cmd == "mouse_move" && has_xy && !g_captured) {
            // Remember a checked screen mapping, so a key press on the
            // help screen can start the game without a click.
            Integer mox = 0;
            Integer moy = 0;
            if (calibrate(draw_box, bx, by, bw, bh, mox, moy) == 0) {
               seen_ox = mox;
               seen_oy = moy;
               have_seen = 1;
            }
            want_frame = 1;
         } else if (cmd == "mouse_move" && has_xy) {
            if (g_captured) {
               Real dx = bx - (warp_x + jig);
               Real dy = by - warp_y;
               if (Absolute(dx) < 3. && Absolute(dy) < 3.) confirmed = 1;
               if (Absolute(dx) >= 1.5) {
                  g_pa = g_pa + dx * 0.0045;
                  last_input = g_now;
               }
               if (bx < 0. || bx > bw || by < 0. || by > bh) {
                  release = 1;
                  why = "the mouse left the game";
               } else {
                  jig = 1 - jig;
                  Set_cursor_position(ox + warp_x + jig, oy - warp_y);
               }
            }
            want_frame = 1;
         } else if (cmd == "mouse_leave" && g_captured) {
            // A fast flick can leave the box between events. Once warps
            // are known to land, pull the cursor back; otherwise, or if
            // it keeps happening, let go.
            if (g_now - leave_window > 1.) {
               leave_window = g_now;
               leaves = 0;
            }
            ++leaves;
            if (!confirmed || leaves > 4) {
               release = 1;
               why = "the mouse left the game";
            } else {
               Set_cursor_position(ox + warp_x + jig, oy - warp_y);
            }
         } else if ((cmd == "click_lb_down" || cmd == "double_click_lb") && g_captured) {
            // A quick second click arrives as double_click_lb with no
            // click_lb_down of its own.
            fire();
            last_input = g_now;
            want_frame = 1;
         } else if (((cmd == "click_rb") || (cmd == "click_lb" && g_show_help)) && !g_captured && has_xy) {
            // Right click (or any click on the help screen) starts play.
            // Calibrate on the click: msg and the cursor are both inside
            // the box here.
            Integer cox = 0;
            Integer coy = 0;
            Integer cal = calibrate(draw_box, bx, by, bw, bh, cox, coy);
            if (cal == 1) {
               Set_data(message_box, "Right click inside the game to start playing.");
            } else if (cal == 2) {
               Set_data(message_box, "Couldn't start -- try moving the panel, then right click again.");
            } else {
               start_req = 1;
               req_ox = cox;
               req_oy = coy;
            }
            want_frame = 1;
         } else if (cmd == "click_lb" && !g_captured) {
            Set_data(message_box, "Right click the game to start playing.");
            show_msg("Right click to play", 1.5);
            want_frame = 1;
         } else if (cmd == "click_rb" && g_captured) {
            // Right click again stops mouselook.
            release = 1;
            why = "";
         }
      } else if (id == Get_id64(key_box)) {
         if (cmd == "keystroke") {
            Text k = Text_lower(msg);
            // Any game key on the help screen starts play.
            if (g_show_help && !g_captured && (k == "w" || k == "a" || k == "s" || k == "d" || k == "f" || k == " ")) {
               start_req = 1;
               if (have_seen) {
                  req_ox = seen_ox;
                  req_oy = seen_oy;
               } else {
                  // No mouse movement over the game yet: use the panel
                  // position (the view starts 8 px right of it and h + 30
                  // px below it -- measured, see domain-notes.md).
                  Integer kgx = 0;
                  Integer kgy = 0;
                  Get_position(draw_box, kgx, kgy);
                  req_ox = kgx + 8;
                  req_oy = kgy + 30 + bh;
               }
            }
            if (k == "w" || k == "a" || k == "s" || k == "d") {
               // A fresh press moves for TAP_TIME (easing in -- see update()).
               // The same key again within 0.6 s is the key being held: the
               // first auto-repeat comes ~0.5 s after the press, the rest
               // every ~30 ms. (A 0.12 s window treated that first repeat as
               // a fresh press and restarted the slow start mid-hold.)
               if (k == g_key && g_now - g_key_last < 0.6) {
                  g_key_until = g_now + 0.1;
                  g_key_held = 1;
               } else {
                  g_key_until = g_now + TAP_TIME;
                  g_key_start = g_now;
                  g_key_held = 0;
               }
               g_key = k;
               g_key_last = g_now;
            }
            if (k == "f" || k == " ") fire();
            if (k == "m") g_show_map = 1 - g_show_map;
            if (k == "h") g_show_help = 1 - g_show_help;
            if (k == "r") reset_game();
            if (k == "n") new_random_map();
            if (k == "1") g_colw = 3;
            if (k == "2") g_colw = 4;
            if (k == "3") g_colw = 6;
            if (k == "q" && g_captured) {
               release = 1;
               why = "";
            }
            Set_data(key_box, "");
            last_input = g_now;
            if (!g_captured) want_frame = 1;
         } else if (cmd == "text selected") {
            // Enter drops focus; take it back for the game keys.
            Set_data(key_box, "");
            Set_focus(key_box);
         } else if (cmd == "kill_focus" && g_captured) {
            release = 1;
            why = "another window was clicked";
         }
      } else if (cmd == "restart" || cmd == "random" || cmd == "original") {
         if (cmd == "restart") reset_game();
         if (cmd == "random") new_random_map();
         if (cmd == "original") {
            g_seed = 0;
            reset_game();
         }
         Set_focus(key_box);
         want_frame = 1;
      }

      if (start_req && !g_captured) {
         // Start playing: grab the mouse (warp point in the HUD bar).
         ox = req_ox;
         oy = req_oy;
         warp_x = Floor(bw / 2.);
         warp_y = Floor(g_hud_h / 2.);
         jig = 0;
         confirmed = 0;
         leaves = 0;
         g_captured = 1;
         g_show_help = 0;
         last_input = g_now;
         Set_cursor_position(ox + warp_x, oy - warp_y);
         Set_focus(key_box);
         Set_data(message_box, "Playing. Right click or Q to pause.");
         want_frame = 1;
      }

      if (g_captured && g_now - last_input > 45.) {
         release = 1;
         why = "idle";
      }
      if (release && g_captured) {
         g_captured = 0;
         Text paused = "Paused.";
         if (why != "") paused = "Paused (" + why + ").";
         Set_data(message_box, paused + " Right click the game to carry on.");
         want_frame = 1;
      }
   }

   return 0;
}

void main()
{
   run_gui_mode();
}
