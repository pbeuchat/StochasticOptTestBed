%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     runBlackBoxSimWithConfig.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnAllResults] = runBlackBoxSimWithConfig(inputBlackBoxInstructions)

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > Function to run the following steps:
%                   - Load the requested building model
%                   - Simulate each controller
%                   - Keep the results organised and return them
%               

%% --------------------------------------------------------------------- %%
%% EXTRACT THE INFORMATION FROM THE INPUT
% First check that it has the required fields
fieldsToCheckFor = { 'systemType' , 'systemIDRequest' , 'controllers' };
checkForFields( inputBlackBoxInstructions , fieldsToCheckFor );

% Get the system Type and ID requested
sysType     = inputBlackBoxInstructions.systemType;
sysID       = inputBlackBoxInstructions.systemIDRequest;

% Get the Full File Path to the Black Box location on this machine
bbFullPath = inputBlackBoxInstructions.fullPath;

% Get the cell array of controller specificatinos
controllerSpecArray = inputBlackBoxInstructions.controllers;
numControlTechniques = length(controllerSpecArray);

% Get the time horizon specification
timeStart           = inputBlackBoxInstructions.timeStart;
timeHorizon         = inputBlackBoxInstructions.timeHorizon;
timeUnits           = inputBlackBoxInstructions.timeUnits;

% Get the save results flag
flag_saveResults    = inputBlackBoxInstructions.flag_saveResults;

%% --------------------------------------------------------------------- %%
%% HANDLE THE DIFFERENT UNITS THE THE TIME COULD HAVE BEEN SPECIFIED IN

% We are not realy handling anything other than "steps" at the moment
if ~strcmp( timeUnits , 'steps' )
    disp(' ... ERROR: only time units of "steps" are handled at the moment, sorry :-(');
    error(bbConstants.errorMsg);
else
    timeIndex_start     = timeStart;
    timeIndex_end       = timeStart + timeHorizon;
end


%% --------------------------------------------------------------------- %%
%% GET THE CONSTATNS REQUIRED FOR RUNNING THE BLACK BOX
% This is uneccessary, the "bbConstants" class object is available at all
% times



%% --------------------------------------------------------------------- %%
%% LOAD THE BUILDING MODEL REQUESTED
tic; % Start the timer
% Keep the user updated
disp('******************************************************************');
disp([' Black-Box: Loading the "',sysType,'"-type model requested']);
disp('            and wrapping it together as a "Progress Model Engine" class');
% Load the building
[bbBuilding , bbX0 , bbConstraints , bbCosts , bbDisturbances ,  ] = load_forBlackBox_BuildingModel( sysID , bbFullPath );

clear buildingModelStruct;
buildingModelStruct.building        = bbBuilding;
buildingModelStruct.costs           = bbCosts;
buildingModelStruct.constraints     = bbConstraints;
buildingModelStruct.x0              = bbX0;

% Before creating the object, check that the Building Model Class is a
% subclass of "ModelCostConstraints" and that it is a concrete class:
bbConstants.checkObjIsSubclassOf(ModelCostConstraints_Building,'ModelCostConstraints',1);
bbConstants.checkObjConcrete(ModelCostConstraints_Building,1);

% Create a "Model-Cost-Constraints" class object for this building
clear sysModel;
sysModel = ModelCostConstraints_Building(buildingModelStruct, sysType);

% Extract the "StateDef" definition of the State, Input and Disturbance
stateDef = requestStateDefObject( sysModel );


% Extract the "ConstraintDef" definition object
constraintDef = requestConstraintDefObject( sysModel );

% Extract the "ConstraintDef" definition object
[~] = requestCostDefObject( sysModel );


% Wrap the "Progress Model Engine" class around the model so that the
% interface is always consistent
myProgModelEng = ProgressModelEngine(sysModel,sysType);

% Store the time taken for this section
timedResults.loadModel = toc;
%% --------------------------------------------------------------------- %%
%% LOAD THE DISTURBANCE MODEL REQUESTED
tic;
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Loading the disturbance model requested');
disp('            and wrapping it together as a "Distrubance Coordinator" class');

% Instantiate a "Disturbance Coordinator" object
% This requires the identifier for the disturbance model to be used
thisDistIdentifier  = '001';
thisRecomputeStats  = 0;
distCoord           = Disturbance_Coordinator(thisDistIdentifier);

statsRequired = {'mean','cov','bounds_boxtype'};

thisSuccess = checkStatsAreAvailable_ComputingAsRequired( distCoord , statsRequired , thisRecomputeStats);
if ~thisSuccess
    disp(' ... ERROR: the Disturbance Coordinator was unable to make the required Predicitons for some reason');
    error(bbConstants.errorMsg);
end

% Store the time taken for this section
timedResults.loadDisturbance = toc;
%% --------------------------------------------------------------------- %%
%% INITIALISE A GLOBAL CONTROL COORDINATOR FOR EACH CONTROLLER SPEC
tic;
% This simply creates an array of "Control_GlobalCoordinator" objects and
% initialise each one with ONLY the specifications
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Initialising the Global Coordinator for controller interfacing');

% Initialises the cell array, this will be filled with an object of type
% "Control_Coordinator" for each of the controller specs given
clear myControlCoordArray;
myControlCoordArray     = Control_Coordinator.empty(numControlTechniques,0);
mySettingsControlArray  = cell(numControlTechniques,1);
% Iterated through the controller specs
for iController = 1:numControlTechniques
    % Get the Specifications struct for this controller
    thisControllerSpec = controllerSpecArray{iController};
    % Get the individual Specs for this controller
    thisClassNameLocal      = thisControllerSpec.classNameLocal;
    thisClassNameGlobal     = thisControllerSpec.classNameGlobal;
    thisVararginLocal       = thisControllerSpec.vararginLocal;
    thisVararginGlobal      = thisControllerSpec.vararginGlobal;
    % Create the Global Coordinator for this controller
    myControlCoordArray(iController,1) = Control_Coordinator(thisClassNameLocal , thisClassNameGlobal , thisVararginLocal , thisVararginGlobal , stateDef , constraintDef , sysType);
    
    % Put together the setting for the Global Coord Initialise function
    clear thisSettings;
    thisSettings.modelFree          = thisControllerSpec.modelFree;
    thisSettings.trueModelBased     = thisControllerSpec.trueModelBased;
    thisSettings.globalInit         = thisControllerSpec.globalInit;
    
    % Put the struct of setting into the Array
    mySettingsControlArray{iController,1} = thisSettings;
end


% Store the time taken for this section
timedResults.initCtrl_Coord = toc;
%% --------------------------------------------------------------------- %%
%% INITIALISE THE LOCAL CONTROLLER INTERFACE
tic;
% This is done via the Global Coordinator, and invloves calling the
% "Initialise Handle"
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Initialising the Local Controller Interfaces');

% Iterated through the controller specs
for iController = 1:numControlTechniques
    % Get the settings for this controller
    clear thisSettings;
    thisSettings = mySettingsControlArray{iController,1};
    
    % Call the initialisation function for the Control Coordinator
    % Within the initialisation this will:
    %   > Call the initialisation functions of both the Global and Local
    %     controller classes
    %   > Only pass on the "sysModel" to these initialisation functions
    %     base on if specified as "Model-Based" versus "Model-Free"
    initialiseControllers( myControlCoordArray(iController,1) , thisSettings , sysModel );
    
end

% Store the time taken for this section
timedResults.initCtrl_Controllers = toc;
%% --------------------------------------------------------------------- %%
%% SIMULATE EACH CONTROLLER ON THE SAME BUILDING MODEL AND DISTURBANCE SCENARIO

%% First Initialise all the specifications for the simiultation
tic;
% Instantiating a "Simulation Object" for each controller
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: creating a Simulation instance for testing each contoller');

% Initialises the cell array, this will be filled with an object of type
% "Simulation_Coordinator" for each of the controller specs given
clear mySimCoordArray;
mySimCoordArray     = Simulation_Coordinator.empty(numControlTechniques,0);
%mySettingsSimArray  = cell(numControlTechniques,1);
% Iterate through the controller specs
for iController = 1:numControlTechniques
    % Get the Specifications struct for this controller
    %thisControllerSpec = controllerSpecArray{iController};
    
    % Create the Global Coordinator for this controller
    mySimCoordArray(iController,1) = Simulation_Coordinator( distCoord , myControlCoordArray(iController,1) , myProgModelEng , stateDef );
    
    % Set the parameters for the simulation
    specifySimulationParameters( mySimCoordArray(iController,1) , timeIndex_start , timeIndex_end , flag_saveResults);
    
    % Check that the components of the simulation are compatible
    flag_throwError = true;
    this_isCompatible = checkSimulationCompatability( mySimCoordArray(iController,1) , flag_throwError );
    if ~(this_isCompatible)
        disp(' ... ERROR: the simulation for Control Technique number "',num2str(iController),'" is incompatable and will not be run');
    end
    
    % Finally check that the simulation is ready to be run
    flag_throwError = true;
    this_isReady = checkSimulationIsReadyToRun( mySimCoordArray(iController,1) , flag_throwError );
    if ~(this_isReady)
        disp(' ... ERROR: the simulation Coordinator Object has been instantiated and intialised, but for some reason is not "ready" for simulation');
    end
    
    % Put together the setting for the Global Coord Initialise function
    %clear thisSettings;
    %thisSettings.modelFree          = thisController.modelFree;
    %thisSettings.trueModelBased     = thisController.trueModelBased;
    %thisSettings.globalInit         = thisController.globalInit;
    
    % Put the struct of setting into the Array
    %mySettingsControlArray{iController,1} = thisSettings;
end



% Store the time taken for this section
timedResults.initSimulationObject = toc;

%% Before running the Simulations, inform the user of the overall initialisation time
timedResults.initTotal =   timedResults.loadModel ...
                         + timedResults.loadDisturbance ...
                         + timedResults.initCtrl_Coord ...
                         + timedResults.initCtrl_Controllers ...
                         + timedResults.initSimulationObject;
disp(' ');
disp( '******************************************************************');
disp( ' Black-Box: Everything is now initialised to run simulations');
disp( '            The total time for performing all the initialisation functions was:');
disp(['                ', num2str(timedResults.initTotal) ]);


%% NOW RUN THE SIMULATIONS
tic;
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Running the simulation for each contoller on the same');
disp('            Building Model and Disturbance Scenarios');
tic;
% Iterated through the controller specs
for iController = 1:numControlTechniques
    % Run the simulation
    thisCompletedSuccessfully = runSimulation( mySimCoordArray(iController,1) );
    
    % If not completed successfully, inform the user
    if ~thisCompletedSuccessfully
        thisControllerSpec = controllerSpecArray{iController};
        disp([' ... ERROR: the simulation did not successfully run for Control Technique number ',num2str(iController) ]);
        disp( '            The results from this technique should not be trusted' );
        disp( '            To help you identify which control technique this was, its details are:' );
        disp(['            Label:             ',thisControllerSpec.label ]);
        disp(['            classNameLocal:    ',thisControllerSpec.classNameLocal ]);
        disp(['            classNameGlobal:   ',thisControllerSpec.classNameGlobal ]);
    end
    
end

% This loop naturally suits parallelisation, see this links for some
% details about parallelising in Maltab:
% <http://www.mathworks.ch/help/distcomp/parallel-for-loops-parfor.html>
% These seem to be the two easiest functions to call on:
% parfeval();
% parfor iController = 1:numControlTechniques



% Store the time taken for this section
timedResults.runAllSimulations = toc;
% Give the user a little bit of info
disp([' ... INFO: ',num2str(numControlTechniques),' controllers were run for ',num2str((timeIndex_end-timeIndex_start+1)),' time steps each, this was completed in ',num2str(timedResults.runAllSimulations),' seconds']);
%% --------------------------------------------------------------------- %%
%% PUT TOGETHER THE RETURN VARIABLES
returnAllResults = [];


end
%% END OF FUNCTION

%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
%  HOW TO USE:  1) No "User Options" (aka. "pre-compile" switches)
%                   to seelct for this function
%
% INPUTS:
%       > xxx
%
% OUTPUTS:
%       > yyy
%
%
%
%% A COPY OF THE CONTROLLER SPECIFICATIONS SYNTAX (taken from main.m)
% The following fields must be specified for every controller:
% Property Name     Type        Description
% -------------------------------------------------------------------------
% .label            string      A few words specifying the controller
% .legend           string      A few characters to use for plotting
% .modelFree        numeric     1 = Model-Free,   0 = Model-Based
%                               This affect what is passed to the
%                               controller functions
% .trueModelBased   numeric     A Model-Based controller is provided with
%                                   1 = the true model
%                                   0 = a model that deviates from the true
% .funcHandleInit   fnchandle   Must exist with exact spelling in the
%                               "Controllers" sub-directory
%                               - See comments at bottom of this file for a
%                                 full description of the input/output
%                                 syntax
% .funcHandleMain   fnchandle   Same same


% The following fields can OPTIONALLY be specified if desired:
% Property Name     Type        Description
% -------------------------------------------------------------------------
% .description      string      (optional) A more long winded description
% .vararginInit     any         (optional) This will be passed to
%                               "funcHandleInit" when called
% .vararginMain     any         (optional) This will be passed to
%                               "funcHandleMain" when called


