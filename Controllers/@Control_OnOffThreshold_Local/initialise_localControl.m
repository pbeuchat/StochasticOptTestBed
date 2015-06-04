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
    
    
    % Get the min and max control to applie
    if obj.constraintDef.flag_inc_u_box
        obj.on_control  = obj.constraintDef.u_box;
        obj.off_control = -obj.constraintDef.u_box;
    elseif obj.constraintDef.flag_inc_u_rect
       obj.on_control  = obj.constraintDef.u_rect_upper;
        obj.off_control = -obj.constraintDef.u_rect_lower;
    else
        obj.on_control  = zeros( obj.n_u , 1);
        obj.off_control = zeros( obj.n_u , 1);
    end
    
    
    % @TODO: THIS IS A HACK: the "x_ref" should be passed through to this
    % function somehow
    x_ref = 22.5;
    
    obj.x_threshold_upper = 23;
    obj.x_threshold_lower = 20;

    % Set the successfully initialised flag
    flag_successfullyInitialised = true;
    
    
    
            
end
% END OF FUNCTION