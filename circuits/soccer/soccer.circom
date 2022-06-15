pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/comparators.circom";

// Helper Template
//### TO DO ###


template Soccer() {
    signal input defenseField[9][9];
    signal input attackField[9][9];
    signal input goalMatrixDefense[3][3];
    signal input goalMatrixAttack[3][3];


    //Initialize attack and defense soccer fields positions with zero as value 
   //### TO DO ###

    //Initialize attack and defense Goal Matrix positions with zero as value 
    //### TO DO ###

    //Positioning Goal Keeper according choosen position
    //### TO DO ###
    
    //Place Defense Team Players on the Field 
    //### TO DO ###

    //Place Attack Team Players on the Field
    //### TO DO ###


    //Get choosen ball kick position
    //### TO DO ###

    //Compute and save Attack Team ball trajectory
    //### TO DO ###

    //Check for defense Interception of 2 types: 
    //1) Attack Player positioned same cell as Defensor out of defense goal area
    //2) Defense Player placed between ball trajectory
    //### TO DO ###

    //Check Penalty if //1) Attack Player positioned same cell as Defensor inside defense goal area
    //### TO DO ###

    //Check Goal
    //### TO DO ###
    





