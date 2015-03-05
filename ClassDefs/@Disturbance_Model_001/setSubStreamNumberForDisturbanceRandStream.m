function returnSuccess = setSubStreamNumberForDisturbanceRandStream( obj , inputSubStream )
% Defined for the "Disturbance_Model" class, this function set the
% "Sub-Stream" of the Random Stream object if possible
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    %% SET THE "SUB-STREAM" IF THE RAND OBJECT IS A TYPE THAT ALLOWS IT
    if strcmp(obj.randStreamObject.Type,'mrg32k3a') || strcmp(obj.randStreamObject.Type,'mlfg6331_64')
        obj.randStreamObject.Substream = inputSubStream;
    end


end
% END OF FUNCTION
