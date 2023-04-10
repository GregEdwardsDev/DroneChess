
// Globals to track objects at each grid location
global.dcg_objects_found = false;
global.dcg_wall_grid_built = false;
global.dcg_tile_grid_built = false;
global.dcg_wall_grid[0,0] = false;
global.dcg_tile_grid[0,0] = noone;
global.dcg_inst_grid[0,0] = noone;
global.dcg_object_grid[0,0] = 0;
global.dcg_range_grid1[0,0] = 0;
global.dcg_range_grid2[0,0] = 0;
#macro DC_CTRL_NONE                          0
#macro DC_CTRL_USE_FIRST_BEST_PATH           1
#macro DC_CTRL_RETURN_IF_NO_SINGLE_BEST_PATH 2


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


// STATES: 0=None 1=GameStart 2=TurnStart 3=UserSelect 4=UserAnimate 5=EnemyAnimate 6=TurnEnd 7=GameEnd
#macro DC_STATE_NONE 0
#macro DC_STATE_GAME_START 1
#macro DC_STATE_TURN_START 2
#macro DC_STATE_USER_SELECT 3
#macro DC_STATE_USER_ANIMATE 4
#macro DC_STATE_USER_ANIMATE_HIT 5
#macro DC_STATE_ENEMY_ANIMATE 6
#macro DC_STATE_TURN_END 7
#macro DC_STATE_GAME_END 8
global.dcg_state = DC_STATE_NONE;

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
global.dcg_enemies_dying = 0;

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


// Call into FSM to set initial state
dc_p_fsm_room_start();
