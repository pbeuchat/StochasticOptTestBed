function flag_successfullyInitialised = initialise_localControl( obj , inputModelType , inputModel , vararginLocal)
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

    % You can except the "inputModel" parameter to be empty when the
    % control is specified to be "Model-Free" and non-empty otherwise
    
    % When using the "Null" controller as a template, insert your code here
    % to pre-compute off-line parts of your controllers so the the "on-line
    % computation time is minimised when the "copmuteControlAction"
    % function is called at each time step
    
    %% SPECIFY A FEW DEFAULTS TO USE
    
    % FOR THE PREDICITON HORIZON
    statsPredictionHorizon = uint32(12);
    
    % FOR THE REGULARILTY OF RECOMPUTING THE VALUE FUNCTIONS
    computeMPCEveryNumSteps = uint32(12);
    
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
        
        
    else
        disp( ' ... ERROR: the "vararginLocal" variable was not a struct and hence cannot be processed');
    end

    
    %% NOW PERFORM THE INITIALISATION
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
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
    
    
    
            
end
% END OF FUNCTION