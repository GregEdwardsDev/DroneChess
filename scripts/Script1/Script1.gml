// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

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
      // case DC_OBJECT_FIELD:   return instance_find(obj_field, dca_which);  // TODO: add field
    case DC_OBJECT_ENEMY1:  return instance_find(obj_enemymelee, dca_which);
    case DC_OBJECT_ENEMY2:  return instance_find(obj_enemyprojectile, dca_which);
    case DC_OBJECT_WALL:    return instance_find(obj_wall, dca_which);
    default:                return noone;
  }
}
function dc_p_setup_nxt_xy(dca_obj_type, dca_which, gx, gy) {
  var inst = dc_p_find_instance(dca_obj_type, dca_which);
  if (inst == noone) return noone;
  inst.dci_nxt_gx = gx;
  inst.dci_nxt_gy = gy;
  return inst;
}
function dc_p_setup_now_xy(dca_obj_type, dca_which) {
  var inst = dc_p_find_instance(dca_obj_type, dca_which);
  if (inst == noone) return noone;
  // Setup a bunch of per-instance variables to track type and grid position
  inst.dci_obj_type = dca_obj_type;
  inst.dci_which = dca_which;
  inst.dci_now_gx = dc_p_get_object_gx(inst.x);
  inst.dci_now_gy = dc_p_get_object_gy(inst.y);
  dc_p_setup_nxt_xy(dca_obj_type, dca_which, inst.dci_now_gx, inst.dci_now_gy);
  show_debug_message("{0}=[{1},{2}]", dc_p_get_name(dca_obj_type), inst.dci_now_gx, inst.dci_now_gy);
  return inst;
}

function dc_p_find_objects() {
  if (global.dcg_objects_found) return;
  // Find drone/missile/human
  for (var otyp = DC_OBJECT_DRONE; otyp <= DC_OBJECT_HUMAN; otyp++) {
    dc_p_setup_now_xy(otyp, 0);
  }
  // Find melee enemies
  var i1 = 0;
  while (dc_p_setup_now_xy(DC_OBJECT_ENEMY1, i1) != noone) {
    i1++;
  }
  // Find projectile enemies
  var i2 = 0;
  while (dc_p_setup_now_xy(DC_OBJECT_ENEMY2, i2) != noone) {
    i2++;
  }
  // TODO: BARF IF DRONE OR HUMAN (or at least 1) MONSTER MISSING!!!
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
      var inst = instance_nearest(px, py, obj_tilewhite);
      global.dcg_tile_grid[i, j] = inst;
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
    }
  }
  for (var otyp = DC_OBJECT_DRONE; otyp <= DC_OBJECT_WALL; otyp++) {
    var k = 0;
    while (true) {
      var inst = dc_p_find_instance(otyp, k);
      if (inst == noone) break;
      // Build up a bitmask of objects at every grid x/y
      global.dcg_object_grid[inst.dci_now_gx, inst.dci_now_gy] |= (1<<otyp);
      k++;
    }
  }
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
function dc_p_range_grid_setpos(dca_array, gx, gy, val) {
  var listThis = ds_list_create();
  dca_array[@ gx, gy] = val;
  ds_list_add(listThis, (1<<20) + (gx << 10) + (gy << 0));
  return listThis;
}
function dc_p_range_grid_setlinesfrom(dca_array, gx, gy, val) {
  var listThis = ds_list_create();
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      if ((dx == 0) && (dy == 0)) continue;
      // For all 8 directions
      var tgx = gx;
      var tgy = gy;
      // While valid gy/gy and grid pos unset (<0) fill in val
      // and record position in list
      while ( ((tgx + dx) >= 0) && ((tgx + dx) < global.dcg_grid_x_cells) &&
              ((tgy + dy) >= 0) && ((tgy + dy) < global.dcg_grid_y_cells) &&
              (dca_array[@ tgx + dx, tgy + dy] < 0) ) {
        tgx += dx;
        tgy += dy;
        dca_array[@ tgx, tgy] = val;
        ds_list_add(listThis, (1<<20) + (tgx << 10) + (tgy << 0));
      }
    }
  }
  return listThis;
}
function dc_p_range_grid_populate(dca_array, dca_list, val) {
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
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          if ((dx == 0) && (dy == 0)) continue;
          // For all 8 neighbours
          if ( ((gx + dx) >= 0) && ((gx + dx) < global.dcg_grid_x_cells) &&
               ((gy + dy) >= 0) && ((gy + dy) < global.dcg_grid_y_cells) &&
               (dca_array[@ gx + dx, gy + dy] < 0) ) {

            dca_array[@ gx + dx, gy + dy] = val;
            ds_list_add(listNext, (1<<20) + ((gx+dx) << 10) + ((gy+dy) << 0));
          }
        }
      }
    }

    // Swap listThis to be listNext; create brand new listNext; repeat with val+1
    if (listThis != dca_list) ds_list_destroy(listThis);
    listThis = listNext;
    listNext = ds_list_create();
    val++;
  }

  // Cleanup
  if (listThis != dca_list) ds_list_destroy(listThis);
  ds_list_destroy(listNext);
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
}


function dc_p_initialise() {
  dc_p_find_objects();
  dc_p_find_walls();
  dc_p_make_tile_grid();
  dc_p_make_object_grid();
  dc_p_button_all(true);  // Set all buttons available
}


//
// SELECTION LINE LOGIC
//
function dc_p_find_delta(a, b) {
  var delta = b - a;
  if (delta < 0) return -1;
  if (delta > 0) return 1;
  return 0;  // a == b
}
function dc_p_selection_onoff(start_gx, start_gy, end_gx, end_gy, lighton) {
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return;  // Bail if no sel0
  if ((start_gx < 0) || (start_gy < 0) || (end_gx < 0) || (end_gy < 0)) return;
  // Go from (start_gx,start_gy) --> (end_gx,end_gy) lighting or unlighting cells
  var delta_gx = dc_p_find_delta(start_gx, end_gx);
  var delta_gy = dc_p_find_delta(start_gy, end_gy);
  var tmp_gx = start_gx;
  var tmp_gy = start_gy;
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
        inst.sprite_index = (lighton) ?spr_tileselected :spr_tilewhite;
      }
    }
    // Stop if we get to end point
    if ((tmp_gx == end_gx) && (tmp_gy == end_gy)) break;
    tmp_gx += delta_gx;
    tmp_gy += delta_gy;
  }
}

function dc_p_same_line(g1_gx, g1_gy, g2_gx, g2_gy) {
  if ((g1_gx < 0) || (g1_gy < 0) || (g2_gx < 0) || (g2_gy < 0)) return false;
  if (g1_gx == g2_gx) return true;
  if (g1_gy == g2_gy) return true;
  if (abs(g1_gx - g2_gx) == abs(g1_gy - g2_gy)) return true;
  return false;
}
function dc_p_same_line_as_sel0(gx, gy) {
  return dc_p_same_line(global.dcg_sel0_gx, global.dcg_sel0_gy, gx, gy);
}
function dc_p_direction8(g1_gx, g1_gy, g2_gx, g2_gy) {
  // Return BAD=0 N=1 NE=2 E=3 SE=4 S=5 SW=6 W=7 NW=8
  if ((g1_gx < 0) || (g1_gy < 0) || (g2_gx < 0) || (g2_gy < 0)) return 0;  // BAD
  if (g1_gx == g2_gx) return (g1_gy < g2_gy) ?1 :5;  // N or S
  if (g1_gy == g2_gy) return (g1_gx < g2_gx) ?7 :3;  // W or E
  if (abs(g1_gx - g2_gx) != abs(g1_gy - g2_gy)) return 0;  // BAD - not same diag
  if ((g1_gx == g2_gx) && (g1_gy == g2_gy)) return 0;  // BAD - identical
  if ((g1_gx < g2_gx) && (g1_gy < g2_gy)) return 8;  // NW
  if ((g1_gx > g2_gx) && (g1_gy > g2_gy)) return 4;  // SE
  if ((g1_gx < g2_gx) && (g1_gy > g2_gy)) return 6;  // SW
  if ((g1_gx > g2_gx) && (g1_gy < g2_gy)) return 2;  // NE
  return 0;  // BAD
}
function dc_p_direction8_from_sel0(gx, gy) {
  return dc_p_direction8(global.dcg_sel0_gx, global.dcg_sel0_gy, gx, gy);
}
function dc_p_same_line_012(g0_gx, g0_gy, g1_gx, g1_gy, g2_gx, g2_gy) {
  // Check if points 0, 1, 2 on same line in order 0->1->2
  if ((g0_gx < 0) || (g0_gy < 0) || (g1_gx < 0) || (g1_gy < 0) || (g2_gx < 0) || (g2_gy < 0)) return false;
  var dir01 = dc_p_direction8(g0_gx, g0_gy, g1_gx, g1_gy);
  var dir12 = dc_p_direction8(g1_gx, g1_gy, g2_gx, g2_gy);
  if ((dir01 > 0) && (dir01 == dir12)) return true;
  return false;
}
function dc_p_same_line_021(g0_gx, g0_gy, g1_gx, g1_gy, g2_gx, g2_gy) {
  // Check if points 0, 1, 2 on same line but now in order 0->2->1
  return dc_p_same_line_012(g0_gx, g0_gy, g2_gx, g2_gy, g1_gx, g1_gy);
}

function dc_p_find_sel2(mouse_gx, mouse_gy, limited) {
  global.dcg_sel2_gx = -1;
  global.dcg_sel2_gy = -1;
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return false;  // Bail if no sel0
  if (!dc_p_same_line_as_sel0(mouse_gx, mouse_gy)) return false;  // Mouse not on same row/col/diag as sel0
  // Start at global.dcg_sel0
  // Apply delta_gx delta_gy until find obstacle/mouse (iff sel_line_limited) or find edge grid
  // Set sel2 (may end up SAME as sel0)
  var delta_gx = dc_p_find_delta(global.dcg_sel0_gx, mouse_gx);
  var delta_gy = dc_p_find_delta(global.dcg_sel0_gy, mouse_gy);
  var tmp_gx = global.dcg_sel0_gx;
  var tmp_gy = global.dcg_sel0_gy;
  var back_one_step = true;
  // show_debug_message("Sel0=[{0},{1}] Delta=[{2},{3}]", global.dcg_sel0_gx, global.dcg_sel0_gy, delta_gx, delta_gy);
  while (true) {
    tmp_gx += delta_gx;
    tmp_gy += delta_gy;
    if ((tmp_gx < 0) || (tmp_gx >= global.dcg_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dcg_grid_y_cells)) {
      break;  // Gone too far so will go back one step

    } else if (limited) {
      if ((tmp_gx == mouse_gx) && (tmp_gy == mouse_gy)) {
        back_one_step = false;  // Got to mouse pos so NO need to go back one step
        break;
      } else {
        var inst = global.dcg_tile_grid[tmp_gx, tmp_gy];
        if ((inst != noone) && (inst.object_index == obj_enemymelee)) {  // TODO: !!!!!!!!!!!!!!!!!! FIXME !!!!!!!!!!!!!!!!!
          // show_debug_message("SAW KNIFE");
          break;  // Gone too far so will go back one step
        }
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
function dc_p_fsm_debug(dc_event) {
  show_debug_message("DEBUG: State={0} Event={1}", global.dcg_state, dc_event);
}
function dc_p_fsm_state_invalid(dc_event) {
  dc_p_fsm_debug(dc_event);
}

function dc_p_fsm(dc_event) {
  dc_p_fsm_debug(dc_event);
  switch (global.dcg_state) {
    case DC_STATE_GAME_START:    dc_p_fsm_game_start(dc_event); return;
    case DC_STATE_TURN_START:    dc_p_fsm_turn_start(dc_event); return;
    case DC_STATE_USER_SELECT:   dc_p_fsm_user_select(dc_event); return;
    case DC_STATE_USER_ANIMATE:  dc_p_fsm_user_animate(dc_event); return;
    case DC_STATE_ENEMY_ANIMATE: dc_p_fsm_enemy_animate(dc_event); return;
    case DC_STATE_TURN_END:      dc_p_fsm_turn_end(dc_event); return;
    case DC_STATE_GAME_END:      dc_p_fsm_game_end(dc_event); return;
    default: dc_p_fsm_state_invalid(dc_event); return;
  }
}
function dc_p_fsm_set_state(dc_new_state) {
  if (global.dcg_state == dc_new_state) return;
  global.dcg_state = dc_new_state;
  dc_p_fsm(DC_EVENT_ENTER_STATE);
}

function dc_p_fsm_game_start(dc_event) {
  // TODO: is this needed? Or do we just jump into room_start/turn_start
  // Setup overall game state
  if (dc_event == DC_EVENT_ENTER_STATE) {
    dc_p_fsm_set_state(DC_STATE_TURN_START);
  }
}
function dc_p_fsm_room_start() {
  // TODO: assumes this re-called each time we enter new room
  dc_p_initialise();

  // Setup Drone gx/gy as original selected object
  global.dcg_object_selected = DC_OBJECT_DRONE;

  dc_p_button_control();

  dc_p_fsm_set_state(DC_STATE_TURN_START);
}
function dc_p_fsm_turn_start(dc_event) {
  if (dc_event == DC_EVENT_ENTER_STATE) {
    // Setup per-room state
    dc_p_fsm_set_state(DC_STATE_USER_SELECT);
  }
}
function dc_p_fsm_user_select(dc_event) {
  if (dc_event == DC_EVENT_ENTER_STATE) {
    dc_p_make_object_grid();  // Track where everything is
  }
  if ((dc_event == DC_EVENT_ENTER_STATE) || (dc_event == DC_EVENT_OBJECT_SELECTED)) {
    dc_p_button_all(true);  // All buttons available
    var inst = dc_p_find_instance(global.dcg_object_selected, 0);
    if (inst != noone) {
      show_debug_message("{0} at [{1},{2}]", dc_p_get_name(global.dcg_object_selected), inst.dci_now_gx, inst.dci_now_gy);
      // Setup selected object gx/gy as sel0_gx/gy
      global.dcg_sel0_gx = inst.dci_now_gx;
      global.dcg_sel0_gy = inst.dci_now_gy;
    }
  }
  if (dc_event == DC_EVENT_DEST_SELECTED) {
    global.dcg_object_animate = global.dcg_object_selected;
    dc_p_fsm_set_state(DC_STATE_USER_ANIMATE);
  }
}
function dc_p_fsm_user_animate(dc_event) {
  if (dc_event == DC_EVENT_ENTER_STATE) {
    dc_p_button_all(false);  // All buttons unavailable
  }
  if (dc_event == DC_EVENT_ANIMATE_ENDED) {
    global.dcg_object_animate = DC_OBJECT_NONE;
    // dc_p_fsm_set_state(DC_STATE_USER_SELECT);
    // TODO: FIX: But for now go to enemy animate
    dc_p_fsm_set_state(DC_STATE_ENEMY_ANIMATE);
  }
}
function dc_p_fsm_enemy_animate(dc_event) {
  if (dc_event == DC_EVENT_ENTER_STATE) {
    dc_p_make_object_grid();  // Track where everything is
    dc_p_make_range_grid1();
    dc_p_make_range_grid2();

    global.dcg_objects_animating = dc_p_fsm_update_enemies();
    if (global.dcg_objects_animating > 0) {
      // Some enemies to animate
      global.dcg_object_animate = DC_OBJECT_ENEMY1;
    } else {
      // No enemies to animate - turn is over
      dc_p_fsm_set_state(DC_STATE_TURN_END);
    }
  }
  if (dc_event == DC_EVENT_ANIMATE_ENDED) {
    global.dcg_objects_animating--;
    if (global.dcg_objects_animating == 0) {
      // Enemies finished animateing - turn is over
      dc_p_fsm_set_state(DC_STATE_TURN_END);
    }
  }
}
function dc_p_fsm_turn_end(dc_event) {
  if (dc_event == DC_EVENT_ENTER_STATE) {
      global.dcg_object_animate = DC_OBJECT_NONE;
    // Loop back to start
    dc_p_fsm_set_state(DC_STATE_TURN_START);
  }
}
function dc_p_fsm_game_end(dc_event) {
  // TODO: is this needed?
  if (dc_event == DC_EVENT_ENTER_STATE) {
  }
}

// Fixup enemies nxt_gx/gy
function dc_p_fsm_update_enemies() {
  var n_to_animate = 0;
  // Do ENEMY2 first - they're nastier!
  for (var etyp = DC_OBJECT_ENEMY2; etyp >= DC_OBJECT_ENEMY1; etyp--) {
    var i = 0;
    while (true) {
      var monst = dc_p_find_instance(etyp, i);
      if (monst == noone) break;
      if (dc_p_update_enemy_nxt(monst)) n_to_animate++;
      i++;
    }
  }
  return n_to_animate;  // Count of enemies that will animate
}




// Call this function to enable/disable buttons - honours true/false vals in global.dcg_button_available array
function dc_p_button_control() {
  if (global.dcg_button_available[DC_OBJECT_LASER]) {
    obj_buttonlaser.sprite_index = (global.dcg_object_selected == DC_OBJECT_LASER) ?spr_buttonlaserOn :spr_buttonlaserOff;
  } else {
    obj_buttonlaser.sprite_index = spr_buttonlaserUnav;
  }
  if (global.dcg_button_available[DC_OBJECT_MISSILE]) {
    obj_buttonmissile.sprite_index = (global.dcg_object_selected == DC_OBJECT_MISSILE) ?spr_buttonmissileOn :spr_buttonmissileOff;
  } else {
    obj_buttonmissile.sprite_index = spr_buttonmissileUnav;
  }
  if (global.dcg_button_available[DC_OBJECT_FIELD]) {
    obj_buttonfield.sprite_index = (global.dcg_object_selected == DC_OBJECT_FIELD) ?spr_buttonfieldOn :spr_buttonfieldOff;
  } else {
    obj_buttonfield.sprite_index = spr_buttonfieldUnav;
  }
  if (global.dcg_button_available[DC_OBJECT_HUMAN]) {
    obj_buttondisplace.sprite_index = (global.dcg_object_selected == DC_OBJECT_HUMAN) ?spr_buttondisplaceOn :spr_buttondisplaceOff;
  } else {
    obj_buttondisplace.sprite_index = spr_buttondisplaceUnav;
  }
}
function dc_p_button_all(dca_onoff) {
  var otyp = DC_OBJECT_DRONE;
  for (var otyp = DC_OBJECT_DRONE; otyp <= DC_OBJECT_FIELD; otyp++) {
    // while (otyp <= DC_OBJECT_FIELD) {
    global.dcg_button_available[otyp] = dca_onoff;
    // otyp++;
  }
  dc_p_button_control();
}
function dc_p_button(dca_otyp, dca_onoff) {
  global.dcg_button_available[dca_otyp] = dca_onoff;
  dc_p_button_control();
}


//
// STEP FUNCTIONS and STEP UTILITY FUNCTIONS
//
function dc_p_set_speed_direction(spd) {
  var original_speed = speed;
  speed = 0;
  if ((dci_now_gx < 0) || (dci_now_gy < 0) || (dci_nxt_gx < 0) || (dci_nxt_gy < 0)) return (original_speed > 0);
  if ((dci_now_gx == dci_nxt_gx) && (dci_now_gy == dci_nxt_gy)) return (original_speed > 0);

  var nxt_px = global.dcg_grid_min_px + (dci_nxt_gx * global.dcg_grid_cell_width);
  var nxt_py = global.dcg_grid_min_py + (dci_nxt_gy * global.dcg_grid_cell_height) - global.dcg_grid_cell_height_offset;
  var pdist = point_distance(x, y, nxt_px, nxt_py);
  if (pdist < global.dcg_grid_min_distance) {
    dci_now_gx = dci_nxt_gx;
    dci_now_gy = dci_nxt_gy;
    speed = 0;
  } else {
    speed = min(pdist, spd);  // This stops the object oscillating at its endpoint
    direction = point_direction(x, y, nxt_px, nxt_py);
  }
  if ((dci_obj_type == DC_OBJECT_ENEMY1) || (dci_obj_type == DC_OBJECT_ENEMY2)) {
    //show_debug_message("END: Now=[{0},{1}] Nxt=[{2},{3}]  Dist={4} Speed={5} Inst={6}",
    //                   dci_now_gx, dci_now_gy, dci_nxt_gx, dci_nxt_gy, pdist, speed, dci_which);
    //show_debug_message("END: Now=[{0},{1}] Nxt=[{2},{3}]  Dist={4} Speed={5} Inst={6}",
    //                   x, y, nxt_px, nxt_py, pdist, speed, dci_which);
  }
  return (original_speed > 0) && (speed == 0);  // Return true if stopped on this call
}

function dc_p_find_enemy_best_path(dca_monst, dca_array, ctrl) {
  var gx = dca_monst.dci_now_gx;
  var gy = dca_monst.dci_now_gy;
  var original_range = dca_array[@ gx, gy];
  var smallest_range = original_range;
  var smallest_range_gx = -1;
  var smallest_range_gy = -1;
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      if ((dx == 0) && (dy == 0)) continue;
      // For all 8 neighbours
      if ( ((gx + dx) >= 0) && ((gx + dx) < global.dcg_grid_x_cells) &&
           ((gy + dy) >= 0) && ((gy + dy) < global.dcg_grid_y_cells) ) {
        var range = dca_array[@ gx + dx, gy + dy];
        if (range < smallest_range) {
          smallest_range_gx = gx + dx;
          smallest_range_gy = gy + dy;
          smallest_range = range;
        } else if (range == smallest_range) {
          if (ctrl == DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH) return false;
          if (ctrl == DC_CTRL_USE_FIRST_BEST_PATH) continue;
          smallest_range_gx = gx + dx;
          smallest_range_gy = gy + dy;
        }
      }
    }
  }
  if (smallest_range == original_range) return false;
  dca_monst.dci_nxt_gx = smallest_range_gx;
  dca_monst.dci_nxt_gy = smallest_range_gy;
  // Put large value into nxt pos so no other monster can move into it
  dca_array[@ dca_monst.dci_nxt_gx, dca_monst.dci_nxt_gy] = 9999999;
  return true;
}
function dc_p_update_enemy_nxt(dca_monst) {
  // This function returns true if the enemy needs to be animated
  if (dca_monst == noone) return false;

  var ok2 = false;
  if (dca_monst.dci_obj_type == DC_OBJECT_ENEMY2) {
    // Here we're using the DC_OBJECT_ENEMY2 grid
    // We get back ok=false if NO best path or if NO *SINGLE* best path
    // in which case we fall through to the DC_OBJECT_ENEMY1 logic below
    ok2 = dc_p_find_enemy_best_path(dca_monst, global.dcg_range_grid2, DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH);
  }
  if (!ok2) {
    // Here we're using the DC_OBJECT_ENEMY1 grid
    // Pass in ctrl = 0 (DC_CTRL_NONE) for even monsters, 1 (DC_CTRL_USE_FIRST_BEST_PATH) for odd
    // This mean a given monster will, when there are multiple best paths, deterministically
    // select the first one found or the last one found.
    var ok1 = dc_p_find_enemy_best_path(dca_monst, global.dcg_range_grid1, (dca_monst.dci_which % 2));
  }
  with (dca_monst) {
    return ((dci_now_gx != dci_nxt_gx) || (dci_now_gy != dci_nxt_gy));
  }
}


function dc_step_drone() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_DRONE) return;  // Must be animating DRONE
  var stopped = dc_p_set_speed_direction(10);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_missile() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_MISSILE) return;  // Must be animating MISSILE
  var stopped = dc_p_set_speed_direction(50);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_human() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_HUMAN) return;  // Must be animating HUMAN
  var stopped = dc_p_set_speed_direction(5);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_laser() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_LASER) return;  // Must be animating LASER
  var stopped = dc_p_set_speed_direction(100);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_enemy() {
  if (global.dcg_state != DC_STATE_ENEMY_ANIMATE) return;  // Must be in STATE EnemyAnimate
  // if (global.dcg_object_animate != DC_OBJECT_ENEMY1) return;
  var stopped = dc_p_set_speed_direction(1);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}





//
// EVENT HANDLERS and EVENT HANDLER UTILITY FUNCTIONS
//
function dc_p_clear_selection_line() {
  // Clear existing selection if we have one
  dc_p_selection_onoff(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, false);
  // Invalidate sel1
  global.dcg_sel1_gx = -1;
  global.dcg_sel1_gy = -1;
}
function dc_ev_draw_new_selection_line(mouse_px, mouse_py) {
  // CALLED when mouse enters any tile - only does stuff if state is Select
  if (global.dcg_state != DC_STATE_USER_SELECT) return;

  // Uses global state:
  // 1. dc_sel0_gx|gy - grid pos of active object (ie drone or missile) (may be -1/-1 if no selection)
  // 2. dc_sel1_gx|gy - grid pos of other end of selection line (may be identical to dc_sel0_gx|gy)
  // 3. dc_sel_line_limited - whether selection line should be limited by walls/obstacles

  // Map mouse pixel position to grid position
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return;  // Bail if no sel0
  var mouse_gx = dc_p_get_gx(mouse_px);
  var mouse_gy = dc_p_get_gy(mouse_py);
  if ((mouse_gx < 0) || (mouse_gy < 0)) return;

  // If mouse still at sel1, bail, leaving sel1 unchanged
  if ((mouse_gx == global.dcg_sel1_gx) && (mouse_gy == global.dcg_sel1_gy)) return;

  // Now we find sel2_gx|gy - a possible NEW position value for sel1_gx|sel1_gy
  dc_p_find_sel2(mouse_gx, mouse_gy, global.dcg_sel_line_limited);
  // If new sel2 position same as previous sel1 position, bail
  if ((global.dcg_sel2_gx == global.dcg_sel1_gx) && (global.dcg_sel2_gy == global.dcg_sel1_gy)) return;

  if (dc_p_same_line_012(global.dcg_sel0_gx, global.dcg_sel0_gy,
                         global.dcg_sel1_gx, global.dcg_sel1_gy, global.dcg_sel2_gx, global.dcg_sel2_gy)) {
    // Sel1/Sel2 valid and new selection (sel2) in same N/ne/E/se/S/sw/W/nw direction as old (sel1) and further from sel0
    var delta_gx = dc_p_find_delta(global.dcg_sel1_gx, global.dcg_sel2_gx);
    var delta_gy = dc_p_find_delta(global.dcg_sel1_gy, global.dcg_sel2_gy);
    dc_p_selection_onoff(global.dcg_sel1_gx + delta_gx, global.dcg_sel1_gy + delta_gy, global.dcg_sel2_gx, global.dcg_sel2_gy, true);

  } else if (dc_p_same_line_021(global.dcg_sel0_gx, global.dcg_sel0_gy,
                                global.dcg_sel1_gx, global.dcg_sel1_gy, global.dcg_sel2_gx, global.dcg_sel2_gy)) {
    // Sel1/Sel2 valid and new selection (sel2) in same N/ne/E/se/S/sw/W/nw direction as old (sel1) but closer to sel0
    var delta_gx = dc_p_find_delta(global.dcg_sel2_gx, global.dcg_sel1_gx);
    var delta_gy = dc_p_find_delta(global.dcg_sel2_gy, global.dcg_sel1_gy);
    dc_p_selection_onoff(global.dcg_sel2_gx + delta_gx, global.dcg_sel2_gy + delta_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, false);

  } else {
    // EITHER one/both of sel1/sel2 invalid OR new selection (sel2) in DIFF N/ne/E/se/S/sw/W/nw direction to old (sel1)
    // Unlight sel0->sel1 (does nothing if no sel1)
    dc_p_selection_onoff(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, false);
    // Light sel0->sel2 (does nothing if no sel2)
    dc_p_selection_onoff(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel2_gx, global.dcg_sel2_gy, true);
  }
  // Set sel1 <== sel2
  global.dcg_sel1_gx = global.dcg_sel2_gx;
  global.dcg_sel1_gy = global.dcg_sel2_gy;
}

function dc_ev_select_dest(mouse_px, mouse_py) {
  // Called on mouse release if on tile NOT on button - only does stuff if state is USER_SELECT
  if (global.dcg_state != DC_STATE_USER_SELECT) return;
  // Only does stuff if an object has been selected
  if ((global.dcg_object_selected < DC_OBJECT_DRONE) || (global.dcg_object_selected > DC_OBJECT_FIELD)) return;
  // Only does stuff if valid sel0 and sel1
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0) || (global.dcg_sel1_gx < 0) || (global.dcg_sel1_gy < 0)) return;
  // Only does stuff if sel0 != sel1
  if ((global.dcg_sel0_gx == global.dcg_sel1_gx) && (global.dcg_sel0_gy == global.dcg_sel1_gy)) return;

  // Clear existing selection - but leave sel1 as is until installed in selected object
  dc_p_selection_onoff(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, false);

  // Setup nxt_gx/gy coords from sel1_gx/gy
  var inst = dc_p_find_instance(global.dcg_object_selected, 0);
  if (inst != noone) {
    inst.dci_nxt_gx = global.dcg_sel1_gx;
    inst.dci_nxt_gy = global.dcg_sel1_gy;
  }
  // Report destination selected
  dc_p_fsm(DC_EVENT_DEST_SELECTED);
}

function dc_ev_button_action(dc_obj_this, dc_action, dc_spr_on, dc_spr_off, dc_spr_hov, dc_spr_unav) {
  // Called when any action button clicked - only does stuff if state is USER_SELECT
  if (global.dcg_state != DC_STATE_USER_SELECT) return;
  // Clear any existing selection line
  dc_p_clear_selection_line();
  // Bail if this button's sprite has been set to the 'unavailable' sprite
  if (sprite_index == dc_spr_unav) return;

  if (dc_action == DC_ACTION_ENTER) {
    sprite_index = dc_spr_hov;

  } else if (dc_action == DC_ACTION_CLICK) {
    // If clicked object NOT already selected, DO select otherwise DO deselect and go back to selecting DRONE
    var cur_obj_sel = global.dcg_object_selected;
    var new_obj_sel = (dc_obj_this == cur_obj_sel) ?DC_OBJECT_DRONE :dc_obj_this;
    if (cur_obj_sel != new_obj_sel) {
      // Setup sel0_gx/gy coords from new object
      var inst = dc_p_find_instance(new_obj_sel, 0);
      if (inst != noone) {
        global.dcg_object_selected = new_obj_sel;
        show_debug_message("CLICK {0}=[{1},{2}]", dc_p_get_name(new_obj_sel), inst.dci_now_gx, inst.dci_now_gy);
      }
      dc_p_button_control();
    }
    dc_p_fsm(DC_EVENT_OBJECT_SELECTED);  // Report object selected

  } else if (dc_action == DC_ACTION_EXIT) {
    sprite_index = (dc_obj_this == global.dcg_object_selected) ?dc_spr_on :dc_spr_off;
  }
}



//
// THINGS LEFT TO DO:
//
//  0. Sound API investigate - DONE
//  1. Figure out location of drone/human etc dynamically from room config - DONE
//  2. Figure out monster locations dynamically (2 flavours) (use monster_array[]) - DONE
//  3. Add logic to animate monsters somewhat - just head to human if space avail - DONE
//  4. Add turn taking, player->monsters->player->monsters - DONE
//  5. Add smart monster movement - melee vs ranged grids - update post player turn - DONE
//
//  6. SelectionLine should be configurable to disallow going thru walls etc (see 15-17)
//  7. Add player getting movement plus action in one turn
//  7a. Grey out unavailable options
//  7b. Support 'TurnEnd' button
//  7c. Handle missile/drone at same location - use invisible missile sprite if so
//  7d. Allow extra missile move if initial deploy from drone
//
//  8. Add collision/end game detection logic
//  9. Use int64
//
//
// 10. Name global vars dcg, instance vars dci - rename private funcs to dc_p_
// 11. Maintain array of instances for Drone/Missile/Human etc (just 1) - index by DC_OBJECT
// 12. Maintain array of monster instances for each monster type
// 13. Maybe munge gx|gy into a single gxy (1000gx+gy if debug, gx<<8|gy if not)
// 14. Keep gxy within instance - use dci_now_gxy and dci_nxt_gxy instance vars
//
// 15. Keep bitmap for grid tracking what exists at every gx/gy - update post each move
// 16. Use object-specific bitmask during SelectionLine to limit extent
// 17. Enhance SelectionLine to allow a maximum range extent


//
// AUDIO:
//
// 0. ogg, mp3 or wav
// 1. Upto 128 sounds
// 2. voice = audio_play_sound(snd_Asset, 10, false);  // asset, pri, loop?
// 3. Can apply properties such as Gain/Pitch/Offset
// 4. Change loop start/end with audio_sound_loop_start/end
// 5. Can add effects such as reverb/echo/delay
// 6. Can setup N sounds to be in SYNC and fade elements in/out
