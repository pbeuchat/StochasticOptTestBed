%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     load_forBlackBox_BuildingModel.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnResults] = simulate_forBlackBox_BuildingModel( inputCntr, inputBuilding , inputConstraints , inputCosts , inputDisturbances , inputX0 , inputTmax )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function runs the following sequence:
%                   - ...
%

%% --------------------------------------------------------------------- %%
%% INITILIASE THE CONTROLLER
% Keep the user updated
disp('******************************************************************');
disp(' Black-Box: Initialising the Controller');

% Get the function handle for the Initialise Controller Function
initFncHandle = inputCntr.funcHandleInit;

% Get the extra varaibles to be passed to the handle
vararginInit = inputCntr.vararginInit;

% The arguments passed to the "Controller Initialisation Function Handle"
% depends on whether it is Model-Free or Model-Based, with True or False
% Model
if inputCntr.modelFree
    [cntrConfig] = initFncHandle( inputConstraints , inputCosts , inputDisturbances.nominalPred , inputDisturbances.bounds , vararginInit );
else
    if inputCntr.trueModelBased
        [cntrConfig] = initFncHandle( inputBuilding , inputConstraints , inputCosts , inputDisturbances.nominalPred , inputDisturbances.bounds , vararginInit );
    else
        [cntrConfig] = initFncHandle( inputBuilding , inputConstraints , inputCosts , inputDisturbances.nominalPred , inputDisturbances.bounds , vararginInit );
    end
end


%% --------------------------------------------------------------------- %%
%% RUN A SIMULATION FOR MULTIPLE DISTURBANCE REALISATIONS

% Get the number of disturbance realisations
numV = inputDisturbances.numRealisations;

% Choose the number of time steps for which to run each simulation
T = inputTmax;

% Iterate through each realisation
for iV = 1:numV

    % Get the function handle for the "Run Controller Function
    cntrFncHandle = inputCntr.funcHandleMain;
    
    % Get the extra varaibles to be passed to the handle
    vararginMain = inputCntr.vararginMain;
    
    % Get a disturbance realisation for this iteration
    thisV = inputDisturbances.realisations(iV);

    % Run a simulation
    thisResults = wrapperForBRCMSimulationEvnironment( inputBuilding , thisV , inputX0 , T , cntrFncHandle);
    
    % Save the results from this disturbance realisation
    returnResults = thisResults;

end

%% PUT TOGETHER THE RETURN VARIABLES
returnResults = [];

disp(' ... ERROR: nothing is wrong');
error('Terminating now :-( See previous messages and ammend');


end
%% END OF FUNCTION

%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
% The following fields are specified for every controller:
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
