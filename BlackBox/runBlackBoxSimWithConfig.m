function [returnAllResults, returnSavePath, object_system, object_disturbance] = runBlackBoxSimWithConfig(inputBlackBoxInstructions)
%  runBlackBoxSimWithConfig.m
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > Function to run the following steps:
%                   - Load the requested building model
%                   - Simulate each controller
%                   - Keep the results organised and return them
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



%% --------------------------------------------------------------------- %%
%% EXTRACT THE INFORMATION FROM THE INPUT
% First check that it has the required fields
fieldsToCheckFor = { 'systemType' , 'systemIDRequest' , 'controllers' };
checkForFields( inputBlackBoxInstructions , fieldsToCheckFor );

% Get the system Type and ID requested
sysType     = inputBlackBoxInstructions.systemType;
sysID       = inputBlackBoxInstructions.systemIDRequest;
sysOptions  = inputBlackBoxInstructions.systemOptions;
 
% Get the disturbance model ID requested and the options for loading it
distID       = inputBlackBoxInstructions.disturbanceIDRequest;
distOptions  = inputBlackBoxInstructions.disturbanceOptions;

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

% Get the perform control simulations flag
flag_performControlSimulations      = inputBlackBoxInstructions.flag_performControlSimulations;
% Get the flag for whether to return the various object or not
flag_returnObjectsToWorkspace       = inputBlackBoxInstructions.flag_returnObjectsToWorkspace;

% Get the flag for whether to perform a deterministic simulation or not
flag_deterministicSimulation        = inputBlackBoxInstructions.flag_deterministicSimulation;

% Get the seed for controlling repeatability of runs
seed_forSimulation                  = inputBlackBoxInstructions.seed_forSimulation;
% Get the random number "Generator Type" for how to draw random samples
seed_RandNumGeneratorType           = inputBlackBoxInstructions.seed_RandNumGeneratorType;

% Get the details stuct about "Evaulating Multiple Realisations"
details_evalMultiReal               = inputBlackBoxInstructions.details_evalMultiReal;


% Get the plotting flags:
flag_plotResults                        = inputBlackBoxInstructions.flag_plotResults;
flag_plotResultsPerController           = inputBlackBoxInstructions.flag_plotResultsPerController;
flag_plotResultsControllerComparison    = inputBlackBoxInstructions.flag_plotResultsControllerComparison;
plotResults_unitsForTimeAxis            = inputBlackBoxInstructions.plotResults_unitsForTimeAxis;


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
timerStart = clock; % Start the timer
% Keep the user updated
disp('******************************************************************');
disp([' Black-Box: Loading the "',sysType,'"-type model requested']);
disp('            and wrapping it together as a "Progress Model Engine" class');
% Load the building
[bbBuilding , bbX0 , bbStateDef, bbConstraints , bbCostDef ] = load_forBlackBox_BuildingModel( sysID , bbFullPath , sysOptions );

disp(' DEBUGGING: If this is displayed then the load function was finished before the crash...');

clear buildingModelStruct;
buildingModelStruct.building        = bbBuilding;
buildingModelStruct.stateDef        = bbStateDef;
buildingModelStruct.costDef         = bbCostDef;
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
%stateDef = requestStateDefObject( sysModel );
stateDef = bbStateDef;


% Extract the "ConstraintDef" definition object
constraintDef = requestConstraintDefObject( sysModel );

% NOTE: This was moved into the "load_forBlackBox_BuildingModel" function
% Extract the "CostDef" definition object
%costDef = requestCostDefObject( sysModel );
costDef = requestCostDefObject( sysModel );


% Wrap the "Progress Model Engine" class around the model so that the
% interface is always consistent
myProgModelEng = ProgressModelEngine(sysModel,sysType);

% Store the time taken for this section
timedResults.loadModel = etime(clock,timerStart);
%% --------------------------------------------------------------------- %%
%% LOAD THE DISTURBANCE MODEL REQUESTED
timerStart = clock;
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Loading the disturbance model requested');
disp('            and wrapping it together as a "Distrubance Coordinator" class');

% Instantiate a "Disturbance Coordinator" object
% This requires the identifier for the disturbance model to be used
thisDistIdentifier  = distID;
thisRecomputeStats  = distOptions.recomputeStats;
distCoord           = Disturbance_Coordinator(thisDistIdentifier);

statsRequired = distOptions.statsRequired;

thisSuccess = checkStatsAreAvailable_ComputingAsRequired( distCoord , statsRequired , thisRecomputeStats);
if ~thisSuccess
    disp(' ... ERROR: the Disturbance Coordinator was unable to make the required Predicitons for some reason');
    error(bbConstants.errorMsg);
end

% Store the time taken for this section
timedResults.loadDisturbance = etime(clock,timerStart);

%% --------------------------------------------------------------------- %%
%% ALL CONTROL SIMULATION REQUIRED STEPS CAN BE SKIPPED IF NOT REQUESTED
if flag_performControlSimulations

%% --------------------------------------------------------------------- %%
%% INITIALISE A GLOBAL CONTROL COORDINATOR FOR EACH CONTROLLER SPEC
timerStart = clock;
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
    myControlCoordArray(iController,1) = Control_Coordinator(thisClassNameLocal , thisClassNameGlobal , thisVararginLocal , thisVararginGlobal , stateDef , constraintDef , sysType , sysID , distID );
    
    % Put together the setting for the Global Coord Initialise function
    clear thisSettings;
    thisSettings.modelFree          = thisControllerSpec.modelFree;
    thisSettings.trueModelBased     = thisControllerSpec.trueModelBased;
    thisSettings.globalInit         = thisControllerSpec.globalInit;
    
    % Put the struct of setting into the Array
    mySettingsControlArray{iController,1} = thisSettings;
end


% Store the time taken for this section
timedResults.initCtrl_Coord = etime(clock,timerStart);
%% --------------------------------------------------------------------- %%
%% INITIALISE THE LOCAL CONTROLLER INTERFACE
timerStart = clock;
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
    initialiseControllers( myControlCoordArray(iController,1) , thisSettings , sysModel , distCoord );
    
end

% Store the time taken for this section
timedResults.initCtrl_Controllers = etime(clock,timerStart);
%% --------------------------------------------------------------------- %%
%% SIMULATE EACH CONTROLLER ON THE SAME BUILDING MODEL AND DISTURBANCE SCENARIO

%% First Initialise all the specifications for the simiultation
timerStart = clock;
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
    mySimCoordArray(iController,1) = Simulation_Coordinator( distCoord , myControlCoordArray(iController,1) , myProgModelEng , stateDef , costDef , constraintDef );
    
    % Set the parameters for the simulation
    specifySimulationParameters( mySimCoordArray(iController,1) , timeIndex_start , timeIndex_end , seed_forSimulation , seed_RandNumGeneratorType , flag_saveResults , flag_deterministicSimulation, details_evalMultiReal);
    
    % Check that the components of the simulation are compatible
    flag_throwError = true;
    this_isCompatible = checkSimulationCompatability( mySimCoordArray(iController,1) , flag_throwError );
    if ~(this_isCompatible)
        disp(' ... ERROR: the simulation for Control Technique number "',num2str(iController),'" is incompatable and will not be run');
    end
    
    % Next check that the simulation is ready to be run
    flag_throwError = true;
    this_isReady = checkSimulationIsReadyToRun( mySimCoordArray(iController,1) , flag_throwError );
    if ~(this_isReady)
        disp(' ... ERROR: the simulation Coordinator Object has been instantiated and intialised, but for some reason is not "ready" for simulation');
    end
    
    % To allow parallel simulation create cell array of disturbance
    % coordinators, each initialised with a random number generator to
    % allow for repeatability of the results
    this_parallelInitialised = prepareDetailsFor_MultipleDistCoord_ForParallelSimulations( mySimCoordArray(iController,1) );
    if ~(this_parallelInitialised)
        disp(' ... ERROR: the Simulation Coordinator Object could not successfully make a deep copy of the disturbance Coordinator object for parallel simulations');
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
timedResults.initSimulationObject = etime(clock,timerStart);

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


%% CREATE A FOLDER IN WHICH TO SAVE THE SIMULATION RESULTS

if flag_saveResults
    % Get the Root Path for where to save everything
    savePath_Root = constants_MachineSpecific.saveDataPath;

    % Path for Save Simulations Results Data
    savePath_Results = [savePath_Root,'savedResults/'];
    if ~(exist(savePath_Results,'dir') == 7)
        mkdir(savePath_Results);
    end

    % Get a string for the current time to name the save folder
    [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();

    % Save Path for the time of this run
    savePath_Results_thisTime = [ savePath_Results , currDateStr , '_' , currTimeStr ,'/' ];
    if ~(exist(savePath_Results_thisTime,'dir') == 7)
        mkdir(savePath_Results_thisTime);
    end
    
    
    % Should run a look here to check that all the ".saveFolderName"
    % properties are unique
    %for iController = 1:numControlTechniques
    %    
    %end
    
else
    % Set the "savePath_Results_thisTime" variable as blank for the retrn
    savePath_Results_thisTime = [];
    
end




%% NOW RUN THE SIMULATIONS
timerStart = clock;
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Running the simulation for each contoller on the same');
disp('            Building Model and Disturbance Scenarios');

% Initialise an empty cell array for storing all the results
allResults          = cell( numControlTechniques , 1 );
allDataFileNames    = cell( numControlTechniques , 1 );

% Initialise a flag required
passedSameDisturbanceToAllSimulators = false;

% Iterated through the controller specs
for iController = 1:numControlTechniques
    % Start a timer for this control technique
    thisStartTime = clock;
    
    % Get the specification for this control technique
    thisControllerSpec = controllerSpecArray{iController};
    
    % Create a folder to save the results for this Control Technique
    if flag_saveResults
        savePath_Results_thisTime_thisTechnique = [ savePath_Results_thisTime , controllerSpecArray{iController,1}.saveFolderName ,'/' ];
        if ~(exist(savePath_Results_thisTime_thisTechnique,'dir') == 7)
            mkdir(savePath_Results_thisTime_thisTechnique);
        end
    else
        savePath_Results_thisTime_thisTechnique = [];
    end
    
    % Inform the use about the simulation that is about to be run
    disp( ' ');
    disp( ' ... INFO: The following simulation will now commence:' );
    disp(['            Controller:                    "',thisControllerSpec.label ,'"' ]);
    disp(['            # Time Steps per realisation:   ',num2str((timeIndex_end-timeIndex_start+1)) ]);
    disp(['            # of realisations:              ',num2str(2) ]);
    
    % RUN THE SIMULATION:
    [thisCompletedSuccessfully , allResults{iController,1} , savedDataFileNames] = runSimulation( mySimCoordArray(iController,1) , savePath_Results_thisTime_thisTechnique );
    
    % Keep the results into one big struct
    allDataFileNames{iController,1} = savedDataFileNames;
    
    
    % If completed successfully then store the names of the files saved
    % (saved into the same folder as the results)
    % NOTE: the "controllerSpecArray" will be saved directly in the root
    % "savePath_Results_thisTime" folder so that it can be used to
    % unambiguously get the folder names in which the results are saved.
    if thisCompletedSuccessfully
        if flag_saveResults
            save( [savePath_Results_thisTime_thisTechnique,'savedDataFileNames.mat'] , 'savedDataFileNames' , '-v7.3' );
        end
        
    % If not completed successfully, inform the user
    else
        %thisControllerSpec = controllerSpecArray{iController};
        disp([' ... ERROR: the simulation did not successfully run for Control Technique number ',num2str(iController) ]);
        disp( '            The results from this technique should not be trusted' );
        disp( '            To help you identify which control technique this was, its details are:' );
        disp(['            Label:             ',thisControllerSpec.label ]);
        disp(['            classNameLocal:    ',thisControllerSpec.classNameLocal ]);
        disp(['            classNameGlobal:   ',thisControllerSpec.classNameGlobal ]);
    end
    % Store the time taken for this section
    thisTime = etime(clock,thisStartTime);
    % Give the user a little bit of info
    disp([' ... INFO: ',num2str(thisTime),' seconds elapsed using the following:' ]);
    disp(['            Controller:                    "',thisControllerSpec.label ,'"' ]);
    disp(['            # Time Steps per realisation:   ',num2str((timeIndex_end-timeIndex_start+1)) ]);
    if details_evalMultiReal.flag_evaluateOnMultipleRealisations
        disp(['            # of realisations:              ',num2str(details_evalMultiReal.numSamplesUserSpec) ]);
    else
        disp( '            # of realisations:              1' );
    end
    disp(' ');


    
    if ~details_evalMultiReal.flag_evaluateOnMultipleRealisations
        % TO ENSURE THAT EVERY CONTROLLER SEES THE SAME DISTURBANCE
        % This is also for some computational efficiency because it "should" be
        % quicker than starting with the same seed and generating the same
        % random number that are from the same sequence
        if ~passedSameDisturbanceToAllSimulators && (numControlTechniques > 1)
            % If the field exists
            if isfield( allResults{iController,1} , 'xi' )
                % Then get the disturbance sequence that was used
                tempXi = allResults{iController,1}.xi.data;
                % A flag for whether to throw errors or not
                temp_flag_throwError = false;
                % Now step through all the remaining Simulations and add this
                % same disturbance sequence to their property
                for iTemp = (iController+1) : numControlTechniques
                    % Add the data
                    specifyPrecomputedDisturbances( mySimCoordArray(iTemp,1) , tempXi );
                    % Check the compatibility
                    returnIsCompatible = checkSimulationCompatability( mySimCoordArray(iTemp,1) , temp_flag_throwError );
                    % If the compatibility check failed
                    if ~returnIsCompatible
                        % then remove the disturbance data
                        specifyPrecomputedDisturbances( mySimCoordArray(iTemp,1) , false );
                        % and check the compatability again
                        checkSimulationCompatability( mySimCoordArray(iTemp,1) , temp_flag_throwError );
                    end
                end
            end
            % Set the flag so that we don't do this again
            passedSameDisturbanceToAllSimulators = true;
        end
        % END OF: "if passedSameDisturbanceToAllSimulators && (numControlTechniques > 1)"
    end
    
end

% NOW SAVE THE "controllerSpecArray" directly in the root
    % "savePath_Results_thisTime" folder so that it can be used to
    % unambiguously get the folder names in which the results are saved.
if flag_saveResults
    save( [savePath_Results_thisTime,'controllerSpecArray.mat'] , 'controllerSpecArray' , '-v7.3' );
end


% This loop naturally suits parallelisation, see this links for some
% details about parallelising in Maltab:
% <http://www.mathworks.ch/help/distcomp/parallel-for-loops-parfor.html>
% These seem to be the two easiest functions to call on:
% parfeval();
% parfor iController = 1:numControlTechniques



% Store the time taken for this section
timedResults.runAllSimulations = etime(clock,timerStart);
% Give the user a little bit more info for the cumulative time
disp(' ');
disp([' ... INFO: ',num2str(numControlTechniques),' controllers were run for ',num2str((timeIndex_end-timeIndex_start+1)),' time steps each, this was completed in ',num2str(timedResults.runAllSimulations),' seconds']);
disp(' ');
%% --------------------------------------------------------------------- %%
%% NOW PLOT THE RESULTS
timerStart = clock;

% Only plot results if requested to do so
if flag_plotResults
    
    % Keep the user updated
    disp('******************************************************************');
    disp(' Black-Box: Plotting the simulation results');

    
    % BUILD A STRUCT WITH THE SELECTED OPTIONS FOR THE PLOTTING
    clear plotOptions;
    plotOptions.unitsForTimeAxis = plotResults_unitsForTimeAxis;
    plotOptions.flag_plotResultsPerController = flag_plotResultsPerController;
    plotOptions.flag_plotResultsControllerComparison = flag_plotResultsControllerComparison;
    
    
    % CALL THE GENERAL PLOTTING FUNCTION
    % (the idea is that this function can be equally called separately to
    % plot saved date)
    
    
    % PLOT THE PER-CONTROLLER RESULTS
    if flag_plotResultsPerController
        % Iterated through the controller specs
        for iController = 1:numControlTechniques
            % Visualise the results for each controller
            Visualisation.visualise_singleController( controllerSpecArray{iController,1} , allResults{iController,1} , allDataFileNames{iController,1} , plotOptions );
        end
    end
    % END OF: "if flag_plotResultsPerController"
    
    % PLOT THE A COMPARISON OF THE CONTROLLER RESULTS
    if flag_plotResultsControllerComparison
        % Don't bother calling the plotting function if only 1 control
        % technique was simulated...
        if numControlTechniques > 1
            % The cell array of "allDataFileNames" should be consolidated
            % to only include file names that exists for multiple
            % controllers
            % For now we will cheat and assume they all have 'x', 'u' and
            % 'cost'
            
            % Visualise the comparative results for ALL controller
            Visualisation.visualise_multipleControllers( controllerSpecArray(:,1) , allResults(:,1) , allDataFileNames{iController,1} , plotOptions );
        end
        
    end

end
% END OF: "if flag_plotResultsPerControllerflag_plotResults"

% Store the time taken for this section
timedResults.plotResults = etime(clock,timerStart);
%% --------------------------------------------------------------------- %%
%% ELSE: if NOT "flag_performControlSimulations", then do some BOOK KEEPING to make things work smoothly
else
    %returnAllResults = [];
    savePath_Results_thisTime = [];
    
    
end
% END OF: "if flag_performControlSimulations"


%% --------------------------------------------------------------------- %%
%% PUT TOGETHER THE RETURN VARIABLES

% Either as empty or with the actual data depending on the flag
if flag_returnObjectsToWorkspace

    returnAllResults = allResults;
    
    returnSavePath = savePath_Results_thisTime;
    
    object_system = sysModel;
    
    object_disturbance = distCoord;
    
else
    clear returnAllResults;
    returnAllResults = [];
    
    % Still return the path
    returnSavePath = savePath_Results_thisTime;
    
    clear object_system;
    object_system = [];
    
    clear object_disturbance;
    object_disturbance = [];
    
end


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


