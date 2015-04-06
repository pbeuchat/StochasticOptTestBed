function [u , computationTime_per_ss , diagnostics] = computeControlAction( obj , currTime , x , xi , stageCost , stageCost_per_ss , prediction , statsRequired_mask , timeHorizon )
%stageCost.localcost
%stageCost.globalcost
%stageCost.comfort local and global
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



    % Initialise an error tracking variable
    errorOccurred = 0;
    errorMsg = '';

    % Check that the input state "x" is the expected size
    if ~(length(x) == obj.stateDef.n_x)
        errorMsg = [errorMsg,'The length of the state variable "x" did not agree with the length expected by the Global controller class'];
        errorOccurred  = 1;
    end

    % To reduce the number of property call, we could instead put the
    % "mask_x" into a variable here
    mask_x_local   = obj.stateDef.mask_x_ss;
    mask_u_local   = obj.stateDef.mask_u_ss;
    mask_xi_local  = obj.stateDef.mask_xi_ss;
    
    % Intialise the return "u"
    u = zeros(obj.stateDef.n_u,1);
    
    % Initialise the return timing
    computationTime_per_ss = zeros( obj.numControllers , 1 );
    
    % Check if the predicitons are even required
    if isempty( prediction)
        getPrediction = false;
        this_prediction = [];
    else
        getPrediction = true;
    end
    
    % Step through each of the "Local" controllers
    for iCtrl = 1 : obj.numControllers
        % Start the timer for this sub-system
        thisStartTime = clock;
        
        % Get the mask for this controller
        thisMask_x   = mask_x_local(  : , iCtrl );
        thisMask_u   = mask_u_local(  : , iCtrl );
        thisMask_xi  = mask_xi_local( : , iCtrl );
        
        % Extract the state information for this controller using the mask
        this_x   = x(  thisMask_x  );
        this_xi  = xi( thisMask_xi );
        
        % Also need to apply the mask to the precition
        if getPrediction
            this_prediction = Disturbance_ology.applyMaskToPrediciton( statsRequired_mask , prediction , thisMask_xi , timeHorizon );
        end
        
        % Compute the control action (Mapping it back to its portion of
        % the full vector using the mask indexing)
        u(thisMask_u,1) = computeControlAction( obj.localControllerArray(iCtrl) , currTime , this_x , this_xi , stageCost , stageCost_per_ss(:,iCtrl) , this_prediction);
        
        % End the time for this sub-system
        computationTime_per_ss( iCtrl , 1 ) = etime(clock,thisStartTime);
    end
    
    % Put the error flag in to the return variable
    diagnostics.error       = errorOccurred;
    diagnostics.errorMsg    = errorMsg;
	
end
% END OF FUNCTION