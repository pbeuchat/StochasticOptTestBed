function returnSample = requestSampleFromTimeForDuration( obj , startTime , duration , startXi )
% Defined for the "Disturbance_Model" class, this function return a sample
% drawn from this Disturbance Model is defined
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    % Get a random sample 
    tempSample = randn(obj.lengthRandInputVector , 1);
    
    % and pass it through
    returnSample = requestSampleFromTimeForDuration_withRandInput( obj , startTime , duration , startXi , tempSample );
    

end
% END OF FUNCTION