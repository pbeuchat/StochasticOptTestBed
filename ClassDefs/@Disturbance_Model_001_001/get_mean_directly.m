function returnMean = get_mean_directly( obj , startTime , timeHorizon )
% Defined for the "Disturbance_Model" class, this function return the mean
% for this Disturbance model based directly on the model definition
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



% First check that the input "statDesired" is a string
% if ~ischar(statDesired)
%     disp(' ... ERROR: The "statDesired" to be available is not a string and so cannot be parsed');
%     disp('            By default is stat is not directly available');
%     returnCheck = 0;
% else
%     returnCheck = ismember( statDesired , obj.stats_directlyAvailable);
% end


% This is not yet implemented
returnMean = zeros(obj.n_xi,1);

end
% END OF FUNCTION