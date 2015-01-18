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
    flag_ControlStructureChanged = true;
    
    % Specify there to only 1 locl controller that has access to all the
    % information (i.e. a global controller)
    new_n_ss = uint32(1);
    
    % Specify the masks so that this 1 local controller has access to all
    % the information about the state, input and disturbance
    new_mask_x_ss  = true( obj.stateDef.n_x  , 1 );
    new_mask_u_ss  = true( obj.stateDef.n_u  , 1 );
    new_mask_xi_ss = true( obj.stateDef.n_xi , 1 );
    
            
end
% END OF FUNCTION