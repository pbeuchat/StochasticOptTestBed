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
    
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % Store the model type in the appropriate property
    obj.modelType = inputModelType;
            
end
% END OF FUNCTION