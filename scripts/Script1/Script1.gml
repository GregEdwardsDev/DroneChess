// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Script1(){
}

//
// PRIVATE FUNCTIONS
//
function dc_i_make_instance_grid() {
  if (global.dc_grid_built) return;
  for (var i = 0; i < global.dc_grid_x_cells; i++) {
    var px = (i * global.dc_grid_cell_width) + global.dc_grid_min_px;
    for (var j = 0; j < global.dc_grid_y_cells; j++) {
      var py = (j * global.dc_grid_cell_height) + global.dc_grid_min_py;
      var inst = instance_nearest(px, py, obj_tilewhite);
      global.dc_grid[i, j] = inst;
    }
  }
  global.dc_grid_built = true;
}

function dc_i_find_delta(a, b) {
  var delta = b - a;
  if (delta < 0) return -1;
  if (delta > 0) return 1;
  return 0;  // a == b
}
function dc_i_selection_onoff(start_gx, start_gy, end_gx, end_gy, lighton) {
  if ((global.dc_sel0_gx < 0) || (global.dc_sel0_gy < 0)) return;  // Bail if no sel0
  if ((start_gx < 0) || (start_gy < 0) || (end_gx < 0) || (end_gy < 0)) return;
  // Go from (start_gx,start_gy) --> (end_gx,end_gy) lighting or unlighting cells
  var delta_gx = dc_i_find_delta(start_gx, end_gx);
  var delta_gy = dc_i_find_delta(start_gy, end_gy);
  var tmp_gx = start_gx;
  var tmp_gy = start_gy;
  while (true) {
    // Check below should not be needed - but just in case
    if ((tmp_gx < 0) || (tmp_gx >= global.dc_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dc_grid_y_cells)) {
      break;
    }
    if ((tmp_gx == global.dc_sel0_gx) && (tmp_gy == global.dc_sel0_gy)) {
      // Never touch sel0
    } else {
      // But other tiles are fair game
      var inst = global.dc_grid[tmp_gx, tmp_gy];
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

function dc_i_same_line(g1_gx, g1_gy, g2_gx, g2_gy) {
  if ((g1_gx < 0) || (g1_gy < 0) || (g2_gx < 0) || (g2_gy < 0)) return false;
  if (g1_gx == g2_gx) return true;
  if (g1_gy == g2_gy) return true;
  if (abs(g1_gx - g2_gx) == abs(g1_gy - g2_gy)) return true;
  return false;
}
function dc_i_same_line_as_sel0(gx, gy) {
  return dc_i_same_line(global.dc_sel0_gx, global.dc_sel0_gy, gx, gy);
}
function dc_i_direction(g1_gx, g1_gy, g2_gx, g2_gy) {
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
function dc_i_direction_from_sel0(gx, gy) {
  return dc_i_direction(global.dc_sel0_gx, global.dc_sel0_gy, gx, gy);
}
function dc_i_same_line_012(g0_gx, g0_gy, g1_gx, g1_gy, g2_gx, g2_gy) {
  // Check if points 0, 1, 2 on same line in order 0->1->2
  if ((g0_gx < 0) || (g0_gy < 0) || (g1_gx < 0) || (g1_gy < 0) || (g2_gx < 0) || (g2_gy < 0)) return false;
  var dir01 = dc_i_direction(g0_gx, g0_gy, g1_gx, g1_gy);
  var dir12 = dc_i_direction(g1_gx, g1_gy, g2_gx, g2_gy);
  if ((dir01 > 0) && (dir01 == dir12)) return true;
  return false;
}
function dc_i_same_line_021(g0_gx, g0_gy, g1_gx, g1_gy, g2_gx, g2_gy) {
  // Check if points 0, 1, 2 on same line but now in order 0->2->1
  return dc_i_same_line_012(g0_gx, g0_gy, g2_gx, g2_gy, g1_gx, g1_gy);
}

function dc_i_find_sel2(mouse_gx, mouse_gy, limited) {
  global.dc_sel2_gx = -1;
  global.dc_sel2_gy = -1;
  if ((global.dc_sel0_gx < 0) || (global.dc_sel0_gy < 0)) return false;  // Bail if no sel0
  if (!dc_i_same_line_as_sel0(mouse_gx, mouse_gy)) return false;  // Mouse not on same row/col/diag as sel0
  // Start at global.dc_sel0
  // Apply delta_gx delta_gy until find obstacle/mouse (iff sel_line_limited) or find edge grid
  // Set sel2 (may end up SAME as sel0)
  var delta_gx = dc_i_find_delta(global.dc_sel0_gx, mouse_gx);
  var delta_gy = dc_i_find_delta(global.dc_sel0_gy, mouse_gy);
  var tmp_gx = global.dc_sel0_gx;
  var tmp_gy = global.dc_sel0_gy;
  var back_one_step = true;
  // show_debug_message("Sel0=[{0},{1}] Delta=[{2},{3}]", global.dc_sel0_gx, global.dc_sel0_gy, delta_gx, delta_gy);
  while (true) {
    tmp_gx += delta_gx;
    tmp_gy += delta_gy;
    if ((tmp_gx < 0) || (tmp_gx >= global.dc_grid_x_cells) || (tmp_gy < 0) || (tmp_gy >= global.dc_grid_y_cells)) {
      break;  // Gone too far so will go back one step

    } else if (limited) {
      if ((tmp_gx == mouse_gx) && (tmp_gy == mouse_gy)) {
        back_one_step = false;  // Got to mouse pos so NO need to go back one step
        break;
      } else {
        var inst = global.dc_grid[tmp_gx, tmp_gy];
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
  global.dc_sel2_gx = tmp_gx;
  global.dc_sel2_gy = tmp_gy;
  // show_debug_message("Sel2=[{0},{1}]", global.dc_sel2_gx, global.dc_sel2_gy);
}


//
// EVENT HANDLERS
//
function dc_ev_draw_new_selection_line(mouse_px, mouse_py) {
  // CALLED when mouse enters any tile - only does stuff if state is Select
  if (global.dc_state != 1) return;

  // Uses global state:
  // 1. dc_sel0_gx|gy - grid pos of active object (ie drone or missile) (may be -1/-1 if no selection)
  // 2. dc_sel1_gx|gy - grid pos of other end of selection line (may be identical to dc_sel0_gx|gy)
  // 3. dc_sel_line_limited - whether selection line should be limited by walls/obstacles
  dc_i_make_instance_grid();  // only builds grid the first time

  // Map mouse pixel postion to grid position
  if ((global.dc_sel0_gx < 0) || (global.dc_sel0_gy < 0)) return;  // Bail if no sel0
  if ((mouse_px < global.dc_grid_min_px) || (mouse_px > global.dc_grid_max_px)) return;  // Bail if bad x
  if ((mouse_py < global.dc_grid_min_py) || (mouse_py > global.dc_grid_max_py)) return;  // Bail if bad y
  var mouse_gx = (mouse_px - global.dc_grid_min_px) / global.dc_grid_cell_width;  // Map x to grid
  var mouse_gy = (mouse_py - global.dc_grid_min_py) / global.dc_grid_cell_height;  // Map y to grid

  // If mouse still at sel1, bail, leaving sel1 unchanged
  if ((mouse_gx == global.dc_sel1_gx) && (mouse_gy == global.dc_sel1_gy)) return;

  // Now we find sel2_gx|gy - a possible NEW position value for sel1_gx|sel1_gy
  dc_i_find_sel2(mouse_gx, mouse_gy, global.dc_sel_line_limited);
  // If new sel2 position same as previous sel1 position, bail
  if ((global.dc_sel2_gx == global.dc_sel1_gx) && (global.dc_sel2_gy == global.dc_sel1_gy)) return;

  if (dc_i_same_line_012(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel1_gy, global.dc_sel2_gx, global.dc_sel2_gy)) {
    // Sel1/Sel2 valid and new selection (sel2) in same N/ne/E/se/S/sw/W/nw direction as old (sel1) and further from sel0
    var delta_gx = dc_i_find_delta(global.dc_sel1_gx, global.dc_sel2_gx);
    var delta_gy = dc_i_find_delta(global.dc_sel1_gy, global.dc_sel2_gy);
    dc_i_selection_onoff(global.dc_sel1_gx + delta_gx, global.dc_sel1_gy + delta_gy, global.dc_sel2_gx, global.dc_sel2_gy, true);

  } else if (dc_i_same_line_021(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel1_gy, global.dc_sel2_gx, global.dc_sel2_gy)) {
    // Sel1/Sel2 valid and new selection (sel2) in same N/ne/E/se/S/sw/W/nw direction as old (sel1) but closer to sel0
    var delta_gx = dc_i_find_delta(global.dc_sel2_gx, global.dc_sel1_gx);
    var delta_gy = dc_i_find_delta(global.dc_sel2_gy, global.dc_sel1_gy);
    dc_i_selection_onoff(global.dc_sel2_gx + delta_gx, global.dc_sel2_gy + delta_gy, global.dc_sel1_gx, global.dc_sel1_gy, false);

  } else {
    // EITHER one/both of sel1/sel2 invalid OR new selection (sel2) in DIFF N/ne/E/se/S/sw/W/nw direction to old (sel1)
    // Unlight sel0->sel1 (does nothing if no sel1)
    dc_i_selection_onoff(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel1_gy, false);
    // Light sel0->sel2 (does nothing if no sel2)
    dc_i_selection_onoff(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel2_gx, global.dc_sel2_gy, true);
  }
  // Set sel1 <== sel2
  global.dc_sel1_gx = global.dc_sel2_gx;
  global.dc_sel1_gy = global.dc_sel2_gy;
}
function dc_ev_select_object(which) {
  // TODO: !!!!!!!!!!! Should 'grey' out buttons if not available !!!!!!!!!!
  // CALLED on button press - only does stuff if state is Select
  if (global.dc_state != 1) return;

  // 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Enemy
  if ((which < 1) || (which > 4)) return;
  global.dc_object_selected = which;
}
function dc_ev_select_dest() {
  // Called on mouse release if on tile NOT on button - only does stuff if state is Select
  if (global.dc_state != 1) return;
  // Only does stuff if an object has been selected
  if ((global.dc_object_selected < 1) || (global.dc_object_selected > 4)) return;
  // Only does stuff if valid sel0 and sel1
  if ((global.dc_sel0_gx < 0) || (global.dc_sel0_gy < 0) || (global.dc_sel1_gx < 0) || (global.dc_sel1_gy < 0)) return;
  // Only does stuff if sel0 != sel1
  if ((global.dc_sel0_gx == global.dc_sel1_gx) && (global.dc_sel0_gy == global.dc_sel1_gy)) return;

  // Clear existing selection
  dc_i_selection_onoff(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel1_gy, false);

  // Any go to animate state
  dc_state_animate();
}


//
// STATE FUNCTIONS
//
function dc_state_select() {
  global.dc_state = 1;
  global.dc_object_animate = 0;
}
function dc_state_animate() {
  global.dc_state = 2;
  global.dc_object_animate = global.dc_object_selected;
}


//
// STEP FUNCTIONS
//
function dc_step_drone() {
  if (global.dc_object_animate != 1) return;
  dc_set_speed_direction(10);
  if (speed == 0) dc_state_select();
}
function dc_step_missile() {
  if (global.dc_object_animate != 2) return;
  dc_set_speed_direction(50);
  if (speed == 0) dc_state_select();
}
function dc_step_human() {
  if (global.dc_object_animate != 3) return;
  dc_set_speed_direction(5);
  if (speed == 0) dc_state_select();
}
function dc_step_laser() {
  if (global.dc_object_animate != 4) return;
  dc_set_speed_direction(100);
  if (speed == 0) dc_state_select();
}
function dc_step_enemy() {
  if (global.dc_object_animate != 5) return;
  dc_set_speed_direction(1);
  if (speed == 0) dc_state_select();
}




function dc_set_speed_direction(spd) {
  if ((global.dc_sel0_gx < 0) || (global.dc_sel0_gy < 0) || (global.dc_sel1_gx < 0) || (global.dc_sel1_gy < 0)) return;
  if ((global.dc_sel0_gx == global.dc_sel1_gx) && (global.dc_sel0_gy == global.dc_sel1_gy)) return;
  // var sel0_px = global.dc_grid_min_px + (global.dc_sel0_gx * global.dc_grid_cell_width);
  // var sel0_py = global.dc_grid_min_py + (global.dc_sel0_gy * global.dc_grid_cell_height);
  var sel1_px = global.dc_grid_min_px + (global.dc_sel1_gx * global.dc_grid_cell_width);
  var sel1_py = global.dc_grid_min_py + (global.dc_sel1_gy * global.dc_grid_cell_height) - global.dc_grid_cell_height_offset;
  var pdist = point_distance(x, y, sel1_px, sel1_py);
  if (pdist < global.dc_grid_min_distance) {
    global.dc_sel0_gx = global.dc_sel1_gx;
    global.dc_sel0_gy = global.dc_sel1_gy;
    speed = 0;
  } else {
    speed = min(pdist, spd);  // This stops the object oscillating at its endpoint
    direction = point_direction(x, y, sel1_px, sel1_py);
  }
  // show_debug_message("Sel0=[{0},{1}] Sel1=[{2},{3}]  Dist={4} Speed={6}",
  //                   global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel2_gy, pdist, speed);
}
