%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     load_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnB , returnX0 , returnConstraintParams, returnCostParams, returnV, returnTmax , returnDims] = load_BuildingDef( inputBuildingIdentifierString , bbFullPath )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This is based heavily on the "BCRM_DEMOFILE" distributed
%               with the BRCM Toolbox v1.01 - Building Resistance-
%               Capacitance Modeling for Model Predictive Control.
%               Copyright (C) 2013  Automatic Control Laboratory, ETH Zurich.
%               For more infomation check: www.brcm.ethz.ch.
%


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
B = Building(buildingIdentifier);

%% --------------------------------------------------------------------- %%
%% 2) LOAD THE THERMAL MODEL DATA
disp('     2) Load the thermal model data');

% Load the thermal model data. 
B.loadThermalModelData(thermalModelDataDir);

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
EHFModelClassFile = 'BuildingHull.m';                                         % This is the m-file defining this EHF model's class.
EHFModelDataFile = [EHFModelDataDir,filesep,'buildinghull'];                  % This is the spreadsheet containing this EHF model's specification.
EHFModelIdentifier = 'BuildingHull';                                          % This string identifies the EHF model uniquely
B.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);

% Ventilation
% EHFModelClassFile = 'AHU.m'; 
% EHFModelDataFile = [EHFModelDataDir,filesep,'ahu']; 
% EHFModelIdentifier = 'AHU1';
% B.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);

% InternalGains
EHFModelClassFile = 'InternalGains.m'; 
EHFModelDataFile = [EHFModelDataDir,filesep,'internalgains']; 
EHFModelIdentifier = 'IG';
B.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);

% TABS - Building Element Heat Fluxes
% EHFModelClassFile = 'BEHeatfluxes.m'; 
% EHFModelDataFile = [EHFModelDataDir,filesep,'BEHeatfluxes']; 
% EHFModelIdentifier = 'TABS';
% B.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);

% Radiators
EHFModelClassFile = 'Radiators.m'; 
EHFModelDataFile = [EHFModelDataDir,filesep,'radiators']; 
EHFModelIdentifier = 'Rad';
B.declareEHFModel(EHFModelClassFile,EHFModelDataFile,EHFModelIdentifier);



%% --------------------------------------------------------------------- %%
%% 4) Display thermal model data to Command Window and draw Building (optional) 
disp('     4) (Optional) Display details of the thermal model and draw the Building');

% Print the thermal model data in the Command Window for an overview
%B.printThermalModelData;

% 3-D plot of Building
B.drawBuilding;

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






%% --------------------------------------------------------------------- %%
%% 5) EXAMPLES: for how to Manipulate thermal model data and save it back to disk (optional)
%disp('  5) Manipulate thermal model data and save it back to disk (optional)');

% All(many) of the parameters can be retrieved(modified) by using the ThermalModelData's setValue(getValue) method 

% ------------------------------
% EXAMPLE: of how one can set numerical values ...
% thermalModelDataIdentifier = 'M0001';
% thermalModelDataProperty = 'specific_heat_capacity';
% specHeatCapacity = B.thermal_model_data.getValue(thermalModelDataIdentifier,thermalModelDataProperty);
% B.thermal_model_data.setValue(thermalModelDataIdentifier,thermalModelDataProperty,specHeatCapacity*1.2);

% ------------------------------
% EXAMPLE: of how one can do the same for a parameter identifiers
% thermalModelDataIdentifier = 'W0001';
% thermalModelDataProperty = 'U_value';
% B.thermal_model_data.setValue(thermalModelDataIdentifier,thermalModelDataProperty,'UValue_Window_EPConstr_WindowGlazing_Office');


% ------------------------------
% EXAMPLE: of how to Write the changes back to disk
% modifiedThermalModelDataDir = [thermalModelDataDir,'_mod'];
% forceFlag = false;                     % optional flag for automatic overwriting of existing files (default = false)
% writeToCSV = false;                    % optional flag controlling output format. Default is .xls.
% B.writeThermalModelData(modifiedThermalModelDataDir,forceFlag,writeToCSV)


% ------------------------------
% Reload the old data to continue
% B.loadThermalModelData(thermalModelDataDir); 



%% --------------------------------------------------------------------- %%
%% 6) GENERATE THEMAL MODEL AND FULL MODEL
disp('     6) Generate thermal model and full model');

% Generate thermal model (optional)
B.generateThermalModel;

% Generate (full) building model (includes thermal model generation if not yet done)
B.generateBuildingModel;

% Display all available identifiers (these are the names of the control inputs / disturbances / states in the same order as they appear in the matrices)
B.building_model.printIdentifiers;

% Disretization
Ts_hrs = 0.25;
B.building_model.setDiscretizationStep(Ts_hrs);
B.building_model.discretize();







%% --------------------------------------------------------------------- %%
%% 7) Retrieve Matrices and generate costs and constraints
disp('     7) Retrieve Matrices and generate costs and constraints');

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
constraintsParameters = struct();

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
% constraintsParameters.BuildingHull.BPos_blinds_L_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_L_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_N_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_N_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_S_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_S_max = 1;
% constraintsParameters.BuildingHull.BPos_blinds_W_min = 0.1;
% constraintsParameters.BuildingHull.BPos_blinds_W_max = 1;


% For the BUILDING ELEMENT HEAT FLUXES
% constraintsParameters.TABS.Q_BEH_hTABS_heat_min = 100;
% constraintsParameters.TABS.Q_BEH_hTABS_heat_max = 1000;
% constraintsParameters.TABS.Q_BEH_cTABS_cool_min = 100;
% constraintsParameters.TABS.Q_BEH_cTABS_cool_max = 1000;


% For the RADIATORS
constraintsParameters.Rad.Q_rad_Office_Rad_Z0001_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0001_01_max = 3;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0002_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0002_01_max = 3;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0003_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0003_01_max = 3;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0004_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0004_01_max = 3;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0005_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0005_01_max = 3;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0006_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0006_01_max = 3;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0007_01_min = 1;
constraintsParameters.Rad.Q_rad_Office_Rad_Z0007_01_max = 3;


% Get the contraint description
[Fx,Fu,Fv,g] = B.building_model.getConstraintsMatrices(constraintsParameters);


% Get cost vector such that J = cu*u. This is the cost for one particular set of potentially 
% time-varying costParameters. The parameters that have to be passed must be in the form 
% costParameters.<EHF_identifier>.<parameters>. Check the documentation to learn which <parameters> are necessary for
% a particular EHF model. 

% Initialise the stuct for inserting the constraints
costParameters = struct();

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

% If the building_model B.building_model should be saved to use the model in another place, it is necessary that the Classes folder 
% is on the path, otherwise the saved data can not be loaded correctly. If only the matrices are needed, then just 
% the B.building_model.discrete_time_model should be saved and the Classes folder is not necessary.

%% --------------------------------------------------------------------------------------
% 8) Discrete-time simulation of the thermal model or the building model (here only shown for the building model)
% --------------------------------------------------------------------------------------
% disp('% ----------------------------');
% disp('  8) Discrete-time simulation of the thermal model or the building model (here only shown for the building model)');
% disp(' ');
% 
% % The class SimulationExperiment provides a simulation environment. An instantiation requires
% % a Building object that at least containts a thermal model and a the sampling time (this will be 
% % also the simulation timestep). Once the SimulationExperiment object is instantiated, its building 
% % object in  object cannot be manipulated anymore. 
% 
% SimExp = SimulationExperiment(B);
% 
% 
% % It is possible to print/access the identifiers and to access the model/simulation time step
% SimExp.printIdentifiers();
% identifiers = SimExp.getIdentifiers();
% len_v = length(identifiers.v);
% len_u = length(identifiers.u);
% len_x = length(identifiers.x);
% Ts_hrs = SimExp.getSamplingTime();
% 
% % Number of simulation time steps and initial condition must be set before the simulation
% n_timeSteps = 24*4;
% SimExp.setNumberOfSimulationTimeSteps(n_timeSteps);
% x0 = 22*ones(len_x,1);
% SimExp.setInitialState(x0);
% 
% % Simulation of the building model. The simulation environment allows 2 different simulation modes.
% %    1)   mode 'inputTrajectory':     Simulate the model with an input sequence provided by the user.
% %    2)   mode 'handle':              Simulate the model with an input sequence provided by a function handle associated with a function provided by the user.
% 
% mode = 1;
% 
% switch mode
% 
%    case 1
%       % set up input and disturbance sequence
%       V = zeros(len_v,n_timeSteps);
%       U = zeros(len_u,n_timeSteps);
%       idx_u_rad_Offices = getIdIndex('u_rad_Office_Rad_01',identifiers.u);
%       idx_v_Tamb = getIdIndex('v_Tamb',identifiers.v);
%       V(idx_v_Tamb,:) = 22; % ambient temperature to constant 22
%       U(idx_u_rad_Offices,5:end) = 5; % step of 5 W/m2 in the office radiators from the 5th timestep on
%       
%       [X,U,V,t_hrs] = SimExp.simulateBuildingModel('inputTrajectory',U,V);
%       
%    case 2
%       [X,U,V,t_hrs] = SimExp.simulateBuildingModel('handle',@demoUVGenerator);
%       
%    otherwise
%       error('Bad mode.');
%       
% end
% 
% 
% % Plot the simulation results. Every call to SimExp.plot generates a separate figure
% % The command takes a cell array of cells. Every cell produces a subplot for every
% % identifier contained in it.
% 
% firstFigure{1} = identifiers.x(1:7);         % any state/input/disturbance identifier can be used here
% firstFigure{2} = {'Z0001','Z0002'};          % zone identifiers work too
% firstFigure{3} = {'ZoneGrp_EG_N','Z0003'};   % zone group identifiers work too
% fh1 = SimExp.plot(firstFigure);
% 
% secondFigure{1} = identifiers.u;         
% secondFigure{2} = identifiers.v;          
% fh2 = SimExp.plot(secondFigure);


%% PUT TOGETHER A OBJECT OF STATE VARIABLE SIZES
%clear stateInputDisturbanceDimensions;
%stateInputDisturbanceDimensions.n_x     = size( B.building_model.discrete_time_model.A  , 2 );
%stateInputDisturbanceDimensions.n_u     = size( B.building_model.discrete_time_model.Bu , 2 );
%stateInputDisturbanceDimensions.n_xi    = size( B.building_model.discrete_time_model.Bv , 2 );

%returnDims                  = stateInputDisturbanceDimensions;

% If the constraints are time-varying then there is also a Maximum Time
% upto which the constraints will be defined
%returnTmax                  = 20;



%% PUT TOGETHER THE RETURN VARIABLES
returnB                     = B;
returnX0                    = [];
returnConstraintParams      = constraintsParameters;
returnCostParams            = costParameters;

% These are some placeholders that were not yet necessary
returnV                     = [];
returnDims                  = [];
returnTmax                  = [];




end
%% END OF FUNCTION

