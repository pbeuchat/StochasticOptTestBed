function returnIsReady = checkSimulationIsReadyToRun( obj , flag_throwError )
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



    % Initialise a "ready" tracking variable
    % By Default it is set to "true", and if anything is not ready then
    % set it to "false"
    returnIsReady = true;
    
    
    
    %% Check that things are not empty
    foundEmptyProperty = false;
    if isempty( obj.simTimeIndex_start )
        disp(' ... ERROR: the "Start Time Index" is empty')
        foundEmptyProperty = true;
    end
    if isempty( obj.simTimeIndex_end )
        disp(' ... ERROR: the "End Time Index" is empty')
        foundEmptyProperty = true;
    end
    if isempty( obj.simTimeIndex_start )
        disp(' ... ERROR: the "Start Time Index" is empty')
        foundEmptyProperty = true;
    end
    
    if foundEmptyProperty
        disp(' ... ERROR: One of the key properties for the Simulation to run was found to be empty');
        disp('            See above for which one or many they were');
        % Throw an error if requested
        if flag_throwError
            error(bbConstants.errorMsg);
        end
        % Set the return flag to be not compatible
        returnIsReady = false;
    end

    
    %% Check that the Start Index is before the End Index
    if ( obj.simTimeIndex_start  >  obj.simTimeIndex_end )
        disp(' ... ERROR: the "Start Time Index" is specified as being after the "End Time Index');
        disp(['            Start Time Index  = ',num2str(obj.simTimeIndex_start)]);
        disp(['            End Time Index    = ',num2str(obj.simTimeIndex_end)]);
        % Throw an error if requested
        if flag_throwError
            error(bbConstants.errorMsg);
        end
        % Set the return flag to be not compatible
        returnIsReady = false;
    end
    
    
    %% Check that the components have been checked for compatability
    if ~( obj.flag_componentsAreCompatible )
        disp(' ... ERROR: the simulation has either not been checked for compatability...');
        disp('            ... or it is actually incompatible');
        % Throw an error if requested
        if flag_throwError
            error(bbConstants.errorMsg);
        end
        % Set the return flag to be not compatible
        returnIsReady = false;
    end
    
    
    
    
    %% Set the flag of the Simulation Coordinator Object
    obj.flag_readyToSimulate = returnIsReady;
    
            
end
% END OF FUNCTION