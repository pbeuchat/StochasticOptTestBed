function returnParallelInitialised = initialise_MultipleDistCoordRandStream_ForParallelSimulations( obj )
% Defined for the "Simulation_Coordinator" class, this function make a cell
% array of DEEP copies of the "disturbance coordinator" object to make the
% simulations compatible for parallelisation and reproducability
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



    % INITIALISE THE RETURN VARIABLE
    returnParallelInitialised = true;
    
    % ITERATED THROUGH THE NUMBER OF WORKERS
    for iWorker = 1 : obj.evalMulti_numWorkers
        % Initialise via a Rand Stream
        this_randStream = obj.randStream_perWorkerCellArray{iWorker,1};
        this_success = initialiseDisturbanceRandStreamWithRandStream( obj.distCoordArray(iWorker,1) , this_randStream );
        returnParallelInitialised = this_success && returnParallelInitialised;
        
        
        % Or initialise via a struct of details
        %this_randStreamDetails = obj.detailsOf_randStreamPerWorker{iWorker,1};
        %this_success = initialiseDisturbanceRandStreamWithSeedAndDetails( obj.distCoordArray(iWorker,1) , this_randStreamDetails.Seed , this_randStreamDetails );
        %returnParallelInitialised = this_success && returnParallelInitialised;
        
    end
            
end
% END OF FUNCTION



%%
%% A FEW DETAILS ABOUT THE RANDOM STREAMS
%
% See these websites:
%       http://ch.mathworks.com/help/matlab/math/multiple-streams.html?refresh=true
%       http://ch.mathworks.com/help/matlab/math/creating-and-controlling-a-random-number-stream.html
%       http://ch.mathworks.com/help/matlab/ref/randstream.html
%