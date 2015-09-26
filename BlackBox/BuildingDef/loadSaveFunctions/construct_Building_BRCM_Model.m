function [returnB] = construct_Building_BRCM_Model( inputBuildingIdentifierString , flags_EHFModelsToInclude , bbFullPath )
%  construct_Building_BRCM_Model.m
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




%% NOTE: The BRCM Toolbox should already have been added to the path
% Test that a BRCM command works
check1 = exist( 'Building' , 'class' );
% This checks that 'Building' exists on the current path and is a 'class'
% The "exist" function should return "8" if this is true
% Terminate if this is not true
if not( check1 == 8 )
    disp(' ... ERROR: It appears that the BRCM toolbox that not been added to the path');
    error('Terminating now :-( See previous messages and ammend');
end


%% --------------------------------------------------------------------- %%
%% SET THE BRCM LEVEL OF OUTPUT TO THE COMMAND WINDOW
% This controls the output to the Command Window
   % g_debugLvl = -1 all output silent
   % g_debugLvl = 0 any not specifically requested output is completely silent
   % g_debugLvl = 1 only most important messages
   % g_debugLvl = 2 all messages

global g_debugLvl
g_debugLvl = 1;


%% --------------------------------------------------------------------- %%
%% SPECIFY THE ROOT PATH WHERE THE REQUEST BUILDING DEFINITION IS LOCATED
buildingDefRootPath = [ bbFullPath , filesep , 'BlackBox/BuildingDef/InputDef' ];
buildingDefFolder = [ bbConstants.loadDefFolderPrefix , inputBuildingIdentifierString , '/', bbConstants.loadDefFolderPrefix , inputBuildingIdentifierString , bbConstants.loadDefFolderSuffixTrue ];

thermalModelDataDir =   [ buildingDefRootPath , filesep , buildingDefFolder , filesep , 'ThermalModel'];
EHFModelDataDir =       [ buildingDefRootPath , filesep , buildingDefFolder , filesep , 'EHFM'];


%% --------------------------------------------------------------------- %%
%% 1) CREATE AN EMPTY BUILDING VARIABLE
disp('     1) Create a building');

% Create an empty Building object with an optional identifier argument.
buildingIdentifier = [ bbConstants.loadDefFolderPrefix , inputBuildingIdentifierString , bbConstants.loadDefFolderSuffixTrue ];
returnB = Building(buildingIdentifier);

%% --------------------------------------------------------------------- %%
%% 2) LOAD THE THERMAL MODEL DATA
disp('     2) Load the thermal model data');

% Load the thermal model data. 
returnB.loadThermalModelData(thermalModelDataDir);

% The thermal model data consists of zones, building elements,
% constructions, materials, windows and parameters. The data of each
% element group must be provided by a separate .xls files and all base
% files are required for loading the builing data. We require the file
% names and the file contents to follow a specific convention, see the
% Documentation.


%% --------------------------------------------------------------------- %%
%% 3) DECLARE EXTERNAL HEAT FLUX MODELS THAT SHOULD BE INCLUDED
disp('     3) Declare external heat flux models that should be included');

% Heat exchange with ambient air and solar gains
if flags_EHFModelsToInclude.BuildingHull
    EHFModelClassFile = 'BuildingHull.m';                                         % This is the m-file defining this EHF model's class.
    EHFModelDataFile = [EHFModelDataDir,filesep,'buildinghull'];                  % This is the spreadsheet containing this EHF model's specification.
    EHFModelIdentifier = 'BuildingHull';                                          % This string identifies the EHF model uniquely
    returnB.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);
end


% Ventilation
if flags_EHFModelsToInclude.AHU
    
    for iAHU = 1 : flags_EHFModelsToInclude.AHU_quantity
        EHFModelClassFile = 'AHU.m'; 
        EHFModelDataFile = [EHFModelDataDir,filesep,'ahu',num2str(iAHU,'%02d')]; 
        EHFModelIdentifier = [ 'AHU',num2str(iAHU,'%02d') ];
        returnB.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);
    end
end


% InternalGains
if flags_EHFModelsToInclude.InternalGains
    EHFModelClassFile = 'InternalGains.m'; 
    EHFModelDataFile = [EHFModelDataDir,filesep,'internalgains']; 
    EHFModelIdentifier = 'IG';
    returnB.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);
end


% TABS - Building Element Heat Fluxes
if flags_EHFModelsToInclude.BEHeatfluxes
    EHFModelClassFile = 'BEHeatfluxes.m'; 
    EHFModelDataFile = [EHFModelDataDir,filesep,'BEHeatfluxes']; 
    EHFModelIdentifier = 'TABS';
    returnB.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);
end


% Radiators
if flags_EHFModelsToInclude.Radiators
    EHFModelClassFile = 'Radiators.m'; 
    EHFModelDataFile = [EHFModelDataDir,filesep,'radiators']; 
    EHFModelIdentifier = 'Rad';
    returnB.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);
end






%% --------------------------------------------------------------------- %%
%% 4) GENERATE THEMAL MODEL AND FULL MODEL
disp('     4) Generate thermal model and full model');

% Generate thermal model (optional)
%returnB.generateThermalModel;

% Generate (full) building model (includes thermal model generation if not yet done)
returnB.generateBuildingModel;

% Display all available identifiers (these are the names of the control inputs / disturbances / states in the same order as they appear in the matrices)
returnB.building_model.printIdentifiers;




%% --------------------------------------------------------------------- %%
%% 5) PERFORM THE DISCRETISATION
%% THIS IS NOT AN ACTION TO BE PERFORMED WHILE LOADING
% disp('     5) Perform the discretisation');
% 
% % --------------------------------------- %
% % USING BRCM:
% % the BRCM ".discretize()" function implements the following:
% %       A_discrete = expm( A_continuous );
% %       B_discrete = A_continuous \ (A_discrete - I) * B_continuous;
% % Where B = [Bu , Bv , Bvu , Bxu ] for both continous and discrete
% % This is in general not structure preserving
% Ts_hrs = 0.25;
% returnB.building_model.setDiscretizationStep(Ts_hrs);
% returnB.building_model.discretize();
% 
% 
% 
% % --------------------------------------- %
% % BY "HAND"
% % Access of full continous model matrices, and then implement a
% % discretisation technique that is structure preserving
% % contTime_A     = B.building_model.continuous_time_model.A;
% % contTime_Bu    = B.building_model.continuous_time_model.Bu;
% % contTime_Bv    = B.building_model.continuous_time_model.Bv;
% % contTime_Bvu   = B.building_model.continuous_time_model.Bvu;
% % contTime_Bxu   = B.building_model.continuous_time_model.Bxu;
% % 
% % contTime_Sys = ss( contTime_A , contTime_B, 0 , 0 );
% % 
% % deltaT = Ts_hrs;
% % 
% % discTime_Euler_A = speye(size(conTimeA,1)) + contTime_A * deltaT;
% % discTime_Euler_B = speye(size(conTimeA,1)) + contTime_A * deltaT;
% 
% % Now save this back into the "B" building object under the discrete model
% % property


%% --------------------------------------------------------------------- %%
%% 6) Display thermal model data to Command Window and draw Building (optional) 
%% THIS IS NOT AN ACTION TO BE PERFORMED WHILE LOADING
%disp('     6) (Optional) Display details of the thermal model and draw the Building');

% Print the thermal model data in the Command Window for an overview
%B.printThermalModelData;

% 3-D plot of Building
%returnB.drawBuilding;

% It is possible to control the labeling
% B.drawBuilding('NoBELabels');
% B.drawBuilding('NoLabels');
% B.drawBuilding('NoZoneLabels');

% 2-D plot of Building
% B.drawBuilding('Floorplan');

% Drawing parts of the building can be done by a cell array of zone group and/or zone identifiers
% B.drawBuilding({'ZoneGrp_WestEnd'}); 
% B.drawBuilding({'ZoneGrp_CenterWest'}); 
% B.drawBuilding({'Z0003'}); 




%% PUT TOGETHER THE RETURN VARIABLES
%returnB                     = returnB;


%% CLEAR THE GLOBAL VARIABLE
clear -global g_debugLvl;

end
%% END OF FUNCTION



%% --------------------------------------------------------------------- %%
%% --------------------------------------------------------------------- %%
%% NOTES FOR: section 7), this is the example code for retrieving matrices,
%             specifying cost and constraints

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


%% NOTES FOR: PUT TOGETHER A OBJECT OF STATE VARIABLE SIZES
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
