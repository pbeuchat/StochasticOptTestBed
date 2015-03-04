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