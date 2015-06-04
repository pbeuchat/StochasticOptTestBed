function [returnCost , returnCostPerSubSystem] = computeCostComponent( obj , x , u , xi , currentTime )
% Defined for the "CostComponent" class, this function computes the cost
% for its type without performing any checks on the input
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function is specific to linear cost functions,
%                 assumptions are made and checks left out in order to
%                 speed up the computations
%               > Computational speed is important for this function
%                 because it is called at every iteration
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

    % Initialise the return cost to be zero
    returnCost = 0;
    returnCostPerSubSystem = zeros(obj.subSystemCosts_num,1);

    % Step through each of the "Sub-Systems" as defined by the size of the
    % "subSystemCosts_array" array
    for iSubSys = 1 : obj.subSystemCosts_num
        % Compute the cost for this component
        % Assuming that each element of the "obj.subSystemCost_array" is a
        % primary type of "CostComponent" element and hence returns only a
        % "returnCost" accompanied by an empty "returnCostPerSubSystem"
        [thisReturnCost , ~] = computeCostComponent( obj.subSystemCosts_array(iSubSys,1) , x , u , xi , currentTime );
        % Use this cost as required
        returnCostPerSubSystem(iSubSys,1) = thisReturnCost;
        returnCost = returnCost + thisReturnCost;
    end


end
% END OF FUNCTION


