function [flag_ControlStructureChanged , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss] = initialise_globalControl( obj , inputModelType ,  inputModel , vararginGlobal)
% Defined for the "Control_GlobalControl" class, this function will be
% called once before the simulation is started
% This function should be used to adjust the structure of the local
% control schemes
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
    % to specify if a different control structure is to be used
    
    % NOTE: that the updated "n_ss" and "masks" that are returned from this
    % function will be checked for validity
    
    % Store the model type in the appropriate property
    obj.modelType = inputModelType;
    
    % Specify the return flag about whether a change is being made
    flag_ControlStructureChanged = false;
    
    % Set all the other return variable to be blank
    new_n_ss = [];
    new_mask_x_ss  = [];
    new_mask_u_ss  = [];
    new_mask_xi_ss = [];
    

    % Pre-allocate the "current_u" variable
    obj.current_u = zeros( obj.stateDef.n_ss , 1 );

            
end
% END OF FUNCTION