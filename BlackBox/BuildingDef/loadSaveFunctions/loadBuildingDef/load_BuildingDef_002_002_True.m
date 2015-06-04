function [B , returnX0 , returnConstraintParams, returnCostParams, returnV, returnTmax , returnDims] = load_BuildingDef_002_002_True( inputBuildingIdentifierString , bbFullPath , inputSysOptions )
%  load_BuildingDef_002_002_True.m
%  ---------------------------------------------------------------------  %
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
% will be useful, but WITHOUT ANY WARRANTY; without even the implied
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
discretisationMethod    = inputSysOptions.discretisationMethod;


%% --------------------------------------------------------------------- %%
%% 1) LOAD OR CONSTRUCT THE BUILDING
disp('     -> Getting the Building Model');

% Specify the flags for which "External Heat Flux" (EHF) models to include
flag_EHFModelsToInclude.BuildingHull        = false;
flag_EHFModelsToInclude.AHU                 = false;
flag_EHFModelsToInclude.InternalGains       = false;
flag_EHFModelsToInclude.BEHeatfluxes        = false;
flag_EHFModelsToInclude.Radiators           = false;

flags_EHFModelsToInclude.reconstructModel   = false;

B = get_BuildingDef( inputBuildingIdentifierString , flags_EHFModelsToInclude , bbFullPath , sysOptions );
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
        disp('     -> Drawing a 2-D floorplan of the building');
        tempHandle = figure;
        B.drawBuilding([],{'Floorplan'},tempHandle);

        % Drawing parts of the building can be done by a cell array of zone group and/or zone identifiers
        % SYNTAX:
        % B.drawBuilding({zone group and/or zone identifiers} , {Draw Specs} , figure_handle); 
    end
end



%% --------------------------------------------------------------------- %%
%% 2) PERFORM THE DISCRETISATION
disp('     -> Perform the discretisation');

% --------------------------------------- %
% USING BRCM:
% the BRCM ".discretize()" function implements the following:
%       A_discrete = expm( A_continuous );
%       B_discrete = A_continuous \ (A_discrete - I) * B_continuous;
% Where B = [Bu , Bv , Bvu , Bxu ] for both continous and discrete
% This is in general not structure preserving
Ts_hrs = 0.25;
B.building_model.setDiscretizationStep(Ts_hrs);
B.building_model.discretize();



% --------------------------------------- %
% BY "HAND"
% Access of full continous model matrices, and then implement a
% discretisation technique that is structure preserving
% contTime_A     = B.building_model.continuous_time_model.A;
% contTime_Bu    = B.building_model.continuous_time_model.Bu;
% contTime_Bv    = B.building_model.continuous_time_model.Bv;
% contTime_Bvu   = B.building_model.continuous_time_model.Bvu;
% contTime_Bxu   = B.building_model.continuous_time_model.Bxu;
% 
% contTime_Sys = ss( contTime_A , contTime_B, 0 , 0 );
% 
% deltaT = Ts_hrs;
% 
% discTime_Euler_A = speye(size(conTimeA,1)) + contTime_A * deltaT;
% discTime_Euler_B = speye(size(conTimeA,1)) + contTime_A * deltaT;

% Now save this back into the "B" building object under the discrete model
% property



%% --------------------------------------------------------------------- %%
%% 3) GENERATE CONSTRAINT DESCRIPTION
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
constraintsParameters = struct();





% --------------------------------------- %
% BY "HAND"
% Initialise the empty conatiner for the constraints
constraintsByHand = struct();

% Get the size of the state vector
n_x = size( B.building_model.discrete_time_model.A  , 2 );
% Get the size of the input vector
n_u = size( B.building_model.discrete_time_model.Bu  , 2 );

% For the min and max on each state:
%   (assuming they are all temperatures)
constraintsByHand.x_rect_lower = 20 * ones( n_x , 1);
constraintsByHand.x_rect_upper = 25 * ones( n_x , 1);

% For the min and max on each input
%   (assuming they are all radiators)
u_radiator_min = 0;
u_radiator_max = 20;
constraintsByHand.u_rect_lower = u_radiator_min * ones( n_u , 1);
constraintsByHand.u_rect_upper = u_radiator_max * ones( n_u , 1);

% For the coupling resourse constraint
constraintsByHand.u_poly_A = sparse( ones(1,n_u) , 1:n_u , ones(n_u,1) , 1 , n_u , n_u );
constraintsByHand.u_poly_b = n_u * u_radiator_max * 0.8;

constraintsByHand.u_poly_label = { 'resource' };


%% --------------------------------------------------------------------- %%
%% 8) GENERATE COST DESCRIPTION
disp('     8) Generate cost description');


% --------------------------------------- %
% USING BRCM:

% Get cost vector such that J = cu*u. This is the cost for one particular set of potentially 
% time-varying costParameters. The parameters that have to be passed must be in the form 
% costParameters.<EHF_identifier>.<parameters>. Check the documentation to learn which <parameters> are necessary for
% a particular EHF model. 

% Initialise the stuct for inserting the constraints
%costParameters = struct();

% For the RADIATORS
costParameters.Rad.costPerJouleHeated = 10;

% For the BUILDING ELEMENT HEAT FLUXES
% costParameters.TABS.costPerJouleCooled = 10;
% costParameters.TABS.costPerJouleHeated = 10;

% For the AIR HANDLING UNIT
% costParameters.AHU1.costPerKgAirTransported = 1;
% costParameters.AHU1.costPerJouleCooled = 10;
% costParameters.AHU1.costPerKgCooledByEvapCooler = 10;
% costParameters.AHU1.costPerJouleHeated = 10;


% Get the cost vector
cu = B.building_model.getCostVector(costParameters);

cu = 0*cu;

% If the building_model B.building_model should be saved to use the model in another place, it is necessary that the Classes folder 
% is on the path, otherwise the saved data can not be loaded correctly. If only the matrices are needed, then just 
% the B.building_model.discrete_time_model should be saved and the Classes folder is not necessary.


% --------------------------------------- %
% BY "HAND"
% Initialise the empty conatiner for the constraints
costsByHand = struct();

% Get the size of the state vector
n_x = size( B.building_model.discrete_time_model.A  , 2 );
% Get the size of the input vector
n_u = size( B.building_model.discrete_time_model.Bu  , 2 );

x_ref = 22.5;
num_x_to_cotnrol = 42;

scalingOfComfortRelativeToEnergy = 100000;


% Now put in the parameters
costsByHand.type    = 'linear';
costsByHand.c       = scalingOfComfortRelativeToEnergy * num_x_to_cotnrol * x_ref^2;
costsByHand.q       = sparse( 1:num_x_to_cotnrol , ones(num_x_to_cotnrol,1) , -2*scalingOfComfortRelativeToEnergy*x_ref * ones(num_x_to_cotnrol,1) , n_x , 1 , num_x_to_cotnrol );
costsByHand.r       = cu;
costsByHand.Q       = sparse( 1:num_x_to_cotnrol , 1:num_x_to_cotnrol , scalingOfComfortRelativeToEnergy * ones(num_x_to_cotnrol,1) , n_x , n_x , num_x_to_cotnrol );
costsByHand.R       = sparse([],[],[],n_u,n_u,0);
costsByHand.S       = sparse([],[],[],n_u,n_x,0);


costsByHand.subCosts_num      = uint32(2);
costsByHand.subCosts_label    = {'energy';'comfort'};




%% --------------------------------------------------------------------- %%
%% SPECIFY THE INITIAL CONDITION
n_x = size( B.building_model.discrete_time_model.A  , 2 );
x0 = 22.5 * ones( n_x , 1 );





%% PUT TOGETHER THE RETURN VARIABLES
returnX0                    = x0;
returnConstraintParams      = constraintsByHand;
returnCostParams            = costsByHand;

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
