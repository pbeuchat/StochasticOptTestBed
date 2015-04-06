function u = computeControlAction( obj , currentTime , x , xi_prev , stageCost_prev , stageCost_this_ss_prev , predictions )
 %timeStepIndex , timeStepAbsolute
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
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



    % Select the control action to be randomly between upper and lower
    % bounds defined by the Hyper-Rectangle constraints
    u_lower = obj.constraintDef.u_rect_lower;
    u_upper = obj.constraintDef.u_rect_upper;

    % Get the size of the input to be returned for this sub-system
    n_u = obj.stateDef.n_u;
    
    % Seed the Random Number Generator
    %rng( sum(x) );

    % Now compute the input
    u = u_lower + rand(n_u,1) * (u_upper - u_lower);
    
    % Now pass the u to the global coordinator for checking
    passLocalInputToGlobalCoordinator( obj.globalController , obj.idnum , u , currentTime.index ); 
            
end
% END OF FUNCTION