function returnParallelInitialise = initialiseMultipleDistCoordForParallelSimulations( obj )
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


    
    %% ----------------------------------------------------------------- %%
    %% SPECIFY HOW THE EVALUATION OF MULTIPLE REALISATIONS SHOULD BE HANDLED
    
    
    %% If NOT requested to perform multiple realisations, then set the
    % details to produce results for 1 realisation
    if ~obj.evalMultiReal_details.flag_evaluateOnMultipleRealisations
        clear temp_evalMultiReal_details;
        temp_evalMultiReal_details.numSampleMethod          = 'userSpecified';
        temp_evalMultiReal_details.numSamplesMax            = inf;
        temp_evalMultiReal_details.parallelise_onOff        = false;
        temp_evalMultiReal_details.parallelise_numThreads   = 1;
        
        temp_evalMultiReal_details.flag_save_x      = obj.evalMultiReal_details.flag_save_x;
        temp_evalMultiReal_details.flag_save_u      = obj.evalMultiReal_details.flag_save_u;
        temp_evalMultiReal_details.flag_save_xi     = obj.evalMultiReal_details.flag_save_xi;
        temp_evalMultiReal_details.flag_save_cost   = obj.evalMultiReal_details.flag_save_cost;
        temp_evalMultiReal_details.flag_save_cost_perSubSystem = obj.evalMultiReal_details.flag_save_perSubSystem;
        temp_evalMultiReal_details.flag_save_controllerDetails = obj.evalMultiReal_details.flag_save_controllerDetails;
        
        % Put this back into the object
        obj.evalMultiReal_details = temp_evalMultiReal_details;
    end

    
    %% COMPUTE OR EXTRACT THE NUMBER OF REALISAISATION TO BE EVALUATED
    if strcmp(obj.evalMultiReal_details.numSampleMethod , 'userSpecified')
        evalMulti_numRealisation = obj.evalMultiReal_details.numSamplesUserSpec;
    elseif strcmp(obj.evalMultiReal_details.numSampleMethod , 'n_xi^2')
        evalMulti_numRealisation = ( obj.stateDef.n_xi * timeDuration )^2;
    else
        disp( ' ... ERROR: the specified number of realisations method was not recognised' );
        disp(['            The specified method was:   "',obj.evalMultiReal_details.numSampleMethod,'"' ]);
        disp( '            Setting the number of realisation to 1 instead' );
        evalMulti_numRealisation = 1;
    end
    
    
    %% EXTRACT THE RAND NUMBER GENERATOR TYPE TO USE
    rng_generatorType = obj.randNumGenType;
    
    % OPTIONS: that can have independent sub-streams
    %       'mrg32k3a', 'mlfg6331_64'
    % OPTIONS: that need sub-streams to be defined separately
    %       'mt19937ar'

    
    
    %% CREATE THE CELL ARRAY OF "RandStream" OBJECTS
    
    % Get the number of threads available on the current machine:
    % The Matlab command "maxNumCompThreads" which returns this number will
    % be deprecated in the newer versions of Matlab
    % @TODO how to determine automatically the number of threads available
    % Just hardcode it to be "1" for now
    maxNumCompThreads_availableOnThisMachine = 1;
    
    if obj.evalMultiReal_details.parallelise_numThreads == inf
        obj.evalMultiReal_details.parallelise_numThreads = maxNumCompThreads_availableOnThisMachine;
    end

    % Set the number of "workers" to be the number of "threads" (or the
    % number of realisations to evaluate if that is a smaller number)
    evalMulti_numWorkers = min( obj.evalMultiReal_details.parallelise_numThreads , evalMulti_numRealisation);

    % Initialise the cell array of "RandSteam" object per worker
    randStream_perWorkerCellArray = cell(evalMulti_numWorkers,1);

    % From the "Original Seed" initialise a RandStream for each worker
    % Separate depending on whether the "Generator Type" supports multiple sub-streams
    % FOR GENERATORS THAT SUPPORT "SUB-STREAMS"
    if strcmp(rng_generatorType,'mrg32k3a') || strcmp(rng_generatorType,'mlfg6331_64')
        % A few things for creating the "RandStream" objects
        temp_numStreams = evalMulti_numWorkers;
        temp_seed = obj.seed_original;
        % Create the "RandStream" for each worker
        for iWorker = 1:evalMulti_numWorkers
            randStream_perWorkerCellArray{iWorker,1} = RandStream.create('mrg32k3a','numstreams',temp_numStreams,'streamindices',iWorker,'Seed',temp_seed);
        end

    % FOR GENERATORS THAT DON'T SUPPORT "SUB-STREAMS"
    elseif strcmp(rng_generatorType,'mt19937ar')
        % Create a seed per worker starting from the original seed
        seedPerWorker = obj.seed_original + 1:evalMulti_numWorkers;
        % Create the "RandStream" for each worker
        for iWorker = 1:evalMulti_numWorkers
            temp_seed = seedPerWorker(iWorker);
            randStream_perWorkerCellArray{iWorker,1} = RandStream.create('mt19937ar','Seed',temp_seed);
        end

    % FOR GENERATORS THAT ARE NOT RECOGNISED
    else
        disp( ' ... ERROR: the specified random number "Generator Type" was not recognised' );
        disp(['            The specified type was:   "',rng_generatorType,'"' ]);
        error(bbConstants.errorMsg);
    end

    % @TODO: should the "randStream_perWorkerCellArray" be kept as a
    % property of the "Simulation_Coordinator" obj that this function is
    % running under
    
    
    %% Compute the number of Realisation to evaluate per Worker
    
    % If there is only 1 worker then the answer is simple
    if evalMulti_numWorkers == 1
        evalMulti_numRealisationsPerWorkerVector = evalMulti_numRealisation;
    else
        % Spread the number of realisations evenly betweem the workers (to
        % the nearest integer) and give the remainder to the last worker
        temp_num = floor(evalMulti_numRealisation / evalMulti_numWorkers);
        temp_rem = evalMulti_numRealisation - temp_num*evalMulti_numWorkers;
        evalMulti_numRealisationsPerWorkerVector = [temp_num * ones(evalMulti_numWorkers-1,1) ; temp_num+temp_rem ];
    end
    
    % Also comput the realisation indexing for when the data is saved to
    % disk
    if evalMulti_numWorkers == 1
        evalMulti_realisationIndexStart     = 1;
        evalMulti_realisationIndexEnd       = evalMulti_numRealisation;
    else
        evalMulti_realisationIndexStart     = (1  :  temp_num  :  (temp_num*evalMulti_numWorkers+1))';
        evalMulti_realisationIndexEnd       = [(temp_num : temp_num : temp_num*(evalMulti_numWorkers-1))' ; evalMulti_numRealisation];
    end
    
    
    %% Create a "result_seed" struct that can be saved 
    % It will be used to unambiguously re-create the same reults
    
    % Initialise a cell array
    result_randStreamPerWorker = cell(evalMulti_numWorkers,1);
    % Step through each worker storing the details
    for iWorker = 1 : evalMulti_numWorkers
        % And store all the properties of the Rand Stream
        result_randStreamPerWorker{iWorker,1}.Type              = randStream_perWorkerCellArray{iWorker,1}.Type;
        result_randStreamPerWorker{iWorker,1}.Seed              = randStream_perWorkerCellArray{iWorker,1}.Seed;
        result_randStreamPerWorker{iWorker,1}.NumStreams        = randStream_perWorkerCellArray{iWorker,1}.NumStreams;
        result_randStreamPerWorker{iWorker,1}.StreamIndex       = randStream_perWorkerCellArray{iWorker,1}.StreamIndex;
        result_randStreamPerWorker{iWorker,1}.State             = randStream_perWorkerCellArray{iWorker,1}.State;
        result_randStreamPerWorker{iWorker,1}.Substream         = randStream_perWorkerCellArray{iWorker,1}.Substream;
        result_randStreamPerWorker{iWorker,1}.NormalTransform   = randStream_perWorkerCellArray{iWorker,1}.NormalTransform;
        result_randStreamPerWorker{iWorker,1}.Antithetic        = randStream_perWorkerCellArray{iWorker,1}.Antithetic;
        result_randStreamPerWorker{iWorker,1}.FullPrecision     = randStream_perWorkerCellArray{iWorker,1}.FullPrecision;
        
        % Store details about how many samples are drawn per realisation
        result_randStreamPerWorker{iWorker,1}.numSamplesPerTimeStep         = obj.stateDef.n_xi;
        result_randStreamPerWorker{iWorker,1}.numTimeStepsPerRealisation    = timeDuration;
        result_randStreamPerWorker{iWorker,1}.numRealisations               = evalMulti_numRealisationsPerWorkerVector(iWorker,1);
        
        % Store the worker number for completeness of cross-checking when
        % using this data to replicate a specific realisation
        result_randStreamPerWorker{iWorker,1}.workerNumber      = iWorker;
    end
    
    % Make a cell array of these properties
    %tempWorker = 1;
    %propertiesFor_randStreamPerWorker = fieldnames( result_randStreamPerWorker{tempWorker,1} );
    
    
    
    
    
    %% SET THAT THE SIMULATION WAS SUCCESSFUL IF WE MADE IT HERE
    % Put the error flag in to the return variable
    %diagnostics.error       = errorOccurred;
    %diagnostics.errorMsg    = errorMsg;
    
    returnCompletedSuccessfully = true;
            
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
%