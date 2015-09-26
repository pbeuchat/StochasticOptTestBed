function [B , returnX0 , returnStateDefObject, returnConstraintParams, returnCostDefObject, returnV, returnTmax , returnDims] = load_BuildingDef_004_003_True( inputBuildingIdentifierString, bbFullPath , inputSysOptions )
%  load_BuildingDef_002_001_True.m
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This is based heavily on the "BCRM_DEMOFILE" distributed
%               with the BRCM Toolbox v1.01 - Building Resistance-
%               Capacitance Modeling for Model Predictive Control.
%               Copyright (C) 2013  Automatic Control Laboratory, ETH Zurich.
%               For more infomation check: www.brcm.ethz.ch.
% ----------------------------------------------------------------------- %
% This file is part of the Stochastic Optimisation Test Bed.
%
% The Stochastic Optimisation Test Bed - Copyright (C) 2015 Paul Beuchat
%
% The Stochastic Optimisation Test Bed is free software: you can
% redistribute it and/or modify it under the terms of the GNU General
% Public License as published by the Free Software Foundation, either
% version 3 of the License, or (at your option) any later version.
% 
% The Stochastic Optimisation Test Bed is distributed in the hope that it
% will be useful, but WITHOUT ANY W ARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with the Stochastic Optimisation Test Bed.  If not, see
% <http://www.gnu.org/licenses/>.
%  ---------------------------------------------------------------------  %


%% THIS FUNCTION SHOULD PERFORM THE FOLLOWING
%       -> Draw the building if requested
%       -> Discretise the building model
%       -> Specify the costs
%       -> Specify the constraints
%       -> Specify the initial condition



%% --------------------------------------------------------------------- %%
%% 0) EXTRACT DETAILS FROM THE INPUT - Mainly the options specified

flag_displaySystem      = inputSysOptions.displaySystemDetails;
flag_drawSystem         = inputSysOptions.drawSystem;
flag_plotSparisity      = inputSysOptions.plotContTimeModelSparisity;
discretisationMethod    = inputSysOptions.discretisationMethod;



%% --------------------------------------------------------------------- %%
%% 1) LOAD OR CONSTRUCT THE BUILDING

% Specify the flags for which "External Heat Flux" (EHF) models to include
flags_EHFModelsToInclude.BuildingHull        = true;
flags_EHFModelsToInclude.AHU                 = true;
flags_EHFModelsToInclude.AHU_quantity        = 3;
flags_EHFModelsToInclude.InternalGains       = false;
flags_EHFModelsToInclude.BEHeatfluxes        = true;
flags_EHFModelsToInclude.Radiators           = false;

flags_EHFModelsToInclude.reconstructModel    = false;

B = get_BuildingDef( inputBuildingIdentifierString , flags_EHFModelsToInclude , bbFullPath );
disp( ' DEBUGGING: If this is displayed then I was wrong :-( #06' );


%% --------------------------------------------------------------------- %%
%% 1) DISPLAY AND DRAW BUILDING (optional)
if (flag_displaySystem || flag_drawSystem)
    % Displaying
    if flag_displaySystem
        disp('     -> Displaying details of the thermal model');
        % Print the thermal model data in the Command Window for an overview
        B.printThermalModelData;
    end
    % Drawing
    if flag_drawSystem
        % 3-D plot of Building
        disp('     -> Drawing a 3-D model of the building');
        tempHandle = figure;
        B.drawBuilding([],[],tempHandle);

        % 2-D plot of Building
        disp('     -> Drawing a 2-D floorplan of the building - for floor number 1');
        tempHandle = figure;
        B.drawBuilding({'Z0021','Z0020','Z0019'},{'Floorplan'},tempHandle);
        

        % Drawing parts of the building can be done by a cell array of zone group and/or zone identifiers
        % SYNTAX:
        % B.drawBuilding({zone group and/or zone identifiers} , {Draw Specs} , figure_handle); 
    end
end




%% --------------------------------------------------------------------- %%
%% 2) PLOT CONINUOUS TIME SPARSITY

if flag_plotSparisity

    % Set the default interpreter to "latex"
    set(0, 'defaultTextInterpreter', 'latex');
    tempFontSize = 24;
    
    
    % First plot the A and B matrices is one plot
    A_cont = B.building_model.continuous_time_model.A;
    Bu_cont = B.building_model.continuous_time_model.Bu;
    Bxi_cont = B.building_model.continuous_time_model.Bv;
    
    % Create the figure
    thisFig = figure('position',[100 100 1200 700]);
    set(thisFig,'color','w')
    
    % Space things a bit nicely so that the matrices will be a similar
    % height
    temp_n_x   = size(A_cont   ,2);
    temp_n_u   = size(Bu_cont  ,2);
    temp_n_xi  = size(Bxi_cont ,2);
    temp_n_tot = temp_n_x + temp_n_u + temp_n_xi;
    
    lsp = 0.01;
    csp = 0.01;
    rsp = 0.05;
    axbuff = 0.05;
    axwtot = 1.0-lsp-2*csp-rsp-3*axbuff;
    
    tsp = 0.08;
    bsp = 0.12;
    axh = 1-tsp-bsp;
    
    A_w     = axbuff + axwtot * (temp_n_x  / temp_n_tot);
    Bu_w    = axbuff + axwtot * (temp_n_u  / temp_n_tot);
    Bxi_w   = axbuff + axwtot * (temp_n_xi / temp_n_tot);
    
    % Plot the A matrix in the first position
    %subplot(1,3,1);
    thisAxes_A = axes('position',[lsp,bsp, A_w ,axh]);
    spy(A_cont);
    title('$A$','fontsize',tempFontSize);
    set(thisAxes_A,'fontsize',tempFontSize);
    % Plot the Bu matrix in the second position
    %subplot(1,3,2);
    thisAxes_Bu = axes('position',[lsp+A_w+csp,bsp, Bu_w ,axh]);
    spy(Bu_cont);
    title('$B_u$','fontsize',tempFontSize);
    set(thisAxes_Bu,'fontsize',tempFontSize);
    % Plot the Bxi matrix in the third position
    %subplot(1,3,3);
    thisAxes_Bxi = axes('position',[lsp+A_w+csp+Bu_w+csp,bsp, Bxi_w ,axh]);
    spy(Bxi_cont);
    title('$B_xi$','fontsize',tempFontSize);
    set(thisAxes_Bxi,'fontsize',tempFontSize);
    
end



%% --------------------------------------------------------------------- %%
%% 2) PERFORM THE DISCRETISATION
disp('     -> Perform the discretisation');


% SPECIFY THE DISCRETISATION TIME
Ts_hrs = 0.25;
B.building_model.setDiscretizationStep(Ts_hrs);

% --------------------------------------- %
% BY "HAND" - using the "FORWARD EULER" discretisation technique
if strcmp( discretisationMethod , 'euler' )

    
    % Access of full continous model matrices, and then implement a
    % discretisation technique that is structure preserving
    contTime_A     = B.building_model.continuous_time_model.A;
    %contTime_Bu    = B.building_model.continuous_time_model.Bu;
    %contTime_Bv    = B.building_model.continuous_time_model.Bv;
    %contTime_Bvu   = B.building_model.continuous_time_model.Bvu;
    %contTime_Bxu   = B.building_model.continuous_time_model.Bxu;

    % contTime_Sys = ss( contTime_A , contTime_B, 0 , 0 );
    % 
    % deltaT = Ts_hrs;
    % 
    % discTime_Euler_A = speye(size(conTimeA,1)) + contTime_A * deltaT;
    % discTime_Euler_B = speye(size(conTimeA,1)) + contTime_A * deltaT;
    
    
    % COMPUTE THE EIGENVALUES OF THE CONTINOUS TIME SYSTEM
    eigenValuesContTime = eig(contTime_A);
    
    % First check that the real part of all the eigenvalues are negative
    if any( real(eigenValuesContTime) >= 0 )
        disp(' ... NOTE: the continous time system has eigen-values with real part >= 0');
        disp('           Hence the "forward euler discretisation" will NOT be stable');
    end
    
    % Now find the largest discretisation time that can be used for Forward
    % Euler discretisation, based on:
    % h_0 = max_h { h , s.t. |1+h*\lambda| = 1 }
    h_per_eig = -2 .* real(eigenValuesContTime) ./ ( real(eigenValuesContTime).^2 + imag(eigenValuesContTime).^2 );
    
    h0 = min( h_per_eig );
    
    % Check if the discretisation time chosen is less than "h0" or not
    secondsPerHour = 60 * 60;
    Ts_seconds = Ts_hrs * secondsPerHour;
    if Ts_seconds > h0
        disp( ' ... NOTE: the discretisation time specified is larger than the maximum discretisation time');
        disp( '           that would maintain stability of forward euler discretisation');
    end
    
    B.building_model.setDiscretizationStep(0.5*h0/secondsPerHour);
    
    % NOW PERFORM THE "FORWARD EULER" DISCRETISATION
    %discTime_A  = speye(size(contTime_A,1))  + contTime_A  * Ts_seconds;
    %discTime_Bu = speye(size(contTime_Bu,1)) + contTime_Bu * Ts_seconds;
    %discTime_Bv = speye(size(contTime_Bv,1)) + contTime_Bv * Ts_seconds;
    
    %discTime_Bvu = contTime_Bvu;
    %discTime_Bxu = contTime_Bxu;
    
    % Now save this back into the "B" building object under the discrete model
    % property
    B.building_model.discretise_viaForwardEuler();
    
    
else
    
    % --------------------------------------- %
    % USING BRCM:
    % the BRCM ".discretize()" function implements the following:
    %       A_discrete = expm( A_continuous );
    %       B_discrete = A_continuous \ (A_discrete - I) * B_continuous;
    % Where B = [Bu , Bv , Bvu , Bxu ] for both continous and discrete
    % This is in general not structure preserving
    B.building_model.discretize();

end





%% --------------------------------------------------------------------- %%
%% 3) x0 - SPECIFY THE INITIAL CONDITION
disp('     -> "Reading" the specified initial condition');
%n_x = size( B.building_model.discrete_time_model.A  , 2 );
%x0 = 16 * ones( n_x , 1 );


%internalStates = [1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ]';
internalStates = [1, 1, 1, 0 0 0 1 1, 1, 1 1 1 1 1 1 1, 1 1, 0 0 0 1 1, 1, 1 1 1 1 1 1 1, 0 0 0 1 1, 1 1 1, 1 1 1 1 1 1 1, 1 1, 1 1, 1 1, 1 1, 1 1, 1 1 ]';
%                 1          5           10        15          20          25        30         35          40        45          50           55];

%x0 = 22.5*internalStates + 16 * ~internalStates;
x0 = 22.4*internalStates + 16 * ~internalStates;
%x0 = 22.2*internalStates + 16 * ~internalStates;
%x0 = 22.0*internalStates + 16 * ~internalStates;
%x0 = 21.5*internalStates + 16 * ~internalStates;
%x0 = 21.0*internalStates + 16 * ~internalStates;
%x0 = 20.0*internalStates + 16 * ~internalStates;
%x0 = 19.0*internalStates + 16 * ~internalStates;
%x0 = 30*internalStates + 16 * ~internalStates;
%x0 = 24*internalStates + 16 * ~internalStates;

TABSStates = sparse( [47,48,49,50,51,52,] , ones(6,1) , ones(6,1) , 58 , 1 , 6 );

% Adjust the TABS layers to be a lil hotter
x0 = x0 - x0(1) * TABSStates + 22.5 * TABSStates;



%% --------------------------------------------------------------------- %%
%% 4) BUILD A STATE DEFINITION OBJECT (extracting "n_x" and "n_u")
disp('     -> Build a "State Definition" object');
% This is all automatically extracted from the properties of the "B"
% building object, and requires the initial condition to be specified
stateDefObject = ModelCostConstraints_Building.buildStateDefObjectFromBuildingObject( B , x0 , internalStates );


% Get the size of the state vector
n_x = size( B.building_model.discrete_time_model.A  , 2 );
% Get the size of the input vector
n_u = size( B.building_model.discrete_time_model.Bu  , 2 );

% Specify by hand the number of rooms (or get is from the building object)
%num_rooms = 7;
num_rooms = length(B.thermal_model_data.zones);

% Add the plotting flag to the State Definition Object
plotMask_x  = [true(num_rooms,1) ; false(n_x-num_rooms,1)];
plotMask_u  = true( stateDefObject.n_u  , 1);
plotMask_xi = true( stateDefObject.n_xi , 1);


updatePlottingMasks( stateDefObject , plotMask_x, plotMask_u, plotMask_xi );


%% --------------------------------------------------------------------- %%
%% 5) GENERATE CONSTRAINT DESCRIPTION
disp('     -> Generate constraint description');

% --------------------------------------- %
% USING BRCM:
% Get constraint matrices such that % Fx*x+Fu*u+Fv*v <= g. These are the constraints for one particular set of potentially 
% time-varying constraintsParameters. Every row of the matrices represents one constraint the name of which is the 
% corresponding entry in constraint_identifiers. The parameters that have to be passed must be in the form 
% constraintsParameters.<EHF_identifier>.<parameters>. Check the documentation to learn which <parameters> are necessary for
% a particular EHF model.
%
% However the very general constraint description of BRCM is not
% necessarily the "best" in all cases, as it may be just describing
% hyper-rectangle constraints, but is return as a dense matrix

% Initialise the stuct for inserting the constraints
%constraintsParameters = struct();

% EXAMPLE VALUE FROM BRCM DEMO
% constraintsParameters.AHU1.mdot_min = 0;
% constraintsParameters.AHU1.mdot_max = 1;
% constraintsParameters.AHU1.T_supply_max = 30;
% constraintsParameters.AHU1.T_supply_min = 22;
% constraintsParameters.AHU1.Q_heat_min = 0;
% constraintsParameters.AHU1.Q_heat_max = 1000;
% constraintsParameters.AHU1.Q_cool_min = 0;
% constraintsParameters.AHU1.Q_cool_max = 1;
% constraintsParameters.AHU1.x = 23*ones(length(B.building_model.identifiers.x),1);
% constraintsParameters.AHU1.v_fullModel = 20*ones(length(B.building_model.identifiers.v),1);
% 
% constraintsParameters.BuildingHull.BPos_blinds_E_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_E_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_L_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_L_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_N_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_N_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_S_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_S_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_W_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_W_max = 1;
% 
% 
% constraintsParameters.TABS.Q_BEH_hTABS_heat_min = 100;
% constraintsParameters.TABS.Q_BEH_hTABS_heat_max = 1000;
% constraintsParameters.TABS.Q_BEH_cTABS_cool_min = 100;
% constraintsParameters.TABS.Q_BEH_cTABS_cool_max = 1000;
% 
% constraintsParameters.Rad.Q_rad_CornerOffices_min = 1;
% constraintsParameters.Rad.Q_rad_CornerOffices_max = 3;
% constraintsParameters.Rad.Q_rad_Offices_min = 2;
% constraintsParameters.Rad.Q_rad_Offices_max = 4;
% 
% [Fx,Fu,Fv,g] = B.building_model.getConstraintsMatrices(constraintsParameters);



% --------------------------------------- %
% ORDER OF INPUTS
%                     u_AHU01_noERC
%                    u_AHU01_heater
%                     u_AHU02_noERC
%                    u_AHU02_heater
%                     u_AHU03_noERC
%                    u_AHU03_heater
%   u_BEH_Office_TABS_Z0019_01_heat
%   u_BEH_Office_TABS_Z0020_01_heat
%   u_BEH_Office_TABS_Z0021_01_heat




% --------------------------------------- %
% BY "HAND"
% Initialise the empty conatiner for the constraints
constraintsByHand = struct();

% STATE CONSTRAINTS:
% For the min and max on each state:
%   (assuming they are all temperatures)
constraintsByHand.x_rect_lower = 20 * ones( n_x , 1);
constraintsByHand.x_rect_upper = 25 * ones( n_x , 1);


% % RADIATOR CONSTRAINTS
% % For the min and max on each input
% %   (assuming they are all radiators)
% u_radiator_min = 0;
% %u_radiator_max = 18.75;
% u_radiator_max = 25;
% constraintsByHand.u_rect_lower = u_radiator_min * ones( n_u , 1);
% constraintsByHand.u_rect_upper = u_radiator_max * ones( n_u , 1);
% 
% % For the coupling resourse constraint
% % constraintsByHand.u_poly_A = sparse( ones(1,n_u) , 1:n_u , ones(n_u,1) , 1 , n_u , n_u );
% % constraintsByHand.u_poly_b = n_u * u_radiator_max * 0.75;
% % constraintsByHand.u_poly_label = { 'resource' };


% TABS CONSTRAINTS
% For the min and max on each input
%   (assuming they are all Thermally Activated Building Systems)
u_TABS_min = 0;
%u_radiator_max = 18.75;
u_TABS_max = 100;


% AHU CONSTRAINTS
% For the min and max on each input
%   (assuming they are all Thermally Activated Building Systems)
u_AHU_mdot_min = 0;
u_AHU_mdot_max = 2;

u_AHU_T_supply_min = 22;
u_AHU_T_supply_max = 30;

u_AHU_Q_heat_min = 0;
u_AHU_Q_heat_max = 1000;


% THE AHU TEMPERATURE IN - THIS IS A DISTURBANCE IN THE REAL SYSTEM
% BUT WE ARE FIXING IT TO BE A CONSTANT
AHU_Tin = 16;  % This needs to agree with the Disturbance



% PUT TOGETHER THE MIN-MAX CONSTRAINTS
constraintsByHand.u_rect_lower = [  repmat( [u_AHU_mdot_min ; u_AHU_Q_heat_min] , 3 , 1 )  ;...
                                    u_TABS_min * ones( 3 , 1)  ...
                                 ];


constraintsByHand.u_rect_upper = [  repmat( [u_AHU_mdot_max ; u_AHU_Q_heat_max] , 3 , 1 )  ;...
                                    u_TABS_max * ones( 3 , 1)  ...
                                 ];

                             
% ORDER OF INPUTS:
% AHU_01 Flow
% AHU_01 Heat
% AHU_02 Flow
% AHU_02 Heat
% AHU_03 Flow
% AHU_03 Heat
% TABS_01 Heat
% TABS_02 Heat
% TABS_03 Heat



% FOR THE AHU "T_Supply" MIN AND MAX
C_air = Constants.C_air;
coeff_flow_min =  C_air * ( - AHU_Tin + u_AHU_T_supply_min );
coeff_flow_max =  C_air * (   AHU_Tin - u_AHU_T_supply_max );

temp_index_i = [1,1,2,2,3,3,4,4,5,5,6,6];
temp_index_j = [1,2,1,2,3,4,3,4,5,6,5,6];
temp_values  = repmat( [coeff_flow_min , -1 , coeff_flow_max, 1] , 1 , 3 );

temp_num_AHU_poly_constraints = 2*3;

constraintsByHand.u_poly_A = sparse( temp_index_i , temp_index_j , temp_values , temp_num_AHU_poly_constraints , n_u , length(temp_values) );
constraintsByHand.u_poly_b = zeros(temp_num_AHU_poly_constraints , 1);
constraintsByHand.u_poly_label = repmat( {'T_supply_min_max'} , 6 , 1 );



% FOR THE COUPLING RECOURSE CONSTRAINT
% constraintsByHand.u_poly_A = sparse( ones(1,n_u) , 1:n_u , ones(n_u,1) , 1 , n_u , n_u );
% constraintsByHand.u_poly_b = n_u * u_radiator_max * 0.75;
% constraintsByHand.u_poly_label = { 'resource' };




%% --------------------------------------------------------------------- %%
%% COSTS - GENERATE COST DESCRIPTION
disp('     -> Generate cost description');


% --------------------------------------- %
% USING BRCM:

% Get cost vector such that J = cu*u. This is the cost for one particular set of potentially 
% time-varying costParameters. The parameters that have to be passed must be in the form 
% costParameters.<EHF_identifier>.<parameters>. Check the documentation to learn which <parameters> are necessary for
% a particular EHF model. 

% Initialise the stuct for inserting the constraints
%costParameters = struct();

% EXAMPLE VALUES FROM BRCM DEMO FILE
% costParameters = struct();
% costParameters.Rad.costPerJouleHeated = 10;
% costParameters.TABS.costPerJouleCooled = 10;
% costParameters.TABS.costPerJouleHeated = 10;
% costParameters.AHU1.costPerKgAirTransported = 1;
% costParameters.AHU1.costPerJouleCooled = 10;
% costParameters.AHU1.costPerKgCooledByEvapCooler = 10;
% costParameters.AHU1.costPerJouleHeated = 10;
% cu = B.building_model.getCostVector(costParameters);


% For the RADIATORS
% costParameters.Rad.costPerJouleHeated = 10;

% For the BUILDING ELEMENT HEAT FLUXES
% costParameters.TABS.costPerJouleCooled = 10;
costParameters.TABS.costPerJouleHeated = 10;

% For the AIR HANDLING UNIT(S)
AHU_costPerKgAirTransported_default = 1;
AHU_costPerJouleHeated_default = 10;

costParameters.AHU01.costPerKgAirTransported = AHU_costPerKgAirTransported_default;
%costParameters.AHU01.costPerJouleCooled = 10;
%costParameters.AHU01.costPerKgCooledByEvapCooler = 10;
costParameters.AHU01.costPerJouleHeated = AHU_costPerJouleHeated_default;

costParameters.AHU02.costPerKgAirTransported = AHU_costPerKgAirTransported_default;
%costParameters.AHU02.costPerJouleCooled = 10;
%costParameters.AHU02.costPerKgCooledByEvapCooler = 10;
costParameters.AHU02.costPerJouleHeated = AHU_costPerJouleHeated_default;

costParameters.AHU03.costPerKgAirTransported = AHU_costPerKgAirTransported_default;
%costParameters.AHU03.costPerJouleCooled = 10;
%costParameters.AHU03.costPerKgCooledByEvapCooler = 10;
costParameters.AHU03.costPerJouleHeated = AHU_costPerJouleHeated_default;





% Get the cost vector
cu = B.building_model.getCostVector(costParameters);

%cu = 0*cu;


% If the building_model B.building_model should be saved to use the model in another place, it is necessary that the Classes folder 
% is on the path, otherwise the saved data can not be loaded correctly. If only the matrices are needed, then just 
% the B.building_model.discrete_time_model should be saved and the Classes folder is not necessary.


% --------------------------------------- %
% BY "HAND"
% Initialise the empty conatiner for the constraints
costsByHand = struct();


% SPECIFY the reference temperature
%x_ref = 20.0;
x_ref = 22.5;
%num_x_to_cotnrol = 42;

% scalingOfComfortRelativeToEnergy = 1; %1000000;
% 
% %toControl = ~[1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
% toControl = [ ones(num_rooms,1) ; zeros(n_x-num_rooms,1) ];
% num_x_to_cotnrol = nnz(toControl);
% 
% 
% % Now put in the parameters
% costsByHand.type    = 'linear';
% %costsByHand.c       = scalingOfComfortRelativeToEnergy * num_x_to_cotnrol * x_ref^2;
% costsByHand.c       = scalingOfComfortRelativeToEnergy * sum(toControl) * x_ref^2;
% %costsByHand.q       = sparse( 1:num_x_to_cotnrol , ones(num_x_to_cotnrol,1) , -2*scalingOfComfortRelativeToEnergy*x_ref * ones(num_x_to_cotnrol,1) , n_x , 1 , num_x_to_cotnrol );costsByHand.q       = sparse( 1:num_x_to_cotnrol , ones(num_x_to_cotnrol,1) , -2*scalingOfComfortRelativeToEnergy*x_ref * ones(num_x_to_cotnrol,1) , n_x , 1 , num_x_to_cotnrol );
% costsByHand.q       = sparse( 1:num_x_to_cotnrol , ones(num_x_to_cotnrol,1) , -2*scalingOfComfortRelativeToEnergy*x_ref * toControl , n_x , 1 , num_x_to_cotnrol );
% costsByHand.r       = cu;
% %costsByHand.Q       = sparse( 1:num_x_to_cotnrol , 1:num_x_to_cotnrol , scalingOfComfortRelativeToEnergy * ones(num_x_to_cotnrol,1) , n_x , n_x , num_x_to_cotnrol );
% costsByHand.Q       = sparse( 1:num_x_to_cotnrol , 1:num_x_to_cotnrol , scalingOfComfortRelativeToEnergy * toControl , n_x , n_x , num_x_to_cotnrol );
% costsByHand.R       = sparse([],[],[],n_u,n_u,0);
% costsByHand.S       = sparse([],[],[],n_u,n_x,0);
% 
% 
% costsByHand.subCosts_num      = uint32(2);
% costsByHand.subCosts_label    = {'energy';'comfort'};



%% Put the costs together into the the format required
% Specify the number of Cost Components that are summed together to make up
% the total costs
% i.e. the cost components are the objectives in a multi-objective
% optimisation and the total cost is the objective in a single objective
% optimisation given a particular set of scalings
% This split into components is used to generate plots of a Pareto Front
% and make Pareto type comparisons of different methods

costComponents_num      = uint32(2);
costComponents_label    = {'energy';'comfort'};
%costComponents_scaling  = ones( costComponents_num , 1);
costComponents_scaling  = [ 5e-4 ; 1 ];

% The cost components should be individually defined to allow for clear
% separation of the costs

% NOTE: difficult to instatiate an empty array of the correct type because
% they could all be different types inherritting from the same
% "CostComponent", super class
%costComponentArray = CostComponent.empty(costComponents_num,0);
clear costComponentArray;

% COST COMPONENT CELL ARRAY
% Each cell will contain a cost function
% costComponentCellArray_energy = cell(7,1);
% costComponentCellArray_comfort = cell(7,1);

% Create the "energy" cost as a component array of the linear costs for
% each sub-system
n_ss = 3;
for i_ss = 1:n_ss
    temp_indicies = [ 2*(i_ss-1)+1 , 2*(i_ss-1)+2 , 2*n_ss+i_ss];
    %temp_indicies = [ 2*(i_ss-1)+1 , 2*(i_ss-1)+2];
    this_cu = sparse( temp_indicies , [1,1,1] , cu(temp_indicies,1) , n_u , 1 , length(temp_indicies) );
    costComponentArray_energy(i_ss,1) = CostComponent_Linear( sparse([],[],[],n_x,1,0) , this_cu , sparse([],[],[],1,1,0) , stateDefObject );
    
    %costComponentCellArray_energy{i_ss,1} = CostDef.createCostComponent_Linear( sparse([],[],[],n_x,1,0) , this_cu , sparse([],[],[],1,1,0) , stateDefObject );
end


% Create the "comfort" cost as a component array of the quadratic costs
% for each sub-system
%x_ref = 22.5; % This is defined above
for i_ss = 1:num_rooms
    this_Q = sparse( i_ss , i_ss , 1         , n_x , n_x , 1);
    this_q = sparse( i_ss , 1    , -2*x_ref  , n_x , 1   , 1);
    this_c = sparse( 1    , 1    , x_ref^2   , 1   , 1   , 1);
    costComponentArray_comfort(i_ss,1) = CostComponent_Quadratic_StateOnly( this_Q , this_q , this_c , stateDefObject );
    
    % costComponentCellArray_comfort{i_ss,1} = costDef.createCostComponent_Quadratic_StateOnly( this_Q , this_q , this_c , stateDefObject );
end


% Now fill in each element of the array:
%  -> The "energy" cost, a linear function of the input only
costComponentArray(1,1) = CostComponent_PerSubSystem( costComponentArray_energy , stateDefObject );
%costComponentArray{1,1} = CostComponent_PerSubSystem( costComponentArray_energy , stateDefObject );

%  -> The "comfort" cost, a quadratic cost of the states
costComponentArray(2,1) = CostComponent_PerSubSystem( costComponentArray_comfort , stateDefObject );

% costComponentCellArray = { ...
%         costComponentCellArray_energy   ;...
%         costComponentArray_comfort       ...
%      };


% Then the cost components should be wrappen together into a "Cost
% Definition" object
costDefObject = CostDef( stateDefObject , costComponents_num , costComponents_label , costComponentArray , costComponents_scaling );
%costDefObject = CostDef( stateDefObject , costComponents_num , costComponents_label , costComponentCellArray , costComponents_scaling );





%% PUT TOGETHER THE RETURN VARIABLES
returnX0                    = x0;
returnStateDefObject        = stateDefObject;
returnConstraintParams      = constraintsByHand;
returnCostDefObject         = costDefObject;

% These are some placeholders that were not yet necessary
returnV                     = [];
returnDims                  = [];
returnTmax                  = [];




end
%% END OF FUNCTION



%% --------------------------------------------------------------------- %%
%% --------------------------------------------------------------------- %%
%% NOTES/EXAMPLE CODE FOR ACCESSING THE BUILDING MODEL AND FUNCTIONS AVAILABLE


%% for: DRAWING AND DISPLAYING OPTIONS


%% for: RETRIEVING MATRICES
% Access of full model matrices
% discreteTimeFullModelMatrix_A       = B.building_model.discrete_time_model.A;       % same for Bu,Bv,Bvu,Bxu
% continuousTimeFullModelMatrix_A     = B.building_model.continuous_time_model.A;     % same for Bu,Bv,Bvu,Bxu
% discreteTimeFullModelMatrix_Bu      = B.building_model.discrete_time_model.Bu;      % same for Bu,Bv,Bvu,Bxu
% discreteTimeFullModelMatrix_Bv      = B.building_model.discrete_time_model.Bv;      % same for Bu,Bv,Bvu,Bxu


% Access of thermal model matrices
% continuousTimeThermalModelMatrix_A = B.building_model.thermal_submodel.A; % same for Bq
% [discreteTimeThermalModelMatrix_A,discreteTimeThermalModelMatrix_Bq] = B.building_model.thermal_submodel.discretize(Ts_hrs); % these are usually not used, hence not stored

% Access of EHF model matrices (here for the first EHF model)
% EHFM1Matrix_Aq = B.building_model.EHF_submodels{1}.Aq; % same for Bq_u, Bq_v, Bq_vu, Bq_xu



%% for: SPECIFYING THE CONSTRAINT MATRICES
% Get constraint matrices such that % Fx*x+Fu*u+Fv*v <= g. These are the constraints for one particular set of potentially 
% time-varying constraintsParameters. Every row of the matrices represents one constraint the name of which is the 
% corresponding entry in constraint_identifiers. The parameters that have to be passed must be in the form 
% constraintsParameters.<EHF_identifier>.<parameters>. Check the documentation to learn which <parameters> are necessary for
% a particular EHF model.

% Initialise the stuct for inserting the constraints
%constraintsParameters = struct();

% For the AIR HANDLING UNIT
% constraintsParameters.AHU1.mdot_min = 0;
% constraintsParameters.AHU1.mdot_max = 1;
% constraintsParameters.AHU1.T_supply_max = 30;
% constraintsParameters.AHU1.T_supply_min = 22;
% constraintsParameters.AHU1.Q_heat_min = 0;
% constraintsParameters.AHU1.Q_heat_max = 1000;
% constraintsParameters.AHU1.Q_cool_min = 0;
% constraintsParameters.AHU1.Q_cool_max = 1;
% constraintsParameters.AHU1.x = 23*ones(length(B.building_model.identifiers.x),1);
% constraintsParameters.AHU1.v_fullModel = 20*ones(length(B.building_model.identifiers.v),1);


% For the BUILDING HULL - BLINDS
% constraintsParameters.BuildingHull.BPos_blinds_E_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_E_max = 1;


% For the BUILDING ELEMENT HEAT FLUXES
% constraintsParameters.TABS.Q_BEH_hTABS_heat_min = 100;
% constraintsParameters.TABS.Q_BEH_hTABS_heat_max = 1000;


% For the RADIATORS
%constraintsParameters.Rad.Q_rad_Office_Rad_Z0001_01_min = 1;
%constraintsParameters.Rad.Q_rad_Office_Rad_Z0001_01_max = 3;

% Get the contraint description
%[Fx,Fu,Fv,g] = B.building_model.getConstraintsMatrices(constraintsParameters);


%% for: SPECIFYING THE COST VECTOR
% Get cost vector such that J = cu*u. This is the cost for one particular set of potentially 
% time-varying costParameters. The parameters that have to be passed must be in the form 
% costParameters.<EHF_identifier>.<parameters>. Check the documentation to learn which <parameters> are necessary for
% a particular EHF model. 

% Initialise the stuct for inserting the constraints
%costParameters = struct();

% For the RADIATORS
%costParameters.Rad.costPerJouleHeated = 10;

% For the BUILDING ELEMENT HEAT FLUXES
% costParameters.TABS.costPerJouleCooled = 10;
% costParameters.TABS.costPerJouleHeated = 10;

% For the AIR HANDLING UNIT
% costParameters.AHU1.costPerKgAirTransported = 1;
% costParameters.AHU1.costPerJouleCooled = 10;
% costParameters.AHU1.costPerKgCooledByEvapCooler = 10;
% costParameters.AHU1.costPerJouleHeated = 10;


% Get the cost vector
%cu = B.building_model.getCostVector(costParameters);

% If the building_model B.building_model should be saved to use the model in another place, it is necessary that the Classes folder 
% is on the path, otherwise the saved data can not be loaded correctly. If only the matrices are needed, then just 
% the B.building_model.discrete_time_model should be saved and the Classes folder is not necessary.


%% NOTES FOR: PUTTING TOGETHER A OBJECT OF STATE VARIABLE SIZES
% This is now done via a separate function that parse the "B" building
% object output from here and construct the "StateDef" type object in a
% (hopefully) general enough sense
%
%clear stateInputDisturbanceDimensions;
%stateInputDisturbanceDimensions.n_x     = size( B.building_model.discrete_time_model.A  , 2 );
%stateInputDisturbanceDimensions.n_u     = size( B.building_model.discrete_time_model.Bu , 2 );
%stateInputDisturbanceDimensions.n_xi    = size( B.building_model.discrete_time_model.Bv , 2 );

%returnDims                  = stateInputDisturbanceDimensions;

% If the constraints are time-varying then there is also a Maximum Time
% upto which the constraints will be defined
%returnTmax                  = 20;
