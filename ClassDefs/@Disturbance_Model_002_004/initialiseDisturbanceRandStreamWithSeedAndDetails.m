function returnSuccess = initialiseDisturbanceRandStreamWithSeedAndDetails( obj , inputSeed , inputDetails )
% Defined for the "Disturbance_Model" class, this function initialises a
% Random Stream Object from the input Seed and the type of Rand Stream that
% should be specified in the input details
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    %% EXTRACT THE DETAILS FROM THE INPUT
    rng_generatorType   = inputDetails.Type;
    rng_numStreams      = inputDetails.NumStreams;
    rng_streamIndices   = inputDetails.StreamIndex;


    % Separate depending on whether the "Generator Type" supports multiple sub-streams
    % FOR GENERATORS THAT SUPPORT "SUB-STREAMS"
    if strcmp(rng_generatorType,'mrg32k3a') || strcmp(rng_generatorType,'mlfg6331_64')
        % Create the Rand Stream Object
        obj.randStreamObject = RandStream.create(rng_generatorType,'numstreams',rng_numStreams,'streamindices',rng_streamIndices,'Seed',inputSeed);

    % FOR GENERATORS THAT DON'T SUPPORT "SUB-STREAMS"
    elseif strcmp(rng_generatorType,'mt19937ar')
        % Create the Rand Stream Object
        obj.randStreamObject = RandStream.create(rng_generatorType,'Seed',inputSeed);

    % FOR GENERATORS THAT ARE NOT RECOGNISED
    else
        disp( ' ... ERROR: the specified random number "Generator Type" was not recognised' );
        disp(['            The specified type was:   "',rng_generatorType,'"' ]);
        error(bbConstants.errorMsg);
    end

    % If the code makes it to here then it was successful
    returnSuccess = true;


end
% END OF FUNCTION


%% THE EXPECTED FORMAT OF THE DETAILS STRUCT
%
%         .Type
%         .Seed
%         .NumStreams
%         .StreamIndex
%         .State
%         .Substream
%         .NormalTransform
%         .Antithetic
%         .FullPrecision
% 
%         % Other likely present properties but that shouldn't be needed
%         .numSamplesPerTimeStep
%         .numTimeStepsPerRealisation
%         .numRealisations
%         .workerNumber
