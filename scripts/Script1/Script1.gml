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
  global.dcg_limit_obj_mask[DC_ACTION_DRONE_MOVE] = (1<<DC_OBJECT_WALL) | (1<<DC_OBJECT_MOUSE) | enemies;
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
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      if ((dx == 0) && (dy == 0)) continue;
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
  }
  return listThis;
}
function dc_p_range_grid_populate(dca_array, dca_list, dca_val) {
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

            dca_array[@ gx + dx, gy + dy] = dca_val;
            ds_list_add(listNext, (1<<20) + ((gx+dx) << 10) + ((gy+dy) << 0));
          }
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
}
function dc_p_make_range_grids() {
  dc_p_make_range_grid1();
  dc_p_make_range_grid2();
}

function dc_p_initialise() {
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
function dc_p_direction8(dca_g1_gx, dca_g1_gy, dca_g2_gx, dca_g2_gy) {
  // Direction FROM G1 TO G2 - return BAD=0 N=1 NE=2 E=3 SE=4 S=5 SW=6 W=7 NW=8
  if ((dca_g1_gx < 0) || (dca_g1_gy < 0) || (dca_g2_gx < 0) || (dca_g2_gy < 0)) return 0;  // BAD
  if (dca_g1_gx == dca_g2_gx) return (dca_g1_gy < dca_g2_gy) ?5 :1;  // S or N
  if (dca_g1_gy == dca_g2_gy) return (dca_g1_gx < dca_g2_gx) ?3 :7;  // E or W
  if (abs(dca_g1_gx - dca_g2_gx) != abs(dca_g1_gy - dca_g2_gy)) return 0;  // BAD - not same diag
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
function dc_p_fsm_debug(dca_event) {
  show_debug_message("DEBUG: State={0} Event={1}", global.dcg_state, dca_event);
}
function dc_p_fsm_state_invalid(dca_event) {
  dc_p_fsm_debug(dca_event);
}

function dc_p_fsm(dca_event) {
  dc_p_fsm_debug(dca_event);
  switch (global.dcg_state) {
    case DC_STATE_GAME_START:       dc_p_fsm_game_start(dca_event); return;
    case DC_STATE_TURN_START:       dc_p_fsm_turn_start(dca_event); return;
    case DC_STATE_USER_SELECT:      dc_p_fsm_user_select(dca_event); return;
    case DC_STATE_USER_ANIMATE:     dc_p_fsm_user_animate(dca_event); return;
    case DC_STATE_USER_ANIMATE_HIT: dc_p_fsm_user_animate_hit(dca_event); return;
    case DC_STATE_ENEMY_ANIMATE:    dc_p_fsm_enemy_animate(dca_event); return;
    case DC_STATE_TURN_END:         dc_p_fsm_turn_end(dca_event); return;
    case DC_STATE_GAME_END:         dc_p_fsm_game_end(dca_event); return;
    default: dc_p_fsm_state_invalid(dca_event); return;
  }
}
function dc_p_fsm_set_state(dc_new_state) {
  if (global.dcg_state == dc_new_state) return;
  global.dcg_state = dc_new_state;
  dc_p_fsm(DC_EVENT_ENTER_STATE);
}

function dc_p_fsm_game_start(dca_event) {
  // TODO: is this needed? Or do we just jump into room_start/turn_start
  // Setup overall game state
  if (dca_event == DC_EVENT_ENTER_STATE) {
    dc_p_fsm_set_state(DC_STATE_TURN_START);
  }
}
function dc_p_fsm_room_start() {
  // TODO: assumes this re-called each time we enter new room
  dc_p_initialise();

  dc_p_button_room_start_begin();

  dc_p_fsm_set_state(DC_STATE_TURN_START);
}
function dc_p_fsm_turn_start(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {

    global.dcg_turn++;
    global.dcg_field_used[global.dcg_turn % 2] = false;
    global.dcg_human_used[global.dcg_turn % 2] = false;

    dc_p_button_turn_start_begin();

    dc_p_fsm_set_state(DC_STATE_USER_SELECT);
  }
}
function dc_p_fsm_user_select(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
    dc_p_make_object_grid();  // Track where everything is
    dc_p_make_range_grids();  // TODO: REMOVE: HANDY FOR DEBUGGING THOUGH

    dc_p_button_user_select_begin();
  }
  if ((dca_event == DC_EVENT_ENTER_STATE) || (dca_event == DC_EVENT_OBJECT_SELECTED)) {
    var inst = dc_p_find_instance(global.dcg_object_sel_base, 0);
    if (inst != noone) {
      // show_debug_message("{0} at [{1},{2}]", dc_p_get_name(global.dcg_object_sel_base), inst.dci_now_gx, inst.dci_now_gy);
      // Setup sel_base object gx/gy as sel0_gx/gy - might not be object we actually move
      global.dcg_sel0_gx = inst.dci_now_gx;
      global.dcg_sel0_gy = inst.dci_now_gy;
    }
  }
  if (dca_event == DC_EVENT_DEST_SELECTED) {
    global.dcg_object_animate = global.dcg_object_move;

    // Look along animating object's path and markup any enemies as HIT
    global.dcg_enemies_dying = dc_p_fsm_maybe_hit_enemies();

    dc_p_fsm_set_state(DC_STATE_USER_ANIMATE);
  }
}
function dc_p_fsm_user_animate(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
    dc_p_button_display(0, 0);  // All buttons greyed

    if ((global.dcg_object_animate == DC_OBJECT_LASER) ||
        (global.dcg_object_animate == DC_OBJECT_FIELD) ||
        (global.dcg_object_animate == DC_OBJECT_NONE)) {
      // TODO:FIX - for now if laser/field selected synthesise animate ended
      dca_event = DC_EVENT_ANIMATE_ENDED;
    }
  }
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
  }
  if ((dca_event == DC_EVENT_ENTER_STATE) || (dca_event == DC_EVENT_ANIMATE_ENDED)) {

    // If no one still dying can move on
    if (global.dcg_enemies_dying == 0) {

      // Turn complete? If not return to selecting state. If so then enemy animate
      var turn_not_over = dc_p_button_user_animations_complete();
      if (turn_not_over) {
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

    global.dcg_objects_animating = dc_p_fsm_reposition_enemies();

    if (global.dcg_objects_animating > 0) {
      // Some enemies to animate
      global.dcg_object_animate = DC_OBJECT_ENEMY1;
    } else {
      // No enemies to animate - turn is over
      dc_p_fsm_set_state(DC_STATE_TURN_END);
    }
  }
  if (dca_event == DC_EVENT_ANIMATE_ENDED) {
    global.dcg_objects_animating--;
    if (global.dcg_objects_animating == 0) {
      // Enemies finished animating - turn is over
      dc_p_fsm_set_state(DC_STATE_TURN_END);
    }
  }
}
function dc_p_fsm_turn_end(dca_event) {
  if (dca_event == DC_EVENT_ENTER_STATE) {
    global.dcg_object_animate = DC_OBJECT_NONE;
    // Loop back to start
    dc_p_button_turn_end_begin();
    dc_p_fsm_set_state(DC_STATE_TURN_START);
  }
}
function dc_p_fsm_game_end(dca_event) {
  // TODO: is this needed?
  if (dca_event == DC_EVENT_ENTER_STATE) {
  }
}

// Fixup enemies nxt_gx/gy
function dc_p_fsm_maybe_hit_enemies() {
  var dx = dc_p_get_dx(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy);
  var dy = dc_p_get_dy(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy);
  if ((dx == 0) && (dy == 0)) return 0;
  show_debug_message("HIT [{0},{1}]-->[{2},{3}]  DXY=[{4},{5}]",
                     global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, dx, dy);
  // Go along now/nxt line of animating object looking for enemies - mark them as dying
  var n_hit = 0;
  var tmp_gx = global.dcg_sel0_gx;
  var tmp_gy = global.dcg_sel0_gy;
  while (true) {
    if ((tmp_gx < 0) || (tmp_gx >= global.dcg_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dcg_grid_y_cells))
      break;
    var pinst = global.dcg_inst_grid[tmp_gx, tmp_gy];
    if ((pinst != noone) && (pinst.dci_obj_state == DC_OBJSTATE_ALIVE) &&
        ((pinst.dci_obj_type == DC_OBJECT_ENEMY1) || (pinst.dci_obj_type == DC_OBJECT_ENEMY2))) {
      pinst.dci_obj_state = DC_OBJSTATE_DYING;
      show_debug_message("HIT ENEMY {0} AT [{1},{2}]", pinst.dci_obj_type, tmp_gx, tmp_gy);
      n_hit++;
    }
    if ((tmp_gx == global.dcg_sel1_gx) && (tmp_gy == global.dcg_sel1_gy)) break;
    tmp_gx += dx;
    tmp_gy += dy;
  }
  return n_hit;  // Count of enemies that will need HIT animation
}
// Fixup enemies nxt_gx/gy
function dc_p_fsm_reposition_enemies() {
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
  return n_to_animate;  // Count of enemies that will animate
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
  show_debug_message("BUTTONS = {0} {1} {2} {3} {4}", drone, laser, missile, field, human);
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
function dc_p_button_room_start_begin() {
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
  global.dcg_object_sel_base = DC_OBJECT_DRONE;
  global.dcg_object_move = DC_OBJECT_NONE;
  if (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_MOVE) & 1) == 1) {
    global.dcg_object_move = DC_OBJECT_DRONE;
    global.dcg_object_action_prev = global.dcg_object_action;
    global.dcg_object_action = DC_ACTION_DRONE_MOVE;
  } else if (((global.dcg_button_avail_mask >> DC_ACTION_DRONE_LASER) & 1) == 1) {
    global.dcg_object_move = DC_OBJECT_LASER;
    global.dcg_object_action_prev = global.dcg_object_action;
    global.dcg_object_action = DC_ACTION_DRONE_LASER;
  }
  // Invalidate sel1
  global.dcg_sel1_gx = -1;
  global.dcg_sel1_gy = -1;
  dc_p_button_control();
}
function dc_p_button_user_animations_complete() {
  var moves = (1<<DC_ACTION_DRONE_MOVE) | (1<<DC_ACTION_MISSILE_MOVE);
  var actions = (1<<DC_ACTION_DRONE_LASER) | (1<<DC_ACTION_DRONE_FIELD) | (1<<DC_ACTION_DRONE_HUMAN);

  // Clear flag corresponding to button used - use of move uses up ALL moves - use of action uses up ALL actions
  switch (global.dcg_object_action) {
    case DC_ACTION_DRONE_MOVE: case DC_ACTION_MISSILE_MOVE:
      global.dcg_button_avail_mask &= ~moves;
      break;
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
  } else {
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

function dc_p_find_enemy_best_path(dca_monst, dca_array_a, dca_array_b, dca_ctrl) {
  var gx = dca_monst.dci_now_gx;
  var gy = dca_monst.dci_now_gy;
  var original_range = dca_array_a[@ gx, gy] % 9000000;
  var smallest_range = original_range;
  var smallest_range_gx = -1;
  var smallest_range_gy = -1;
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      if ((dx == 0) && (dy == 0)) continue;
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
  }
  if (smallest_range == original_range) return false;
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
                                    DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH);
  }
  if (!ok2) {
    // Here we're using the DC_OBJECT_ENEMY1 grid
    // Pass in ctrl = 0 (DC_CTRL_NONE) for even monsters, 1 (DC_CTRL_USE_FIRST_BEST_PATH) for odd
    // This mean a given monster will, when there are multiple best paths, deterministically
    // select the first one found or the last one found.
    var ok1 = dc_p_find_enemy_best_path(dca_monst, global.dcg_range_grid1, global.dcg_range_grid2,
                                        (dca_monst.dci_which % 2));
  }
  with (dca_monst) {
    return ((dci_now_gx != dci_nxt_gx) || (dci_now_gy != dci_nxt_gy));
  }
}


function dc_step_drone() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_DRONE) return;  // Must be animating DRONE
  var stopped = dc_p_set_speed_direction(10, false);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_missile() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_MISSILE) return;  // Must be animating MISSILE
  var stopped = dc_p_set_speed_direction(25, true);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_human() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_HUMAN) return;  // Must be animating HUMAN
  var stopped = dc_p_set_speed_direction(3, false);
  // Humans go via the drone gx/gy, in which case maybe they've not really stoppped
  if ((stopped) && (dc_p_go_via(self))) stopped = false;
  if (!stopped) return;
  dc_p_clear_via(self);
  dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_laser() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_LASER) return;  // Must be animating LASER
  var stopped = dc_p_set_speed_direction(100, false);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_field() {
  if (global.dcg_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dcg_object_animate != DC_OBJECT_FIELD) return;  // Must be animating FIELD
  var stopped = dc_p_set_speed_direction(10, false);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_enemy_PREV() {
  if (global.dcg_state != DC_STATE_ENEMY_ANIMATE) return;  // Must be in STATE EnemyAnimate
  // if (global.dcg_object_animate != DC_OBJECT_ENEMY1) return;
  var stopped = dc_p_set_speed_direction(1, false);
  if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_enemy() {
  if ((global.dcg_state == DC_STATE_USER_ANIMATE_HIT) && (self.dci_obj_state == DC_OBJSTATE_DYING)) {
    self.dci_step++;
    if ((self.dci_step % 20) != 0) return;
    // Doing enemy HIT->DYING->DEAD animation
    // TODO:FIX For now just do a weird sprite sequence
    switch (self.sprite_index) {
      case spr_enemymelee:              self.sprite_index = spr_enemymeleeback; break;
      case spr_enemymeleeback:          self.sprite_index = spr_enemymelee2; break;
      case spr_enemyprojectileidle:     self.sprite_index = spr_enemyprojectileidleback; break;
      case spr_enemyprojectileidleback: self.sprite_index = spr_enemymelee2; break;
      case spr_enemymelee2:
        self.dci_obj_state = DC_OBJSTATE_DEAD;
        dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
        break;
    }
  } else if ((global.dcg_state == DC_STATE_ENEMY_ANIMATE) && (self.dci_obj_state == DC_OBJSTATE_ALIVE)) {
    // Moving enemy towards human
    var stopped = dc_p_set_speed_direction(1, false);
    if (stopped) dc_p_fsm(DC_EVENT_ANIMATE_ENDED);
  }
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
function dc_ev_draw_new_selection_line(dca_mouse_px, dca_mouse_py) {
  // CALLED when mouse enters any tile - only does stuff if state is Select
  if (global.dcg_state != DC_STATE_USER_SELECT) return;

  // Uses global state:
  // 1. dc_sel0_gx|gy - grid pos of active object (ie drone or missile) (may be -1/-1 if no selection)
  // 2. dc_sel1_gx|gy - grid pos of other end of selection line (may be identical to dc_sel0_gx|gy)

  // Map mouse pixel position to grid position
  var mouse_gx = dc_p_get_gx(dca_mouse_px);
  var mouse_gy = dc_p_get_gy(dca_mouse_py);
  if ((mouse_gx < 0) || (mouse_gy < 0)) return;
  show_debug_message("[{0},{1}]= OBJECTS={2} RANGE={3}/{4}", mouse_gx, mouse_gy,
                     global.dcg_object_grid[mouse_gx,mouse_gy],
                     global.dcg_range_grid1[mouse_gx,mouse_gy], global.dcg_range_grid2[mouse_gx,mouse_gy]);

  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0)) return;  // Bail if no sel0

  // If mouse still at sel1, bail, leaving sel1 unchanged
  if ((mouse_gx == global.dcg_sel1_gx) && (mouse_gy == global.dcg_sel1_gy)) return;

  // Now we find sel2_gx|gy - a possible NEW position value for sel1_gx|sel1_gy
  // We limit how far selection line extends based on the current action selected
  dc_p_find_sel2(mouse_gx, mouse_gy, global.dcg_limit_obj_mask[global.dcg_object_action],
                 global.dcg_max_distance[global.dcg_object_action]);
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

function dc_ev_select_dest(dca_mouse_px, dca_mouse_py) {
  // Called on mouse release if on tile NOT on button - only does stuff if state is USER_SELECT
  if (global.dcg_state != DC_STATE_USER_SELECT) return;
  // Only does stuff if an object has been selected
  if ((global.dcg_object_move < DC_OBJECT_DRONE) || (global.dcg_object_move > DC_OBJECT_FIELD)) return;
  // Only does stuff if valid sel0 and sel1
  if ((global.dcg_sel0_gx < 0) || (global.dcg_sel0_gy < 0) || (global.dcg_sel1_gx < 0) || (global.dcg_sel1_gy < 0)) return;
  // Only does stuff if sel0 != sel1
  if ((global.dcg_sel0_gx == global.dcg_sel1_gx) && (global.dcg_sel0_gy == global.dcg_sel1_gy)) return;

  // Clear existing selection - but leave sel1 as is until installed in selected object
  dc_p_selection_onoff(global.dcg_sel0_gx, global.dcg_sel0_gy, global.dcg_sel1_gx, global.dcg_sel1_gy, false);

  // Setup nxt_gx/gy coords from sel1_gx/gy
  var inst = dc_p_find_instance(global.dcg_object_move, 0);
  if (inst != noone) {
    inst.dci_nxt_gx = global.dcg_sel1_gx;
    inst.dci_nxt_gy = global.dcg_sel1_gy;

    if (inst.dci_obj_type == DC_OBJECT_HUMAN) {
      // ... but human goes via DRONE gx/gy before going to sel1 gx/gy
      var drone = dc_p_find_instance(DC_OBJECT_DRONE, 0);
      if (drone != noone) {
        inst.dci_nxt_gx = drone.dci_now_gx;
        inst.dci_nxt_gy = drone.dci_now_gy;
        inst.dci_via_gx[0] = drone.dci_now_gx;
        inst.dci_via_gy[0] = drone.dci_now_gy;
        inst.dci_via_gx[1] = global.dcg_sel1_gx;
        inst.dci_via_gy[1] = global.dcg_sel1_gy;
      }
    }
  }
  // Report destination selected
  dc_p_fsm(DC_EVENT_DEST_SELECTED);
}

function dc_ev_button_action(dca_obj_action, dca_ui_action, dca_spr_on, dca_spr_off, dca_spr_hov, dca_spr_unav) {
  // Called when any action button clicked - only does stuff if state is USER_SELECT
  if (global.dcg_state != DC_STATE_USER_SELECT) return;
  // Clear any existing selection line
  dc_p_clear_selection_line();
  // Bail if this button's sprite has been set to the 'unavailable' sprite
  if (sprite_index == dca_spr_unav) return;

  if (dca_ui_action == DC_ACTION_ENTER) {
    sprite_index = dca_spr_hov;

  } else if (dca_ui_action == DC_ACTION_CLICK) {
    // If clicked action NOT already selected, DO select otherwise DO deselect
    var cur_obj_act = global.dcg_object_action;
    var new_obj_act = dca_obj_action;
    if (cur_obj_act == new_obj_act) new_obj_act = DC_ACTION_NONE;  // Deselect ==> no action

    // Select
    var new_obj_move = DC_OBJECT_NONE;
    var new_obj_sel_base = DC_OBJECT_NONE;
    switch (new_obj_act) {
      case DC_ACTION_MISSILE_MOVE: new_obj_sel_base = DC_OBJECT_MISSILE; new_obj_move = DC_OBJECT_MISSILE; break;
      case DC_ACTION_DRONE_MOVE:   new_obj_sel_base = DC_OBJECT_DRONE; new_obj_move = DC_OBJECT_DRONE; break;
      case DC_ACTION_DRONE_HUMAN:  new_obj_sel_base = DC_OBJECT_DRONE; new_obj_move = DC_OBJECT_HUMAN; break;
      case DC_ACTION_DRONE_LASER:  new_obj_sel_base = DC_OBJECT_DRONE; new_obj_move = DC_OBJECT_LASER; break;

      case DC_ACTION_DRONE_FIELD:
      case DC_ACTION_NONE:
      default:
        // new_obj_sel_base = DC_OBJECT_DRONE;
        break;
    }
    global.dcg_object_sel_base = new_obj_sel_base;
    global.dcg_object_move = new_obj_move;
    global.dcg_object_action = new_obj_act;

    dc_p_button_control();

    dc_p_fsm(DC_EVENT_OBJECT_SELECTED);  // Report object selected

    // TODO: MAYBE NEED TO CREATE OBJECTS HERE???


    // If clicked object NOT already selected, DO select otherwise DO deselect and go back to selecting DRONE
    // var cur_obj_sel = global.dcg_object_selected;
    // var new_obj_sel = (dca_obj_action == cur_obj_sel) ?DC_OBJECT_DRONE :dca_obj_action;
    // if (cur_obj_sel != new_obj_sel) {
    //  var inst = dc_p_find_instance(new_obj_sel, 0);
    //  if (inst != noone) {
    //    global.dcg_object_selected = new_obj_sel;
    //    show_debug_message("CLICK {0}=[{1},{2}]", dc_p_get_name(new_obj_sel), inst.dci_now_gx, inst.dci_now_gy);
    //  }
    //  dc_p_button_control();
    // }
    // dc_p_fsm(DC_EVENT_OBJECT_SELECTED);  // Report object selected

  } else if (dca_ui_action == DC_ACTION_EXIT) {
    sprite_index = (dca_obj_action == global.dcg_object_action) ?dca_spr_on :dca_spr_off;
  }
}





//
// BUGS:
//  A. MissileMove is an ACTION!
//  B. Missile/Laser will kill HUMAN
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
//
// THINGS LEFT TO DO:
// 14a. Support 'TurnEnd' button
// 14b. Handle missile/drone at same location - use invisible missile sprite if so
// 14c. Allow extra missile move if initial deploy from drone
// 15. Enemies should use either field-aware range maps or field-oblivious range maps
//
// 16. Add end game detection logic
// 17. Add README
//
// MAYBE:
// 18. Use int64
// 19. Maybe munge gx|gy into a single gxy (1000gx+gy if debug, gx<<8|gy if not)
// 20. Keep gxy within instance - use dci_now_gxy and dci_nxt_gxy instance vars
//


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
