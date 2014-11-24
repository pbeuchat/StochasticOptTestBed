%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     load_forBlackBox_BuildingModel.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnResults] = wrapperForBRCMSimulationEvnironment( inputBuilding , inputV , inputX0 , inputT , cntrFncHandle)

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function runs the following sequence:
%                   - ...
%

%% --------------------------------------------------------------------- %%
%% INITILIASE THE BRCM SIMULATOR

% 8) Discrete-time simulation of the thermal model or the building model (here only shown for the building model)

% The class SimulationExperiment provides a simulation environment. An instantiation requires
% a Building object that at least containts a thermal model and a the sampling time (this will be 
% also the simulation timestep). Once the SimulationExperiment object is instantiated, its building 
% object in  object cannot be manipulated anymore. 

SimExp = SimulationExperiment(inputBuilding);


% It is possible to print/access the identifiers and to access the model/simulation time step
SimExp.printIdentifiers();
identifiers = SimExp.getIdentifiers();
len_v = length(identifiers.v);
len_u = length(identifiers.u);
len_x = length(identifiers.x);
Ts_hrs = SimExp.getSamplingTime();

% Number of simulation time steps and initial condition must be set before the simulation
n_timeSteps = inputT;
SimExp.setNumberOfSimulationTimeSteps(n_timeSteps);
x0 = inputX0;
SimExp.setInitialState(x0);

% Simulation of the building model. The simulation environment allows 2 different simulation modes.
%    1)   mode 'inputTrajectory':     Simulate the model with an input sequence provided by the user.
%    2)   mode 'handle':              Simulate the model with an input sequence provided by a function handle associated with a function provided by the user.

mode = 2;

switch mode

   case 1
      % set up input and disturbance sequence
      V = zeros(len_v,n_timeSteps);
      U = zeros(len_u,n_timeSteps);
      idx_u_rad_Offices = getIdIndex('u_rad_Office_Rad_01',identifiers.u);
      idx_v_Tamb = getIdIndex('v_Tamb',identifiers.v);
      V(idx_v_Tamb,:) = 22; % ambient temperature to constant 22
      U(idx_u_rad_Offices,5:end) = 5; % step of 5 W/m2 in the office radiators from the 5th timestep on
      
      [X,U,V,t_hrs] = SimExp.simulateBuildingModel('inputTrajectory',U,V);
      
   case 2
      [X,U,V,t_hrs] = SimExp.simulateBuildingModel('handle',cntrFncHandle);
      
   otherwise
      error('Bad mode.');
      
end

%% PUT TOGETHER THE RETURN VARIABLES
returnResults.X         = X;
returnResults.U         = U;
returnResults.V         = V;
returnResults.t_hrs     = t_hrs;

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
