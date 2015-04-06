% ----------------------------------------------------------------------- %
%       main.m
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
%
%  ---------------------------------------------------------------------  %
%
% VERSION:          v1.03
% DATE PUBLISHED:   15-Mar-2015
%
%  ---------------------------------------------------------------------  %
%  PACKAGE:     Black-Box Simulation-Based Stochastic Optimisation Test-Bed
%  AUTHOR:      Paul N. Beuchat
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
%               > When running for the first time (on either a personal
%                 machine or a server) see the "Readme.txt" file
%
% ----------------------------------------------------------------------- %

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
% ----------------------------------------------------------------------- %
%   SSSS  Y   Y   SSSS  TTTTTTT  EEEEE  M\  /M
%  S       Y Y   S         T     E      MM\/MM
%   SSS     Y     SSS      T     EEE    M MM M
%      S    Y        S     T     E      M    M
%  SSSS     Y    SSSS      T     EEEEE  M    M
% ----------------------------------------------------------------------- %
% The systems to choose from are:
%   'building'
%   '...'

% For 'building's, the "systemIDRequest" should be a string of length 7,
% that selects from the following:
% '001_001' = a small 1 room building
% '002_001' = a small 7 room, 2 storey building
% '003_001' = a single floor in the Basel OptiControl 2 Building

systemType          = 'building';
%systemIDRequest     = '001';
systemIDRequest     = '002_001';



% Some options for what to do with the system that is loaded
clear systemOptions;
systemOptions.displaySystemDetails         = false;
systemOptions.drawSystem                   = false;
systemOptions.plotContTimeModelSparisity   = false;
systemOptions.discretisationMethod         = 'default';  % 'default','euler','expm'




%% SELECT THE DISTURBANCE MODEL TO BE USED WITHIN THE BLACK-BOX:
% ----------------------------------------------------------------------- %
%  DDDD   III   SSSS  TTTTTTT  U   U  RRRR   BBBB     AA    N    N   CCCC  EEEEE
%  D   D   I   S         T     U   U  R   R  B   B   A  A   NN   N  C      E
%  D   D   I    SSS      T     U   U  RRRR   BBBB   AAAAAA  N N  N  C      EEE
%  D   D   I       S     T     U   U  R  R   B   B  A    A  N  N N  C      E
%  DDDD   III  SSSS      T      UUU   R   R  BBBB   A    A  N   NN   CCCC  EEEEE
% ----------------------------------------------------------------------- %
% Need to make a list of what the various disturbance's are

%disturbanceIDRequest  = '001';
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
% ----------------------------------------------------------------------- %
%  TTTTTTT  III  M\  /M  EEEEE
%     T      I   MM\/MM  E
%     T      I   M MM M  EEE
%     T      I   M    M  E
%     T     III  M    M  EEEEE
% ----------------------------------------------------------------------- %
timeStart       = 1;
timeHorizon     = 0.5*24*4;% (24*4) * 4;
timeUnits       = 'steps'; % Possible Units: 'steps', 'mins', 'hours', 'days'


%% SPECIFY WHETHER THE SIMULATION RESULTS SHOULD BE SAVED FOR NOT
% ----------------------------------------------------------------------- %
%    SSSS       A    V     V   EEEEE
%   S          A A   V     V   E
%    SSS      A___A   V   V    EEE
%       S    A     A   V V     E
%   SSSS     A     A    V      EEEEE
% ----------------------------------------------------------------------- %
flag_saveSimResults = false;        % "true" or "false"


%% SPECIFY WHETHER THE CONTROL SIMULATIONS SHOULD BE RUN OR NOT
% This option can be used if the user only wants to plot the system or
% interogate other details about the system or disturbance

flag_performControlSimulations = true;        % "true" or "false"


%% SPECIFY WHERE THE SIMULATION SHOULD BE RUN DETERMINISTICALLY OR NOT
% This option can be used so that the mean uncertainty predicition is the
% actual uncertainty that occurs

flag_deterministicSimulation = true;

% NOTE: if the flag below named "flag_evaluateOnMultipleRealisations" is
% set to "true", then this overwrites this "deterministic" flag to be false


%% SPECIFY A SEED TO CONTROL THE SIMULATION RESULTS
% ----------------------------------------------------------------------- %
%    SSSS   EEEEE   EEEEE   DD
%   S       E       E       D D
%    SSS    EEE     EEE     D  D
%       S   E       E       D  D
%   SSSS    EEEEE   EEEEE   DDD
% ----------------------------------------------------------------------- %
seed_forSimulation = sum(clock);        % <-- This will give random runs
%seed_forSimulation = 10;               % <-- This could give repeatable runs

seed_RandNumGeneratorType   = 'mrg32k3a';
% OPTIONS: that can have independent sub-streams
%       'mrg32k3a', 'mlfg6331_64'
% OPTIONS: that need sub-streams to be defined separately
%       'mt19937ar'


%% SPECIFY WHETHER THE SIMULATION SHOULD BE RUN ON MULTIPLE DISTURBANCE REALISATIONS
% ----------------------------------------------------------------------- %
%  M    M U  U L    TTTTT I     RRRR  EEEE   A   L    I  SSS   A   TTTTT I  OO  N   N  SSS
%  MM  MM U  U L      T   I     R   R E     A A  L    I S     A A    T   I O  O NN  N S   
%  M MM M U  U L      T   I --- RRRR  EEE  A___A L    I  SS  A___A   T   I O  O N N N  SS  
%  M    M U  U L      T   I     R  R  E    A   A L    I    S A   A   T   I O  O N  NN    S
%  M    M  UU  LLLL   T   I     R   R EEEE A   A LLLL I SSS  A   A   T   I  OO  N   N SSS 
% ----------------------------------------------------------------------- %
% This option is used to properly evaluate the controller performance in a
% stochastic sense

% First the falg to turn this option on or off
flag_evaluateOnMultipleRealisations = false;

% Now some options to speficy the details:
% About how many realisations to run:
evalMultiReal_numSampleMethod       = 'userSpecified';      % OPTIONS: 'userSpecified', 'n_xi^2'
evalMultiReal_numSamplesMax         =  inf;                 % OPTIONS: set to "inf" for unbounded
evalMultiReal_numSamplesUserSpec    =  1;

% About how to parallelise the computations
evalMultiReal_parallelise_onOff     = true;                 % OPTIONS: 'true', 'false'
evalMultiReal_parallelise_numThreads = 1;                   % OPTIONS: this is a desired number, if greater than the max resource available then it will be clipped
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



%% --------------------------------------------------------------------- %%
%% SPECIFY THE CONTROLLERS TO BE SIMULATED ON THE TEST-BED
% ----------------------------------------------------------------------- %
%   CCCC   OOO   N    N  TTTTTTT  RRRR    OOO   L      L      EEEEE  RRRR
%  C      O   O  NN   N     T     R   R  O   O  L      L      E      R   R
%  C      O   O  N N  N     T     RRRR   O   O  L      L      EEE    RRRR
%  C      O   O  N  N N     T     R  R   O   O  L      L      E      R  R
%   CCCC   OOO   N   NN     T     R   R   OOO   LLLLL  LLLLL  EEEEE  R   R
% ----------------------------------------------------------------------- %

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
cntrSpecs = cell(50,1);
% Initialise the counter
numCntr = 0;

% Initialise the "method ID for group plotting" counter
% This is used in, for example, the Pareto Front plot to give the group of
% the same method with only gamma changing, the same colour
% The actual value is unimportant, just that all memeber of a group have
% the same ID
currMethodID_forGroupPlotting = 0;
%currMethodName_forGroupPlotting = 'blank';

%% EXAMPLE CODE FOR ADDING MULTIPLE CONTROLER WITH DIFFERENT MULTI-TO-SINGLE OBJECTIVE SCALINGS
% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense Iteratred P, via DD'; 
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.5e-3, 1e-3];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense It. P wDD - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_It_wDD_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% end



%% BASIC CONTROLLERS - Null, Constant, Random
%currMethodID_forGroupPlotting; = currMethodID_forGroupPlotting; + 1;

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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;




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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;



% -----------------------------------
% % Specify the Group ID and Group Name for grouping the plots
currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
currMethodName_forGroupPlotting = 'Constant Control';
% Add multiple controllers with different Constant Control values
constantControlRange = [0, 10, 20];
% -----------------------------------
% Iterate through the range of constant control values
for iConstant = 1:length(constantControlRange)
    % Add a Controller Spec
    numCntr = numCntr + 1;
    % Get this constant control value
    thisConstant = constantControlRange(iConstant);
    % Mandatory Specifications
    cntrSpecs{numCntr}.label            = ['Constant Action Controller Local Only, u=',num2str(thisConstant,'%-.2e')];
    cntrSpecs{numCntr}.legend           = ['Constant Local, u=',num2str(thisConstant,'%-.2e')];
    cntrSpecs{numCntr}.saveFolderName   = ['Constant_Local_u',num2str(thisConstant,'%-.2e')];
    cntrSpecs{numCntr}.modelFree        = true;
    cntrSpecs{numCntr}.trueModelBased   = [];
    cntrSpecs{numCntr}.classNameLocal   = 'Control_Constant';
    cntrSpecs{numCntr}.classNameGlobal  = [];
    cntrSpecs{numCntr}.globalInit       = false;
    % Optional Specifications
    cntrSpecs{numCntr}.description      = 'A constant controller that always requests the same input';
    thisVararginLocal                   = thisConstant;        % This is the constant control action that will be applied
    cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
    cntrSpecs{numCntr}.vararginGlobal   = [];
    cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
    cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
end


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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;


%% ONE-STEP PREDICITON CONSTROLLER


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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;




%% MPC

% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'MPC';
% cntrSpecs{numCntr}.legend           = 'MPC - One Step Horizon';
% cntrSpecs{numCntr}.saveFolderName   = 'MPC_1step';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'A typical MPC controller';
% 
% clear thisVararginLocal;
% thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler' , 'expm'
% thisVararginLocal.predHorizon               = 1;
% thisVararginLocal.computeMPCEveryNumSteps   = 1;
% cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'MPC';
% cntrSpecs{numCntr}.legend           = 'MPC - T=24h, Recede=2h';
% cntrSpecs{numCntr}.saveFolderName   = 'MPC_T24h_R2h';
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
% thisVararginLocal.predHorizon               = 24*4;
% thisVararginLocal.computeMPCEveryNumSteps   = 2*4;
% cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;
% 
% thisVararginGlobal                  = 'two';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;


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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;







%% MPC - Energy-to-Comfort Scaling Range

% % % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'MPC - T=12h, Recede=2h';
% % Add multiple controllers with different cost-component scaling
% %gammaRange = [5.0e-2, 2.5e-2, 1.0e-2, 7.5e-3, 5.0e-3, 2.5e-3, 1.0e-3, 7.5e-4, 5.0e-4, 0];
% gammaRange = [5.0e-2, 2.5e-2, 1.0e-2, 7.5e-3, 5.0e-3, 2.5e-3, 1.0e-3, 0];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'MPC';
%     cntrSpecs{numCntr}.legend           = ['MPC - T=12h, Recede=2h, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['MPC_T12h_R2h_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'A typical MPC controller';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler'
%     thisVararginLocal.predHorizon               = 12*4;
%     thisVararginLocal.computeMPCEveryNumSteps   = 2*4;
%     thisVararginLocal.energyToComfortScaling    = thisGamma;
%     cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end


%% ADP - various fitting ranges

% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting +1;

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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
% cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;



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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;

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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;



% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - 10-30, T=12h, Recede=2h';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Diag_10-30_T12h_R2h';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Diag P - 10-30, T=12h, Recede=2h, with K-PWA';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Diag_10-30_T12h_R2h_withK-PWA';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'diag';                            % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = true;                            % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% 
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;


% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Distributable P - 10-30, T=12h, Recede=2h';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dist_10-30_T12h_R2h';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'distributable';                  % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;



% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 10-30, T=12h, Recede=2h, gamma=0';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dens_10-30_T12h_R2h';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
% thisVararginLocal.energyToComfortScaling       = 0;
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;



% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 10-30, T=12h, Recede=2h, with K-dense-1piece';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dens_10-30_T12h_R2h_withK-PWA';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = true;                             % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% thisVararginLocal.KMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;




% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 10-30, T=12h, Recede=2h, with K-output-1piece';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dens_10-30_T12h_R2h_withK-PWA';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = true;                             % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% thisVararginLocal.KMatrixStructure          = 'output';                         % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;




% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 10-30, T=12h, Recede=2h, with K-output-decent-1piece';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dens_10-30_T12h_R2h_withK-PWA';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = true;                             % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% thisVararginLocal.KMatrixStructure          = 'output-dist';                    % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;




% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'ADP Centralised';
% cntrSpecs{numCntr}.legend           = 'ADP - Dense P - 10-30, T=12h, Recede=2h, with K-output-decent-1piece';
% cntrSpecs{numCntr}.saveFolderName   = 'ADP_Dens_10-30_T12h_R2h_withK-PWA';
% cntrSpecs{numCntr}.modelFree        = false;
% cntrSpecs{numCntr}.trueModelBased   = true;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
% cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
% cntrSpecs{numCntr}.globalInit       = true;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
% clear thisVararginLocal;
% thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
% thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
% thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
% thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
% thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
% thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.usePWAPolicyApprox        = true;                             % OPTIONS: 'true', 'false'
% thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
% thisVararginLocal.KMatrixStructure          = 'output-decent';                  % OPTIONS: 'diag', 'dense', 'distributable'
% 
% thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
% thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;



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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;






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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;





%% ADP -  Energy-to-Comfort Scaling Range - DENSE "P"

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [2.5e-2, 1.0e-2, 7.5e-3, 5.0e-3, 2.5e-3, 0];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense P - 10-30, T=12h, Recede=2h, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_10-30_T12h_R2h_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end



%% ADP -  Energy-to-Comfort Scaling Range - Diag "P"

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Diag P';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [2.5e-2, 1.0e-2, 7.5e-3, 2.5e-3, 0];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Diag P - 10-30, T=12h, Recede=2h, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Diag_10-30_T12h_R2h_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'diag';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end




%% ADP -  Energy-to-Comfort Scaling Range - Dense "P" - Output "K"

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P - Output K';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [7.5e-3, 5.0e-3, 4.2e-3, 3.3e-3, 2.5e-3, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dens P - Output K - 10-30, T=12h, Recede=2h, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_DensP_OutputK_10-30_T12h_R2h_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = true;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = 'output';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end



%% ADP -  Energy-to-Comfort Scaling Range - Dense "P" - Output-Decent "K"

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P - Output-Decent K';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [7.5e-3, 5.0e-3, 4.2e-3, 3.3e-3, 2.5e-3, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dens P - Output Decent K - 10-30, T=12h, Recede=2h, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_DensP_OutputDecentK_10-30_T12h_R2h_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = 2*4;%timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = true;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = 'output-decent';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end





%% LQR -  Energy-to-Comfort Scaling Range

% % Specify the clipping method to use
% LQR_clipping_default = 'manual';        % OPTIONS: 'closest_2norm', 'manual'
% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = ['LQR - Clipping Method: ',LQR_clipping_default];
% % Add multiple controllers with different cost-component scaling
% gammaRange = [2.5e-3, 2.0e-3, 1.5e-3, 1.0e-3, 7.5e-4, 0];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'LQR Centralised';
%     cntrSpecs{numCntr}.legend           = ['LQR T=12h, Recede=2h, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['LQR_T12h_R2h_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_LQRCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_LQRCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'LQR Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = 12*4;%timeHorizon;
%     thisVararginLocal.computeKEveryNumSteps     = 2*4;%timeHorizon;
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.computeAllKsAtInitialisation = true;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedKs         = true;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.clippingMethod       = LQR_clipping_default;               % OPTIONS: 'closest_2norm', 'manual'
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end




%% MPC - DETERMINISTIC (versus gamma)

% Specify the Group ID and Group Name for grouping the plots
currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
currMethodName_forGroupPlotting = 'MPC - Full Horizon Open Loop';
% Add multiple controllers with different cost-component scaling
gammaRange = [7.5e-4, 5.0e-4, 2.5e-4, 1.0e-4, 0 ];
% -----------------------------------
% Iterate through the range of cost-component scalings
for iGamma = 1:length(gammaRange)
    % Add a Controller Spec
    numCntr = numCntr + 1;
    % Get this scaling
    thisGamma = gammaRange(iGamma);
    % Mandatory Specifications
    cntrSpecs{numCntr}.label            = 'MPC';
    cntrSpecs{numCntr}.legend           = ['MPC - OL, gamma=',num2str(thisGamma,'%-.2e')];
    cntrSpecs{numCntr}.saveFolderName   = ['MPC_OL_gamma',num2str(thisGamma,'%-.2e')];
    cntrSpecs{numCntr}.modelFree        = false;
    cntrSpecs{numCntr}.trueModelBased   = true;
    cntrSpecs{numCntr}.classNameLocal   = 'Control_MPC_Local';
    cntrSpecs{numCntr}.classNameGlobal  = 'Control_MPC_Global';
    cntrSpecs{numCntr}.globalInit       = true;
    % Optional Specifications
    cntrSpecs{numCntr}.description      = 'A typical MPC controller';

    clear thisVararginLocal;
    thisVararginLocal.discretisationMethod      = 'none';   % 'none' , 'euler'
    thisVararginLocal.predHorizon               = timeHorizon;
    thisVararginLocal.computeMPCEveryNumSteps   = timeHorizon;
    thisVararginLocal.energyToComfortScaling    = thisGamma;
    cntrSpecs{numCntr}.vararginLocal            = thisVararginLocal;

    thisVararginGlobal                  = 'two';
    cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
    cntrSpecs{numCntr}.methodID_forGroupPlotting    = currMethodID_forGroupPlotting;
    cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
end



%% ADP diag P - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - diag P';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.0e-3, 7.5e-4, 5.0e-4, 2.5e-4, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Diag P - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Diag_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'diag';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end




%% ADP output P - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Output P';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.0e-3, 7.5e-4, 5.0e-4, 2.5e-4, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Output P - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Output_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'output';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end




%% ADP Dense P - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.5e-3, 1.5e-3 , 7.5e-4, 5.0e-4, 2.5e-4, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense P - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality', 'itBellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
%     thisVararginLocal.useScaledDiagDomForBellmanIneq = false;                         % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end





%% ADP Dense P via SDD - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P via SDD';
% % Add multiple controllers with different cost-component scaling
% gammaRange = (1.5e-3);
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense P wSDD - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_wSDD_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality', 'itBellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
%     thisVararginLocal.useScaledDiagDomForBellmanIneq = true;                         % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end






%% ADP Dense It. P - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense Iteratred P';
% % Add multiple controllers with different cost-component scaling
% gammaRange = (1.5e-3);
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense It. P - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_It_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'itBellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality', 'itBellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'iterated';                   % OPTIONS: 'step-by-step', 'iterated'
%     thisVararginLocal.useScaledDiagDomForBellmanIneq = false;                         % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end



%% ADP Dense It. P via SDD - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense Iteratred P, via SDD';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.5e-3, 1e-3];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense It. P wSDD - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_It_wSDD_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';      % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                 % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.numBellmanIneqIterations  = 1;                        % OPTIONS: any integer >= 1
%     thisVararginLocal.sdpRelaxation             = 'sdd';                   % OPTIONS: 'sdp', 'ssd', 'dd'
% 
%     thisVararginLocal.buildFormulationWith      = 'yalmip';                 % OPTIONS: 'yalmip', 'direct'
%     thisVararginLocal.solverToUse               = 'gurobi';                 % OPTIONS: 'sedumi', 'gurobi', 'modek', 'ecos'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end


%% ADP Dense It. P via DD - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense Iteratred P, via DD';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.5e-3, 1e-3];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised - Dense It. P via DD';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dense It. P wDD - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_Dens_It_wDD_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';      % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                 % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.numBellmanIneqIterations  = 1;                        % OPTIONS: any integer >= 1
%     thisVararginLocal.sdpRelaxation             = 'dd';                   % OPTIONS: 'sdp', 'ssd', 'dd'
% 
%     thisVararginLocal.buildFormulationWith      = 'direct';                 % OPTIONS: 'yalmip', 'direct'
%     thisVararginLocal.solverToUse               = 'gurobi';                 % OPTIONS: 'sedumi', 'gurobi', 'modek', 'ecos'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = false;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = ' ';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end










%% ADP Dense P, Output K - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P, Output K';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.5e-3, 1.3e-3, 1.0e-3, 7.5e-4, 5.0e-4, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dens P - Output K - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_DensP_OutputK_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = true;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = 'output';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end





%% ADP Dense P, Output-Decent K - DETERMIISTIC (versus gamma)

% % Specify the Group ID and Group Name for grouping the plots
% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
% currMethodName_forGroupPlotting = 'ADP - Dense P, Output-Decent K';
% % Add multiple controllers with different cost-component scaling
% gammaRange = [1.5e-3, 1.3e-3, 1.0e-3, 7.5e-4, 0 ];
% % -----------------------------------
% % Iterate through the range of cost-component scalings
% for iGamma = 1:length(gammaRange)
%     % Add a Controller Spec
%     numCntr = numCntr + 1;
%     % Get this scaling
%     thisGamma = gammaRange(iGamma);
%     % Mandatory Specifications
%     cntrSpecs{numCntr}.label            = 'ADP Centralised';
%     cntrSpecs{numCntr}.legend           = ['ADP - Dens P - Output Decent K - 10-30 - OL, gamma=',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.saveFolderName   = ['ADP_DensP_OutputDecentK_10-30_OL_gamma',num2str(thisGamma,'%-.2e')];
%     cntrSpecs{numCntr}.modelFree        = false;
%     cntrSpecs{numCntr}.trueModelBased   = true;
%     cntrSpecs{numCntr}.classNameLocal   = 'Control_ADPCentral_Local';
%     cntrSpecs{numCntr}.classNameGlobal  = 'Control_ADPCentral_Global';
%     cntrSpecs{numCntr}.globalInit       = true;
%     % Optional Specifications
%     cntrSpecs{numCntr}.description      = 'ADP Controller using a Centralised architecture';
% 
%     clear thisVararginLocal;
%     thisVararginLocal.predHorizon               = timeHorizon;
%     thisVararginLocal.computeVEveryNumSteps     = timeHorizon;
%     thisVararginLocal.ADPMethod                 = 'bellmanInequality';              % OPTIONS: 'samplingWithLeastSquaresFit', 'bellmanInequality'
%     thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
%     thisVararginLocal.bellmanIneqType           = 'step-by-step';                   % OPTIONS: 'step-by-step', 'iterated'
% 
%     thisVararginLocal.PMatrixStructure          = 'dense';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.usePWAPolicyApprox        = true;                            % OPTIONS: 'true', 'false'
%     thisVararginLocal.liftingNumSidesPerDim     = 1;                                % OPTIONS: 'true', 'false'
%     thisVararginLocal.KMatrixStructure          = 'output-decent';                          % OPTIONS: 'diag', 'dense', 'distributable'
% 
%     thisVararginLocal.computeAllVsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
%     thisVararginLocal.usePreviouslySavedVs         = true;                           % OPTIONS: 'true', 'false'
% 
%     thisVararginLocal.energyToComfortScaling       = thisGamma;
% 
%     thisVararginLocal.VFitting_xInternal_lower  = 10;
%     thisVararginLocal.VFitting_xInternal_upper  = 30;
%     thisVararginLocal.VFitting_xExternal_lower  = 10;
%     thisVararginLocal.VFitting_xExternal_upper  = 20;
% 
%     cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% 
%     thisVararginGlobal                  = 'two';
%     cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
%     cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
%     cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
% end







%% LQR DETERMINISTIC (versus gamma)

% Specify the clipping method to use
LQR_clipping_default = 'manual';        % OPTIONS: 'closest_2norm', 'manual'
% Specify the Group ID and Group Name for grouping the plots
currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;
currMethodName_forGroupPlotting = 'LQR';
% Add multiple controllers with different cost-component scaling
%gammaRange = [7.5e-4, 5.0e-4, 2.5e-4, 1.0e-4, 5.0e-5, 0];
gammaRange = [7.5e-4, 5.0e-4, 2.5e-4, 1.0e-4, 0];
% -----------------------------------
% Iterate through the range of cost-component scalings
for iGamma = 1:length(gammaRange)
    % Get this scaling
    thisGamma = gammaRange(iGamma);
    % Add a Controller Spec
    numCntr = numCntr + 1;
    % Mandatory Specifications
    cntrSpecs{numCntr}.label            = 'LQR Centralised';
    cntrSpecs{numCntr}.legend           = ['LQR OL, gamma=',num2str(thisGamma),'%-.2e'];
    cntrSpecs{numCntr}.saveFolderName   = ['LQR_OL_gamma',num2str(thisGamma),'%-.2e'];
    cntrSpecs{numCntr}.modelFree        = false;
    cntrSpecs{numCntr}.trueModelBased   = true;
    cntrSpecs{numCntr}.classNameLocal   = 'Control_LQRCentral_Local';
    cntrSpecs{numCntr}.classNameGlobal  = 'Control_LQRCentral_Global';
    cntrSpecs{numCntr}.globalInit       = true;
    % Optional Specifications
    cntrSpecs{numCntr}.description      = 'LQR Controller using a Centralised architecture';

    clear thisVararginLocal;
    thisVararginLocal.predHorizon               = timeHorizon;
    thisVararginLocal.computeKEveryNumSteps     = timeHorizon;
    thisVararginLocal.systemDynamics            = 'linear';                         % OPTIONS: 'linear', 'bilinear'
    thisVararginLocal.computeAllKsAtInitialisation = false;                           % OPTIONS: 'true', 'false'
    thisVararginLocal.usePreviouslySavedKs         = true;                           % OPTIONS: 'true', 'false'
    thisVararginLocal.energyToComfortScaling       = thisGamma;

    thisVararginLocal.clippingMethod       = LQR_clipping_default;               % OPTIONS: 'closest_2norm', 'manual'

    cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;

    thisVararginGlobal                  = 'two';
    cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
    cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;
    cntrSpecs{numCntr}.methodName_forGroupPlotting  = currMethodName_forGroupPlotting;
end





%% MODEL-FREE

% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;

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
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;



%% PCAO

% currMethodID_forGroupPlotting = currMethodID_forGroupPlotting + 1;

% % -----------------------------------
% % Add a Controller Spec
% numCntr = numCntr + 1;
% % Mandatory Specifications
% cntrSpecs{numCntr}.label            = 'PCAO';
% cntrSpecs{numCntr}.legend           = 'PCAO';
% cntrSpecs{numCntr}.saveFolderName   = 'PCAO_Decent';
% cntrSpecs{numCntr}.modelFree        = true;
% cntrSpecs{numCntr}.trueModelBased   = false;
% cntrSpecs{numCntr}.classNameLocal   = 'Control_PCAO_Local_pnbEdits';
% cntrSpecs{numCntr}.classNameGlobal  = '';
% cntrSpecs{numCntr}.globalInit       = false;
% % Optional Specifications
% cntrSpecs{numCntr}.description      = 'PCAO - Model Free Controller';
% thisVararginLocal                   = 'three';
% cntrSpecs{numCntr}.vararginLocal    = thisVararginLocal;
% thisVararginGlobal                  = 'four';
% cntrSpecs{numCntr}.vararginGlobal   = thisVararginGlobal;
% cntrSpecs{numCntr}.methodID_forGroupPlotting = currMethodID_forGroupPlotting;





%% --------------------------------------------------------------------- %%
%% CHECK THAT THE SPECIFIED "saveFolderNames" are unique
% ----------------------------------------------------------------------- %
%   CCCC  H   H  EEEEE   CCCC  K   K
%  C      H   H  E      C      K  K
%  C      HHHHH  EEE    C      KKK
%  C      H   H  E      C      K  K
%   CCCC  H   H  EEEEE   CCCC  K   K
% ----------------------------------------------------------------------- %

[flag_saveFolderNames_unique , new_saveFolderNames , flag_namesChanged] = bbConstants.checkUniqueness_cellArrayProperty( cntrSpecs(1:numCntr,1) , 'saveFolderName' );

% If the names were not unique
if not( flag_saveFolderNames_unique )
    % Iterate through all the controllers
    for iControl = 1:numCntr
        % If the "save folder name" was this control was updated
        if flag_namesChanged(iControl)
            % Then inform the user about the update
            disp( ' ' );
            % And put in the update
            cntrSpecs{iControl,1}.saveFolderName = new_saveFolderNames{iControl};
        end
    end
end



%% --------------------------------------------------------------------- %%
%% RUN THE TEST-BED
% ----------------------------------------------------------------------- %
%  RRRR   U   U  N    N
%  R   R  U   U  NN   N
%  RRRR   U   U  N N  N
%  R  R   U   U  N  N N
%  R   R   UUU   N   NN
% ----------------------------------------------------------------------- %

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
disp(' Black-Box has finished running');
if flag_returnObjectsToWorkspace
    disp( ' ... INFO: all the results were returned to main.m,' );
    disp( '           hence they can be found in the following variables:')
    disp( '               "allResults", "object_system", and "object_disturbance"' );
end
if ~isempty(savePath_Results) && flag_performControlSimulations
    disp( ' The results were saved in the folder named: ' );
    disp(['        ',savePath_Results ]);
end



%% --------------------------------------------------------------------- %%
%% More details about this script/function - THIS IS OUTDATED AND NEEDS TO BE UPDATED!!!
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