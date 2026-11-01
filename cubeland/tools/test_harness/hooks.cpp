// Test hooks appended to the translated macro (can see its globals)
extern std::map<Text,std::function<void()>> g_calls;
void push_front_click(const char*kind,double x,double y);
static void dump(){
  printf("[dump] pos %.2f %.2f %.2f yaw %.2f pitch %.2f health %d dead %d ground %d water %d sel %d\n",g_player_x,g_player_y,g_player_z,g_player_yaw,g_player_pitch,g_player_health,g_player_dead,g_player_on_ground,g_player_in_water,g_player_selected);
  printf("[dump] inventory:"); for(int s=1;s<=36;s++) if(g_inv_item[s]) printf(" [%d]%s x%d",s,item_name(g_inv_item[s]).c_str(),g_inv_count[s]); printf("  cursor %d x%d\n",g_cursor_item,g_cursor_count);
  int cows=0; for(int c=1;c<=24;c++) cows+=g_cow_alive[c]; int drops=0; for(int d=1;d<=128;d++) drops+=g_drop_used[d];
  printf("[dump] cows %d drops %d edits %d target %d (%d %d %d) screen %d faces %d polys %d sections %d builds %d overflow %d\n",cows,drops,g_edit_count,g_target_kind,g_target_x,g_target_y,g_target_z,g_ui_screen,g_stat_faces,g_stat_polygons,g_stat_sections,g_mesh_builds,g_mesh_overflow);
  for(int f=1;f<=32;f++) if(g_furnace_used[f]) printf("[dump] furnace %d at %d %d %d in %d x%d fuel %d x%d out %d x%d burn %.1f prog %.1f\n",f,g_furnace_x[f],g_furnace_y[f],g_furnace_z[f],g_furnace_in_item[f],g_furnace_in_count[f],g_furnace_fuel_item[f],g_furnace_fuel_count[f],g_furnace_out_item[f],g_furnace_out_count[f],g_furnace_burn_left[f],g_furnace_progress[f]);
}
static void recipe_click(int r){ ui_layout(g_box_w,g_box_h); if(ui_recipe_rect(r)) push_front_click("click",g_ui_rect_x+20,g_ui_rect_y+5); else printf("no recipe rect %d\n",r); }
static void slot_click(int s,const char*k){ ui_layout(g_box_w,g_box_h); if(ui_slot_rect(s)) push_front_click(k,g_ui_rect_x+g_ui_rect_w/2,g_ui_rect_y+g_ui_rect_h/2); else printf("no slot rect %d\n",s); }
static void register_hooks(){
  g_calls["dump"]=dump;
  g_calls["texstats"]=[]{ for(int t=1;t<=23;t++) printf("[tex] %d rects %d base %d\n",t,g_tex_rect_count[t],g_tex_base[t]); printf("[tex] total %d\n",g_rect_total); };
  g_calls["give"]=[]{ inventory_add(6,4); inventory_add(3,16); inventory_add(21,3); inventory_add(4,10); };
  g_calls["cow_front"]=[]{ int c=cows_spawn(g_player_x+Cos(g_player_yaw)*3.0, g_player_y+0.5, g_player_z+Sin(g_player_yaw)*3.0, g_player_yaw+3.14159); printf("[hook] cow %d\n",c); };
  g_calls["look_down"]=[]{ g_player_pitch=-1.3; };
  g_calls["look_level"]=[]{ g_player_pitch=-0.1; };
  g_calls["look_cow"]=[]{ g_player_pitch=-0.25; };
  g_calls["lift10"]=[]{ g_player_y+=12; g_player_fall_peak=g_player_y; };
  g_calls["hurt"]=[]{ g_player_health=2; };
  for(int r=1;r<=6;r++) g_calls["recipe"+std::to_string(r)]=[r]{ recipe_click(r); };
  for(int s=1;s<=39;s++){ g_calls["slot"+std::to_string(s)]=[s]{ slot_click(s,"click"); }; g_calls["rslot"+std::to_string(s)]=[s]{ slot_click(s,"rclick"); }; }
  g_calls["select4"]=[]{ g_player_selected=4; };
  g_calls["aim_cow"]=[]{ int best=0; double bd=1e9; for(int c=1;c<=24;c++) if(g_cow_alive[c]){ double dx=g_cow_x[c]-g_player_x,dz=g_cow_z[c]-g_player_z; double d=dx*dx+dz*dz; if(d<bd){bd=d;best=c;} }
     if(!best) return; double dx=g_cow_x[best]-g_player_x, dy=g_cow_y[best]+0.9-(g_player_y+1.62), dz=g_cow_z[best]-g_player_z; g_player_yaw=wrap_angle(atan2(dz,dx)); g_player_pitch=atan2(dy,sqrt(dx*dx+dz*dz)); printf("[hook] aim cow %d dist %.2f\n",best,sqrt(bd)); };
  g_calls["cow_near"]=[]{ int c=cows_spawn(g_player_x+2.5, g_player_y+0.2, g_player_z+0.8, 2.3); g_cow_timer[c]=100; g_cow_walking[c]=0; printf("[hook] cow %d\n",c); };
  g_calls["clear_front"]=[]{ for(int dx=1;dx<=5;dx++) for(int dz=-2;dz<=2;dz++) for(int dy=0;dy<=3;dy++) world_set_block((int)g_player_x+dx,(int)g_player_y+dy,(int)g_player_z+dz,0); for(int dx=1;dx<=5;dx++) for(int dz=-2;dz<=2;dz++) world_set_block((int)g_player_x+dx,(int)g_player_y-1,(int)g_player_z+dz,5); mesh_reset(); };
  g_calls["give_furnace"]=[]{ inventory_add(11,1); inventory_add(9,6); g_player_selected=1; for(int s=1;s<=9;s++) if(g_inv_item[s]==11) g_player_selected=s; };
  g_calls["aim_block_front"]=[]{ g_player_yaw=0; g_player_pitch=-0.55; };
  g_calls["aim_placed"]=[]{ g_player_yaw=0; g_player_pitch=-0.12; };
  g_calls["noclip_up"]=[]{ g_player_y+=15; g_player_fall_peak=g_player_y; g_player_vy=0; };
  g_calls["time60"]=[]{ g_sim_time+=60; };
  g_calls["aim_furnace"]=[]{ g_player_yaw=0; g_player_pitch=-0.42; };
  g_calls["give_beef"]=[]{ inventory_add(21,3); };
  g_calls["check_furnace_block"]=[]{ printf("[hook] block at furnace = %d\n", world_get_block(85,64,73)); };
  g_calls["full"]=[]{ g_player_health=20; };
  g_calls["to_water"]=[]{ for(int r=1;r<60;r++) for(int dx=-r;dx<=r;dx++) for(int dz=-r;dz<=r;dz++){ int x=(int)g_player_x+dx, z=(int)g_player_z+dz; if(world_get_block(x,60,z)==8 && world_get_block(x,55,z)==8){ player_reset(x+0.5,60.5,z+0.5); g_player_pitch=-0.2; printf("[hook] water at %d %d\n",x,z); return; } } };
  g_calls["to_forest"]=[]{ int best=-1,bx=0,bz=0; for(int x=8;x<120;x+=2) for(int z=8;z<120;z+=2){ int n=0; for(int dx=-6;dx<=6;dx++) for(int dz=-6;dz<=6;dz++){ int t=world_top_solid_y(x+dx,z+dz); if(t>0&&world_get_block(x+dx,t,z+dz)==7) n++; } if(n>best){best=n;bx=x;bz=z;} }
     int t=world_top_solid_y(bx,bz); player_reset(bx+0.5,t+1.0,bz+0.5); g_player_pitch=0.05; printf("[hook] forest %d at %d %d\n",best,bx,bz); };
  g_calls["to_hill"]=[]{ int best=-1,bx=0,bz=0; for(int x=8;x<120;x+=3) for(int z=8;z<120;z+=3){ int t=world_top_solid_y(x,z); if(t>best){best=t;bx=x;bz=z;} } player_reset(bx+0.5,best+1.0,bz+0.5); g_player_pitch=-0.25; printf("[hook] hill %d at %d %d\n",best,bx,bz); };
  g_calls["frames_reset"]=[]{ extern long long g_frames, g_polygons; printf("[mark] frames %lld polygons %lld\n", g_frames, g_polygons); };
  g_calls["frames_report"]=[]{ extern long long g_frames, g_polygons; printf("[mark] frames %lld polygons %lld\n", g_frames, g_polygons); };
  g_calls["stone_front"]=[]{ int x=(int)g_player_x+2, y=(int)g_player_y, z=(int)g_player_z; world_place_block(x,y,z,2); world_place_block(x,y+1,z,10); g_player_yaw=0; g_player_pitch=-0.3; };
  g_calls["noon"]=[]{ g_player_yaw=1.0; g_player_pitch=0.0; };
}
