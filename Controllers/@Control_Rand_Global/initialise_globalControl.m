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