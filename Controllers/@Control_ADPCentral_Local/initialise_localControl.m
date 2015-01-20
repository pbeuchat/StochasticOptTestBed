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
    
    % FOR THE ADP METHOD TO USE:
    useMethod_samplingWithLSFit = false;
    useMethod_bellmanIneq       = true;
    
    % FOR THE PREDICITON HORIZON
    statsPredictionHorizon = uint32(12);
    
    % FOR THE REGULARILTY OF RECOMPUTING THE VALUE FUNCTIONS
    computeVEveryNumSteps = uint32(6);
    
    %% EXTRACT THE OPTIONS FROM THE "vararginLocal" INPUT VARIABLE
    if isstruct( vararginLocal )
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED ADP METHOD TO USE
        if isfield( vararginLocal , 'ADPMethod' )
            if strcmp( vararginLocal.ADPMethod , 'samplingWithLeastSquaresFit' )
                useMethod_samplingWithLSFit = true;
                useMethod_bellmanIneq       = false;
            elseif strcmp( vararginLocal.ADPMethod , 'bellmanInequality' )
                useMethod_samplingWithLSFit = false;
                useMethod_bellmanIneq       = true;
            else
                disp( ' ... ERROR: The specified ADP Method was not recognised');
                disp( '            The method specified was:');
                disp(vararginLocal.ADPMethod);
                disp( ' ... NOTE: Using the Bellman Inequality Method as a default');
            end
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "ADPMethod"');
            disp( ' ... NOTE: Using the Bellman Inequality Method as a default');
        end
        
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
        if isfield( vararginLocal , 'computeVEveryNumSteps' )
            computeVEveryNumSteps = uint32(vararginLocal.computeVEveryNumSteps);
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "computeVEveryNumSteps"');
            disp([' ... NOTE: Using the default of ',num2str(computeVEveryNumSteps),' time steps']);
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
    
    % Create a cell array for storing the Value function at each time step
    obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
    obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
    obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
    
    % Store the prediction horizon to be used
    obj.statsPredictionHorizon = statsPredictionHorizon;
    
    % Store the recomputation regularilty
    obj.computeVEveryNumSteps = computeVEveryNumSteps;
    
    % Initialise the counter so that V is compute during the first step
    obj.iterationCounter = obj.computeVEveryNumSteps;
    
    % Store which ADP Method to use
    obj.useMethod_samplingWithLSFit     = useMethod_samplingWithLSFit;
    obj.useMethod_bellmanIneq           = useMethod_bellmanIneq;
    
    
            
end
% END OF FUNCTION