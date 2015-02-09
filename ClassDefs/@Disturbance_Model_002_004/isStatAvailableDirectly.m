function returnCheck = isStatAvailableDirectly( obj , statDesired )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

% First check that the input "statDesired" is a string
if ~ischar(statDesired)
    disp(' ... ERROR: The "statDesired" to be available is not a string and so cannot be parsed');
    disp('            By default is stat is not directly available');
    returnCheck = 0;
else
    returnCheck = ismember( statDesired , obj.stats_directlyAvailable);
end


end
% END OF FUNCTION