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
    % to pre-compute off-line parts of your controllers so the the "on-line
    % computation time is minimised when the "copmuteControlAction"
    % function is called at each time step
    
    %% SPECIFY A FEW DEFAULTS TO USE
    
    % FOR THE PREDICITON HORIZON
    % (This default is used unless a value is specified in "vararginLocal")
    statsPredictionHorizon = uint32(12);
    
    % FOR THE REGULARILTY OF RECOMPUTING THE VALUE FUNCTIONS
    % (This default is used unless a value is specified in "vararginLocal")
    computeMPCEveryNumSteps = uint32(12);
    
    % FOR THE ENERGY TO COMFORT SCALING
    energyToComfortScaling = 0;
    
    
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
        if isfield( vararginLocal , 'computeMPCEveryNumSteps' )
            computeMPCEveryNumSteps = uint32(vararginLocal.computeMPCEveryNumSteps);
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "computeMPCEveryNumSteps"');
            disp([' ... NOTE: Using the default of ',num2str(computeMPCEveryNumSteps),' time steps']);
        end
        
        % --------------------------------------------------------------- %
        % GET THE ENERGY TO COMFORT SCALING
        if isfield( vararginLocal , 'energyToComfortScaling' )
            energyToComfortScaling = vararginLocal.energyToComfortScaling;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "energyToComfortScaling"');
            disp([' ... NOTE: Using the default of ',num2str(energyToComfortScaling),' time steps']);
        end
        
    else
        disp( ' ... ERROR: the "vararginLocal" variable was not a struct and hence cannot be processed');
    end

    
    %% NOW PERFORM THE INITIALISATION
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % Store the size of the input vector
    obj.n_u  = obj.stateDef.n_u;
    
    % Store the model type in the appropriate property
    obj.modelType = inputModelType;
    
    % Store the model
    obj.model = inputModel;
    
    % Store the prediction horizon to be used
    obj.statsPredictionHorizon = statsPredictionHorizon;
    
    % Store the recomputation regularilty
    obj.computeMPCEveryNumSteps = computeMPCEveryNumSteps;
    
    % Initialise the counter so that MPC is computed during the first step
    obj.iterationCounter = obj.computeMPCEveryNumSteps;
    
    % Set the energy to comfort scaling
    obj.energyToComfortScaling = energyToComfortScaling;
    
    %% SET THE MODEL MATRICES BASED ON THE DISCRETISATION SPECIFIED
    % Initialise a flag for whether to use the discrete model from the
    % "inputModel" or not
    flag_useInputModelDiscreteTimeModel = true;
    
    % Check is a discretisation method" property is defined for the
    % "VARiable ARGuments INput"
    if isfield(vararginLocal,'discretisationMethod')
        % If the option was set to "euler" then update the model to be used
        if strcmp(vararginLocal.discretisationMethod , 'euler')
            % Get the discretisation time step from the "inputModel"
            secondsPerHours = 60 * 60;
            Ts_seconds = inputModel.building.building_model.Ts_hrs * secondsPerHours;
            
            temp_n_x = size( inputModel.building.building_model.continuous_time_model.A , 1 );
            
            obj.A    =  speye(temp_n_x) + sparse( inputModel.building.building_model.continuous_time_model.A   .* Ts_seconds );
            obj.Bu   =                    sparse( inputModel.building.building_model.continuous_time_model.Bu  .* Ts_seconds );
            obj.Bxi  =                    sparse( inputModel.building.building_model.continuous_time_model.Bv  .* Ts_seconds );
            
            % Set the flag to prevent this been over-written
            flag_useInputModelDiscreteTimeModel = false;
        end
    end
    
    
    % Use the discrete time model from the "inputModel" variable if
    % required
    if flag_useInputModelDiscreteTimeModel
        obj.A    =  sparse(  inputModel.building.building_model.discrete_time_model.A   );
        obj.Bu   =  sparse(  inputModel.building.building_model.discrete_time_model.Bu  );
        obj.Bxi  =  sparse(  inputModel.building.building_model.discrete_time_model.Bv  );
    end
    
    
    %% SET THE QUADRATIC COST MATRICES
    
    % Get the coefficients for a quadratic cost
    currentTime = [];
    [costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( obj.model.costDef , currentTime );
    
    Q_k     = costCoeff.Q;
    R_k     = costCoeff.R;
    S_k     = costCoeff.S;
    q_k     = costCoeff.q;
    r_k     = costCoeff.r;
    c_k     = costCoeff.c;
    
    
    % APPLY THE ENERGY TO COMFORT SCALING
    % If the "S" term is non-zero then this scaling doesn't make as
    % much sense
    %R_k = obj.energyToComfortScaling*R_k;
    r_k = obj.energyToComfortScaling*r_k;
    
    % Display an error message if all Cost Components are not included
    if not(flag_allCostComponentsIncluded)
        disp( ' ... ERROR: not all of the cost components could be retireived');
        disp( '            This likely because at least one of the components is NOT a quadratic or linear function');
        disp( '            and this ADP implementation can only handle linear or quadratic cost terms');
    end
    
    
    
    
    
    %% BUILD THE PREDICTIVE MODEL MATRICES
    
    % Build the generic MPC matrices first
    [obj.A_mpc , obj.Bu_mpc , obj.Bxi_mpc , obj.Q_mpc , obj.R_mpc , obj.S_mpc , obj.q_mpc , obj.r_mpc , obj.c_mpc ] = Control_MPC_Local.buildMPCMatrices_static( statsPredictionHorizon, obj.A, obj.Bu, obj.Bxi, Q_k, R_k, S_k, q_k, r_k, c_k);
    
    % Now build the matrices that are need at each time step
    buildMPCMatrices_specific( obj );
    
    
    %% BUILD THE CONSTRAINT MATRICES
    % Get the constraints
    [obj.A_ineq_input, obj.b_ineq_input] = Control_MPC_Local.buildMPC_inputConstraints_fromConstraintDefObject( statsPredictionHorizon, obj.constraintDef );
    
            
end
% END OF FUNCTION