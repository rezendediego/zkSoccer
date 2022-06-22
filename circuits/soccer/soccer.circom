/**
° ZKUniversity - Final Project circuit for Assignment 7 
° ZK-SOCCER 
° @author Diego Rezende | e-mail: diegorezende.ce@gmail.com   discord: diegorezende#2184
° June 6, 2022.
°
**/

/*

                            +---------------------------+    
                              |\                          |\   
                              | \    @ \_    /            | \
                              |  \  /  \_o--<_/           | o\
______________________________|___|/______________________|-|\|__________________
         /                   /    /              _ o     / /|_                /
        /                   /  _o'------------- / / \ ----/                  /
       /                   /  /|_                /\    /                    /
      /                   /_ /\ _______________ / / __/                    /
     /                      / /                                           /
    /                                                                    /
   /                                                                    /
  /                                                                    /
 /____________________________________________________________________/
 
.%%%%%%..%%..%%...%%%%....%%%%....%%%%....%%%%...%%%%%%..%%%%%..
....%%...%%.%%...%%......%%..%%..%%..%%..%%..%%..%%......%%..%%.
...%%....%%%%.....%%%%...%%..%%..%%......%%......%%%%....%%%%%..
..%%.....%%.%%.......%%..%%..%%..%%..%%..%%..%%..%%......%%..%%.
.%%%%%%..%%..%%...%%%%....%%%%....%%%%....%%%%...%%%%%%..%%..%%.
................................................................

Reference:
art_source: https://www.asciiart.eu/sports-and-outdoors/soccer
typography: https://www.askapache.com/online-tools/figlet-ascii/
*/

pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include RangeProof.circom

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Helper Template to organize soccer circuit input
template BUFFER(){
    signal input in;
    signal output out;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////





template Soccer() {
    /* <<<<< THE SOCCER FIELD IS A MATRIX 9x9 >>>>> */

    //PUBLIC SIGNALS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    //The value 0(zero) is a single Player against Autoplay adversary, 
    //while value 1 is a multiplayer game 
    signal input autoplay;

    //The value 0(zero) means that Player1 Attacks while Player2 or Generated Autoplay 
    //defends, while value 1 is represents the opposite turn. 
    signal input fieldLayerMode;
    
    
    
    //PRIVATE SIGNALS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    //Input signal for defense players on the field
    signal input defenseField[9][9];
    //Input signal for attack players on the field
    signal input attackField[9][9];


    //Flatened matrix holds position from Input signal for Goal Keeper body 
    //positioning while defending under the goal matrix
    signal input goalMatrixDefense[9];
    //Flatened matrix holds position Input signal for the goal kick  
    signal input goalMatrixAttack[9];


    // The Result Array is the final output of the game circuit after all checks 
    signal output result[5];
 

    //VARIABLES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    //Field Node Map to make easier some calculations
    var nodeMap[9][9] = [
	    [ 1,  2,  3,  4,  5,  6,  7,  8,  9],
	    [10, 11, 12, 13, 14, 15, 16, 17, 18],
	    [19, 20, 21, 22, 23, 24, 25, 26, 27],
	    [28, 29, 30, 31, 32, 33, 34, 35, 36],
	    [37, 38, 39, 40, 41, 42, 43, 44, 45],
	    [46, 47, 48, 49, 50, 51, 52, 53, 54],
	    [55, 56, 57, 58, 59, 60, 61, 62, 63],
	    [64, 65, 66, 67, 68, 69, 70, 71, 72],
	    [73, 74, 75, 76, 77, 78, 79, 80, 81]
    ]; 
    
    //Penalty Mark Area
    var penaltyAreaNodesLayer1[6] = [ 4,  5,  6, 13, 14, 15];
    var penaltyAreaNodesLayer2[6] = [67, 68, 69, 76, 77, 78];

    //Ball coordinates(x|ball[0], y|ball[1])
    var ball[2];

    // Player's position 
    // Defense Players (x|index_0, y|index_1) 
    var matrixPosDefensePlayer-01[2];
    var matrixPosDefensePlayer-02[2];
    var matrixPosDefensePlayer-03[2];

    // Attack Players (x|index_0, y|index_1)
    var matrixPosAttackPlayer-01[2];
    var matrixPosAttackPlayer-02[2];
    var matrixPosAttackPlayer-03[2];

    // Support for Penalty and Fault verification on the 3 moments of the match:
    // Transition: 1-->2,  2-->3, and 3-->GOAL, 
    var faultArray[3];
    var penaltyArray[3]; 

  

    //LOGIC COMPONENTS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        
    /* 
     ° ///////////////////////////////////////////////////////////////////////////////////////
     °  CIRCUIT'S COMPONENTS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><>>>>>>>>>>>>>>>>>>>>>>>>>>
     ° ///////////////////////////////////////////////////////////////////////////////////////   
    */

    /*
     ° INPUTs THAT FEED THE GAME AND TRIGGER GAMEPLAY CIRCUIT LOGIC VERIFICATIONS   
    */

    // A - BUFFER/YES - FAULT CONDITION. 
    // THE VALUE IS 1 IF FAULT IS DETECTED WHICH MEANS AN ATTACKER PLAYER IS POSITIONED 
    // AT SAME QUADRANT ALREADY OCCUPIED BY DEFFENSE PLAYER
    component BUFFER_A_Fault = BUFFER();
    
     
    // B - BUFFER/YES - INTERCEPTION POSITION 1 TO POSITION 2 CONDITION. 
    // THE VALUE IS 1 IF INTERCEPTION BY DEFENSOR IS DETECTED WHICH MEANS THAT THERE IS A DEFENSOR 
    // POSITIONED IN THE LINE OF PASS FROM POSITION 1 TO POSITION 2
    component BUFFER_B_Interception_1to2 = BUFFER();
    

    // C - BUFFER/YES - INTERCEPTION POSITION 2 TO POSITION 3 CONDITION. 
    // THE VALUE IS 1 IF INTERCEPTION BY DEFENSOR IS DETECTED WHICH MEANS THAT THERE IS A DEFENSOR 
    // POSITIONED IN THE LINE OF PASS FROM POSITION 2 TO POSITION 3
    component BUFFER_C_Interception_2to3 = BUFFER();
    

    // D - BUFFER/YES - INTERCEPTION POSITION 3 TO POSITION GOAL CONDITION. 
    // THE VALUE IS 1 IF INTERCEPTION BY DEFENSOR IS DETECTED WHICH MEANS THAT THERE IS A DEFENSOR 
    // POSITIONED IN THE LINE OF PASS FROM POSITION 3 TO POSITION GOAL
    component BUFFER_D_Interception_3toGoal = BUFFER();
    

    // E - BUFFER/YES - PENALTY CONDITION. 
    // THE VALUE IS 1 IF PENALTY IS DETECTED WHICH MEANS AN ATTACKER PLAYER IS POSITIONED 
    // AT SAME QUADRANT ALREADY OCCUPIED BY DEFFENSE PLAYER WITHIN THE PENALTY AREA
    component BUFFER_E_Penalty = BUFFER();
    
    
    // F - BUFFER/YES - GOAL KEEPER BODY CONDITION. 
    // THE VALUE IS 1 IF GOAL KEEPER BODY IS POSITIONED IN A WAY TO DEFEND/AVOID THE GOAL
    // WHICH MEANS THAT A PART OF GOAL KEEPER BODY IS POSITIONED AT SAME QUADRANT CHOOSEN 
    // AS GOAL KICK TARGET
    component BUFFER_F_Goal_Keeper = BUFFER();
    
    
    // G - BUFFER/YES - GOAL KICK/ GOAL CONDITION. 
    // THE VALUE IS 1 IF GOAL KICK TARGET QUADRANT IS EMPTY WICH MEANS THAT HAS NO GOAL 
    // KEEPER POSITIONED OVER THE CHOOSEN TARGET 
    component BUFFER_G_Goal_Kick = BUFFER();
    

    /*
     °
     ° ZK SOCCER GAMEPLAY CIRCUIT LOGIC
     °  
    */
    // 01 - OR GATE - ATTACKER FROM POSITION 1 TO POSITION 2 && 
    // ATTACKER FROM POSITION 2 TO POSITION 3 INTERCEPTION CHECK
    component OR_01_Defense_Intercept_1to2_2to3 = OR();
    
    // 02 - NOT/INVERTER GATE - PENALTY CONDITION INVERTER.IT REINFORCES THE PENALTY 
    // SUPERIOR HIERARCHY ON POSSIBLE CASE OF INTERCEPTION INSIDE PENALTY AREA FROM 
    // POSITION 3 TO GOAL
    component NOT_02_Penalty_Condition_Inverter = NOT();
    
    // 03 - AND GATE - ATTACKER FROM 3 TO GOAL INTERCEPTION && PENALTY CHECK. 
    // REINFORCES RULE THAT IF THERE IS A PENALTY, AN INTERCEPTION BETWEEN 
    // PATH PLAYER 3 TO GOAL WILL NOT BE CONSIDERED  
    component AND_03_Defense_Intercept_3toGOAL_Penalty = AND();
    
    // 04 - OR GATE - INTERCEPTION AT ANY OF 3 MOMENTS CHECK: 
    // IS THERE AN INTERCEPTION (DEFENSE PLAYER IN THE MIDDLE OF THE PATH OF THE PASS BETWEEN ATTACK PLAYERS)
    // 1 - ATTACKER 1 TO ATTACKER 2 || 2 - ATTACKER 2 TO ATTACKER 3 || 3 - ATTACKER 3 TO ATTACKER GOAL 
    component OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal = OR();

    // 05 - NOT/INVERTER GATE - GOAL KEEPER BODY TO BE CHECKED AGAINST CHOICE OF GOAL KICK
    // IF THE BODY DOES NOT AVOID THE GOAL KICK BEING VALUE ZERO, IT IS INVERTED TO COMPOSE
    // WITH GOAL KICK AND ACTIVATE AND_6 THAT CHECKS FOR GOAL
    component NOT_05_Goal_Keeper_Body_Defense_Checker = NOT();

    // 06 - AND GATE - GOAL CHECK. IT HAS VALUE 1 IF GOAL KEEPER BODY POSITION DOES NOT AVOID 
    // GOAL KICK; THEN ITS GOAL. OTHERWISE, VALUE IS ZERO, MEANING DEFENSE BY GOAL KEEPER WAS MADE.
    component AND_06_Goal_Check = AND();
    
    // 07 - NOT/INVERTER GATE - GOAL INVERTER TO REINFORCE RULE OF GOAL SUPERIOR HIERARCHY WITH 
    // RELATION TO PENALTY CONDITION. SO IF THERE IS A GOAL AND A PENALTY CONDITION SIMULTANEOUSLY
    // PREVAILS THE GOAL, AND IF THERE IS NO GOAL, BUT EXIST A PENALTY CONDITION, THE PENALTY 
    // ROUTINE MUST BE TRIGGERED 
    component NOT_07_GoalCheck_3toGOAL_Penalty_Inverter = NOT();
    
    // 08 - NOT/INVERTER GATE - INTERCEPTION INVERTER. ITS FUNCTION IS REINFORCE RULE THAT IF 
    // THERE IS AN INTERCEPTION DURING THE FIRST TWO MOVIMENTS, BEFORE THE PENALTY, THEN 
    // PREVAILS INTERCEPTION OVER THE PENALTY 
    component NOT_08_Interception_Inverter = NOT();
    
    // 09 - AND GATE - INTERCEPTION OR PENALTY CHECK
    component AND_09_Interception_or_Penalty_Check = AND();
    
    // 10 - AND GATE - GOAL OR PENALTY CHECK. IF THERE IS A GOAL AND PENALTY SIMULTANEOUS.
    // INVERTER NOT_07_GoalCheck_3toGOAL_Penalty_Inverter WILL VALUE ZERO REINFORCING THAT 
    // GOAL PREVAILS OVER PENALTY
    component AND_10_Goal_or_Penalty_Check = AND();
    
    // 11 - AND GATE - GOAL OR FAULT CHECK. REINFORCE RULE THAT FAULT PREVAILS OVER GOAL
    component AND_11_Goal_or_Fault_Check = AND();
    
    // 12 - AND GATE - INTERCEPTION OR FAULT CHECK. REINFORCE RULE THAT FAULT PREVAILS OVER INTERCEPTION
    component AND_12_Interception_or_Fault_Check = AND();
    
    // 13 - AND GATE - PENALTY OR FAULT CHECK. REINFORCE RULE THAT FAULT PREVAILS OVER PENALTY
    component AND_13_Penalty_or_Fault_Check = AND();
    
    // 14 - OR GATE - ACCUMULLATE WETHER AN INTERCEPTION, PENALTY OR FAULT HAPPENED
    component OR_14_Certify_Interception_Penalty_or_Fault = OR();
    
    // 15 - XOR GATE - IDENTIFY IF INTERCEPTION OR PENALTY HAPPENED
    component XOR_15_Identify_Interception_or_Penalty_Happened = XOR();
    
    // 16 - NOR GATE - GOAL KEEPER DEFENSE CHECK. THE GATE RECEIVES THE PREVIOUS GATE XOR_15 WHICH IDENTIFIES 
    // IF AN INTERCEPTION OR PENALTY HAPPENED. ALSO RECEIVE GOAL CHECK FROM AND_06. SO IF THERE IS NO INTERCEPTION, 
    // NO PENALTY AND NO GOAL IT MEANS THE GOAL KEPPER DEFENDED
    component NOR_16_Goal_Keeper_Deffense_Check = NOR();
    
    // 17 - AND GATE - GOAL KEEPER DEFENSE OR FAULT CHECK. REINFORCE RULE THAT FAULT PREVAILS OVER GOAL KEEPER DEFENSE
    component AND_17_Goal_Keeper_Defense_or_Fault_Check = AND();
    
    // 18 - OR GATE - ACCUMULLATE WETHER AN INTERCEPTION, PENALTY, GOAL KEEPER DEFENSE OR FAULT HAPPENED
    component OR_18_Certify_Interception_Penalty_Goal_Keeper_Defense_or_Fault = OR();
    
    // 19 - OR GATE - ACCUMULLATE WETHER AN INTERCEPTION, PENALTY, GOAL KEEPER DEFENSE, GOAL OR FAULT HAPPENED 
    component OR_19_Certify_Interception_Penalty_Goal_Keeper_Defense_Goal_or_Fault = OR();
    
    // 20 - NOT/INVERTER GATE - FAULT CHECKER INVERTER. 
    component NOT_20_Fault_Checker_Inverter = NOT();
    
    // 21 - AND GATE - REINFORCE FAULT OVER GOAL KEEPER DEFENSE
    component AND_21_Fault_or_Goal_Keeper_Defense = AND();

    
    

    /* 
     ° ///////////////////////////////////////////////////////////////////////////////////////
     °   PRE COMPUTE AND EXTRACT DATA FROM INPUT FOR VERIFICATIONS OF GAMEPLAY >>>>>>>>>>>>>>>
     ° ///////////////////////////////////////////////////////////////////////////////////////   
    */
    
    /*
     ° WHERE ARE THE PLAYERS POSITIONED ON THE FIELD? >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     °
     ° Read attack and defense soccer fields then:
     °   1) Check all positions for rangeProof it has a valid value  between 0 and 3 
     °      where zero is empty space and 1, 2, and 3 are the player´s position except 
     °      the goal keaper that will be treated in separate.
     °
     °   2) Assign player position to its variable for later computation     
    */ 

    component virtualDefenseField[9][9];
    component virtualAttackField[9][9];

    for (var i = 0; i < 9; i++) {
       for (var j = 0; j < 9; j++) {
            //DEFENSE check
            virtualDefenseField[i][j] = RangeProof();
            virtualDefenseField[i][j].range[0] <== 0;
            virtualDefenseField[i][j].range[1] <== 3;
            virtualDefenseField[i][j].in <== defenseField[i][j];
            assert(virtualDefenseField[i][j].out = 1);

            var positonTempDefense = defenseField[i][j];

            //Check if position is not empty (ZERO VALUE) , hence, has a Defense player positioned in it 
            if(positionTempDefense != 0){
                    //Where is defense player 01? 
                    if (positionTempDefense == 1){
                        matrixPosDefensePlayer-01[0] = i;
                        matrixPosDefensePlayer-01[1] = j;
                    }
                    //Where is defense player 02?
                    if (positionTempDefense == 2){
                        matrixPosDefensePlayer-02[0] = i;
                        matrixPosDefensePlayer-02[1] = j;
                    }
                    //Where is defense player 03?
                    if (positionTempDefense == 3){
                        matrixPosDefensePlayer-03[0] = i;
                        matrixPosDefensePlayer-03[1] = j;
                    }                  
            }//End 

            
            //ATTACK check 
              
            virtualAttackField[i][j] = RangeProof();
            virtualAttackField[i][j].range[0] <== 0;
            virtualAttackField[i][j].range[1] <== 3;
            virtualAttackField[i][j].in <== attackField[i][j];
            assert(virtualAttackField[i][j].out = 1);

            var positonTempAttack = attackField[i][j];

            //Check if position is not empty, hence, has a Attack player positioned in it 
            if(positionTempAttack != 0){
                    //Where is the attack player 01?
                    if (positionTempAttack == 1){
                            matrixPosAttackPlayer-01[0] = i;
                            matrixPosAttackPlayer-01[1] = j;
                    }
                    //Where is the attack player 02?
                    if (positionTempAttack == 2){
                            matrixPosAttackPlayer-02[0] = i;
                            matrixPosAttackPlayer-02[1] = j;
                    }
                    //Where is the attack player 03?
                    if (positionTempAttack == 3){
                            matrixPosAttackPlayer-03[0] = i;
                            matrixPosAttackPlayer-03[1] = j;
                    }


            }
        
        }// End FOR LOOP variable j
    
    }// End FOR LOOP variable i

    //#######################################################
    //Convert Matrix position to node position

    function Matrix2Node(a[0],a[1]){
        var nodeNumber;

        if(a[0]==0){
            var nodeNumber = a[1];
            return nodeNumber;
        }

        //Find node from matrix point(x,y)
        //nodeNumber = ( (x-1) * row.length) + y
        nodeNumber = ((a[0]-1)*9) + a[1];
        return nodeNumber;
    }

    //Defender Nodes 
    var nodeDefensePlayer[3];
    nodeDefensePlayer[0] =  Matrix2Node(matrixPosDefensePlayer-01[0], matrixPosDefensePlayer-01[1]);
    nodeDefensePlayer[1] =  Matrix2Node(matrixPosDefensePlayer-02[0], matrixPosDefensePlayer-02[1]);
    nodeDefensePlayer[2] =  Matrix2Node(matrixPosDefensePlayer-03[0], matrixPosDefensePlayer-03[1]);

    //Defender Nodes each player in a different position
    assert(nodeDefensePlayer[0] != nodeDefensePlayer[1]);
    assert(nodeDefensePlayer[0] != nodeDefensePlayer[2]);
    assert(nodeDefensePlayer[1] != nodeDefensePlayer[2]);

    //Attacker nodes
    var nodeAttackPlayer[3];
    nodeAttackPlayer[0] = Matrix2Node(matrixPosAttackPlayer-01[0], matrixPosAttackPlayer-01[1]);
    nodeAttackPlayer[1] = Matrix2Node(matrixPosAttackPlayer-02[0], matrixPosAttackPlayer-02[1]);
    nodeAttackPlayer[2] = Matrix2Node(matrixPosAttackPlayer-03[0], matrixPosAttackPlayer-03[1]);

    //Attacker Nodes each player in a different position
    assert(nodeAttackPlayer[0] != nodeAttackPlayer[1]);
    assert(nodeAttackPlayer[0] != nodeAttackPlayer[2]);
    assert(nodeAttackPlayer[1] != nodeAttackPlayer[2]);

    //#######################################################

    //FAULT DETECTION  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    /*
     ° FAULT = If the Player that attacks choose a position already taken by Defender Player 
     °         anywhere on the field with excepetion of PENALTY MARKING AREA.
     ° 
     ° PENALTY = If the Player that attacks choose a position already taken by Defender Player
     °           but both are inside the PENALTY MARKING AREA, then, its PENALTY**.
     °           
     °           **TO BE CONFIRMED, MUST HAVE NO PRIOR INTERCEPTION HAPPENED
     °
     */

    //Helper function checkPenaltyOrFault ////////////////////////////////////////////
    function checkPenalty(nodeAttackPlayer, nodeDefensePlayer){
        //This variable will keep zero as value in case it is Fault 
        //and will be assigned value 1 in case it is penalty
        var penaltyChecker = 0;
        
        /*
         °Check if the considered field is
         °
         ° fieldLayerMode = value 0 >>> LAYER 1 choice: Player 1 attacks on defense field of Player 2 or Autoplay
         °
         ° fieldLayerMode = value 0 >>> LAYER 2 choice: Player 1 defends on its own defense field from Player 2 or Autoplay attack turn
         °
        */

        //LAYER 1 choice:##########################################################
        if (fieldLayerMode == 0){
                for(var K=0; k<6; k++){
                    component checkPenaltyAttacker = IsEqual();
                    checkPenaltyAttacker.in[0]<-- nodeAttackPlayer;
                    checkPenaltyAttacker.in[1]<-- penaltyAreaNodesLayer1[k];
                
                    component checkPenaltyDefensor = IsEqual();
                    checkPenaltyDefensor.in[0]<-- nodeDefensePlayer;
                    checkPenaltyDefensor.in[1]<-- penaltyAreaNodesLayer1[k];
                
                    if(checkPenaltyDefensor.out == 1){
                        if (checkPenaltyAttacker.out ==1){
                            penaltyChecker = 1;
                            return penaltyChecker;
                        }

                    }
                    return penaltyChecker;
                }
        }


        //LAYER 2 choice:##########################################################

        if (fieldLayerMode == 1){
                for(var K=0; k<6; k++){
                    component checkPenaltyAttacker = IsEqual();
                    checkPenaltyAttacker.in[0]<-- nodeAttackPlayer;
                    checkPenaltyAttacker.in[1]<-- penaltyAreaNodesLayer2[k];
                
                    component checkPenaltyDefensor = IsEqual();
                    checkPenaltyDefensor.in[0]<-- nodeDefensePlayer;
                    checkPenaltyDefensor.in[1]<-- penaltyAreaNodesLayer2[k];
                
                    if(checkPenaltyDefensor.out == 1){
                        if (checkPenaltyAttacker.out ==1){
                            penaltyChecker = 1;
                            return penaltyChecker;
                        }

                    }
                    return penaltyChecker;
                }
        }
        

    } //End Helper function checkPenaltyOrFault ////////////////////////////////////////////

     

    //FAULT OR PENALTY VERIFICATION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    for(var i = 0; i<3; i++){ //Attack Node
        for(var j=0; j<3; j++){ //Defender Node
            //If players are positioned over the same quadrant/node
            if(nodeAttackPlayer[i] == nodeDefensePlayer[j]){
                //Check whether or not the players are inside the Penalty Area 
                var checkPenalty = checkPenalty(nodeAttackPlayer[i], nodeDefensePlayer[j]);
                if (checkPenalty == 1){
                    faultArray[i] = 0;
                    penaltyArray[i] = 1;
                }else{
                    faultArray[i] = 1;
                    penaltyArray[i] = 0;                       
                }                                
            }
        }
    }

    // CIRCUIT INPUT ASSIGNMENT

    // If there is a fault on at least one of these positions: faultArray[0], faultArray[1] or faultArray[2], 
    // check whether a fault was already marked or not. In case BUFFER_A_Fault.out != 1 , 
    // then, assign 1 to it through BUFFER_A_Fault.in <-- 1 meaning a fault was found, hence assigned. 

    if(faultArray[0]==1){
        if(BUFFER_A_Fault.out != 1){
            BUFFER_A_Fault.in <-- 1;
        }       
    }

    if(faultArray[1]==1){
        if(BUFFER_A_Fault.out != 1){
            BUFFER_A_Fault.in <-- 1;
        }       
    }

    if(faultArray[2]==1){
        if(BUFFER_A_Fault.out != 1){
            BUFFER_A_Fault.in <-- 1;
        }       
    }
    
    // If there is a penalty on at least one of these positions: penaltyArray[0], penaltyArray[1] or penaltyArray[2], 
    // check whether a penalty was already marked or not. In case BUFFER_E_Penalty.out != 1 , 
    // then, assign 1 to it through BUFFER_E_Penalty.in <-- 1 meaning a penalty was found, hence assigned. 

    if(penaltyArray[0]==1){
        if(BUFFER_E_Penalty.out != 1){
            BUFFER_E_Penalty.in <-- 1;
        }       
    }

    if(penaltyArray[1]==1){
        if(BUFFER_E_Penalty.out != 1){
            BUFFER_E_Penalty.in <-- 1;
        }       
    }

    if(penaltyArray[2]==1){
        if(BUFFER_E_Penalty.out != 1){
            BUFFER_E_Penalty.in <-- 1;
        }       
    }
    
 

    //##########################################################################################
    //BALL TRAJECTORY CALCULATION  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    //##########################################################################################
    
    //Ball starts on the feet of First Attack Player
    ball[0] = matrixPosAttackPlayer-01[0];
    ball[1] = matrixPosAttackPlayer-01[1];

    /*
    This function calculates if Horizontal pass is possible.
    Based in 2 players, horizontal pass is possible if both 
    positions are in same line, hence playerA(x,y1) and playerB(x,y2)
    */
    /* <<<<< TO DO >>>>>*/

    /*
    This function calculates if Vertical pass is possible.
    Based in 2 players, vertical pass is possible if both 
    positions are in same column, hence playerA(x1,y) and playerB(x2,y)
    */
    /* <<<<< TO DO >>>>>*/


    /*
    This function calculates if Diagonal pass is possible.
    Based in 2 players, diagonal pass is possible if both 
    positions are in diagonal, hence playerA(x,y1) and playerB(x,y2)
    */
    /* <<<<< TO DO >>>>>*/


     /*
     This function calculates if pinpoint pass 
     (Perfect horizontal, vertical or diagonal)
     is possible. Returns 1 for success or 0 for interception
    */
    /* <<<<< TO DO >>>>>*/



    // GOAL OR GOAL KEEPER DEFENSE VERIFICATION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    //<<< If Goal cannot be scored, no need for further calculation >>> 
    //First of all check if is it possible to score a goal
    for(var i=0; i<9; i++){
        //Find the target quadrant choosen by attack user
        if(goalMatrixAttack[i] == 1){
            //Check wether the choosen quadrant is empty to make possible score 
            //the goal.
            
            //NAND component wasItGoal? GOAL (out=1) or DEFENSE (out=0) 
            component wasItGoal = NAND();
            
            // Since Here, inside this if condition, the Goal Kick is already value 1, 
            // if the Goal Keeper is there to defend its value will be also 1
            // Therefore NAND will produce 0 (zero) as output, meaning 
            // NO GOAL WAS POSSIBLE AND DEFENSE WAS MADE.
            // Otherwise, the Goal Keeper by not being there will have value 0 and the NAND will produce output 1
            // Which means GOAL SCORED!
            wasItGoal.a <-- goalMatrixAttack[i];
            wasItGoal.b <-- goalMatrixDefense[i];

            if (wasItGoal.out == 1){
                BUFFER_F_Goal_Keeper.in <-- 0;
                BUFFER_G_Goal_Kick <-- 1;

            }else{
                BUFFER_F_Goal_Keeper.in <-- 1;
                BUFFER_G_Goal_Kick <-- 0;
            }
        }
    }

    //#########################################################################################################
    // CIRCUIT CONNECTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    //#########################################################################################################

    /*
     °
     ° ZK SOCCER GAMEPLAY CIRCUIT LOGIC
     ° Circuit is within the pdf. Soonly it will also be here in ascii 
    */
    
    OR_01_Defense_Intercept_1to2_2to3.a <== BUFFER_B_Interception_1to2.out;
    OR_01_Defense_Intercept_1to2_2to3.b <== BUFFER_C_Interception_2to3.out;



    NOT_02_Penalty_Condition_Inverter.in <== BUFFER_E_Penalty.out;



    AND_03_Defense_Intercept_3toGOAL_Penalty.a <== BUFFER_D_Interception_3toGoal.out;
    AND_03_Defense_Intercept_3toGOAL_Penalty.b <== NOT_02_Penalty_Condition_Inverter.out;
    


    OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal.a <== OR_01_Defense_Intercept_1to2_2to3.out;
    OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal.b <== AND_03_Defense_Intercept_3toGOAL_Penalty.out;



    NOT_05_Goal_Keeper_Body_Defense_Checker.in <== BUFFER_E_Penalty.out;



    AND_06_Goal_Check.a <== NOT_05_Goal_Keeper_Body_Defense_Checker.out;
    AND_06_Goal_Check.b <== BUFFER_G_Goal_Kick.out;



    NOT_07_GoalCheck_3toGOAL_Penalty_Inverter.in <== AND_06_Goal_Check.out;
    


    NOT_08_Interception_Inverter.in <== OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal.out;
    


    AND_09_Interception_or_Penalty_Check.a <== NOT_08_Interception_Inverter.out;
    AND_09_Interception_or_Penalty_Check.b <== BUFFER_E_Penalty.out;
    


    AND_10_Goal_or_Penalty_Check.a <== AND_09_Interception_or_Penalty_Check.out;
    AND_10_Goal_or_Penalty_Check.b <== NOT_07_GoalCheck_3toGOAL_Penalty_Inverter.out;
    


    AND_11_Goal_or_Fault_Check.a <== AND_06_Goal_Check.out;
    AND_11_Goal_or_Fault_Check.b <== BUFFER_A_Fault.out;
    


    AND_12_Interception_or_Fault_Check.a <== BUFFER_A_Fault.out;
    AND_12_Interception_or_Fault_Check.b <== OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal.out;



    AND_13_Penalty_or_Fault_Check.a <== BUFFER_A_Fault.out;
    AND_13_Penalty_or_Fault_Check.b <== AND_10_Goal_or_Penalty_Check.out;



    OR_14_Certify_Interception_Penalty_or_Fault.a <== AND_13_Penalty_or_Fault_Check.out;
    OR_14_Certify_Interception_Penalty_or_Fault.b <== AND_12_Interception_or_Fault_Check.out;



    XOR_15_Identify_Interception_or_Penalty_Happened.a <== OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal.out;
    XOR_15_Identify_Interception_or_Penalty_Happened.b <== AND_10_Goal_or_Penalty_Check.out;



    NOR_16_Goal_Keeper_Deffense_Check.a <== XOR_15_Identify_Interception_or_Penalty_Happened.out;
    NOR_16_Goal_Keeper_Deffense_Check.b <== AND_06_Goal_Check.out;



    AND_17_Goal_Keeper_Defense_or_Fault_Check.a <== BUFFER_A_Fault.out;
    AND_17_Goal_Keeper_Defense_or_Fault_Check.b <== NOR_16_Goal_Keeper_Deffense_Check.out;



    OR_18_Certify_Interception_Penalty_Goal_Keeper_Defense_or_Fault.a <== OR_14_Certify_Interception_Penalty_or_Fault.out;
    OR_18_Certify_Interception_Penalty_Goal_Keeper_Defense_or_Fault.b <== AND_17_Goal_Keeper_Defense_or_Fault_Check.out;



    OR_19_Certify_Interception_Penalty_Goal_Keeper_Defense_Goal_or_Fault.a <== AND_11_Goal_or_Fault_Check.out;
    OR_19_Certify_Interception_Penalty_Goal_Keeper_Defense_Goal_or_Fault.b <== OR_18_Certify_Interception_Penalty_Goal_Keeper_Defense_or_Fault.out;



    NOT_20_Fault_Checker_Inverter.in <== OR_19_Certify_Interception_Penalty_Goal_Keeper_Defense_Goal_or_Fault.out;



    AND_21_Fault_or_Goal_Keeper_Defense.a <== NOT_20_Fault_Checker_Inverter.out;   
    AND_21_Fault_or_Goal_Keeper_Defense.b <== NOR_16_Goal_Keeper_Deffense_Check.out;


    //####################################################################################################
    // RESULT OF GAME CIRCUIT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    //####################################################################################################

    //FAULT
    result[0] <-- OR_19_Certify_Interception_Penalty_Goal_Keeper_Defense_Goal_or_Fault.out;
    //GOAL
    result[1] <-- AND_06_Goal_Check.out;
    //PENALTY
    result[2] <-- AND_10_Goal_or_Penalty_Check.out;
    //DEFENDER INTERCEPTION
    result[3] <-- OR_04_Defense_Intercept_Checker_1to2_2to3_3toGoal.out;
    //GOAL KEEPER DEFENSE
    result[4] <-- AND_21_Fault_or_Goal_Keeper_Defense.out;
    
    /*
    
        +---------+---------+---------+-----------------------+----------------------+---------------------------------------------------------------+
        |  FAULT  |  GOAL   | PENALTY | DEFENDER INTERCEPTION | GOAL KEEPER DEFENSE  |                            RESULT                             |
        +---------+---------+---------+-----------------------+----------------------+---------------------------------------------------------------+
        | INDEX 0 | INDEX 1 | INDEX 2 | INDEX 3               | INDEX 4              | MESSAGE                                                       |
        | 1       | 1       | 1       | 1                     | 1                    | FAULT -  meaning the attack is cancelled in favor of defensor |
        | 0       | 1       | 1       | 1                     | 0                    | INTERCEPTION - Defender intercepted attack                    |
        | 0       | 0       | 1       | 1                     | 0                    | INTERCEPTION - Defender intercepted attack before penalty     |
        | 0       | 0       | 1       | 0                     | 0                    | PENALTY - play a new routine to kick to goal                  |
        | 0       | 1       | 1       | 0                     | 0                    | GOAL plus PENALTY - prevails GOAL.                            |
        | 0       | 1       | 0       | 0                     | 0                    | GOAL                                                          |
        | 0       | 0       | 0       | 0                     | 1                    | GOAL KEEPER DEFENSE                                           |
        | 1       | X       | X       | X                     | X                    | FAULT plus any combination - FAULT prevails                   |
        +---------+---------+---------+-----------------------+----------------------+---------------------------------------------------------------+


    
    
    */
   
}// End TEMPLATE SOCCER
           
    
   
 

 




