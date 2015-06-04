function [flag_successfullyInitialised , flag_requestDisturbanceData] = initialise_localControl( obj , inputModelType , inputModel , vararginLocal)
% Defined for the "Control_LocalControl" class, this function will be
% called once before the simulation is started
% This function should be used to perform off-line possible
% computations so that the controller computation speed during
% simulation run-time is faster
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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



    % You can except the "inputModel" parameter to be empty when the
    % control is specified to be "Model-Free" and non-empty otherwise
    
    % In general this "flag_requestDisturbanceData" flag should be left as
    % "false" and only set to true if access to the disturbance data is
    % required for computational speed up purposes
    flag_requestDisturbanceData = false;
    
    % When using the "Null" controller as a template, insert your code here
    % to pre-compute off-line parts of your controllers so the the
    % "on-line" computation time is minimised when the
    % "copmuteControlAction" function is called at each time step
    
    %% ----------------------------------------------------------------- %%
    %% SPECIFY A FEW DEFAULTS TO USE IN CASE A FIELDS IS MISSING FROM "vararginLocal"
    
    % FOR THE PREDICITON HORIZON
    statsPredictionHorizon = uint32(12);
    
    % FOR THE REGULARILTY OF RECOMPUTING THE VALUE FUNCTIONS
    computeKEveryNumSteps = uint32(6);
    
    % THE "FIT ALL K's AT INITIALISATION" FLAG
    computeAllKsAtInitialisation = false;
    
    % USE THE PREVIOUSLY FITTED K's (if available)
    usePreviouslySavedKs = false;
    
    % FOR THE ENERGY TO COMFORT SCALING
    energyToComfortScaling = 1;
    
    % FOR THE METHOD USED TO "CLIP" THE CONTROL BACK INTO ITS FEASIBLE SET
    clippingMethod = 'manual';
    
    %% EXTRACT THE OPTIONS FROM THE "vararginLocal" INPUT VARIABLE
    if isstruct( vararginLocal )
        
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED TIME HORIZON TO USE
        if isfield( vararginLocal , 'predHorizon' )
            statsPredictionHorizon = uint32(vararginLocal.predHorizon);
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "predHorizon"');
            disp([' ... NOTE: Using the default of ',num2str(statsPredictionHorizon),' time steps']);
        end
            
        % --------------------------------------------------------------- %
        % GET THE REGULARILTY WITH WHICH THE VALUE FUNCTIONS SHOULD BE
        % RE-COMPUTED
        if isfield( vararginLocal , 'computeKEveryNumSteps' )
            computeKEveryNumSteps = uint32(vararginLocal.computeKEveryNumSteps);
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "computeKEveryNumSteps"');
            disp([' ... NOTE: Using the default of ',num2str(computeKEveryNumSteps),' time steps']);
        end
        
        
        % --------------------------------------------------------------- %
        % GET THE "FIT ALL K's AT INITIALISATION" FLAG
        if isfield( vararginLocal , 'computeAllKsAtInitialisation' ) 
            computeAllKsAtInitialisation = vararginLocal.computeAllKsAtInitialisation;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the field "computeAllKsAtInitialisation"');
            disp( ' ... NOTE: Using the default of "false"');
        end
        
        % --------------------------------------------------------------- %
        % USE THE PREVIOUSLY FITTED K's (if available)
        if isfield( vararginLocal , 'usePreviouslySavedKs' ) 
            usePreviouslySavedKs = vararginLocal.usePreviouslySavedKs;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the field "usePreviouslySavedKs"');
            disp( ' ... NOTE: Using the default of "false"');
        end
        
        % --------------------------------------------------------------- %
        % FOR THE ENERGY TO COMFORT SCALING
        if isfield( vararginLocal , 'energyToComfortScaling' ) 
            energyToComfortScaling = vararginLocal.energyToComfortScaling;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the field "energyToComfortScaling"');
            disp( ' ... NOTE: Using the default of "false"');
        end
        
        % --------------------------------------------------------------- %
        % FOR THE METHOD USED TO "CLIP" THE CONTROL BACK INTO ITS FEASIBLE SET
        if isfield( vararginLocal , 'clippingMethod' ) 
            clippingMethod = vararginLocal.clippingMethod;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the field "clippingMethod"');
            disp([' ... NOTE: Using the default of ',clippingMethod]);
        end
        
        
    else
        disp( ' ... ERROR: the "vararginLocal" variable was not a struct and hence cannot be processed');
    end
    
    
    %% PUT THE EXTRACTED OPTIONS INTO THE APPROPRIATE PROPERTIES OF THE OBJECT
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % Store the model type in the appropriate property
    obj.modelType = inputModelType;
    
    % Store the model
    obj.model = inputModel;
    
    % Store the prediction horizon to be used
    obj.statsPredictionHorizon = statsPredictionHorizon;
    
    % Store the recomputation regularilty
    obj.computeKEveryNumSteps = computeKEveryNumSteps;
    
    % Initialise the counter so that V is computed during the first step
    obj.iterationCounter = obj.computeKEveryNumSteps;
        
    % Store "fit all K's at initialisation" flag
    obj.computeAllKsAtInitialisation = computeAllKsAtInitialisation;
    
    % Store "use previously saved K's" flag
    obj.usePreviouslySavedKs = usePreviouslySavedKs;
    
    % Store the energy to comfort scaling
    obj.energyToComfortScaling = energyToComfortScaling;
        
    % Store the clipping method
    obj.clippingMethod = clippingMethod;
    
    
    %% ----------------------------------------------------------------- %%
    %% INITIALISE A CELL ARRAY FOR THE "P" AND "K" MATRICES
    % Create a cell array for storing the Value function at each time step
    % (and the "State Feedback" if it will be used)
    if ~computeAllKsAtInitialisation
        obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
        
            obj.K = cell( obj.statsPredictionHorizon+1 , 1 );
        
    else

    %% OR SPECIFY THAT THE INITIALISATION SHOULD BE CALLED AGAIN WITH "DisturbanceData"
        % All the Value Function approximations will be computed at once so
        % that multiple scenarios can be played at maximum computational
        % speed
        
        % Access to the necessary disturbance data is not provided through
        % this initialisation function
        % Instead, it is required to request that an additional
        % initialisation be run providing access to the disturbance data
        flag_requestDisturbanceData = true;
    end
    
    
    
    %% ----------------------------------------------------------------- %%
    %% GET THE COST CO-EFFICIENT TO SAVE HAVING TO GET THEM AT EVERY ITERATION
    
    % SYNTAX: "[costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( myCosts , currentTime )"
    tempCurrentTime = 1;
    [costCoeff , ~]  = getCostCoefficients_uptoQuadratic( obj.model.costDef , tempCurrentTime );
    obj.costCoeff_Q  =  costCoeff.Q;
    obj.costCoeff_R  =  costCoeff.R;
    obj.costCoeff_S  =  costCoeff.S;
    obj.costCoeff_q  =  costCoeff.q;
    obj.costCoeff_r  =  costCoeff.r;
    obj.costCoeff_c  =  costCoeff.c;
    

    
    
    
            
end
% END OF FUNCTION