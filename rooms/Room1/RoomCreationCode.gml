
// Globals to track objects at each grid location
global.dcg_objects_found = false;
global.dcg_wall_grid_built = false;
global.dcg_tile_grid_built = false;
global.dcg_wall_grid[0,0] = false;
global.dcg_tile_grid[0,0] = noone;
global.dcg_object_grid[0,0] = 0;
global.dcg_range_grid1[0,0] = 0;
global.dcg_range_grid2[0,0] = 0;
#macro DC_CTRL_NONE                          0
#macro DC_CTRL_USE_FIRST_BEST_PATH           1
#macro DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH 2


// Global array to track whether certain buttons are available or not
// OBJECTS: 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Field 6=Enemy1(Melee) 7=Enemy2(Projectile)
global.dcg_button_available[0] = false;

// Stuff to map grid x/y to pixel x/y and vice versa
global.dcg_grid_invalid = 999;
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
global.dcg_sel_line_limited = true;


// STATES: 0=None 1=GameStart 2=TurnStart 3=UserSelect 4=UserAnimate 5=EnemyAnimate 6=TurnEnd 7=GameEnd
#macro DC_STATE_NONE 0
#macro DC_STATE_GAME_START 1
#macro DC_STATE_TURN_START 2
#macro DC_STATE_USER_SELECT 3
#macro DC_STATE_USER_ANIMATE 4
#macro DC_STATE_ENEMY_ANIMATE 5
#macro DC_STATE_TURN_END 6
#macro DC_STATE_GAME_END 7
global.dcg_state = DC_STATE_NONE;

// EVENTS: 0=None 1=EnterState 2=ObjectSelected 3=DestSelected 4=TurnFinished 5=AnimateEnded
#macro DC_EVENT_NONE 0
#macro DC_EVENT_ENTER_STATE 1
#macro DC_EVENT_OBJECT_SELECTED 2
#macro DC_EVENT_DEST_SELECTED 3
#macro DC_EVENT_TURN_FINISHED 4
#macro DC_EVENT_ANIMATE_ENDED 5

// OBJECTS: 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Field 6=Enemy1(Melee) 7=Enemy2(Projectile)
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
global.dcg_object_selected = DC_OBJECT_NONE;
global.dcg_object_animate = DC_OBJECT_NONE;
global.dcg_objects_animating = 0;

// UI ACTIONS: 0=None 1=MouseEnter 2=MouseClick 3=MouseExit
#macro DC_ACTION_NONE 0
#macro DC_ACTION_ENTER 1
#macro DC_ACTION_CLICK 2
#macro DC_ACTION_EXIT 3

// Call into FSM to set initial state
dc_p_fsm_room_start();
