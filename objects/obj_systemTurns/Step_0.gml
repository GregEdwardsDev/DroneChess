/// @description Insert description here
// You can write your code in this editor

global.playerTurn = true;
global.enemyTurn = false;

global.playerMoves = 1;
global.playerActions = 1;

// When the player takes their turn
if (global.playerTurn) {
    // Your code for the player's turn goes here
    // ...

    // End the player's turn and start the enemy's turn
    global.playerTurn = false;
    global.enemyTurn = true;
}

// When the enemy takes their turn
if (global.enemyTurn) {
    // Your code for the enemy's turn goes here
    // ...

    // End the enemy's turn and start the player's turn again
    global.enemyTurn = false;
    global.playerTurn = true;
	
	
}


//Check the player has used their move and actions

if global.playerMoves = 0 and global.playerActions = 0 {
	global.playerTurn = false;
	global.enemyTurn = true;
}