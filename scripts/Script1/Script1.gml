// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information


//
// INITIALISATION LOGIC - these not called directly from GameMaker events
//
// Called from FSM STATES GAME_START and ROOM_START
//
function dc_p_initialise_game_globals() {
  global.dcg_human_is_immortal = false;  
  global.dcg_pitch_var = 1.0595;  // 12th root of 2; 1 semitone variation

  // Setup sounds
  audio_play_sound(loopDrone, 10, true, 1);
  audio_play_sound(loopMissile, 10, true, 1);
  audio_play_sound(loopMeleeEnemy, 10, true, 1);
  audio_play_sound(loopProjectileEnemy, 10, true, 1);
}
function dc_p_initialise_room_globals() {
  // Lots of per-room globals - also MACROS
  global.dcg_abs_smallest_range = 9999999;
  global.dcg_pitch_mult = 1;  

  // Globals to track objects at each grid location
  global.dcg_objects_found = false;
  global.dcg_wall_grid_built = false;
  global.dcg_tile_grid_built = false;
  global.dcg_wall_grid[0,0] = false;
  global.dcg_tile_grid[0,0] = noone;
  global.dcg_available_grid[0,0] = noone;
  global.dcg_corner_grid[0,0] = noone;
  global.dcg_inst_grid[0,0] = noone;
  global.dcg_object_grid[0,0] = 0;
  global.dcg_range_grid1[0,0] = 0;
  global.dcg_range_grid2[0,0] = 0;
#macro DC_CTRL_NONE                          0
#macro DC_CTRL_USE_FIRST_BEST_PATH           1
#macro DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH 2

  // Stuff to map grid x/y to pixel x/y and vice versa
  global.dcg_grid_invalid = 999;
  global.dcg_grid_max_distance = 12;
  global.dcg_grid_x_cells = 12;
  global.dcg_grid_y_cells = 12;
  global.dcg_grid_cell_width = 32;
  global.dcg_grid_cell_height = 32;
  global.dcg_grid_cell_height_offset = global.dcg_grid_cell_height / 2;
  global.dcg_grid_min_distance = 4;
  global.dcg_grid_min_px = 0;
  global.dcg_grid_min_py = 128;
  global.dcg_grid_max_px = global.dcg_grid_min_px + (global.dcg_grid_x_cells * global.dcg_grid_cell_width) - 1;
  global.dcg_grid_max_py = global.dcg_grid_min_py + (global.dcg_grid_y_cells * global.dcg_grid_cell_height) - 1;

  // Grid x/y locations for selection line
  global.dcg_sel0_gx = -1;
  global.dcg_sel0_gy = -1;
  global.dcg_sel1_gx = -1;
  global.dcg_sel1_gy = -1;
  global.dcg_sel2_gx = -1;
  global.dcg_sel2_gy = -1;

  // STATES: 0=GameStart 1=RoomStart 2=TurnStart 3=UserSelect 4=UserAnimate 5=EnemyAnimate 6=TurnEnd 7=GameEnd
#macro DC_STATE_GAME_START 0
#macro DC_STATE_ROOM_START 1
#macro DC_STATE_TURN_START 2
#macro DC_STATE_USER_SELECT 3
#macro DC_STATE_USER_ANIMATE 4
#macro DC_STATE_USER_ANIMATE_HIT 5
#macro DC_STATE_ENEMY_ANIMATE 6
#macro DC_STATE_ENEMY_ANIMATE_ATTACK 7
#macro DC_STATE_USER_ANIMATE_DYING 8
#macro DC_STATE_TURN_END 9
#macro DC_STATE_ROOM_END 10
#macro DC_STATE_GAME_END 11
  global.dcg_state = DC_STATE_ROOM_START;

  // EVENTS: 0=None 1=EnterState 2=ObjectSelected 3=DestSelected 4=TurnFinished 5=AnimateEnded
#macro DC_EVENT_NONE 0
#macro DC_EVENT_ENTER_STATE 1
#macro DC_EVENT_OBJECT_SELECTED 2
#macro DC_EVENT_DEST_SELECTED 3
#macro DC_EVENT_TURN_FINISHED 4
#macro DC_EVENT_ANIMATE_ENDED 5

  // OBJECTS: 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Field 6=Enemy1(Melee) 7=Enemy2(Projectile)
  //         15=Mouse (pseudo-object to match against in dc_p_find_sel2)
#macro DC_OBJECT_FIRST 0
#macro DC_OBJECT_NONE 0
#macro DC_OBJECT_DRONE 1
#macro DC_OBJECT_MISSILE 2
#macro DC_OBJECT_HUMAN 3
#macro DC_OBJECT_LASER 4
#macro DC_OBJECT_FIELD 5
#macro DC_OBJECT_ENEMY1 6
#macro DC_OBJECT_ENEMY2 7
#macro DC_OBJECT_WALL 8
#macro DC_OBJECT_MOUSE 15
  global.dcg_object_sel_base = DC_OBJECT_NONE;
  global.dcg_object_move = DC_OBJECT_NONE;
  global.dcg_object_animate = DC_OBJECT_NONE;
  global.dcg_objects_animating = 0;

  // OBJECT STATES: 0=None 1=Alive 2=Dying 3=Dead
#macro DC_OBJSTATE_NONE  0
#macro DC_OBJSTATE_ALIVE 1
#macro DC_OBJSTATE_DYING 2
#macro DC_OBJSTATE_DEAD  3
  global.dcg_human_alive = true;
  global.dcg_enemies_n_melee = 0;
  global.dcg_enemies_n_projectile = 0;
  global.dcg_enemies_alive = 0;
  global.dcg_enemies_dying = 0;
  global.dcg_enemies_dead = 0;

  // UI ACTIONS: 13=MouseEnter 14=MouseClick 15=MouseExit
#macro DC_ACTION_NONE          0
#macro DC_ACTION_ENTER         1
#macro DC_ACTION_CLICK         2
#macro DC_ACTION_EXIT          3

  // GAME ACTIONS: 0=None 11=DroneMove 12=DroneFireLaser 13=DroneProjectField 14=DroneDisplaceHuman 15=MissileMove
#macro DC_ACTION_DRONE_MOVE   11
#macro DC_ACTION_DRONE_LASER  12
#macro DC_ACTION_DRONE_FIELD  13
#macro DC_ACTION_DRONE_HUMAN  14
#macro DC_ACTION_MISSILE_MOVE 15
  global.dcg_object_action = DC_ACTION_NONE;

  // Turn counter - incremented on turn start so first turn is turn 1
  global.dcg_turn = 0;
  // Global var to track whether certain action buttons are available or not
  global.dcg_button_avail_mask = 0;
  // ...and whether human/field have been used
  global.dcg_field_used[0] = false;
  global.dcg_human_used[0] = false;
  global.dcg_field_used[1] = false;
  global.dcg_human_used[1] = false;

  // For each action type maintain a mask of where selection lines should stop
  global.dcg_limit_obj_mask[0] = 0;
  // For each action type maintain a max distance that selection lines are allowed to extend
  global.dcg_max_distance[0] = 0;
  // Track if missile docled
  global.dcg_missile_docked = false; 
  // Track last stimulus used in calls to dc_p_set_available_tiles
  global.dcg_last_start_gx = -1;
  global.dcg_last_start_gy = -1;
  global.dcg_last_lim_obj_mask = 0;
  global.dcg_last_max_distance = 0;
  global.dcg_last_end_gx[0] = -1;
  global.dcg_last_end_gy[0] = -1;
  global.dcg_last_corner0 = noone;
  global.dcg_last_corner1 = noone;
    
}


//
// PRIVATE FUNCTIONS - these not called directly from GameMaker events
//
function dc_p_get_gx(px) {
  if ((px < global.dcg_grid_min_px) || (px > global.dcg_grid_max_px)) return -1;  // Bail if bad x
  return (px - global.dcg_grid_min_px) / global.dcg_grid_cell_width;  // Map pixel x to grid x
}
function dc_p_get_gy(py) {
  if ((py < global.dcg_grid_min_py) || (py > global.dcg_grid_max_py)) return -1;  // Bail if bad y
  return (py - global.dcg_grid_min_py) / global.dcg_grid_cell_height;  // Map pixel y to grid y
}
function dc_p_get_object_gx(px) {
  return round(dc_p_get_gx(px));
}
function dc_p_get_object_gy(py) {
  return round(dc_p_get_gy(py + global.dcg_grid_cell_height_offset));
}

function dc_p_get_name(dca_obj_type) {
  switch (dca_obj_type) {
    case DC_OBJECT_DRONE:   return "DRONE";
    case DC_OBJECT_MISSILE: return "MISSILE";
    case DC_OBJECT_HUMAN:   return "HUMAN";
    case DC_OBJECT_LASER:   return "LASER";
    case DC_OBJECT_FIELD:   return "FIELD";
    case DC_OBJECT_ENEMY1:  return "ENEMY1";
    case DC_OBJECT_ENEMY2:  return "ENEMY2";
    case DC_OBJECT_WALL:    return "WALL";
    default:                return "INVALID";
  }
}
function dc_p_find_instance(dca_obj_type, dca_which) {
  switch (dca_obj_type) {
    case DC_OBJECT_DRONE:   return instance_find(obj_drone, dca_which);
    case DC_OBJECT_MISSILE: return instance_find(obj_missile, dca_which);
    case DC_OBJECT_HUMAN:   return instance_find(obj_humanidle, dca_which);
    case DC_OBJECT_LASER:   return instance_find(obj_laserNS, dca_which);
    case DC_OBJECT_FIELD:   return instance_find(obj_field, dca_which);
    case DC_OBJECT_ENEMY1:  return instance_find(obj_enemymelee, dca_which);
    case DC_OBJECT_ENEMY2:  return instance_find(obj_enemyprojectile, dca_which);
    case DC_OBJECT_WALL:    return instance_find(obj_wall, dca_which);
    default:                return noone;
  }
}

function dc_p_setup_nxt_xy(dca_obj_type, dca_which, dca_gx, dca_gy) {
  var inst = dc_p_find_instance(dca_obj_type, dca_which);
  if (inst == noone) return noone;
  inst.dci_nxt_gx = dca_gx;
  inst.dci_nxt_gy = dca_gy;
  return inst;
}
function dc_p_setup_now_xy(dca_obj_type, dca_which) {
  var inst = dc_p_find_instance(dca_obj_type, dca_which);
  if (inst == noone) return noone;
  // Setup a bunch of per-instance variables to track type and grid position
  inst.dci_obj_state = DC_OBJSTATE_ALIVE;
  inst.dci_obj_type = dca_obj_type;
  inst.dci_which = dca_which;
  inst.dci_now_gx = dc_p_get_object_gx(inst.x);
  inst.dci_now_gy = dc_p_get_object_gy(inst.y);
  inst.dci_step = 0;
  for (var i = 0; i < 3; i++) {
    inst.dci_via_gx[i] = -1;
    inst.dci_via_gy[i] = -1;
  }
  dc_p_setup_nxt_xy(dca_obj_type, dca_which, inst.dci_now_gx, inst.dci_now_gy);
  show_debug_message("{0}=[{1},{2}]", dc_p_get_name(dca_obj_type), inst.dci_now_gx, inst.dci_now_gy);
  return inst;
}
function dc_p_setup_pseudo_object(dca_obj_type, dca_gm_obj_type, dca_px, dca_py) {
  // Special logic to construct pseudo-objects
  var pobj = dc_p_find_instance(dca_obj_type, 0);
  if (pobj != noone) return;  // Just in case room already has one
  var new_pobj_id = instance_create_layer(dca_px, dca_py, "Instances_1", dca_gm_obj_type);
  var new_pobj = dc_p_find_instance(dca_obj_type, 0);
  if (new_pobj == noone) return;
  new_pobj.sprite_index = spr_clear;  // Invisible initially
  dc_p_setup_now_xy(dca_obj_type, 0);
}
function dc_p_setup_laser() {
  // Special logic to construct laser pseudo-object
  // It gets special sprites to indicate laser fire which need its x/y to get futzed with
  // Otherwise it follows drone around
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  if (drone == noone) return;
  dc_p_setup_pseudo_object(DC_OBJECT_LASER, obj_laserNS, drone.x, drone.y);
}
function dc_p_setup_field() {
  // Special logic to construct field pseudo-object
  // Normally it just follows drone around
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  if (drone == noone) return;
  dc_p_setup_pseudo_object(DC_OBJECT_FIELD, obj_field, drone.x, drone.y);
}
function dc_p_setup_missile_if_missing() {
    // Special logic to construct missile if we haven't found one
    // If we don't find one we assumed it's 'docked in drone' - so we create the object but with a clear sprite
    var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
    if (drone == noone) return;    
    var missile = dc_p_find_instance(DC_OBJECT_MISSILE, 0);
    if (missile == noone) {
	global.dcg_missile_docked = true;
	audio_sound_gain(loopMissile, 0, 100);  // Gain 0 (in 100ms) - missile quiet	
	dc_p_setup_pseudo_object(DC_OBJECT_MISSILE, obj_missile, drone.x, drone.y);
    }
}


function dc_p_find_objects() {
  if (global.dcg_objects_found) return;
  // Find drone/missile/human
  for (var otyp = DC_OBJECT_DRONE; otyp <= DC_OBJECT_FIELD; otyp++) {
    dc_p_setup_now_xy(otyp, 0);
  }
  // Create missile object 'docked in drone' if none in room
  dc_p_setup_missile_if_missing();
    
  // Find melee enemies
  var i1 = 0;
  while (dc_p_setup_now_xy(DC_OBJECT_ENEMY1, i1) != noone) {
    i1++;
  }
  var gain1 = (i1 > 0) ?1 :0;
  global.dcg_enemies_n_melee = i1;
  audio_sound_gain(loopMeleeEnemy, gain1, 100);  // 100ms
  // Find projectile enemies
  var i2 = 0;
  while (dc_p_setup_now_xy(DC_OBJECT_ENEMY2, i2) != noone) {
    i2++;
  }
  var gain2 = (i2 > 0) ?1 :0;
  global.dcg_enemies_n_projectile = i2;
  audio_sound_gain(loopProjectileEnemy, gain2, 100);  // 100ms
    
  global.dcg_enemies_alive = i1 + i2;

  dc_p_setup_laser();
  dc_p_setup_field();
  // TODO: BARF IF DRONE OR HUMAN or MONSTER(S) MISSING!!!
  global.dcg_objects_found = true;
}
function dc_p_find_walls() {
  if (global.dcg_wall_grid_built) return;
  for (var i = 0; i < global.dcg_grid_x_cells; i++) {
    for (var j = 0; j < global.dcg_grid_y_cells; j++) {
      global.dcg_wall_grid[i, j] = false;
    }
  }
  var w = 0;
  while (true) {
    var wall = dc_p_setup_now_xy(DC_OBJECT_WALL, w);
    if (wall == noone) break;
    global.dcg_wall_grid[wall.dci_now_gx, wall.dci_now_gy] = true;
    w++;
  }
  global.dcg_wall_grid_built = true;
}
function dc_p_make_tile_grid() {
    if (global.dcg_tile_grid_built) return;
    for (var i = 0; i < global.dcg_grid_x_cells; i++) {
	var px = (i * global.dcg_grid_cell_width) + global.dcg_grid_min_px;
	for (var j = 0; j < global.dcg_grid_y_cells; j++) {
	    var py = (j * global.dcg_grid_cell_height) + global.dcg_grid_min_py;
	    // obj_tile is parent of obj_tilewhite and obj_tilegrey
	    var inst = instance_nearest(px, py, obj_tile);
	    global.dcg_tile_grid[i, j] = inst;
	    // Now we dynamically create obj_tileavailable and obj_corners
	    // in every tile, initially making them invisible
	    var available = instance_create_layer(px, py, "Instances0_Background_UI_Available", obj_tileavailable);
	    global.dcg_available_grid[i, j] = available;
	    available.sprite_index = spr_clear;
	    var corner = instance_create_layer(px, py, "Instances0_Background_UI_Corners", obj_corner);
	    global.dcg_corner_grid[i, j] = corner;
	    corner.sprite_index = spr_clear;
	}
    }
    global.dcg_tile_grid_built = true;
}
function dc_p_make_object_grid() {
  // May repeatedly call this
  dc_p_find_objects();
  dc_p_find_walls();
  for (var i = 0; i < global.dcg_grid_x_cells; i++) {
    for (var j = 0; j < global.dcg_grid_y_cells; j++) {
      global.dcg_object_grid[i, j] = 0;
      global.dcg_inst_grid[i, j] = noone;
    }
  }
  for (var otyp = DC_OBJECT_DRONE; otyp <= DC_OBJECT_WALL; otyp++) {
    var k = 0;
    while (true) {
      var inst = dc_p_find_instance(otyp, k);
      if (inst == noone) break;
      if (inst.dci_obj_state == DC_OBJSTATE_ALIVE) {
        // Build up a bitmask of objects at every grid x/y
        global.dcg_object_grid[inst.dci_now_gx, inst.dci_now_gy] |= (1<<otyp);
        // And store the current object instance at each grid x/y
        global.dcg_inst_grid[inst.dci_now_gx, inst.dci_now_gy] = inst;
      }
      k++;
    }
  }
}
function dc_p_make_limit_obj_masks() {
  for (var i = 0; i < 16; i++) global.dcg_limit_obj_mask[i] = (1<<DC_OBJECT_WALL);
  var enemies = (1<<DC_OBJECT_ENEMY1) | (1<<DC_OBJECT_ENEMY2);
  global.dcg_limit_obj_mask[DC_ACTION_DRONE_MOVE] = (1<<DC_OBJECT_WALL) | (1<<DC_OBJECT_HUMAN) | (1<<DC_OBJECT_MOUSE) | enemies;
  global.dcg_limit_obj_mask[DC_ACTION_DRONE_LASER] = 0;
  global.dcg_limit_obj_mask[DC_ACTION_DRONE_FIELD] = (1<<DC_OBJECT_WALL) | (1<<DC_OBJECT_MOUSE);
  global.dcg_limit_obj_mask[DC_ACTION_DRONE_HUMAN] = (1<<DC_OBJECT_WALL) | (1<<DC_OBJECT_HUMAN) | (1<<DC_OBJECT_MOUSE) | enemies;
  global.dcg_limit_obj_mask[DC_ACTION_MISSILE_MOVE] = (1<<DC_OBJECT_WALL) | (1<<DC_OBJECT_MOUSE);
}
function dc_p_make_max_distances() {
  for (var i = 0; i < 16; i++) global.dcg_max_distance[i] = 999;
  global.dcg_max_distance[DC_ACTION_NONE] = 0;
  global.dcg_max_distance[DC_ACTION_DRONE_MOVE] = 999;
  global.dcg_max_distance[DC_ACTION_DRONE_LASER] = 999;
  global.dcg_max_distance[DC_ACTION_DRONE_FIELD] = 1;
  global.dcg_max_distance[DC_ACTION_DRONE_HUMAN] = 1;
  global.dcg_max_distance[DC_ACTION_MISSILE_MOVE] = 999;
}


//
// FUNCTIONS TO MAKE RANGE GRIDS
//
// These are grids where each cell entry contains a number
// describing the distance to a target cell (where human is).
// Enemies consult range grids and move to the neighbouring cell
// containing the numerically lowest range.
//
function dc_p_range_grid_initialise(dca_array) {
  // Initialise range grid non-wall locations to -1, wall locations to 9999999
  for (var i = 0; i < global.dcg_grid_x_cells; i++) {
    for (var j = 0; j < global.dcg_grid_y_cells; j++) {
      dca_array[@ i, j] = (global.dcg_wall_grid[i,j]) ?9999999 :-1;
    }
  }
}
function dc_p_range_grid_setpos(dca_array, dca_gx, dca_gy, dca_val) {
  var listThis = ds_list_create();
  dca_array[@ dca_gx, dca_gy] = dca_val;
  ds_list_add(listThis, (1<<20) + (dca_gx << 10) + (dca_gy << 0));
  return listThis;
}
function dc_p_range_grid_setlinesfrom(dca_array, dca_gx, dca_gy, dca_val) {
  var listThis = ds_list_create();
  // Fill in grid vals in order W E N S NW NE SW SE
  var dxtab = [ -1,  1,  0,  0, -1,  1, -1,  1 ];
  var dytab = [  0,  0, -1,  1, -1, -1,  1,  1 ];
  for (var i = 0; i < 8; i++) {
    var dx = dxtab[i];
    var dy = dytab[i];	
    if ((dx == 0) && (dy == 0)) continue;  // Just in case
    // For all 8 directions
    var tgx = dca_gx;
    var tgy = dca_gy;
    // While valid gy/gy and grid pos unset (<0) fill in val
    // and record position in list
    while ( ((tgx + dx) >= 0) && ((tgx + dx) < global.dcg_grid_x_cells) &&
            ((tgy + dy) >= 0) && ((tgy + dy) < global.dcg_grid_y_cells) &&
            (dca_array[@ tgx + dx, tgy + dy] < 0) ) {
      tgx += dx;
      tgy += dy;
      dca_array[@ tgx, tgy] = dca_val;
      ds_list_add(listThis, (1<<20) + (tgx << 10) + (tgy << 0));
    }
  }
  return listThis;
}
function dc_p_range_grid_populate(dca_array, dca_list, dca_val) {
  // Fill in grid vals in order W E N S NW NE SW SE
  var dxtab = [ -1,  1,  0,  0, -1,  1, -1,  1 ];
  var dytab = [  0,  0, -1,  1, -1, -1,  1,  1 ];
  var listThis = dca_list;
  var listNext = ds_list_create();  // To hold new list for val+1

  // Now go through listThis of locations, then look at all neighbouring
  // locations, and if they're < 0, set their value to val and add the
  // neighbour locations to list listNext.
  // Repeat with listNext as listThis and value val+1.
  // Stop when listThis is empty.
  while (true) {

    var sz = ds_list_size(listThis);
    if (sz == 0) break;  // listThis was empty - we're done

    for (var i = 0; i < sz; i++) {
      var listEntry = listThis[|i];
      var gx = (listEntry >> 10) & 0x3FF;
      var gy = (listEntry >>  0) & 0x3FF;

      // Look for all valid neighbour cells of gx/gy that currently are -1 and set
      // them to X+1 and also add those neighbour gx/gy locations to listNext
      for (var j = 0; j < 8; j++) {
        var dx = dxtab[j];
        var dy = dytab[j];	
        if ((dx == 0) && (dy == 0)) continue;
        // For all 8 neighbours
        if ( ((gx + dx) >= 0) && ((gx + dx) < global.dcg_grid_x_cells) &&
             ((gy + dy) >= 0) && ((gy + dy) < global.dcg_grid_y_cells) &&
             (dca_array[@ gx + dx, gy + dy] < 0) ) {

          dca_array[@ gx + dx, gy + dy] = dca_val;
          ds_list_add(listNext, (1<<20) + ((gx+dx) << 10) + ((gy+dy) << 0));
        }
      }
    }

    // Swap listThis to be listNext; create brand new listNext; repeat with val+1
    if (listThis != dca_list) ds_list_destroy(listThis);
    listThis = listNext;
    listNext = ds_list_create();
    dca_val++;
  }

  // Cleanup
  if (listThis != dca_list) ds_list_destroy(listThis);
  ds_list_destroy(listNext);
}
function dc_p_range_grid_enemyinvalidate(dca_array) {
  for (var etyp = DC_OBJECT_ENEMY2; etyp >= DC_OBJECT_ENEMY1; etyp--) {
    var i = 0;
    while (true) {
      var monst = dc_p_find_instance(etyp, i);
      if (monst == noone) break;
      if (monst.dci_obj_state == DC_OBJSTATE_ALIVE) {
        with (monst) {
          // Make range of enemy current cell v.big to prevent selection
          // (actual range will be restored if enemy moves off gx/gy)
          dca_array[@ dci_now_gx, dci_now_gy] += 9000000;
        }
      }
      i++;
    }
  }
}
function dc_p_range_grid_fieldinvalidate(dca_array) {
  var field = dc_p_find_instance(DC_OBJECT_FIELD, 0);
  if ((field == noone) || (field.sprite_index == spr_clear)) return;
  with (field) {
    // Make range of active field current cell = 0 to prevent selection
    // and to 'freeze' any monster currently on it
    dca_array[@ dci_now_gx, dci_now_gy] = 0;
  }
}
function dc_p_range_grid_droneinvalidate(dca_array) {
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  if (drone == noone) return;
  with (drone) {
    // Make range of drone current cell = 0 to prevent monsters moving on to it
    dca_array[@ dci_now_gx, dci_now_gy] = 0;
  }
}

// Make dcg_range_grid1 used by DC_OBJECT_ENEMY1(melee) to move closer to human
function dc_p_make_range_grid1() {
  var human = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
  if (human == noone) return;
  // Make DC_OBJECT_ENEMY1 range grid
  dc_p_range_grid_initialise(global.dcg_range_grid1);
  // Set human location to value 0 - getting back (singleton) list of location with val 0
  var list0 = dc_p_range_grid_setpos(global.dcg_range_grid1, human.dci_now_gx, human.dci_now_gy, 0);
  // Use list to set neighouring cells to 1, then neighbours of the 1 cells to 2, and so on
  dc_p_range_grid_populate(global.dcg_range_grid1, list0, 1);
  ds_list_destroy(list0);
  // Prevent enemy locations being valid locations to move to
  dc_p_range_grid_enemyinvalidate(global.dcg_range_grid1);
  // Prevent field being a valid location to move to
  dc_p_range_grid_fieldinvalidate(global.dcg_range_grid1);
  // Prevent drone being a valid location to move to
  dc_p_range_grid_droneinvalidate(global.dcg_range_grid1);
}
// Make dcg_range_grid2 used by DC_OBJECT_ENEMY2(projectile) to move closer to any
// horizontal/vertical/diagonal line that has visibility of human
function dc_p_make_range_grid2() {
  var human = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
  if (human == noone) return;
  // Make DC_OBJECT_ENEMY2 range grid
  dc_p_range_grid_initialise(global.dcg_range_grid2);
  // Set human location to value 0 - getting back (singleton) list of location with val 0
  var list0 = dc_p_range_grid_setpos(global.dcg_range_grid2, human.dci_now_gx, human.dci_now_gy, 0);
  ds_list_destroy(list0);  // List not needed
  // Set horizontal/vertical/diagonal lines from human location to have val 1 getting back location list
  var list1 = dc_p_range_grid_setlinesfrom(global.dcg_range_grid2, human.dci_now_gx, human.dci_now_gy, 1);
  // Use list to set neighouring cells to 2, then neighbours of the 2 cells to 3, and so on
  dc_p_range_grid_populate(global.dcg_range_grid2, list1, 2);
  ds_list_destroy(list1);
  // Prevent enemy locations being valid locations to move to
  dc_p_range_grid_enemyinvalidate(global.dcg_range_grid2);
  // Prevent field being a valid location to move to
  dc_p_range_grid_fieldinvalidate(global.dcg_range_grid2);
  // Prevent drone being a valid location to move to
  dc_p_range_grid_droneinvalidate(global.dcg_range_grid1);
}
function dc_p_make_range_grids() {
  dc_p_make_range_grid1();
  dc_p_make_range_grid2();
}

function dc_p_initialise_room() {
  dc_p_find_objects();
  dc_p_find_walls();
  dc_p_make_tile_grid();
  dc_p_make_limit_obj_masks();
  dc_p_make_max_distances();
  dc_p_make_object_grid();
}


//
// SELECTION LINE LOGIC
//
function dc_p_find_delta(dca_a, dca_b) {
  var delta = dca_b - dca_a;
  if (delta < 0) return -1;
  if (delta > 0) return 1;
  return 0;  // a == b
}

function dc_p_selection_onoff(dca_start_gx, dca_start_gy, dca_end_gx, dca_end_gy, dca_lighton) {
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return;  // Bail if no sel0
  if ((dca_start_gx < 0) || (dca_start_gy < 0) || (dca_end_gx < 0) || (dca_end_gy < 0)) return;
  // Go from (start_gx,start_gy) --> (end_gx,end_gy) lighting or unlighting cells
  var delta_gx = dc_p_find_delta(dca_start_gx, dca_end_gx);
  var delta_gy = dc_p_find_delta(dca_start_gy, dca_end_gy);
  var tmp_gx = dca_start_gx;
  var tmp_gy = dca_start_gy;
  while (true) {
    // Check below should not be needed - but just in case
    if ((tmp_gx < 0) || (tmp_gx >= global.dcg_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dcg_grid_y_cells)) {
      break;
    }
    if ((tmp_gx == global.dcg_sel0_gx) && (tmp_gy == global.dcg_sel0_gy)) {
      // Never touch sel0
    } else {
      // But other tiles are fair game
      var inst = global.dcg_tile_grid[tmp_gx, tmp_gy];
      if (inst != noone) {
        inst.sprite_index = (dca_lighton) ?spr_tileselected :spr_tilewhite;
      }
    }
    // Stop if we get to end point
    if ((tmp_gx == dca_end_gx) && (tmp_gy == dca_end_gy)) break;
    tmp_gx += delta_gx;
    tmp_gy += delta_gy;
  }
}

function dc_p_same_line(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  if ((dca_g1_gx < 0) || (dca_g1_gy < 0) || (dca_g2_gx < 0) || (dca_g2_gy < 0)) return false;
  if (dca_g1_gx == dca_g2_gx) return true;
  if (dca_g1_gy == dca_g2_gy) return true;
  if (abs(dca_g1_gx - dca_g2_gx) == abs(dca_g1_gy - dca_g2_gy)) return true;
  return false;
}
function dc_p_same_line_as_sel0(dca_gx, dca_gy) {
  return dc_p_same_line(global.dcg_sel0_gx, global.dcg_sel0_gy, dca_gx, dca_gy);
}
function dc_p_direction8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy, check_diags=true) {
  // Direction FROM G1 TO G2 - return BAD=0 N=1 NE=2 E=3 SE=4 S=5 SW=6 W=7 NW=8
 if ((dca_g1_gx < 0) || (dca_g1_gy < 0) || (dca_g2_gx < 0) || (dca_g2_gy < 0)) return 0;  // BAD
  if (dca_g1_gx == dca_g2_gx) return (dca_g1_gy < dca_g2_gy) ?5 :1;  // S or N
  if (dca_g1_gy == dca_g2_gy) return (dca_g1_gx < dca_g2_gx) ?3 :7;  // E or W
  if (check_diags && (abs(dca_g1_gx - dca_g2_gx) != abs(dca_g1_gy - dca_g2_gy))) return 0;  // BAD - not same diag
  if ((dca_g1_gx == dca_g2_gx) && (dca_g1_gy == dca_g2_gy)) return 0;  // BAD - identical
  if ((dca_g1_gx < dca_g2_gx) && (dca_g1_gy < dca_g2_gy)) return 4;  // SE
  if ((dca_g1_gx > dca_g2_gx) && (dca_g1_gy > dca_g2_gy)) return 8;  // NW
  if ((dca_g1_gx < dca_g2_gx) && (dca_g1_gy > dca_g2_gy)) return 2;  // NE
  if ((dca_g1_gx > dca_g2_gx) && (dca_g1_gy < dca_g2_gy)) return 6;  // SW
  return 0;  // BAD
}
function dc_p_direction8_from_sel0(dca_gx, dca_gy) {
  return dc_p_direction8(global.dcg_sel0_gx, global.dcg_sel0_gy, dca_gx, dca_gy);
}
function dc_p_get_dx(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  var dir8 = dc_p_direction8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy);
  if      ((dir8 == 6) || (dir8 == 7) || (dir8 == 8)) return -1; // G2 is WEST (SW W NW) of G1
  else if ((dir8 == 2) || (dir8 == 3) || (dir8 == 4)) return  1; // G2 is EAST (NE E SE) of G1
  else                                                return  0;
}
function dc_p_get_dy(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  var dir8 = dc_p_direction8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy);
  if      ((dir8 == 1) || (dir8 == 2) || (dir8 == 8)) return -1; // G2 is NORTH (N NE NW) of G1
  else if ((dir8 == 4) || (dir8 == 5) || (dir8 == 6)) return  1; // G2 is SOUTH (SE S SW) of G1
  else                                                return  0;
}
function dc_p_distance8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  if (dc_p_direction8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) == 0) return -1;
  return max( abs(dca_g1_gx - dca_g2_gx), abs(dca_g1_gy - dca_g2_gy) );
}
function dc_p_same_line_012(dca_g0_gx, dca_g0_gy, dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  // Check if points 0, 1, 2 on same line in order 0->1->2
  if ((dca_g0_gx < 0) || (dca_g0_gy < 0) || (dca_g1_gx < 0) || (dca_g1_gy < 0) || (dca_g2_gx < 0) || (dca_g2_gy < 0)) return false;
  var dir01 = dc_p_direction8(dca_g0_gx, dca_g0_gy, dca_g1_gx, dca_g1_gy);
  var dir12 = dc_p_direction8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy);
  if ((dir01 > 0) && (dir01 == dir12)) return true;
  return false;
}
function dc_p_same_line_021(dca_g0_gx, dca_g0_gy, dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  // Check if points 0, 1, 2 on same line but now in order 0->2->1
  return dc_p_same_line_012(dca_g0_gx, dca_g0_gy, dca_g2_gx, dca_g2_gy, dca_g1_gx, dca_g1_gy);
}

function dc_p_find_sel2(dca_mouse_gx, dca_mouse_gy, dca_lim_obj_mask, dca_max_distance) {
  global.dcg_sel2_gx = -1;
  global.dcg_sel2_gy = -1;
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return false;  // Bail if no sel0
  if (!dc_p_same_line_as_sel0(dca_mouse_gx, dca_mouse_gy)) return false;  // Mouse not on same row/col/diag as sel0
  if (dca_max_distance == 0) return false;
  // Start at global.dcg_sel0
  // Apply delta_gx delta_gy until find obstacle/mouse or find edge grid
  // Set sel2 (may end up SAME as sel0)
  var steps = 0;
  var delta_gx = dc_p_find_delta(global.dcg_sel0_gx, dca_mouse_gx);
  var delta_gy = dc_p_find_delta(global.dcg_sel0_gy, dca_mouse_gy);
  var tmp_gx = global.dcg_sel0_gx;
  var tmp_gy = global.dcg_sel0_gy;
  var back_one_step = true;
  // show_debug_message("Sel0=[{0},{1}] Delta=[{2},{3}]", global.dcg_sel0_gx, global.dcg_sel0_gy, delta_gx, delta_gy);
  while (true) {
    steps++;
    tmp_gx += delta_gx;
    tmp_gy += delta_gy;
    if ((tmp_gx < 0) || (tmp_gx >= global.dcg_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dcg_grid_y_cells)) {
      // show_debug_message("[{0},{1}] Too far!", tmp_gx, tmp_gy);
      break;  // Gone too far so will go back one step

    } else {
      if ((global.dcg_object_grid[tmp_gx, tmp_gy] & dca_lim_obj_mask) != 0) {
        // If we've got on to a cell containing an invalid object stop and go back one step
        // show_debug_message("[{0},{1}] Obstacle object {2}", tmp_gx, tmp_gy, (global.dcg_object_grid[tmp_gy, tmp_gy] & dca_lim_obj_mask),
        break;
      } else if ( ((((dca_lim_obj_mask >> DC_OBJECT_MOUSE) & 1) == 1) && (tmp_gx == dca_mouse_gx) && (tmp_gy == dca_mouse_gy)) ||
                  (steps == dca_max_distance) ) {
        // show_debug_message("[{0},{1}] Got to MOUSE/MAX!", tmp_gx, tmp_gy);
        back_one_step = false;  // Got to mouse pos or max distance so NO need to go back one step
        break;
      }
    }
  }
  if (back_one_step) {
    tmp_gx -= delta_gx;
    tmp_gy -= delta_gy;
  }
  global.dcg_sel2_gx = tmp_gx;
  global.dcg_sel2_gy = tmp_gy;
  // show_debug_message("Sel2=[{0},{1}]", global.dcg_sel2_gx, global.dcg_sel2_gy);
}




//
// STATE MACHINE AND STATE UTILITY FUNCTIONS
//
// EXTERNAL
//
function dc_game_start() {
  dc_p_fsm_game_start(DC_EVENT_ENTER_STATE);
}
function dc_room_start() {
  dc_p_fsm_room_start(DC_EVENT_ENTER_STATE);
}

// INTERNAL
//
function dc_p_fsm_debug(dca_event) {
  show_debug_message("DEBUG: State={0} Event={1}", global.dcg_state, dca_event);
}
function dc_p_fsm_state_invalid(dca_event) {
  dc_p_fsm_debug(dca_event);
}
function dc_p_fsm(dca_event) {
  dc_p_fsm_debug(dca_event);
  switch (global.dcg_state) {
    case DC_STATE_GAME_START:            dc_p_fsm_game_start(dca_event); return;
    case DC_STATE_ROOM_START:            dc_p_fsm_room_start(dca_event); return;
    case DC_STATE_TURN_START:            dc_p_fsm_turn_start(dca_event); return;
    case DC_STATE_USER_SELECT:           dc_p_fsm_user_select(dca_event); return;
    case DC_STATE_USER_ANIMATE:          dc_p_fsm_user_animate(dca_event); return;
    case DC_STATE_USER_ANIMATE_HIT:      dc_p_fsm_user_animate_hit(dca_event); return;
    case DC_STATE_ENEMY_ANIMATE:         dc_p_fsm_enemy_animate(dca_event); return;
    case DC_STATE_ENEMY_ANIMATE_ATTACK:  dc_p_fsm_enemy_animate_attack(dca_event); return;
    case DC_STATE_USER_ANIMATE_DYING:    dc_p_fsm_user_animate_dying(dca_event); return;
    case DC_STATE_TURN_END:              dc_p_fsm_turn_end(dca_event); return;
    case DC_STATE_ROOM_END:              dc_p_fsm_room_end(dca_event); return;
    case DC_STATE_GAME_END:              dc_p_fsm_game_end(dca_event); return;
    default:                             dc_p_fsm_state_invalid(dca_event); return;
  }
}
function dc_p_fsm_set_state(dc_new_state) {
  if (global.dcg_state == dc_new_state) return;
  global.dcg_state = dc_new_state;
  dc_p_fsm(DC_EVENT_ENTER_STATE);
}


function dc_p_fsm_game_start(dca_event) {
  // Setup overall game state
  if (dca_event == DC_EVENT_ENTER_STATE) {

    dc_p_initialise_game_globals();

    room_goto_next();
  }
}
function dc_p_fsm_room_start(dca_event) {
    if (dca_event == DC_EVENT_ENTER_STATE) {
	
	show_debug_message("DEBUG: Initialising globals for room {0}", room_get_name(room));
	dc_p_initialise_room_globals();
	
	show_debug_message("DEBUG: Initialising room {0}", room_get_name(room));
	dc_p_initialise_room();
	
	dc_p_button_room_start_begin();
    }
    dc_p_fsm_set_state(DC_STATE_TURN_START);
}
function dc_p_fsm_turn_start(dca_event) {
    if (dca_event == DC_EVENT_ENTER_STATE) {
	
	global.dcg_turn++;
	global.dcg_field_used[global.dcg_turn % 2] = false;
	global.dcg_human_used[global.dcg_turn % 2] = false;
	
	dc_p_button_turn_start_begin();
	
	if (false) {
	    var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
	    if (drone != noone) {
		global.dcg_object_sel_base = DC_OBJECT_DRONE;
		global.dcg_object_move = DC_OBJECT_DRONE;
		global.dcg_object_action = DC_ACTION_DRONE_MOVE;
		var lim_obj_mask = global.dcg_limit_obj_mask[DC_ACTION_DRONE_MOVE];	
		var max_distance = global.dcg_max_distance[DC_ACTION_DRONE_MOVE];
   		dc_p_set_available_tiles(drone.dci_now_gx, drone.dci_now_gy, lim_obj_mask, max_distance, true);				     
	    }
	}
	
	dc_p_fsm_set_state(DC_STATE_USER_SELECT);	    
    }
}
function dc_p_fsm_user_select(dca_event) {
    if (dca_event == DC_EVENT_ENTER_STATE) {
	dc_p_make_object_grid();  // Track where everything is
	// dc_p_make_range_grids();  // TODO: REMOVE: HANDY FOR DEBUGGING THOUGH
	
	dc_p_button_user_select_begin();
    }
    if ((dca_event == DC_EVENT_ENTER_STATE) || (dca_event == DC_EVENT_OBJECT_SELECTED)) {
	
	var inst = dc_p_find_instance(global.dcg_object_sel_base, 0);
	if (inst != noone) {
	    show_debug_message("{0} at [{1},{2}]", dc_p_get_name(global.dcg_object_sel_base), inst.dci_now_gx, inst.dci_now_gy);
	    global.dcg_sel0_gx = inst.dci_now_gx;
	    global.dcg_sel0_gy = inst.dci_now_gy;
	}
    }
    if (dca_event == DC_EVENT_DEST_SELECTED) {
	global.dcg_object_animate = global.dcg_object_move;
	
	// Look along animating object's path and markup any enemies as HIT
	global.dcg_enemies_dying = dc_p_fsm_maybe_hit_enemies();
	global.dcg_enemies_alive -= global.dcg_enemies_dying;
	
	dc_p_fsm_set_state(DC_STATE_USER_ANIMATE);
    }
}
function dc_p_fsm_user_animate(dca_event) {
    if (dca_event == DC_EVENT_ENTER_STATE) {
	dc_p_button_display(0, 0);  // All buttons greyed
	dc_p_clear_available_tiles(); // Clear tile availability

	if (global.dcg_object_animate == DC_OBJECT_NONE) {
	    dca_event = DC_EVENT_ANIMATE_ENDED;
	}
    }
    // Only a single object animating here
    if (dca_event == DC_EVENT_ANIMATE_ENDED) {
	global.dcg_object_animate = DC_OBJECT_NONE;

	// User animation ended - maybe need to animate enemies dying
	dc_p_fsm_set_state(DC_STATE_USER_ANIMATE_HIT);
    }
}
function dc_p_fsm_user_animate_hit(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
  }
  if (dca_event == DC_EVENT_ANIMATE_ENDED) {
    global.dcg_enemies_dying--;
    global.dcg_enemies_dead++;

  }
  if ((dca_event == DC_EVENT_ENTER_STATE) || (dca_event == DC_EVENT_ANIMATE_ENDED)) {

    // If no one still dying can move on
    if (global.dcg_enemies_dying == 0) {

      // Turn complete? If not return to selecting state. If so then enemy animate
      // (NB Turn might end prematurely if no enemies left alive)
      var turn_not_over = dc_p_button_user_animations_complete();
      if (global.dcg_enemies_alive == 0) {
        dc_p_fsm_set_state(DC_STATE_ENEMY_ANIMATE);
      } else if (turn_not_over) {
        dc_p_fsm_set_state(DC_STATE_USER_SELECT);
      } else {
        dc_p_fsm_set_state(DC_STATE_ENEMY_ANIMATE);
      }
    }
  }
}
function dc_p_fsm_enemy_animate(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
    dc_p_make_object_grid();  // Track where everything is
    dc_p_make_range_grids();

    // (Just in case) if *before moving* there's an enemy alive, alongside a human, then human dies
    if (dc_p_fsm_enemy_alongside_human()) global.dcg_human_alive = false;
    global.dcg_objects_animating = dc_p_fsm_enemies_reposition();

    if (global.dcg_objects_animating > 0) {
      // Some enemies to animate
      global.dcg_object_animate = DC_OBJECT_ENEMY1;
    } else {
      // No enemies to animate - animate attacks
      dc_p_fsm_set_state(DC_STATE_ENEMY_ANIMATE_ATTACK);
    }
  }
  if (dca_event == DC_EVENT_ANIMATE_ENDED) {
    global.dcg_objects_animating--;

    // If *after moving* there's an enemy alive, alongside a human, then human dies
    if (dc_p_fsm_enemy_alongside_human()) global.dcg_human_alive = false;

    // show_debug_message("NUM ENEMIES STILL ANIMATING = {0}", global.dcg_objects_animating);
    if (global.dcg_objects_animating == 0) {
      // Enemies finished moving - animate attacks
      dc_p_fsm_set_state(DC_STATE_ENEMY_ANIMATE_ATTACK);
    }
  }
}
function dc_p_fsm_enemy_animate_attack(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {

    global.dcg_objects_animating = dc_p_fsm_enemies_attack();
    if (global.dcg_objects_animating == 0) {
      // No enemy attacks to animate - enemy turn is over
      dc_p_fsm_set_state(DC_STATE_USER_ANIMATE_DYING);
    }
  }
  if (dca_event == DC_EVENT_ANIMATE_ENDED) {
    global.dcg_objects_animating--;
    if (global.dcg_objects_animating == 0) {
      // Enemy attacks finished attack animations - enemy turn is over
      dc_p_fsm_set_state(DC_STATE_USER_ANIMATE_DYING);
    }
  }
}
function dc_p_fsm_user_animate_dying(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {

    if (global.dcg_human_alive) {
      global.dcg_object_animate = DC_OBJECT_NONE;
      // Human still alive - so turn is over
      dc_p_fsm_set_state(DC_STATE_TURN_END);
    } else {
      global.dcg_object_animate = DC_OBJECT_HUMAN;	
    }
  }
  if (dca_event == DC_EVENT_ANIMATE_ENDED) {
      global.dcg_object_animate = DC_OBJECT_NONE;
      // User death animation finished - turn is over
      dc_p_fsm_set_state(DC_STATE_TURN_END);
  }
}
function dc_p_fsm_turn_end(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
    global.dcg_object_animate = DC_OBJECT_NONE;
    // Reset any field
    dc_p_fsm_reset_field();
    dc_p_button_turn_end_begin();
    if ((global.dcg_enemies_alive == 0) || (!global.dcg_human_alive)) {
      // This room over
      dc_p_fsm_set_state(DC_STATE_ROOM_END);
    } else {
      // Loop back to start
      dc_p_fsm_set_state(DC_STATE_TURN_START);
    }
  }
}
function dc_p_fsm_room_end(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
    var px = (2 * global.dcg_grid_cell_width) + global.dcg_grid_min_px;  // At (2,4)
    var py = (4 * global.dcg_grid_cell_height) + global.dcg_grid_min_py;
    var banner = instance_create_layer(px, py,  "Instances_1", obj_banner);
    if (!global.dcg_human_alive) {
      banner.sprite_index = spr_bannerFail;
      // var human = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
      // if (human != noone) human.sprite_index = spr_clear	
    } else {
      banner.sprite_index = spr_bannerSuccess;
    }	  
    var tmp = call_later(5, time_source_units_seconds, dc_p_fsm_room_end2);
  }
}
function dc_p_fsm_room_end2() {
  instance_destroy(obj_banner);
  // Revert any pitch change in tracks
  audio_sound_pitch(loopDrone, 1);
  audio_sound_pitch(loopMissile, 1);
  audio_sound_pitch(loopMeleeEnemy, 1);
  audio_sound_pitch(loopProjectileEnemy, 1);
  // And set track_pos back to start
  audio_sound_set_track_position(loopDrone, 0);
  audio_sound_set_track_position(loopMissile, 0);
  audio_sound_set_track_position(loopMeleeEnemy, 0);
  audio_sound_set_track_position(loopProjectileEnemy, 0);

  if (!global.dcg_human_alive && !global.dcg_human_is_immortal) {
    room_restart();
  } else {
    room_goto_next();
  }
}
function dc_p_fsm_game_end(dca_event) {
  // TODO: is this needed?
  if (dca_event == DC_EVENT_ENTER_STATE) {
  }
}


// See if human has an enemy adjacent
function dc_p_fsm_enemy_alongside_human() {
  var human = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
  if (human == noone) return false;
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      if ((dx == 0) && (dy == 0)) continue;
      // For all 8 directions
      var tgx = human.dci_now_gx + dx;
      var tgy = human.dci_now_gy + dy;
      if ( (tgx >= 0) && (tgx < global.dcg_grid_x_cells) &&
           (tgy >= 0) && (tgy < global.dcg_grid_y_cells) ) {
        var pinst = global.dcg_inst_grid[tgx, tgy];
        if ((pinst != noone) && (pinst.dci_obj_state == DC_OBJSTATE_ALIVE) &&
            ((pinst.dci_obj_type == DC_OBJECT_ENEMY1) || (pinst.dci_obj_type == DC_OBJECT_ENEMY2))) {
          return true;
        }
      }
    }
  }
  return false;
}
// Fixup enemies nxt_gx/gy
function dc_p_fsm_maybe_hit_enemies() {
    // Only MISSILE and LASER cause enemy hits - these days also may kill human
    if ((global.dcg_object_animate != DC_OBJECT_MISSILE) && (global.dcg_object_animate != DC_OBJECT_LASER)) return 0;
    
    var dx = dc_p_get_dx(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy);
    var dy = dc_p_get_dy(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy);
    if ((dx == 0) && (dy == 0)) return 0;
    
    // show_debug_message("HIT [{0},{1}]-->[{2},{3}]  DXY=[{4},{5}]",
    //                    global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, dx, dy);
    // Go along now/nxt line of animating object looking for enemies or human - mark them as dying
    var n_hit = 0;
    var tmp_gx = global.dcg_sel0_gx;
    var tmp_gy = global.dcg_sel0_gy;
    while (true) {
	if ((tmp_gx < 0) || (tmp_gx >= global.dcg_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dcg_grid_y_cells))
	    break;
	var pinst = global.dcg_inst_grid[tmp_gx, tmp_gy];
	if (pinst != noone) {
	    var enemy = ( (pinst.dci_obj_type == DC_OBJECT_ENEMY1) || (pinst.dci_obj_type == DC_OBJECT_ENEMY2));
	    var human = (pinst.dci_obj_type == DC_OBJECT_HUMAN);
	    if ((pinst.dci_obj_state == DC_OBJSTATE_ALIVE) && enemy) {
		pinst.dci_obj_state = DC_OBJSTATE_DYING;
		n_hit++;
	    } else if ((pinst.dci_obj_state == DC_OBJSTATE_ALIVE) && human) {
		// Markup human as dead - but does *not* count as a hit
		if (pinst.dci_obj_type == DC_OBJECT_HUMAN) {
		    human.sprite_index = spr_human11dying;
		    global.dcg_human_alive = false;
		}
	    }
	}
	if ((tmp_gx == global.dcg_sel1_gx) && (tmp_gy == global.dcg_sel1_gy)) break;
	tmp_gx += dx;
	tmp_gy += dy;
    }
    return n_hit;  // Count of enemies that will need HIT animation
}
// Fixup enemies nxt_gx/gy
function dc_p_fsm_enemies_reposition() {
  var prev_abs_smallest_range = global.dcg_abs_smallest_range;
  var n_to_animate = 0;
  // Do ENEMY2 first - they're nastier!
  for (var etyp = DC_OBJECT_ENEMY2; etyp >= DC_OBJECT_ENEMY1; etyp--) {
    var i = 0;
    while (true) {
      var monst = dc_p_find_instance(etyp, i);
      if (monst == noone) break;
      if (monst.dci_obj_state == DC_OBJSTATE_ALIVE) {
        if (dc_p_update_enemy_nxt(monst)) n_to_animate++;
      }
      i++;
    }
  }

  var curr_abs_smallest_range = global.dcg_abs_smallest_range;
  var tooClose = 2;
  var pitch_mult = global.dcg_pitch_mult;  
    if ((prev_abs_smallest_range > tooClose) && (curr_abs_smallest_range <= tooClose) && (pitch_mult <= 1.0)) {
      // Increase pitch by a semitone
      pitch_mult *= global.dcg_pitch_var;
    } else if ((prev_abs_smallest_range <= tooClose) && (curr_abs_smallest_range > tooClose) && (pitch_mult > 1.0)) {
      // Decrease pitch by a semitone
      pitch_mult /= global.dcg_pitch_var;
  }
  if (global.dcg_pitch_mult != pitch_mult) {
      global.dcg_pitch_mult = pitch_mult;
      audio_sound_pitch(loopDrone, global.dcg_pitch_mult);
      audio_sound_pitch(loopMissile, global.dcg_pitch_mult);
      audio_sound_pitch(loopMeleeEnemy, global.dcg_pitch_mult);
      audio_sound_pitch(loopProjectileEnemy, global.dcg_pitch_mult);
  }
  return n_to_animate;  // Count of enemies that will animate
}
function dc_p_fsm_enemies_attack() {
    var n_to_animate = 0;
    var i = 0;
    while (true) {
	var monst = dc_p_find_instance(DC_OBJECT_ENEMY2, i);  // Only ENEMY2
	if (monst == noone) break;
	if (monst.dci_obj_state == DC_OBJSTATE_ALIVE) {
	    if (dc_p_proj_enemy_fires_bullet(monst)) n_to_animate++;
	}
	i++;
    }
    var j = 0;
    while (true) {
	var monst = dc_p_find_instance(DC_OBJECT_ENEMY1, j);  // Only ENEMY1
	if (monst == noone) break;
	if (monst.dci_obj_state == DC_OBJSTATE_ALIVE) {
	    if (dc_p_melee_enemy_attacks(monst)) n_to_animate++;
	}
	j++;
    }
    return n_to_animate;  // Count of enemies that will animate
}
// Called at end of enemy turn to reset any active field
function dc_p_fsm_reset_field() {
  var field = dc_p_find_instance(DC_OBJECT_FIELD, 0);
  if ((field == noone) || (field.sprite_index == spr_clear)) return;
  field.sprite_index = spr_clear;
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  if (drone == noone) return;
  field.dci_now_gx = drone.dci_now_gx; field.dci_now_gy = drone.dci_now_gy;
  field.x = drone.x; field.y = drone.y;
}



//
// BUTTON MANAGEMENT and BUTTON UTILITY FUNCTIONS
//
function dc_p_drone_alongside_human() {
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  var human = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
  if ((drone == noone) || (human == noone)) return false;
  return (dc_p_distance8(drone.dci_now_gx, drone.dci_now_gy, human.dci_now_gx, human.dci_now_gy) == 1);
}
function dc_p_button_debug() {
  var drone = (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_MOVE) & 1) == 1) ?"DRONE" :" ";
  var laser = (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_LASER) & 1) == 1) ?"LASER" :" ";
  var missile = (((global.dcg_button_avail_mask >> DC_ACTION_MISSILE_MOVE) & 1) == 1) ?"MISSILE" :" ";
  var field = (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_FIELD) & 1) == 1) ?"FIELD" :" ";
  var human = (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_HUMAN) & 1) == 1) ?"HUMAN" :" ";
  // show_debug_message("BUTTONS = {0} {1} {2} {3} {4}", drone, laser, missile, field, human);
}
function dc_p_button_available() {
  dc_p_button_debug();
  // If only have human move left available but it cannot be used becuase human NOT alongside drone return false
  if ((global.dcg_button_avail_mask == DC_ACTION_DRONE_HUMAN) && !dc_p_drone_alongside_human()) return false;
  // Otherwise if no buttons available return false
  if (global.dcg_button_avail_mask == 0) return false;
  // Else we have some buttons still available so return true
  return true;
}

// Call this function to enable/disable buttons
function dc_p_button_display(dca_button_avail_mask, dca_object_action) {
  if (((dca_button_avail_mask >> DC_ACTION_DRONE_MOVE) & 1) == 1) {
  }
  if (((dca_button_avail_mask >> DC_ACTION_DRONE_LASER) & 1) == 1) {
    obj_buttonlaser.sprite_index = (dca_object_action == DC_ACTION_DRONE_LASER) ?spr_buttonlaserOn :spr_buttonlaserOff;
  } else {
    obj_buttonlaser.sprite_index = spr_buttonlaserUnav;
  }
  if (((dca_button_avail_mask >> DC_ACTION_MISSILE_MOVE) & 1) == 1) {
    obj_buttonmissile.sprite_index = (dca_object_action == DC_ACTION_MISSILE_MOVE) ?spr_buttonmissileOn :spr_buttonmissileOff;
  } else {
    obj_buttonmissile.sprite_index = spr_buttonmissileUnav;
  }
  if (((dca_button_avail_mask >> DC_ACTION_DRONE_FIELD) & 1) == 1) {
    obj_buttonfield.sprite_index = (dca_object_action == DC_ACTION_DRONE_FIELD) ?spr_buttonfieldOn :spr_buttonfieldOff;
  } else {
    obj_buttonfield.sprite_index = spr_buttonfieldUnav;
  }
  if ((((dca_button_avail_mask >> DC_ACTION_DRONE_HUMAN) & 1) == 1) && dc_p_drone_alongside_human()) {
    obj_buttondisplace.sprite_index = (dca_object_action == DC_ACTION_DRONE_HUMAN) ?spr_buttondisplaceOn :spr_buttondisplaceOff;
  } else {
    obj_buttondisplace.sprite_index = spr_buttondisplaceUnav;
  }
}
function dc_p_button_control() {
  dc_p_button_display(global.dcg_button_avail_mask, global.dcg_object_action);
  dc_p_button_debug();
}

// Remainder of these funcs manipulate dcg_button_avail_mask
function dc_p_button_one(dca_oatyp, dca_onoff) {
  if (dca_onoff) {
    global.dcg_button_avail_mask |= (1<<dca_oatyp);
  } else {
    global.dcg_button_avail_mask &= ~(1<<dca_oatyp);
  }
}
function dc_p_button_some(dca_drone_onoff, dca_laser_onoff, dca_field_onoff, dca_human_onoff, dca_missile_onoff) {
  dc_p_button_one(DC_ACTION_DRONE_MOVE, dca_drone_onoff);
  dc_p_button_one(DC_ACTION_DRONE_LASER, dca_laser_onoff);
  dc_p_button_one(DC_ACTION_DRONE_FIELD, dca_field_onoff);
  dc_p_button_one(DC_ACTION_DRONE_HUMAN, dca_human_onoff);
  dc_p_button_one(DC_ACTION_MISSILE_MOVE, dca_missile_onoff);
  dc_p_button_control();
}
function dc_p_button_double_dash() {
  // dc_p_button_one(DC_ACTION_DRONE_MOVE, ??);  // Leave drone move as was
  dc_p_button_one(DC_ACTION_DRONE_LASER, false);
  dc_p_button_one(DC_ACTION_DRONE_FIELD, false);
  dc_p_button_one(DC_ACTION_DRONE_HUMAN, false);
  dc_p_button_one(DC_ACTION_MISSILE_MOVE, true);
  dc_p_button_control();
}
function dc_p_button_room_start_begin() {
  global.dcg_object_sel_base = DC_OBJECT_DRONE;
  global.dcg_object_move = DC_OBJECT_DRONE;
  global.dcg_object_action = DC_ACTION_DRONE_MOVE;
  // All buttons available (though human button only lights up if adjacent to drone)
  dc_p_button_some(true, true, true, true, true);
}
function dc_p_button_turn_start_begin() {
  // Most buttons avail (human not if non-drone-adjacent OR used last turn) (field not if used last turn)
  var drone_ok = true;
  var laser_ok = true;
  var field_ok = !global.dcg_field_used[(global.dcg_turn-1) % 2];
  var human_ok = !global.dcg_human_used[(global.dcg_turn-1) % 2];
  var missile_ok = true;
  dc_p_button_some(drone_ok, laser_ok, field_ok, human_ok, missile_ok);
}
function dc_p_button_user_select_begin() {
    // Buttons available remain unchanged
    //
    // object sel_base/move goes back to drone BUT object action only DRONE_MOVE if move still available
    // otherwise default becomes DRONE_LASER
    //
    var double_dash = (1 << DC_ACTION_MISSILE_MOVE) | (1 << DC_ACTION_DRONE_MOVE);
    global.dcg_object_move = DC_OBJECT_NONE;
    if (global.dcg_button_avail_mask == double_dash) {
	global.dcg_object_sel_base = DC_OBJECT_MISSILE;
	global.dcg_object_move = DC_OBJECT_MISSILE;
	global.dcg_object_action = DC_ACTION_MISSILE_MOVE;
    } else if (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_MOVE) & 1) == 1) {
	global.dcg_object_sel_base = DC_OBJECT_DRONE;
	global.dcg_object_move = DC_OBJECT_DRONE;
	global.dcg_object_action = DC_ACTION_DRONE_MOVE;
    } else if (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_LASER) & 1) == 1) {
	global.dcg_object_sel_base = DC_OBJECT_DRONE;
	global.dcg_object_move = DC_OBJECT_LASER;
	global.dcg_object_action = DC_ACTION_DRONE_LASER;
    } else if (((global.dcg_button_avail_mask >> DC_ACTION_MISSILE_MOVE) & 1) == 1) {
	global.dcg_object_sel_base = DC_OBJECT_MISSILE;
	global.dcg_object_move = DC_OBJECT_MISSILE;
	global.dcg_object_action = DC_ACTION_MISSILE_MOVE;
    }

    // Light up correct available tiles
    var obj = dc_p_find_instance(global.dcg_object_sel_base, 0);
    if (obj != noone) {
	var obj_act = global.dcg_object_action;
	var lim_obj_mask = global.dcg_limit_obj_mask[obj_act];	
	var max_distance = global.dcg_max_distance[obj_act];	
   	dc_p_set_available_tiles(obj.dci_now_gx, obj.dci_now_gy, lim_obj_mask, max_distance, true);
	var attacking = ((obj_act == DC_ACTION_DRONE_LASER) || (obj_act == DC_ACTION_MISSILE_MOVE));
	var spr_redblue = attacking ?spr_cornerRed :spr_cornerBlue;
	corner = global.dcg_corner_grid[obj.dci_now_gx, obj.dci_now_gy];
	if (corner != noone) corner.sprite_index = spr_redblue;
    }
    // Invalidate sel1
    global.dcg_sel1_gx = -1;
    global.dcg_sel1_gy = -1;
    dc_p_button_control();
}
function dc_p_button_user_animations_complete() {
  var moves = (1<<DC_ACTION_DRONE_MOVE);
  var actions = (1<<DC_ACTION_MISSILE_MOVE) | (1<<DC_ACTION_DRONE_LASER) |
      (1<<DC_ACTION_DRONE_FIELD) | (1<<DC_ACTION_DRONE_HUMAN);

  // Clear flag corresponding to button used - use of move uses up ALL moves - use of action uses up ALL actions
  switch (global.dcg_object_action) {
    case DC_ACTION_DRONE_MOVE:
      global.dcg_button_avail_mask &= ~moves;
      break;
    case DC_ACTION_MISSILE_MOVE:
    case DC_ACTION_DRONE_LASER:
      global.dcg_button_avail_mask &= ~actions;
      break;
    case DC_ACTION_DRONE_FIELD:
      global.dcg_field_used[global.dcg_turn % 2] = true;
      global.dcg_button_avail_mask &= ~actions;
      break;
    case DC_ACTION_DRONE_HUMAN:
      global.dcg_human_used[global.dcg_turn % 2] = true;
      global.dcg_button_avail_mask &= ~actions;
      break;
  }
  dc_p_button_control();

  // Return if turn NOT over - are moves still available?
  return dc_p_button_available();
}
function dc_p_button_turn_end_begin() {
}



//
// STEP FUNCTIONS and STEP UTILITY FUNCTIONS
//
function dc_p_clear_via(dca_inst) {
  for (var i = 0; i < 3; i++) {
    dca_inst.dci_via_gx[i] = -1;
    dca_inst.dci_via_gy[i] = -1;
  }
}
function dc_p_go_via(dca_inst) {
  var i = 0;
  while (true) {
    if ((dca_inst.dci_via_gx[i] == -1) && (dca_inst.dci_via_gy[i] == -1)) {
      return false;
    } else if ((dca_inst.dci_via_gx[i] == dca_inst.dci_now_gx) && (dca_inst.dci_via_gy[i] == dca_inst.dci_now_gy) &&
               (dca_inst.dci_via_gx[i+1] != -1) && (dca_inst.dci_via_gy[i+1] != -1)) {
      dca_inst.dci_nxt_gx = dca_inst.dci_via_gx[i+1];
      dca_inst.dci_nxt_gy = dca_inst.dci_via_gy[i+1];
      return true;
    } else {
      i++;
      if (i > 2) return false;  // Just in case!
    }
  }
}



function dc_p_find_enemy_best_path(dca_monst, dca_array_a, dca_array_b, dca_ctrl) {
  var gx = dca_monst.dci_now_gx;
  var gy = dca_monst.dci_now_gy;
  var original_range = dca_array_a[@ gx, gy] % 9000000;
  var smallest_range = original_range;
  var smallest_range_gx = -1;
  var smallest_range_gy = -1;
  // Search for path in order W E N S NW NE SW SE
  var dxtab = [ -1,  1,  0,  0, -1,  1, -1,  1 ];
  var dytab = [  0,  0, -1,  1, -1, -1,  1,  1 ];
  // If monster is on a cell with range 0 (eg a FIELDed cell) then it is 'frozen' and can not move!
  if (original_range == 0) return false;
  for (var i = 0; i < 8; i++) {
    var dx = dxtab[i];
    var dy = dytab[i];
    if ((dx == 0) && (dy == 0)) continue;  // Just in case
    // For all 8 neighbours
    if ( ((gx + dx) >= 0) && ((gx + dx) < global.dcg_grid_x_cells) &&
         ((gy + dy) >= 0) && ((gy + dy) < global.dcg_grid_y_cells) ) {
      var range = dca_array_a[@ gx + dx, gy + dy];
      // Don't move onto human cell or one containing another enemy
      if ((range == 0) || (range >= 9000000)) continue;
      if (range < smallest_range) {
        smallest_range_gx = gx + dx;
        smallest_range_gy = gy + dy;
        smallest_range = range;
      } else if (range == smallest_range) {
        if (dca_ctrl == DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH) return false;
        if (dca_ctrl == DC_CTRL_USE_FIRST_BEST_PATH) continue;
        smallest_range_gx = gx + dx;
        smallest_range_gy = gy + dy;
      }
    }
  }
  if (smallest_range == original_range) return false;
  if (smallest_range < global.dcg_abs_smallest_range) global.dcg_abs_smallest_range = smallest_range;
  // Restore original range in old gx/gy as now a valid location for a monster move
  dca_array_a[@ gx, gy] -= 9000000;
  dca_array_b[@ gx, gy] -= 9000000;
  dca_monst.dci_nxt_gx = smallest_range_gx;
  dca_monst.dci_nxt_gy = smallest_range_gy;
  // Put large range value into new gx/gy to invalidate location
  dca_array_a[@ dca_monst.dci_nxt_gx, dca_monst.dci_nxt_gy] += 9000000;
  dca_array_b[@ dca_monst.dci_nxt_gx, dca_monst.dci_nxt_gy] += 9000000;
  return true;
}
function dc_p_update_enemy_nxt(dca_monst) {
  // This function returns true if the passed-in enemy needs to be animated
  if ((dca_monst == noone) || (dca_monst.dci_obj_state != DC_OBJSTATE_ALIVE)) return false;

  var ok2 = false;
  if (dca_monst.dci_obj_type == DC_OBJECT_ENEMY2) {
    // Here we're using the DC_OBJECT_ENEMY2 grid
    // We get back ok=false if NO best path or if NO *SINGLE* best path
    // in which case we fall through to the DC_OBJECT_ENEMY1 logic below
    ok2 = dc_p_find_enemy_best_path(dca_monst, global.dcg_range_grid2, global.dcg_range_grid1,
                                    DC_CTRL_USE_FIRST_BEST_PATH);
  }
  if (!ok2) {
    // Here we're using the DC_OBJECT_ENEMY1 grid
    // Pass in ctrl = 0 (DC_CTRL_NONE) for even monsters, 1 (DC_CTRL_USE_FIRST_BEST_PATH) for odd
    // (pick 0/1 using (dca_monst.dci_which % 2)
    // This mean a given monster will, when there are multiple best paths, deterministically
    // select the first one found or the last one found.
    // (NB. ***** This causes 'weird' paths - so just always use first best path *****)
    var ok1 = dc_p_find_enemy_best_path(dca_monst, global.dcg_range_grid1, global.dcg_range_grid2,
                                        DC_CTRL_USE_FIRST_BEST_PATH);
  }
  with (dca_monst) {
    return ((dci_now_gx != dci_nxt_gx) || (dci_now_gy != dci_nxt_gy));
  }
}
function dc_p_melee_enemy_attacks(dca_monst) {
    // This function returns true if the melee enemy is alongside human and attacks
    if ((dca_monst == noone) || (dca_monst.dci_obj_state != DC_OBJSTATE_ALIVE)) return false;
    // Only melee enemies(1) attack here
    if (dca_monst.dci_obj_type != DC_OBJECT_ENEMY1) return false;
    var H = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
    var F = dc_p_find_instance(DC_OBJECT_FIELD, 0);
    if ((H == noone) || (F == noone)) return false;
    if ((H.dci_now_gx == F.dci_now_gx) && (H.dci_now_gy == F.dci_now_gy)) return false;
    for (var dx = -1; dx <= 1; dx++) {
	for (var dy = -1; dy <= 1; dy++) {
	    if ((dx == 0) && (dy == 0)) continue;
	    // For all 8 directions
	    var tgx = dca_monst.dci_now_gx + dx;
	    var tgy = dca_monst.dci_now_gy + dy;
	    if ( (tgx == H.dci_now_gx) && (tgy == H.dci_now_gy) ) {
		// Setup melee enemy attacking animation
		dca_monst.sprite_index = spr_enemymeleeattacking;
		audio_play_sound(meleeEnemyAttacking, 10, false);
		global.dcg_human_alive = false;
		H.sprite_index = spr_human11dying;		
		return true;
	    }
        }
    }
    return false;
}
function dc_p_proj_enemy_fires_bullet(dca_monst) {
    // This function returns true if the enemy fires and 'bullets' need to be animated
    if ((dca_monst == noone) || (dca_monst.dci_obj_state != DC_OBJSTATE_ALIVE)) return false;
    // Only projectile enemies(2) fire bullets
    if (dca_monst.dci_obj_type != DC_OBJECT_ENEMY2) return false;
    // Quick check - range to human must be 1 for a firing solution
    var range = global.dcg_range_grid2[dca_monst.dci_now_gx, dca_monst.dci_now_gy] % 9000000;
    if (range != 1) return false;
    // Double check monster and human on same line
    var H = dc_p_find_instance(DC_OBJECT_HUMAN, 0);
    if (H == noone) return false;
    if (!dc_p_same_line(dca_monst.dci_now_gx, dca_monst.dci_now_gy, H.dci_now_gx, H.dci_now_gy)) return false;
    
    // We will be firing!
    var D = dc_p_find_instance(DC_OBJECT_DRONE, 0);
    var F = dc_p_find_instance(DC_OBJECT_FIELD, 0);
    var B = instance_create_layer(dca_monst.x, dca_monst.y, "Instances_1", obj_bullet);
    if ((D == noone) || (F == noone) || (B == noone)) return false;
    
    B.dci_obj_state = DC_OBJSTATE_ALIVE;
    B.dci_obj_type = DC_OBJECT_NONE;
    B.dci_which = 999;
    B.dci_now_gx = dc_p_get_object_gx(B.x);
    B.dci_now_gy = dc_p_get_object_gy(B.y);
    var D_is_obs = dc_p_same_line_012(B.dci_now_gx, B.dci_now_gy, D.dci_now_gx, D.dci_now_gy, H.dci_now_gx, H.dci_now_gy);
    var F_is_obs = dc_p_same_line_012(B.dci_now_gx, B.dci_now_gy, F.dci_now_gx, F.dci_now_gy, H.dci_now_gx, H.dci_now_gy);
    if (F_is_obs && D_is_obs) {
	// Both field F *and* drone D between monster M and human H. Bullets should stop at closer
	var D_dist = dc_p_distance8(B.dci_now_gx, B.dci_now_gy, D.dci_now_gx, D.dci_now_gy);
	var F_dist = dc_p_distance8(B.dci_now_gx, B.dci_now_gy, F.dci_now_gx, F.dci_now_gy);
	D_is_obs = (D_dist <= F_dist);
	F_is_obs = (F_dist <  D_dist);
    }
    if (D_is_obs) {
	// If drone D between monster M and human H then bullets stop at field/drone
	B.dci_nxt_gx = D.dci_now_gx;
	B.dci_nxt_gy = D.dci_now_gy;
    } else if (F_is_obs) {
	// If field F between monster M and human H then bullets stop at field/drone
	B.dci_nxt_gx = F.dci_now_gx;
	B.dci_nxt_gy = F.dci_now_gy;
    } else {
	// If field F and drone D NOT between monster M and human H then bullets stop at human
	// and also mark human as dead
	B.dci_nxt_gx = H.dci_now_gx;
	B.dci_nxt_gy = H.dci_now_gy;
	H.dci_obj_state = DC_OBJSTATE_DYING;
	global.dcg_human_alive = false;
	H.sprite_index = spr_human11dying;
    }
    // Setup projectile enemy firing animation
    dca_monst.sprite_index = spr_enemyprojectileattacking;
    audio_play_sound(projectileEnemyAttacking, 10, false);    
    
    return ((B.dci_now_gx != B.dci_nxt_gx) || (B.dci_now_gy != B.dci_nxt_gy));
}
function dc_p_set_speed_direction(dca_spd, dca_kill) {
    var original_speed = speed;
    speed = 0;
    if ((dci_now_gx < 0) || (dci_now_gy < 0) || (dci_nxt_gx < 0) || (dci_nxt_gy < 0)) return (original_speed > 0);
    if ((dci_now_gx == dci_nxt_gx) && (dci_now_gy == dci_nxt_gy)) return (original_speed > 0);
    
    var nxt_px = global.dcg_grid_min_px + (dci_nxt_gx * global.dcg_grid_cell_width);
    var nxt_py = global.dcg_grid_min_py + (dci_nxt_gy * global.dcg_grid_cell_height) - global.dcg_grid_cell_height_offset;
    var pdist = point_distance(x, y, nxt_px, nxt_py);
    if (pdist < global.dcg_grid_min_distance) {
	global.dcg_inst_grid[dci_now_gx, dci_now_gy] = noone;  // Remove from old pos
	global.dcg_object_grid[dci_now_gx, dci_now_gy] &= ~(1<<dci_obj_type);
	dci_now_gx = dci_nxt_gx;
	dci_now_gy = dci_nxt_gy;
	global.dcg_inst_grid[dci_now_gx, dci_now_gy] = self;  // Place at new pos
	global.dcg_object_grid[dci_now_gx, dci_now_gy] |= (1<<dci_obj_type);
	speed = 0;
	x = nxt_px;
	y = nxt_py;
    } else {
	var now_px = global.dcg_grid_min_px + (dci_now_gx * global.dcg_grid_cell_width);
	var now_py = global.dcg_grid_min_py + (dci_now_gy * global.dcg_grid_cell_height) - global.dcg_grid_cell_height_offset;
	var dist_halfway = point_distance(now_px, now_py, nxt_px, nxt_py) / 2;
	var dist_from_end = pdist;
	var dist_from_halfway = abs(dist_halfway - dist_from_end);
	if (dist_from_halfway > dist_halfway) dist_from_halfway = dist_halfway; // Dunno why this happens!
	// v^2 = u^2 + 2ax - use 2a = 3 - so speed is dca_spd at midpoint
	var pos_spd = dca_spd * sqrt( (dist_halfway - dist_from_halfway) / dist_halfway );  // Speed is dca_spd at midpoint
	dca_spd = max(1, pos_spd);  // Ensure we always have some speed
	speed = min(pdist, dca_spd);  // This stops the object oscillating at its endpoint
	direction = point_direction(x, y, nxt_px, nxt_py);
    }

    // if ((dci_obj_type == DC_OBJECT_ENEMY1) || (dci_obj_type == DC_OBJECT_ENEMY2)) {
    //   show_debug_message("END: Now=[{0},{1}] Nxt=[{2},{3}]  Dist={4} Speed={5} Inst={6}",
    //                      dci_now_gx, dci_now_gy, dci_nxt_gx, dci_nxt_gy, pdist, speed, dci_which);
    //   show_debug_message("END: Now=[{0},{1}] Nxt=[{2},{3}]  Dist={4} Speed={5} Inst={6}",
    //                      x, y, nxt_px, nxt_py, pdist, speed, dci_which);
    // }
    return (original_speed > 0) && (speed == 0);  // Return true if stopped on this call
}


function dc_step_drone() {
    if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
    if (global.dcg_object_animate != DC_OBJECT_DRONE) return;  // Must be animating DRONE
    if (speed == 0) audio_play_sound(DroneMove, 10, false);
    var stopped = dc_p_set_speed_direction(10, false);
    if (!stopped) return;
    // Fixup laser pseudo-object to be at same gx/gy x/y location as drone
    var laser = dc_p_find_instance(DC_OBJECT_LASER, 0);
    var missile = dc_p_find_instance(DC_OBJECT_MISSILE, 0);
    if ((laser == noone) || (missile == noone)) return;
    laser.dci_now_gx = dci_now_gx; laser.dci_now_gy = dci_now_gy;
    laser.x = x; laser.y = y;
    // Figure out whether we've 'docked' with missile
    if (global.dcg_missile_docked) {
	// Missile is docked in drone and drone has moved so mimic movement
	missile.dci_now_gx = dci_now_gx; missile.dci_now_gy = dci_now_gy;
	missile.x = x; missile.y = y;
    } else if ((missile.dci_now_gx == dci_now_gx) && (missile.dci_now_gy == dci_now_gy)) {
	// Missile becomes docked
	global.dcg_missile_docked = true;
	missile.sprite_index = spr_clear;  // Blank missile sprite
	audio_sound_gain(loopMissile, 0, 100);  // Gain 0 (in 100ms) - missile loop quiet
    }
    dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_missile() {
    if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
    if (global.dcg_object_animate != DC_OBJECT_MISSILE) return;  // Must be animating MISSILE
    var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
    if (drone == noone) return;
    var stops_docked = ((drone.dci_now_gx == dci_nxt_gx) && (drone.dci_now_gy == dci_nxt_gy));
    var starts_docked = global.dcg_missile_docked;
    if (speed == 0) {
	var dir8 = dc_p_direction8(dci_now_gx, dci_now_gy, dci_nxt_gx, dci_nxt_gy);
	switch (dir8) {
	case 1:                 sprite_index = spr_missileidleNorth; break;
	case 5:                 sprite_index = spr_missileidleSouth; break;
	case 2: case 3: case 4: sprite_index = spr_missileidleEast;  break;
	case 6: case 7: case 8: sprite_index = spr_missileidleWest;  break;
	default:                sprite_index = spr_missileidle1;     break;	 
	}
	audio_play_sound(MissileMove, 10, false);
    }
    var stopped = dc_p_set_speed_direction(15, true);
    if (!stopped) return;
    if (stops_docked) {
	// Missile stops at drone - so stops 'docked' into drone 
	global.dcg_missile_docked = true;
	audio_sound_gain(loopMissile, 0, 100);  // Gain 0 (in 100ms) - missile quiet
	sprite_index = spr_clear;  // Blank missile sprite to remember missile docked
    } else {
	// Missile stops elsewhere - not docked
	global.dcg_missile_docked = false;
	audio_sound_gain(loopMissile, 1, 100);  // Gain 1 (in 100ms) - missile noises again
	if (starts_docked) { // Did missile start off docked - if so we allow a 'double dash'
	    global.dcg_object_action = DC_ACTION_NONE;  // Clear action to allow missile 'double dash'
	    dc_p_button_double_dash();  // But disable other actions
	}
    }
    dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}

function dc_step_human_end() {
    if (global.dcg_object_animate != DC_OBJECT_HUMAN) return;  // Must be animating HUMAN
    if (global.dcg_state == DC_STATE_USER_ANIMATE_DYING) {
	dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
    }
}
function dc_step_human() {
    if (global.dcg_object_animate != DC_OBJECT_HUMAN) return;  // Must be animating HUMAN
    if (global.dcg_state == DC_STATE_USER_ANIMATE) {
	var stopped = dc_p_set_speed_direction(3, false);
	// Humans go via the drone gx/gy, in which case maybe they've not really stoppped
	if ((stopped) && (dc_p_go_via(self))) stopped = false;
	if (!stopped) return;
	dc_p_clear_via(self);
	dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
    } else if (global.dcg_state >= DC_STATE_USER_ANIMATE_DYING) {
	sprite_index = spr_human11dying;
	// var tmp = call_later(3, time_source_units_seconds, dc_step_human_end);  // 3 sec animation
    }
}

function dc_step_laser_end() {
  var laser = dc_p_find_instance(DC_OBJECT_LASER, 0);
  if (laser == noone) return;
  // Make laser invisible; also set laser x/y back to drone x/y
  laser.sprite_index = spr_clear;
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  if (drone == noone) return;
  laser.x = drone.x;
  laser.y = drone.y;
  dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_laser() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_LASER) return;  // Must be animating LASER
  if (speed == 0) audio_play_sound(Laser1, 10, false);

  // Clear animate object - we only do a single step here - animation ends on timeout
  global.dcg_object_animate = DC_OBJECT_NONE;

  // Find direction of fire and set correct sprite
  // We have to futz with LASER x/y to make it look like spr_laserXX starts at right pos
  //
  // Direction FROM now TO nxt - BAD=0 N=1 NE=2 E=3 SE=4 S=5 SW=6 W=7 NW=8
  // NB. Final false param tells dc_p_direction8 to not check that now/nxt on same diag
  var dir = dc_p_direction8(dci_now_gx, dci_now_gy, dci_nxt_gx, dci_nxt_gy, false);
  // show_debug_message("dc_step_laser  now=[{0},{1}] nxt=[{2},{3}] dir={4}",
  //                    dci_now_gx, dci_now_gy, dci_nxt_gx, dci_nxt_gy, dir);
  switch (dir) {
    case 4: sprite_index = spr_laserBSlash;                     x += 16; y += 16; break;
    case 8: sprite_index = spr_laserBSlash; x -= 384; y -= 384; x += 16; y += 16; break;
    case 2: sprite_index = spr_laserSlash;  y -= 384;           x += 16; y += 16; break;
    case 6: sprite_index = spr_laserSlash;  x -= 384;           x += 16; y += 16; break;
    case 1: sprite_index = spr_laserVertic; x -= 192; y -= 640; x += 16; y += 16; break;
    case 5: sprite_index = spr_laserVertic; x -= 192;           x += 16; y += 16; break;
    case 7: sprite_index = spr_laserHoriz;  x -= 384; y -= 320; x += 16; y += 24; break;
    case 3: sprite_index = spr_laserHoriz;            y -= 320; x += 16; y += 24; break;
    default: break;
  }
  var tmp = call_later(0.4167, time_source_units_seconds, dc_step_laser_end);  // 5/12 sec animation
}
function dc_step_field() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_FIELD) return;  // Must be animating FIELD
  var stopped = dc_p_set_speed_direction(10, false);
  if (!stopped) return;
  sprite_index = spr_fieldedtile;
  dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}

function dc_step_enemy_end() {
  if ((global.dcg_state == DC_STATE_USER_ANIMATE_HIT) && (dci_obj_state == DC_OBJSTATE_DYING)) {
    // Called on amimate end event
    dci_obj_state = DC_OBJSTATE_DEAD;
    if (sprite_index == spr_enemymeleedying) {
	sprite_index = spr_enemymeleedead;	
	global.dcg_enemies_n_melee--;
	if (global.dcg_enemies_n_melee == 0) audio_sound_gain(loopMeleeEnemy, 0, 100);  // 100ms

    } else if (sprite_index == spr_enemyprojectiledying) {
	sprite_index = spr_enemyprojectiledead;
	global.dcg_enemies_n_projectile--;
	if (global.dcg_enemies_n_projectile == 0) audio_sound_gain(loopProjectileEnemy, 0, 100);  // 100ms
    }
    dc_p_fsm(DC_EVENT_ANIMATE_ENDED);

  } else if (global.dcg_state >= DC_STATE_ENEMY_ANIMATE_ATTACK) {
    if (sprite_index == spr_enemymeleeattacking) {
      sprite_index = spr_enemymelee;
    }
    else if (sprite_index == spr_enemyprojectileattacking) {
      sprite_index = spr_enemyprojectileidle;
    }
    dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
  }
}
function dc_step_enemy() {
  if ((global.dcg_state == DC_STATE_USER_ANIMATE_HIT) && (dci_obj_state == DC_OBJSTATE_DYING)) {
    sprite_index = (dci_obj_type == DC_OBJECT_ENEMY1) ?spr_enemymeleedying :spr_enemyprojectiledying;

  } else if ((global.dcg_state == DC_STATE_ENEMY_ANIMATE) && (self.dci_obj_state == DC_OBJSTATE_ALIVE)) {
    // Moving enemy towards human
    var stopped = dc_p_set_speed_direction(1, false);
    if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
  }
}
function dc_step_bullet() {
  if (global.dcg_state != DC_STATE_ENEMY_ANIMATE_ATTACK) return;
  // Move enemy bullets towards human
  var stopped = dc_p_set_speed_direction(50, false);
  if (!stopped) return;
  sprite_index = spr_clear;
  instance_destroy();
  dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}



//
// EVENT HANDLERS and EVENT HANDLER UTILITY FUNCTIONS
//
function dc_p_set_available_tiles(dca_start_gx, dca_start_gy, dca_lim_obj_mask, dca_max_distance, dca_lighton) {
    // show_debug_message("dc_p_last: gx={0} gy={1} mask={2} dist={3} onoff={4)",
    //                     dca_start_gx, dca_start_gy, dca_lim_obj_mask, dca_max_distance, dca_lighton);
    if ((dca_start_gx < -1) || (dca_start_gy < -1)) return;
    global.dcg_last_start_gx = dca_start_gx;
    global.dcg_last_start_gy = dca_start_gy;
    global.dcg_last_lim_obj_mask = dca_lim_obj_mask;
    global.dcg_last_max_distance = dca_max_distance;
    
    // Switch all tiles radiating from start_gx/gy to indicate potential available moves
    for (var delta_gx = -1; delta_gx <= 1; delta_gx++) {
	for (var delta_gy = -1; delta_gy <= 1; delta_gy++) {
	    if ((delta_gx == 0) && (delta_gy == 0)) continue;
	    var dir8 = dc_p_direction8(99, 99, 99 + delta_gx, 99 + delta_gy); // Find direction (99 == arbitrary)
	    
	    // Apply delta_gx delta_gy to start_gx start_gy until find obstacle or find edge grid
	    var steps = 0;
	    var tmp_gx = dca_start_gx;
	    var tmp_gy = dca_start_gy;
	    // show_debug_message("Start=[{0},{1}] Delta=[{2},{3}]", dca_start_gx, dca_start_gy, delta_gx, delta_gy);
	    while (true) {
		steps++;
		tmp_gx += delta_gx;
		tmp_gy += delta_gy;
		if ((tmp_gx < 0) || (tmp_gx >= global.dcg_grid_x_cells) ||
		    (tmp_gy < 0) || (tmp_gy >= global.dcg_grid_y_cells) ||
		    ((global.dcg_object_grid[tmp_gx, tmp_gy] & dca_lim_obj_mask) != 0) ||
		    (steps > dca_max_distance)) {
		    // show_debug_message("Avail[{0},{1}]=false", tmp_gx, tmp_gy);
		    break;
		} else {
		    var avail = global.dcg_available_grid[tmp_gx, tmp_gy];
		    avail.sprite_index = (dca_lighton) ?spr_tileavailable :spr_clear;
		    // Stash end-point of lines in all directions
		    global.dcg_last_gx[dir8] = tmp_gx;
		    global.dcg_last_gy[dir8] = tmp_gy;
		    // show_debug_message("Avail[{0},{1}]=true", tmp_gx, tmp_gy);
		}
	    }
	}
    }
}
function dc_p_clear_available_tiles() {
    dc_p_set_available_tiles(global.dcg_last_start_gx, global.dcg_last_start_gy,
			     global.dcg_last_lim_obj_mask, global.dcg_last_max_distance, false);
    var corner = global.dcg_corner_grid[global.dcg_last_start_gx, global.dcg_last_start_gy];
    corner.sprite_index = spr_clear;
    global.dcg_last_start_gx = -1;
    global.dcg_last_start_gy = -1;
    global.dcg_last_lim_obj_mask = 0;
    global.dcg_last_max_distance = 0;
}



function dc_ev_select_dest_human(dca_human, dca_mouse_px, dca_mouse_py) {
  // Human goes via drone gx/gy before going to sel1 gx/gy
  var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
  if (drone == noone) return;
  dca_human.dci_nxt_gx = drone.dci_now_gx;
  dca_human.dci_nxt_gy = drone.dci_now_gy;
  dca_human.dci_via_gx[0] = drone.dci_now_gx;
  dca_human.dci_via_gy[0] = drone.dci_now_gy;
  dca_human.dci_via_gx[1] = global.dcg_sel1_gx;
  dca_human.dci_via_gy[1] = global.dcg_sel1_gy;
}

function dc_ev_tile_action(dca_mouse_px, dca_mouse_py, dca_ui_action) {
    // Called on mouse release if on tile NOT on button - only does stuff if state is USER_SELECT
    if (global.dcg_state != DC_STATE_USER_SELECT) return;
    // Only does stuff if an object has been selected
    if ((global.dcg_object_move < DC_OBJECT_DRONE) || (global.dcg_object_move > DC_OBJECT_FIELD)) return;
    // Only does stuff if valid sel0
    if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return;

    // Map mouse pixel position to grid position
    var mouse_gx = dc_p_get_gx(dca_mouse_px);
    var mouse_gy = dc_p_get_gy(dca_mouse_py);
    if ((mouse_gx < 0) || (mouse_gy < 0)) return;

    // Figure out what colour to draw corners
    var obj_act = global.dcg_object_action;
    var attacking = ((obj_act == DC_ACTION_DRONE_LASER) || (obj_act == DC_ACTION_MISSILE_MOVE));
    var spr_redblue = attacking ?spr_cornerRed :spr_cornerBlue;
    
    // First corner is around tile we've just entered
    var corner0 = global.dcg_corner_grid[mouse_gx, mouse_gy];    
    var available0 = global.dcg_available_grid[mouse_gx, mouse_gy];
    if ((available0 == noone) || (corner0 == noone)) return;
    var is_avail0 = (available0.sprite_index == spr_tileavailable);
    var is_base0 = ((mouse_gx == global.dcg_sel0_gx) && (mouse_gy == global.dcg_sel0_gy));
    var is_avail = is_avail0;
    // Second corner only used if action is drone firing laser
    var corner1 = noone;
    var available1 = noone;
    var is_avail1 = false;
    var is_base1 = false;

    if ((global.dcg_limit_obj_mask[obj_act] == 0) &&
	(global.dcg_max_distance[obj_act] > global.dcg_grid_max_distance)) {
	// If action has unlimited range then pretend mouse is at endpoint of line
	var dir8 = dc_p_direction8(global.dcg_sel0_gx, global.dcg_sel0_gy, mouse_gx, mouse_gy);
	if (dir8 > 0) {
	    mouse_gx = global.dcg_last_gx[dir8];
	    mouse_gy = global.dcg_last_gy[dir8];
	    // Second corner is lit around tile at endpoint of line	   
	    corner1 = global.dcg_corner_grid[mouse_gx, mouse_gy];    
	    available1 = global.dcg_available_grid[mouse_gx, mouse_gy];
	    if ((available1 == noone) || (corner1 == noone)) return;
	    is_avail1 = (available1.sprite_index == spr_tileavailable);
	    is_base1 = ((mouse_gx == global.dcg_sel0_gx) && (mouse_gy == global.dcg_sel0_gy));
	    is_avail = is_avail1;
	}
    }

    if (dca_ui_action == DC_ACTION_ENTER) {
	// Clear down last corners we lit up
	if ((global.dcg_last_corner0 != noone) &&
	    (global.dcg_last_corner0 != corner0) && (global.dcg_last_corner0 != corner1)) {
	    global.dcg_last_corner0.sprite_index = spr_clear;
	    global.dcg_last_corner0 = noone;
	}
	if ((global.dcg_last_corner1 != noone) &&
	    (global.dcg_last_corner1 != corner0) && (global.dcg_last_corner1 != corner1)) {
	    global.dcg_last_corner1.sprite_index = spr_clear;
	    global.dcg_last_corner1 = noone;
	}
	// Light up new corners and remember where
	if ((!is_base0) && (corner0 != noone)) {
	    corner0.sprite_index = (is_avail0) ?spr_redblue :spr_cornerGrey;
	    global.dcg_last_corner0 = corner0;
	}
	if ((!is_base1) && (corner1 != noone)) {
	    corner1.sprite_index = (is_avail1) ?spr_redblue :spr_cornerGrey;
	    global.dcg_last_corner1 = corner1;
	}
    } else if ((dca_ui_action == DC_ACTION_CLICK) && (is_avail)) {
	global.dcg_sel1_gx = mouse_gx;
	global.dcg_sel1_gy = mouse_gy;
	if (corner0 != noone) corner0.sprite_index = spr_clear;
	if (corner1 != noone) corner1.sprite_index = spr_clear;
	global.dcg_last_corner0 = noone;
	global.dcg_last_corner1 = noone;

	// Setup nxt_gx/gy coords from sel1_gx/gy
	var inst = dc_p_find_instance(global.dcg_object_move, 0);
	if (inst != noone) {
	    switch (inst.dci_obj_type) {
	    case DC_OBJECT_HUMAN:
		dc_ev_select_dest_human(inst, dca_mouse_px, dca_mouse_py);
		break;
	    default:
		inst.dci_nxt_gx = global.dcg_sel1_gx;
		inst.dci_nxt_gy = global.dcg_sel1_gy;
		break;
	    }
	}
	// Report destination selected
	dc_p_fsm(DC_EVENT_DEST_SELECTED);
    }
}	

function dc_ev_button_action(dca_obj_action, dca_ui_action, dca_spr_on, dca_spr_off, dca_spr_hov, dca_spr_unav) {
    // Called when any action button clicked - only does stuff if state is USER_SELECT
    if (global.dcg_state != DC_STATE_USER_SELECT) return;
    // Clear any existing selection line
    // dc_p_clear_selection_line();
    // Bail if this button's sprite has been set to the 'unavailable' sprite
    if (sprite_index == dca_spr_unav) return;

    if (dca_ui_action == DC_ACTION_ENTER) {
	sprite_index = dca_spr_hov;
	
    } else if (dca_ui_action == DC_ACTION_CLICK) {
	// If clicked action NOT already selected, DO select otherwise DO deselect
	var cur_obj_act = global.dcg_object_action;
	var cur_obj_sel_base = global.dcg_object_sel_base;
	var new_obj_act = dca_obj_action;
	if (cur_obj_act == new_obj_act) new_obj_act = DC_ACTION_DRONE_MOVE;  // Deselect ==> back to drone move
	
	// Select
	var new_obj_move = DC_OBJECT_NONE;
	var new_obj_sel_base = DC_OBJECT_NONE;
	switch (new_obj_act) {
	case DC_ACTION_MISSILE_MOVE: new_obj_sel_base = DC_OBJECT_MISSILE; new_obj_move = DC_OBJECT_MISSILE; break;
	case DC_ACTION_DRONE_MOVE:   new_obj_sel_base = DC_OBJECT_DRONE;   new_obj_move = DC_OBJECT_DRONE; break;
	case DC_ACTION_DRONE_HUMAN:  new_obj_sel_base = DC_OBJECT_DRONE;   new_obj_move = DC_OBJECT_HUMAN; break;
	case DC_ACTION_DRONE_LASER:  new_obj_sel_base = DC_OBJECT_DRONE;   new_obj_move = DC_OBJECT_LASER; break;
	case DC_ACTION_DRONE_FIELD:  new_obj_sel_base = DC_OBJECT_DRONE;   new_obj_move = DC_OBJECT_FIELD; break;
	case DC_ACTION_NONE: break;
	default: break;
	}
	if (cur_obj_act != new_obj_act) {
	    dc_p_clear_available_tiles();  // Also clears corner 

	    if (new_obj_sel_base != DC_OBJECT_NONE) {
		var new_obj = dc_p_find_instance(new_obj_sel_base, 0);
		if (new_obj != noone) {
	    	    var lim_obj_mask = global.dcg_limit_obj_mask[new_obj_act];	
		    var max_distance = global.dcg_max_distance[new_obj_act];
	    	    dc_p_set_available_tiles(new_obj.dci_now_gx, new_obj.dci_now_gy, lim_obj_mask, max_distance, true);

		    var attacking = ((new_obj_act == DC_ACTION_DRONE_LASER) || (new_obj_act == DC_ACTION_MISSILE_MOVE));
		    var spr_redblue = attacking ?spr_cornerRed :spr_cornerBlue;
		    corner = global.dcg_corner_grid[new_obj.dci_now_gx, new_obj.dci_now_gy];
		    if (corner != noone) corner.sprite_index = spr_redblue;
		}
	    }
	}
	global.dcg_object_sel_base = new_obj_sel_base;
	global.dcg_object_move = new_obj_move;
	global.dcg_object_action = new_obj_act;
	
	dc_p_button_control();
	
	dc_p_fsm(DC_EVENT_OBJECT_SELECTED);  // Report object selected
	
    } else if (dca_ui_action == DC_ACTION_EXIT) {
	sprite_index = (dca_obj_action == global.dcg_object_action) ?dca_spr_on :dca_spr_off;
    }
}







//
// BUGS:
//  A. MissileMove is an ACTION! - FIXED
//  B. Sometimes player gets 3 goes in a turn?
//  B. Enemies should not move onto drone but can move onto missile
//  C. Use integers for x/y etc
//
//
// THINGS DONE:
//  0. Sound API investigate - DONE
//  1. Figure out location of drone/human etc dynamically from room config - DONE
//  2. Figure out monster locations dynamically (2 flavours) (use monster_array[]) - DONE
//  3. Add logic to animate monsters somewhat - just head to human if space avail - DONE
//  4. Add turn taking, player->monsters->player->monsters - DONE
//  5. Add smart monster movement - melee vs ranged grids - update post player turn - DONE
//  6. Name global vars dcg, instance vars dci - rename private funcs to dc_p_ - DONE
//  7. Maintain array of instances for Drone/Missile/Human etc (just 1) - index by DC_OBJECT - DONE
//  8. Maintain array of monster instances for each monster type - DONE
//  9. SelectionLine should be configurable to disallow going thru walls etc - DONE
//  9a. Keep bitmap for grid tracking what exists at every gx/gy - update post each move - DONE
//  9b. Use object-specific bitmask during SelectionLine to limit extent - DONE
//  9c. Enhance SelectionLine to allow a maximum range extent - DONE
// 10. Use dca_ prefix consistently - DONE
// 11. Handle separation of object selection vs action selection - DONE
// 12. Add player getting movement plus action in one turn - DONE
// 12a. Grey out unavailable options - DONE
// 12b. Disallow human/field on consecutive turns - DONE
// 13. Add pseudo collision logic - DONE
// 14. Laser animation - DONE
// 15. Field handling - DONE
// 16. ProjectileEnemies move and fire in a turn - DONE
// 16a. They will fire at human if on same line - bullets blocked by field though - DONE
// 16b. Humans should die!! - DONE
// 16b. They will fire at drone if on same line - bullets blocked by field though - DONE
// 17a. Handle missile/drone at same location - use invisible missile sprite if so - DONE
// 17b. Allow extra missile move if initial deploy from drone - DONE
// 18. Terminology - Game > Level > Round > PlayerTurn(N) EnemyTurn(1)
// 19. Add in AnimationEnd Event to stop monster 'dying' animation
// 20. Add end game detection logic
//
//
// STILL TO DO:
// 21. Allow human to be hit by missile/laser ==> GameOver!
// 22. Stop laser fire 'escaping' into UI
// 23. Support 'TurnEnd' button
//
//
// MAYBE ALSO:
// 24. Add README
// 25. Use int64
// 26. Maybe munge gx|gy into a single gxy (1000gx+gy if debug, gx<<8|gy if not)
// 27. Keep gxy within instance - use dci_now_gxy and dci_nxt_gxy instance vars
//
//
// AUDIO:
// 0. ogg, mp3 or wav
// 1. Upto 128 sounds
// 2. voice = audio_play_sound(snd_Asset, 10, false);  // asset, pri, loop?
// 3. Can apply properties such as Gain/Pitch/Offset
// 4. Change loop start/end with audio_sound_loop_start/end
// 5. Can add effects such as reverb/echo/delay
// 6. Can setup N sounds to be in SYNC and fade elements in/out
