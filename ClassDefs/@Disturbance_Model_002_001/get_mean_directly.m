function returnMean = get_mean_directly( obj , startTime , duration , startXi )
% Defined for the "Disturbance_Model" class, this function return the mean
% for this Disturbance model based directly on the model definition
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

% First check that the input "statDesired" is a string
% if ~ischar(statDesired)
%     disp(' ... ERROR: The "statDesired" to be available is not a string and so cannot be parsed');
%     disp('            By default is stat is not directly available');
%     returnCheck = 0;
% else
%     returnCheck = ismember( statDesired , obj.stats_directlyAvailable);
% end


% This is not yet implemented
returnMean = requestSampleFromTimeForDuration( obj , startTime , duration , startXi );

end
% END OF FUNCTION