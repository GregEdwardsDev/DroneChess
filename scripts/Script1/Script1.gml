// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

//
// PRIVATE FUNCTIONS - these not called directly from GameMaker events
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
// STATE FUNCTIONS
//
function dc_i_fsm_debug(dc_event) {
  // show_debug_message("DEBUG: State={0} Event={1}", global.dc_state, dc_event);
}

function dc_i_fsm(dc_event) {
  dc_i_fsm_debug(dc_event);
  switch (global.dc_state) {
    case DC_STATE_GAME_START:    dc_i_fsm_game_start(dc_event); return;
    case DC_STATE_TURN_START:    dc_i_fsm_turn_start(dc_event); return;
    case DC_STATE_USER_SELECT:   dc_i_fsm_user_select(dc_event); return;
    case DC_STATE_USER_ANIMATE:  dc_i_fsm_user_animate(dc_event); return;
    case DC_STATE_ENEMY_ANIMATE: dc_i_fsm_enemy_animate(dc_event); return;
    case DC_STATE_TURN_END:      dc_i_fsm_turn_end(dc_event); return;
    case DC_STATE_GAME_END:      dc_i_fsm_game_end(dc_event); return;
    default: dc_i_fsm_state_invalid(dc_event); return;
  }
}
function dc_i_fsm_game_start(dc_event) {
  // Setup overall game state
  global.dc_state = DC_STATE_TURN_START;
  dc_i_fsm(DC_EVENT_ENTER_STATE);
}
function dc_i_fsm_turn_start(dc_event) {
  // Setup room state
  global.dc_state = DC_STATE_USER_SELECT;
  dc_i_fsm(DC_EVENT_ENTER_STATE);
}
function dc_i_fsm_user_select(dc_event) {
  if (dc_event == DC_EVENT_OBJECT_SELECTED) {
  }
  if (dc_event == DC_EVENT_DEST_SELECTED) {
    global.dc_object_animate = global.dc_object_selected;
    global.dc_state = DC_STATE_USER_ANIMATE;
    dc_i_fsm(DC_EVENT_ENTER_STATE);
  }
}
function dc_i_fsm_user_animate(dc_event) {
  if (dc_event == DC_EVENT_ANIMATE_ENDED) {
    global.dc_state = DC_STATE_USER_SELECT;
    dc_i_fsm(DC_EVENT_ENTER_STATE);
  }
}
function dc_i_fsm_enemy_animate(dc_event) {
}
function dc_i_fsm_turn_end(dc_event) {
}
function dc_i_fsm_game_emd(dc_event) {
}
function dc_i_fsm_state_invalid(dc_event) {
  dc_i_fsm_debug(dc_event);
}



function dc_i_coords_read() {
  // Read sel0_gx/gy back into specific object gx/gy coords
  var gx = global.dc_sel0_gx;
  var gy = global.dc_sel0_gy;
  switch (global.dc_object_selected) {
    case DC_OBJECT_DRONE:    global.dc_drone_gx = gx;    global.dc_drone_gy = gy;    break;
    case DC_OBJECT_MISSILE:  global.dc_missile_gx = gx;  global.dc_missile_gy = gy;  break;
    case DC_OBJECT_DISPLACE: global.dc_displace_gx = gx; global.dc_displace_gy = gy; break;
    case DC_OBJECT_LASER:    global.dc_laser_gx = gx;    global.dc_laser_gy = gy;    break;
    case DC_OBJECT_FIELD:    global.dc_field_gx = gx;    global.dc_field_gy = gy;    break;
  }
  global.dc_sel0_gx = -1;
  global.dc_sel0_gy = -1;
}
function dc_i_coords_write() {
  // Write specific object gx/gy coords into sel0_gx/gy to allow object to be moved
  var gx = -1;
  var gy = -1;
  switch (global.dc_object_selected) {
    case DC_OBJECT_DRONE:    gx = global.dc_drone_gx;    gy = global.dc_drone_gy;    break;
    case DC_OBJECT_MISSILE:  gx = global.dc_missile_gx;  gy = global.dc_missile_gy;  break;
    case DC_OBJECT_DISPLACE: gx = global.dc_displace_gx; gy = global.dc_displace_gy; break;
    case DC_OBJECT_LASER:    gx = global.dc_laser_gx;    gy = global.dc_laser_gy;    break;
    case DC_OBJECT_FIELD:    gx = global.dc_field_gx;    gy = global.dc_field_gy;    break;
  }
  global.dc_sel0_gx = gx;
  global.dc_sel0_gy = gy;
}

// Call this function to enable/disable buttons - honours true/false vals in global.dc_button_XX_available
function dc_i_button_control() {
  if (global.dc_button_laser_available) {
    obj_buttonlaser.sprite_index = (global.dc_object_selected == DC_OBJECT_LASER) ?spr_buttonlaserOn :spr_buttonlaserOff;
  } else {
    obj_buttonlaser.sprite_index = spr_buttonlaserUnav;
  }
  if (global.dc_button_missile_available) {
    obj_buttonmissile.sprite_index = (global.dc_object_selected == DC_OBJECT_MISSILE) ?spr_buttonmissileOn :spr_buttonmissileOff;
  } else {
    obj_buttonmissile.sprite_index = spr_buttonmissileUnav;
  }
  if (global.dc_button_field_available) {
    obj_buttonfield.sprite_index = (global.dc_object_selected == DC_OBJECT_FIELD) ?spr_buttonfieldOn :spr_buttonfieldOff;
  } else {
    obj_buttonfield.sprite_index = spr_buttonfieldUnav;
  }
  if (global.dc_button_displace_available) {
    obj_buttondisplace.sprite_index = (global.dc_object_selected == DC_OBJECT_DISPLACE) ?spr_buttondisplaceOn :spr_buttondisplaceOff;
  } else {
    obj_buttondisplace.sprite_index = spr_buttondisplaceUnav;
  }
}


//
// STEP FUNCTIONS and STEP UTILITY FUNCTIONS
//
function dc_i_set_speed_direction(spd) {
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

function dc_step_drone() {
  if (global.dc_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dc_object_animate != DC_OBJECT_DRONE) return;  // Must be animating DRONE
  dc_i_set_speed_direction(10);
  if (speed == 0) dc_i_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_missile() {
  if (global.dc_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dc_object_animate != DC_OBJECT_MISSILE) return;  // Must be animating DRONE
  dc_i_set_speed_direction(50);
  if (speed == 0) dc_i_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_human() {
  if (global.dc_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dc_object_animate != DC_OBJECT_HUMAN) return;  // Must be animating DRONE
  dc_i_set_speed_direction(5);
  if (speed == 0) dc_i_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_laser() {
  if (global.dc_state != DC_STATE_USER_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dc_object_animate != DC_OBJECT_LASER) return;  // Must be animating DRONE
  dc_i_set_speed_direction(100);
  if (speed == 0) dc_i_fsm(DC_EVENT_ANIMATE_ENDED);
}
function dc_step_enemy() {
  if (global.dc_state != DC_STATE_ENEMY_ANIMATE) return;  // Must be in STATE UserAnimate
  if (global.dc_object_animate != DC_OBJECT_ENEMY) return;  // Must be animating DRONE
  dc_i_set_speed_direction(1);
  if (speed == 0) dc_i_fsm(DC_EVENT_ANIMATE_ENDED);
}





//
// EVENT HANDLERS and EVENT HANDLER UTILITY FUNCTIONS
//
function dc_i_clear_selection_line() {
  // Clear existing selection if we have one
  dc_i_selection_onoff(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel1_gy, false);
  // Invalidate sel1
  global.dc_sel1_gx = -1;
  global.dc_sel1_gy = -1;
}
function dc_ev_draw_new_selection_line(mouse_px, mouse_py) {
  // CALLED when mouse enters any tile - only does stuff if state is Select
  if (global.dc_state != DC_STATE_USER_SELECT) return;

  // Uses global state:
  // 1. dc_sel0_gx|gy - grid pos of active object (ie drone or missile) (may be -1/-1 if no selection)
  // 2. dc_sel1_gx|gy - grid pos of other end of selection line (may be identical to dc_sel0_gx|gy)
  // 3. dc_sel_line_limited - whether selection line should be limited by walls/obstacles
  dc_i_make_instance_grid();  // only builds grid the first time

  // Map mouse pixel position to grid position
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

function dc_ev_select_dest(mouse_px, mouse_py) {
  // Called on mouse release if on tile NOT on button - only does stuff if state is USER_SELECT
  if (global.dc_state != DC_STATE_USER_SELECT) return;
  // Only does stuff if an object has been selected
  if ((global.dc_object_selected < DC_OBJECT_DRONE) || (global.dc_object_selected > DC_OBJECT_FIELD)) return;
  // Only does stuff if valid sel0 and sel1
  if ((global.dc_sel0_gx < 0) || (global.dc_sel0_gy < 0) || (global.dc_sel1_gx < 0) || (global.dc_sel1_gy < 0)) return;
  // Only does stuff if sel0 != sel1
  if ((global.dc_sel0_gx == global.dc_sel1_gx) && (global.dc_sel0_gy == global.dc_sel1_gy)) return;

  // Clear existing selection - but leave sel1 as is for animation
  dc_i_selection_onoff(global.dc_sel0_gx, global.dc_sel0_gy, global.dc_sel1_gx, global.dc_sel1_gy, false);

  // Report destination selected
  dc_i_fsm(DC_EVENT_DEST_SELECTED);
}

function dc_ev_button_action(dc_obj_this, dc_action, dc_spr_on, dc_spr_off, dc_spr_hov, dc_spr_unav) {
  // Called when any action button clicked - only does stuff if state is USER_SELECT
  if (global.dc_state != DC_STATE_USER_SELECT) return;
  // Clear any existing selection line
  dc_i_clear_selection_line();
  // Bail if this button's sprite has been set to the 'unavailable' sprite
  if (sprite_index == dc_spr_unav) return;

  if (dc_action == DC_ACTION_ENTER) {
    sprite_index = dc_spr_hov;

  } else if (dc_action == DC_ACTION_CLICK) {
    // Stash old sel0_gx/gy coords back into old object
    dc_i_coords_read();
    // If clicked object NOT already selected, DO select otherwise DO deselect and go back to selecting DRONE
    var cur_obj_sel = global.dc_object_selected;
    var new_obj_sel = (dc_obj_this == cur_obj_sel) ?DC_OBJECT_DRONE :dc_obj_this;
    if (cur_obj_sel != new_obj_sel) {
      // Setup new sel0_gx/gy coords from new object
      global.dc_object_selected = new_obj_sel;
      dc_i_coords_write();
      dc_i_button_control();
    }
    // dc_i_fsm(DC_EVENT_OBJECT_SELECTED);  // Report object selected

  } else if (dc_action == DC_ACTION_EXIT) {
    sprite_index = (dc_obj_this == global.dc_object_selected) ?dc_spr_on :dc_spr_off;
  }
}



function dc_ev_select_object_DEPRECATED(which) {
  // TODO: !!!!!!!!!!! Should 'grey' out buttons if not available !!!!!!!!!!
  // CALLED on button press - only does stuff if state is Select
  if (global.dc_state != DC_STATE_USER_SELECT) return;

  // 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Enemy
  if ((which < 1) || (which > 4)) return;
  global.dc_object_selected = which;

  // Report object selected
  dc_i_fsm(DC_EVENT_OBJECT_SELECTED);
}


//
// THINGS LEFT TO DO:
//
// 1. Figure out location of drone/human etc dynamically from room config
// 2. Figure out monster locations dynamically (2 flavours)
// 3. Add logic to animate monsters somewhat - just head to human if space avail
// 4. Add turn taking, player->monsters->player->monsters
// 5. Add player getting movement plus action in one turn
// 6. SelectionLine should be configurable to disallow going thru walls etc
// 7. Add smart monster movement - melee vs ranged grids - update post player turn
// 8. Add collision/end game detection logic
