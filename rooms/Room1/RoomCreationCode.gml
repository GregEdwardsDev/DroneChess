
// Globals to track objects at each grid location
global.dc_grid_built = false;
global.dc_grid[0,0] = noone;

// Global variables to track whether certain buttons are available or not
global.dc_button_laser_available = true;
global.dc_button_missile_available = true;
global.dc_button_field_available = true;
global.dc_button_displace_available = true;

// Stuff to map grid x/y to pixel x/y and vice versa
global.dc_grid_x_cells = 12;
global.dc_grid_y_cells = 12;
global.dc_grid_cell_width = 32;
global.dc_grid_cell_height = 32;
global.dc_grid_cell_height_offset = global.dc_grid_cell_height / 2;
global.dc_grid_min_distance = 1;
global.dc_grid_min_px = 0;
global.dc_grid_min_py = 128;
global.dc_grid_max_px = global.dc_grid_min_px + (global.dc_grid_x_cells * global.dc_grid_cell_width) - 1;
global.dc_grid_max_py = global.dc_grid_min_py + (global.dc_grid_y_cells * global.dc_grid_cell_height) - 1;

// Grid x/y locations for selection line
global.dc_sel0_gx = 4;  // TEMP
global.dc_sel0_gy = 3;  // TEMP
global.dc_sel1_gx = -1;
global.dc_sel1_gy = -1;
global.dc_sel2_gx = -1;
global.dc_sel2_gy = -1;
global.dc_sel_line_limited = true;

// Grid x/y locations for laser/missile/field/displace(aka human)/drone (TODO: should work these out!)
global.dc_laser_gx = -1;
global.dc_laser_gy = -1;
global.dc_missile_gx = 5;  // TEMP
global.dc_missile_gy = 1;  // TEMP
global.dc_field_gx = -1;
global.dc_field_gy = -1;
global.dc_displace_gx = 3;  // TEMP
global.dc_displace_gy = 6;  // TEMP
global.dc_drone_gx = 4;  // TEMP
global.dc_drone_gy = 3;  // TEMP


// STATES: 0=None 1=GameStart 2=TurnStart 3=UserSelect 4=UserAnimate 5=EnemyAnimate 6=TurnEnd 7=GameEnd
#macro DC_STATE_NONE 0
#macro DC_STATE_GAME_START 1
#macro DC_STATE_TURN_START 2
#macro DC_STATE_USER_SELECT 3
#macro DC_STATE_USER_ANIMATE 4
#macro DC_STATE_ENEMY_ANIMATE 5
#macro DC_STATE_TURN_END 6
#macro DC_STATE_GAME_END 7
global.dc_state = DC_STATE_USER_SELECT;  // TEMP

// EVENTS: 0=None 1=EnterState 2=ObjectSelected 3=DestSelected 4=TurnFinished 5=AnimateEnded
#macro DC_EVENT_NONE 0
#macro DC_EVENT_ENTER_STATE 1
#macro DC_EVENT_OBJECT_SELECTED 2
#macro DC_EVENT_DEST_SELECTED 3
#macro DC_EVENT_TURN_FINISHED 4
#macro DC_EVENT_ANIMATE_ENDED 5

// OBJECTS: 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Enemy
#macro DC_OBJECT_NONE 0
#macro DC_OBJECT_DRONE 1
#macro DC_OBJECT_MISSILE 2
#macro DC_OBJECT_HUMAN 3
#macro DC_OBJECT_LASER 4
#macro DC_OBJECT_FIELD 5
#macro DC_OBJECT_ENEMY 6
#macro DC_OBJECT_DISPLACE DC_OBJECT_HUMAN
global.dc_object_selected = DC_OBJECT_DRONE;  // TEMP
global.dc_object_animate = DC_OBJECT_NONE;

// ACTIONS: 0=None 1=MouseEnter 2=MouseClick 3=MouseExit
#macro DC_ACTION_NONE 0
#macro DC_ACTION_ENTER 1
#macro DC_ACTION_CLICK 2
#macro DC_ACTION_EXIT 3
