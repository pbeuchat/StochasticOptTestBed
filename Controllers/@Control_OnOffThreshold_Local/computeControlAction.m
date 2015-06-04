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


    % Get the temperature value to compare to the threshold
    x_current = x(1);

    % If above the threshold, then turn the radiator off
    if x_current >= obj.x_threshold_upper
        obj.onOff_state = false;
    elseif x_current <= obj.x_threshold_lower
        obj.onOff_state = true;
    else
        % Leave the radiator in its current state
    end
    
    % Specify the input to apply based on the current state
    if obj.onOff_state
        u = obj.on_control;
    else
        u = obj.off_control;
    end
    
    
    
end
% END OF FUNCTION