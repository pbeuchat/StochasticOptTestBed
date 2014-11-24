%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     main.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %


%  ---------------------------------------------------------------------  %
%  PACKAGE:     Black-Box Simulation-Based Stochastic Optimisation Test-Bed
%  AUTHOR:      Paul N. Beuchat - Copyright (C) 2014
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Stochastic Optimisation Test-Bed
%
%  DESCRIPTION: > This script should be all that is required to run a test
%               > This script is used to:
%                   - Specify which Black-Box (i.e. which building) to use
%                   - Specify the controllers to be applied to the Test-Bed
%                   - Initiate the Test-Bed
%                   - Run identical tests for all the controllers specified
%                   - Plot a comparison of the performance
%
%  HOW TO USE:  > Fill in the user inputs below
%               > Then run the script
%
%  ---------------------------------------------------------------------  %

%% --------------------------------------------------------------------- %%
%% CLEAR and CLOSE EVERYTHING
clear all;
close all
clc;

%% --------------------------------------------------------------------- %%
%% ADD ALL THE NECESSARY COMPONENTS TO THE PATH
%  NOTE: if you need extra scripts, toolboxes, etc. added to the path, then
%        they should be added in the controller initialisation function and
%        not here. This allows for a very explicit separation between the
%        black box environment and the controller functions
addpath(genpath( 'BlackBox' ));
addpath(genpath( 'Controllers' ));
addpath(genpath( 'Outputs' ));
addpath(genpath( 'Plotting' ));
addpath( 'ClassDefs' );
constants_MachineSpecific.addUserSpecifiedPaths();

% Get the Full Path to this script
tempPath = mfilename('fullpath');
thisFullPath = tempPath( 1 : end-(length(mfilename)+1) );

% and change to the directory of this script
cd(thisFullPath);

%% --------------------------------------------------------------------- %%
%% USER DEFINED INPUTS:

%% SELECT THE BUILDING TO BE USED WITHIN THE BLACK-BOX:
% The systems to choose from are:
%   'building'
%   '...'

% For 'building's, the "systemIDRequest" should be a string of length 3,
% that selects from the following:
% '001' = a small 8 room building
% '002' = ...
% '003' = ...

systemType          = 'building';
systemIDRequest     = '001';



%% SPECIFY THE TIME HORIZON FOR WHICH TO RUN THE SIMULATIONS

timeStart       = 1;
timeHorizon     = 24*50;
timeUnits       = 'steps'; % Possible Units: 'steps', 'mins', 'hours', 'days'


%% SPECIFY WHETHER THE SIMULATION RESULTS SHOULD BE SAVED FOR NOT

flag_saveSimResults = true;


%% SPECIFY THE CONTROLLERS TO BE SIMULATED ON THE TEST-BED
disp(' '); disp(' ');
disp('------------------------------------------------------------------');
disp(' Reading in the controller specifications')

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
% .globalInit       numeric     1 = All problem data is passed to the
%                               controller Init functoin
%                               0 = A pre-defined split of the problem into
%                               sub-systems is used and based on this the
%                               controller Init function is called once per
%                               sub-system, passing only problem data
%                               relevant to that sub-system


% The following fields can OPTIONALLY be specified if desired:
% Property Name     Type        Description
% -------------------------------------------------------------------------
% .description      string      (optional) A more long winded description
% .vararginInit     any         (optional) This will be passed to
%                               "funcHandleInit" when called
% .vararginMain     any         (optional) This will be passed to
%                               "funcHandleMain" when called


% Initialise a cell for the various controller specs
cntrSpecs = cell(20,1);
% Initialise the counter
numCntr = 0;


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'Null Controller Local Only';
cntrSpecs{numCntr}.legend           = 'Null Local';
cntrSpecs{numCntr}.modelFree        = true;
cntrSpecs{numCntr}.trueModelBased   = [];
cntrSpecs{numCntr}.classNameLocal   = 'Control_Null';
cntrSpecs{numCntr}.classNameGlobal  = [];
cntrSpecs{numCntr}.globalInit       = false;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'A Null controller that always returns 0 input';
thisVararginLocal                   = 'one';
cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
cntrSpecs{numCntr}.vararginGlobal   = [];


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'Null Controller Central';
cntrSpecs{numCntr}.legend           = 'Null Central';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_Null_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_Null_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'A Null controller that always returns 0 input';
thisVararginLocal                   = 'one';
cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;




% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP_Cent';
% cntrSpecs{numCntr}.modelFree        = 0;
% cntrSpecs{numCntr}.trueModelBased   = 1;
% cntrSpecs{numCntr}.classNameLocal   = str2func( 'Control_ADPCentral' );
% cntrSpecs{numCntr}.classNameGlobal  = str2func( 'Control_ADPCentral' );
% cntrSpecs{numCntr}.globalInit       = 1;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% thisVararginLocal                   = 'one';
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% thisVararginMain                    = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginMain;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Model Free';
% cntrSpecs{numCntr}.legend           = 'ModelFree';
% cntrSpecs{numCntr}.modelFree        = 1;
% cntrSpecs{numCntr}.trueModelBased   = 0;
% cntrSpecs{numCntr}.classNameLocal   = str2func( 'Control_ModelFree' );
% cntrSpecs{numCntr}.classNameGlobal  = str2func( 'Control_ModelFree' );
% cntrSpecs{numCntr}.globalInit       = 0;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'Model Free Controller';
% thisVararginLocal                   = 'three';
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% thisVararginGlobal                  = 'four';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


%% --------------------------------------------------------------------- %%
%% RUN THE TEST-BED
disp(' '); disp(' ');
disp('------------------------------------------------------------------');
disp(' Passing the configuration to the Black-Box, from main.m');

% Convert the Control Specifications into "instructions" for the Black-Box
clear blackBoxInstructions;
blackBoxInstructions = struct();
blackBoxInstructions.fullPath           = thisFullPath;

blackBoxInstructions.systemType         = systemType;
blackBoxInstructions.systemIDRequest    = systemIDRequest;

blackBoxInstructions.controllers        = cell(numCntr,1);
blackBoxInstructions.controllers(:,1)   = cntrSpecs(1:numCntr,1);
clear cntrSpecs;

blackBoxInstructions.timeStart          = timeStart;
blackBoxInstructions.timeHorizon        = timeHorizon;
blackBoxInstructions.timeUnits          = timeUnits;

blackBoxInstructions.flag_saveResults   = flag_saveSimResults;


% Initialise some variables to contain the results
allResults = runBlackBoxSimWithConfig(blackBoxInstructions);

disp(' '); disp(' ');
disp('------------------------------------------------------------------');
disp(' Black-Box has finished running and all results returned to main.m');


%% --------------------------------------------------------------------- %%
%% PLOT SOME COMPARITIVE RESULTS
disp(' '); disp(' ');
disp('------------------------------------------------------------------');
disp(' Now plotting some comparitive results');
%plotAll(allResults);


%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
% -> SYNTAX FOR ".funcHandleInit"
%       INPUTS
%           - If Model-Based, then a bi-linear state space model of the
%             building system
%           - The number of control inputs
%           - The control input constraints
%           - The initial conidtion of the state
%           - ...
%       OUTPUTS
%           - The configuration of the controller
%
% -> SYNTAX FOR ".funcHandleInit"
%       INPUTS
%           - The current value for the Objective Function at this step
%           - The current value of the state at this step
%           - The constant part of the controller configuration
%           - The varying part of the controller configuratin
%           - ...
%       OUTPUTS
%           - The input to apply to the system
%           - The updated varying part of the controller configuratin
%           - ...
%
%  HOW TO USE:  1) ...
%
% INPUTS:
%       > ...
%
% OUTPUTS:
%       > ...
%