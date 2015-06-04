function [returnStat , returnSuccess] = requestStatDirectly( obj , statDesired , startTime , duration , startXi )
% Defined for the "DisturbanceModel" class, this function returns a
% statistic "directly" from the definition of the model, without needing to
% perform sampling
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
if ~ischar(statDesired)
    disp(' ... ERROR: The "statDesired" to be available is not a string and so cannot be parsed');
    disp('            By default is stat is not directly available');
    returnSuccess = false;
    returnStat = [];
    return
end

% Next check that the requested Statistic is actually available
checkAvailable = isStatAvailableDirectly( obj , statDesired );
if ~checkAvailable
    disp(' ... ERROR: The "statDesired" is not directly available from the disturbance model');
    disp('            Sampling will need to be performed to compute the statistic');
    returnSuccess = false;
    returnStat = [];
    return
end

% If the function made it to here then the statistic is available...
% Hence get it and return it:
% This is shamelessly hard-coded because is make the flags simpler
if strcmp( 'mean' , statDesired )
    returnStat = get_mean_directly( obj , startTime , duration , startXi );
% elseif strcmp( 'cov' , statDesired )
%     returnStat = get_cov_directly();
% elseif strcmp( 'bounds_boxtype' , statDesired )
%     returnStat = get_boundsBoxType_directly();
else
    % This shouldn't occur
    % Essentially the code got here because "statDesired" is listed in the
    % property "stats_directlyAvailable" but a method for getting it is not
    % actually implemented
    disp(' ... ERROR: The "statDesired" is not directly available from the disturbance model');
    disp('            Sampling will need to be performed to compute the statistic');
    returnSuccess = false;
    returnStat = [];
    return
end


% If the script made it here then it was successful
returnSuccess = true;


end
% END OF FUNCTION