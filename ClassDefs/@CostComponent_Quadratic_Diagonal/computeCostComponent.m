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


    returnCost =     obj.Q' * x.^2  ...
                  +  obj.R' * u.^2  ...
                  +  obj.q' * x  ...
                  +  obj.r' * u  ...
                  +  obj.c;

    returnCostPerSubSystem = sparse([],[],[], obj.n_ss , 1 , 0);
    %returnCostPerSubSystem = [];
    

end
% END OF FUNCTION

