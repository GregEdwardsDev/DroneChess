// Old junk - DELETE!
global.deprecated_grid_min_x = 64;
global.deprecated_grid_min_y = 320;
global.deprecated_grid_x_cells = 12;
global.deprecated_grid_y_cells = 12;
global.deprecated_grid_cell_width = 64;
global.deprecated_grid_cell_height = 64;
global.deprecated_grid_min_distance = 8;
global.deprecated_grid_max_x = global.deprecated_grid_min_x + (global.deprecated_grid_x_cells * global.deprecated_grid_cell_width) - 1;
global.deprecated_grid_max_y = global.deprecated_grid_min_y + (global.deprecated_grid_y_cells * global.deprecated_grid_cell_height) - 1;
global.deprecated_last_mouse_click_grid_x = -1;
global.deprecated_last_mouse_click_grid_y = -1;
global.deprecated_selected_grid_x = -1;
global.deprecated_selected_grid_y = -1;
global.deprecated_grid_built = false;
global.deprecated_grid[0,0] = noone;
global.deprecated_last_tile_exit_pix_x = -1;
global.deprecated_last_tile_exit_pix_y = -1;


// Globals to track objects at each grid location
global.dc_grid_built = false;
global.dc_grid[0,0] = noone;

// Stuff to make grid x/y to pixel x/y and vice versa
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

// 0=None 1=Select 2=Animate
global.dc_state = 1;  // TEMP

// 0=None 1=Drone 2=Missile 3=Human 4=Laser 5=Enemy
global.dc_object_selected = 1;  // TEMP
global.dc_object_animate = 0;
