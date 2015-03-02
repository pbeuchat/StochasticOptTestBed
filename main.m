%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     main.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %

% VERSION:          v1.01
% DATE PUBLISHED:   23-Jan-2015

%  ---------------------------------------------------------------------  %
%  PACKAGE:     Black-Box Simulation-Based Stochastic Optimisation Test-Bed
%  AUTHOR:      Paul N. Beuchat - Copyright (C) 2014
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
%clear all;
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

%% SELECT THE SYSTEM MODEL TO BE USED WITHIN THE BLACK-BOX:
% The systems to choose from are:
%   'building'
%   '...'

% For 'building's, the "systemIDRequest" should be a string of length 7,
% that selects from the following:
% '001_001' = a small 1 room building
% '002_001' = a small 7 room, 2 storey building
% '003_001' = a single floor in the Basel OptiControl 2 Building

systemType          = 'building';
systemIDRequest     = '002_001';


% Some options for what to do with the system that is loaded
clear systemOptions;
systemOptions.displaySystemDetails         = false;
systemOptions.drawSystem                   = false;
systemOptions.plotContTimeModelSparisity   = false;
systemOptions.discretisationMethod         = 'default';  % 'default','euler','expm'




%% SELECT THE DISTURBANCE MODEL TO BE USED WITHIN THE BLACK-BOX:

% Need to make a list of what the various disturbance's are

disturbanceIDRequest  = '002_004';

% Some options for what to do with the disturbance model that is loaded
clear disturbanceOptions;
% Use this flag to force the statistics to be recompute
% OPTIONS: true, false
disturbanceOptions.recomputeStats  = false;
% Use this option as a cell array of strings specifying the statistics to
% be compute in advance of the controller instructing the statistics is
% requires
% OPTIONS: 'mean', 'cov', 'bounds_boxtype'
disturbanceOptions.statsRequired = {'mean','cov','bounds_boxtype'};



%% SPECIFY THE TIME HORIZON FOR WHICH TO RUN THE SIMULATIONS

timeStart       = 1;
timeHorizon     = 2*4;% (24*4) * 4;
timeUnits       = 'steps'; % Possible Units: 'steps', 'mins', 'hours', 'days'


%% SPECIFY WHETHER THE SIMULATION RESULTS SHOULD BE SAVED FOR NOT

flag_saveSimResults = false;        % "true" or "false"


%% SPECIFY WHETHER THE CONTROL SIMULATIONS SHOULD BE RUN OR NOT
% This option can be used if the user only wants to plot the system or
% interogate other details about the system or disturbance

flag_performControlSimulations = true;        % "true" or "false"


%% SPECIFY WHERE THE SIMULATION SHOULD BE RUN DETERMINISTICALLY OR NOT
% This option can be used so that the mean uncertainty predicition is the
% actual uncertainty that occurs

flag_deterministicSimulation = false;


%% SPECIFY A SEED TO CONTROL THE SIMULATION RESULTS
seed_forSimulation = sum(clock);        % <-- This will give random runs
%seed_forSimulation = 10;               % <-- This could give repeatable runs

seed_RandNumGeneratorType   = 'mrg32k3a';
% OPTIONS: that can have independent sub-streams
%       'mrg32k3a', 'mlfg6331_64'
% OPTIONS: that need sub-streams to be defined separately
%       'mt19937ar'


%% SPECIFY WHETHER THE SIMULATION SHOULD BE RUN ON MULTIPLE DISTURBANCE REALISATIONS
% This option is used to properly evaluate the controller performance in a
% stochastic sense

% First the falg to turn this option on or off
flag_evaluateOnMultipleRealisations = true;

% Now some options to speficy the details:
% About how many realisations to run:
evalMultiReal_numSampleMethod       = 'userSpecified';      % OPTIONS: 'userSpecified', 'n_xi^2'
evalMultiReal_numSamplesMax         =  inf;                 % OPTIONS: set to "inf" for unbounded
evalMultiReal_numSamplesUserSpec    =  4;

% About how to parallelise the computations
evalMultiReal_parallelise_onOff     = true;                 % OPTIONS: 'true', 'false'
evalMultiReal_parallelise_numThreads = 2;                   % OPTIONS: this is a desired number, if greater than the max resource available then it will be clipped
                                                            %          or set to "inf" to let it be determined automatically

% About what details to save (options for all of these: 'true' or 'false')
% NOTE: if the "flag_saveSimResults" is 'false' then nothing is saved
flag_save_x         = true;
flag_save_u         = true;
flag_save_xi        = true;
flag_save_cost      = true;
flag_save_cost_perSubSystem     = true;
flag_save_controllerDetails     = false;    % NOTE: This doesn't do anything yet!!
% NOTE ALSO: The cumulative costs and the seeds required to reproduce any
% realisation are save by default (unless "flag_saveSimResults" is 'false')


%% SPECIFY WHETHER THE VARIOUS OBJECT SHOULD BE RETURNED TO THE WORKSPACE OR NOT
% This option can be used if the user only wants the restuls, system, and
% disturbance object to be returned to the workspace so that they can be
% interogated

flag_returnObjectsToWorkspace = true;        % "true" or "false"



%% SPECIFY SOME THINGS ABOUT WHAT RESULTS SHOULD BE PLOTTED
% This option can be used the if user wants to turn plotting off
% completely, or if the used only wishes to see certain catagories or plots

flag_plotResults                        = true;
flag_plotResultsPerController           = false;
flag_plotResultsControllerComparison    = true;

plotResults_unitsForTimeAxis            = 'hours';        % "steps"  or "days" or "hours" or "minutes" or "seconds"



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


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Null Controller Local Only';
% cntrSpecs{numCntr}.legend           = 'Null Local';
% cntrSpecs{numCntr}.saveFolderName   = 'Null_Local';
% cntrSpecs{numCntr}.modelFree        = true;
% cntrSpecs{numCntr}.trueModelBased   = [];
% cntrSpecs{numCntr}.classNameLocal   = 'Control_Null';
% cntrSpecs{numCntr}.classNameGlobal  = [];
% cntrSpecs{numCntr}.globalInit       = false;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A Null controller that always returns 0 input';
% thisVararginLocal                   = 'one';
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% cntrSpecs{numCntr}.vararginGlobal   = [];


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Null Controller Central';
% cntrSpecs{numCntr}.legend           = 'Null Central';
% cntrSpecs{numCntr}.saveFolderName   = 'Null_Central';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_Null_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_Null_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A Null controller that always returns 0 input';
% thisVararginLocal                   = 'one';
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Constant Action Controller Local Only';
% cntrSpecs{numCntr}.legend           = 'Constant Local';
% cntrSpecs{numCntr}.saveFolderName   = 'Constant_Local';
% cntrSpecs{numCntr}.modelFree        = true;
% cntrSpecs{numCntr}.trueModelBased   = [];
% cntrSpecs{numCntr}.classNameLocal   = 'Control_Constant';
% cntrSpecs{numCntr}.classNameGlobal  = [];
% cntrSpecs{numCntr}.globalInit       = false;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A constant controller that always returns the same input';
% thisVararginLocal                   = 0;        % This is the constant control action that will be applied
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% cntrSpecs{numCntr}.vararginGlobal   = [];


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Constant Action Controller Local Only';
% cntrSpecs{numCntr}.legend           = 'Constant Local';
% cntrSpecs{numCntr}.saveFolderName   = 'Constant_Local';
% cntrSpecs{numCntr}.modelFree        = true;
% cntrSpecs{numCntr}.trueModelBased   = [];
% cntrSpecs{numCntr}.classNameLocal   = 'Control_Constant';
% cntrSpecs{numCntr}.classNameGlobal  = [];
% cntrSpecs{numCntr}.globalInit       = false;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A constant controller that always returns the same input';
% thisVararginLocal                   = 10;        % This is the constant control action that will be applied
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% cntrSpecs{numCntr}.vararginGlobal   = [];

% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Constant Action Controller Local Only';
% cntrSpecs{numCntr}.legend           = 'Constant Local';
% cntrSpecs{numCntr}.saveFolderName   = 'Constant_Local';
% cntrSpecs{numCntr}.modelFree        = true;
% cntrSpecs{numCntr}.trueModelBased   = [];
% cntrSpecs{numCntr}.classNameLocal   = 'Control_Constant';
% cntrSpecs{numCntr}.classNameGlobal  = [];
% cntrSpecs{numCntr}.globalInit       = false;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A constant controller that always returns the same input';
% thisVararginLocal                   = 20;        % This is the constant control action that will be applied
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% cntrSpecs{numCntr}.vararginGlobal   = [];


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Random Controller with Central Coordinator';
% cntrSpecs{numCntr}.legend           = 'Rand w Coord';
% cntrSpecs{numCntr}.saveFolderName   = 'Rand_with_GlobalCoord';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_Rand_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_Rand_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A controller that randomly chooses and input between the lower and upper bound for each input';
% thisVararginLocal                   = 'one';
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Using 1-step predicition only';
% cntrSpecs{numCntr}.legend           = 'Naive - One Step Prediciton';
% cntrSpecs{numCntr}.saveFolderName   = 'OneStepPred';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_OneStepPred_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_OneStepPred_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A controller that simply minimises the cost at every step based on the prediciton for the next step';
% clear thisVararginLocal;
% thisVararginLocal.discretisationMethod = 'none';   % 'none' , 'euler'
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;      
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;



% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Using 1-step predicition only';
% cntrSpecs{numCntr}.legend           = 'Naive - One Step Prediciton';
% cntrSpecs{numCntr}.saveFolderName   = 'OneStepPred';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_OneStepPred_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_OneStepPred_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A controller that simply minimises the cost at every step based on the prediciton for the next step';
% clear thisVararginLocal;
% thisVararginLocal.discretisationMethod = 'euler';   % 'none' , 'euler'
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;      
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;





% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'MPC';
cntrSpecs{numCntr}.legend           = 'MPC - One Step Horizon';
cntrSpecs{numCntr}.saveFolderName   = 'MPC_1step';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'A typical MPC controller';

clear thisVararginLocal;
thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler' , 'expm'
thisVararginLocal.predHorizon               = 1;
thisVararginLocal.computeMPCEveryNumSteps   = 1;
cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;

thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'MPC';
cntrSpecs{numCntr}.legend           = 'MPC - T=12h, Recede=2h';
cntrSpecs{numCntr}.saveFolderName   = 'MPC_T12h_R2h';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'A typical MPC controller';

clear thisVararginLocal;
thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler'
thisVararginLocal.predHorizon               = 12*4;
thisVararginLocal.computeMPCEveryNumSteps   = 2*4;
cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;

thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'MPC';
cntrSpecs{numCntr}.legend           = 'MPC - T=24h, Recede=2h';
cntrSpecs{numCntr}.saveFolderName   = 'MPC_T24h_R2h';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'A typical MPC controller';

clear thisVararginLocal;
thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler'
thisVararginLocal.predHorizon               = 24*4;
thisVararginLocal.computeMPCEveryNumSteps   = 2*4;
cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;

thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'MPC';
% cntrSpecs{numCntr}.legend           = 'MPC - Full Horizon';
% cntrSpecs{numCntr}.saveFolderName   = 'MPC';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A typical MPC controller';
% 
% clear thisVararginLocal;
% thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler'
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeMPCEveryNumSteps   = timeHorizon;
% cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;




% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - via Sampling';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'samplingWithLeastSquaresFit';    % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                       % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
%
% thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 22.5 - 3;
% thisVararginLocal.VFitting_xInternal_upper  = 22.5 + 3;
% thisVararginLocal.VFitting_xExternal_lower  = 16.0 - 3;
% thisVararginLocal.VFitting_xExternal_upper  = 16.0 + 3;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;



% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - +/-3';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 22.5 - 3;
% thisVararginLocal.VFitting_xInternal_upper  = 22.5 + 3;
% thisVararginLocal.VFitting_xExternal_lower  = 16.0 - 2;
% thisVararginLocal.VFitting_xExternal_upper  = 16.0 + 2;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
 

% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - +0.5 -3';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
%
% thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 22.5 - 3;
% thisVararginLocal.VFitting_xInternal_upper  = 22.5 + 0.5;
% thisVararginLocal.VFitting_xExternal_lower  = 16.0 - 3;
% thisVararginLocal.VFitting_xExternal_upper  = 16.0 + 0.5;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% 
% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - 10-30';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 16;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 8;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 10;
% thisVararginLocal.VFitting_xInternal_upper  = 30;
% thisVararginLocal.VFitting_xExternal_lower  = 10;
% thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'ADP Centralised';
cntrSpecs{numCntr}.legend           = 'ADP - Diag P - 10-30, T=12h, Recede=2h';
cntrSpecs{numCntr}.saveFolderName   = 'ADP_Diag_10-30_T12h_R2h';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';

clear thisVararginLocal;
thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'

thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'

thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'


thisVararginLocal.VFitting_xInternal_lower  = 10;
thisVararginLocal.VFitting_xInternal_upper  = 30;
thisVararginLocal.VFitting_xExternal_lower  = 10;
thisVararginLocal.VFitting_xExternal_upper  = 20;

cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;

thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'ADP Centralised';
cntrSpecs{numCntr}.legend           = 'ADP - Distributable P - 10-30, T=12h, Recede=2h';
cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dist_10-30_T12h_R2h';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';

clear thisVararginLocal;
thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'

thisVararginLocal.PMatrixStructure          = 'distributable';                  % OPTIONS: 'diag', 'dense', 'distributable'

thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'

thisVararginLocal.VFitting_xInternal_lower  = 10;
thisVararginLocal.VFitting_xInternal_upper  = 30;
thisVararginLocal.VFitting_xExternal_lower  = 10;
thisVararginLocal.VFitting_xExternal_upper  = 20;

cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;

thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;


% -----------------------------------
% Add a Controller Spec
numCntr = numCntr + 1;
% Mandatory Specifications
cntrSpecs{numCntr}.label            = 'ADP Centralised';
cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 10-30, T=12h, Recede=2h';
cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dens_10-30_T12h_R2h';
cntrSpecs{numCntr}.modelFree        = false;
cntrSpecs{numCntr}.trueModelBased   = true;
cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
cntrSpecs{numCntr}.globalInit       = true;
% Optional Specifications
cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';

clear thisVararginLocal;
thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'

thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'

thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'

thisVararginLocal.VFitting_xInternal_lower  = 10;
thisVararginLocal.VFitting_xInternal_upper  = 30;
thisVararginLocal.VFitting_xExternal_lower  = 10;
thisVararginLocal.VFitting_xExternal_upper  = 20;

cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;

thisVararginGlobal                  = 'two';
cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;




% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - 18-24, T=24h, Recede=24h';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
% 
% thisVararginLocal.VFitting_xInternal_lower  = 18;
% thisVararginLocal.VFitting_xInternal_upper  = 24;
% thisVararginLocal.VFitting_xExternal_lower  = 12;
% thisVararginLocal.VFitting_xExternal_upper  = 18;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
% 
% 
% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Distributable P - 18-24, T=24h, Recede=24h';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'distributable';                  % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 18;
% thisVararginLocal.VFitting_xInternal_upper  = 24;
% thisVararginLocal.VFitting_xExternal_lower  = 12;
% thisVararginLocal.VFitting_xExternal_upper  = 18;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
% 
% 
% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 18-24, T=24h, Recede=24h';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 18;
% thisVararginLocal.VFitting_xInternal_upper  = 24;
% thisVararginLocal.VFitting_xExternal_lower  = 12;
% thisVararginLocal.VFitting_xExternal_upper  = 18;
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;






% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - 0-50';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
%
% thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.VFitting_xInternal_lower  = 0;
% thisVararginLocal.VFitting_xInternal_upper  = 50;
% thisVararginLocal.VFitting_xExternal_lower  = 10;
% thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
% 
% 
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;








% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'Model Free';
% cntrSpecs{numCntr}.legend           = 'ModelFree';
% cntrSpecs{numCntr}.modelFree        = true;
% cntrSpecs{numCntr}.trueModelBased   = false;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ModelFree';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ModelFree';
% cntrSpecs{numCntr}.globalInit       = false;
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
blackBoxInstructions.systemOptions      = systemOptions;

blackBoxInstructions.disturbanceIDRequest = disturbanceIDRequest;
blackBoxInstructions.disturbanceOptions = disturbanceOptions;

blackBoxInstructions.controllers        = cell(numCntr,1);
blackBoxInstructions.controllers(:,1)   = cntrSpecs(1:numCntr,1);
clear cntrSpecs;

blackBoxInstructions.timeStart          = timeStart;
blackBoxInstructions.timeHorizon        = timeHorizon;
blackBoxInstructions.timeUnits          = timeUnits;

blackBoxInstructions.flag_saveResults   = flag_saveSimResults;

blackBoxInstructions.flag_performControlSimulations    = flag_performControlSimulations;
blackBoxInstructions.flag_deterministicSimulation      = flag_deterministicSimulation;

blackBoxInstructions.seed_forSimulation                = seed_forSimulation;
blackBoxInstructions.seed_RandNumGeneratorType         = seed_RandNumGeneratorType;

% SETTINGS FOR: Evaluate on Multiple Realisation
% Build a struct of the details first
details_evalMultiReal.flag_evaluateOnMultipleRealisations   = flag_evaluateOnMultipleRealisations;
details_evalMultiReal.numSampleMethod         = evalMultiReal_numSampleMethod;
details_evalMultiReal.numSamplesMax           = evalMultiReal_numSamplesMax;
details_evalMultiReal.numSamplesUserSpec      = evalMultiReal_numSamplesUserSpec;
details_evalMultiReal.parallelise_onOff       = evalMultiReal_parallelise_onOff;
details_evalMultiReal.parallelise_numThreads  = evalMultiReal_parallelise_numThreads;

details_evalMultiReal.flag_save_x                   = flag_save_x;
details_evalMultiReal.flag_save_u                   = flag_save_u;
details_evalMultiReal.flag_save_xi                  = flag_save_xi;
details_evalMultiReal.flag_save_cost                = flag_save_cost;
details_evalMultiReal.flag_save_cost_perSubSystem   = flag_save_cost_perSubSystem;
details_evalMultiReal.flag_save_controllerDetails   = flag_save_controllerDetails;

% Then put this struct of detail into the Instruction
blackBoxInstructions.details_evalMultiReal      = details_evalMultiReal;


blackBoxInstructions.flag_returnObjectsToWorkspace     = flag_returnObjectsToWorkspace;

blackBoxInstructions.flag_plotResults                        = flag_plotResults;
blackBoxInstructions.flag_plotResultsPerController           = flag_plotResultsPerController;
blackBoxInstructions.flag_plotResultsControllerComparison    = flag_plotResultsControllerComparison;
blackBoxInstructions.plotResults_unitsForTimeAxis            = plotResults_unitsForTimeAxis;

% Initialise some variables to contain the results
[allResults, savePath_Results, object_system, object_disturbance]  = runBlackBoxSimWithConfig(blackBoxInstructions);

disp(' '); disp(' ');
disp('------------------------------------------------------------------');
disp(' Black-Box has finished running and all results returned to main.m');
if ~isempty(savePath_Results) && flag_performControlSimulations
    disp( ' The results were saved in the folder named: ' );
    disp(['        ',savePath_Results ]);
end


%% --------------------------------------------------------------------- %%
%% PLOT SOME COMPARITIVE RESULTS
%disp(' '); disp(' ');
%disp('------------------------------------------------------------------');
%disp(' Now plotting some comparitive results');
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