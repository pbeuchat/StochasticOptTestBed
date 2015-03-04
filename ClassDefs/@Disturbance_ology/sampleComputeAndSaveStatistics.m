function returnSuccess = sampleComputeAndSaveStatistics( obj , statsRequired , distCycleTimeSteps , n_xi , isTimeCorrelated , timeHorizon )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               > The "trace" input is optional
% ----------------------------------------------------------------------- %

% WHERE SHOULD THIS BE SPECIFIED AND PASSES AROUND
numSamplesToCollect = 1000;

%% KEEP THE USER UPDATES ABOUT WHAT IS HAPPENING
disp([' ... Now computing the statistic for every step of the Disturbance Model Cycle (out of ',num2str(distCycleTimeSteps),' time steps']);


%% --------------------------------------------------------------------- %%
%% CHECK IF THE "statsRequired" CAN BE COMPUTED BY THIS CLASS

% First check that "statsRequired" is a cell array and not empty
if isempty(statsRequired)
    disp(' ... ERROR: The "statsRequied" object is empty and hence this function has nothing to do');
    error(bbConstants.errorMsg);
end
if ~iscell(statsRequired)
    disp(' ... ERROR: The "statsRequied" object is not a cell array');
    error(bbConstants.errorMsg);
end

% Now check that it is possible to compute each one
%numStatsRequired = length(statsRequired);
%numStatsPossible = length(obj.statsComputationsAvailable);
% Iterate through each of the implemented stat computations, checking if is
% required and setting a flag
% This is shamelessly hard-coded because is make the flags simpler
if ismember('mean',statsRequired)
    computeMean = 1;
else
    computeMean = 0;
end
if ismember('cov',statsRequired)
    computeCov = 1;
else
    computeCov = 0;
end
if ismember('bounds_boxtype',statsRequired)
    computeBoundsBox = 1;
else
    computeBoundsBox = 0;
end

% Check if any of the required stats are not computable
numStatsRequired = length(statsRequired);
for iStat = 1:numStatsRequired
    thisStat = statsRequired{iStat};
    if ~ismember(thisStat,obj.statsComputationsAvailable)
        disp([' ERROR: the statistic "',thisStat,'" is required but a method for computing it is not implemented']);
        error(bbConstants.errorMsg);
    end
end



%% --------------------------------------------------------------------- %%
%% CHECK THE NEED FOR A "trace" TO COMPUTE THE STATISTICS
% This is an input, to minimise the dependence on "getter" methods
%isTimeCorrelated = isDisturbanceModelTimeCorrelated( obj.myDisturbanceModel);

if isTimeCorrelated
    traceRequired = 1;
else
    traceRequired = 0;
end



%% --------------------------------------------------------------------- %%
%% ASK THE DISTURBANCE MODEL IF THE REQUIRED STATISTICS ARE AVAILABLE

% Only ask for the statistic required
getDirectlyMean = 0;
if computeMean
    % Check if available
    getDirectlyMean = isStatAvailableDirectly( obj.myDisturbanceModel , 'mean' );
    computeMean = ~getDirectlyMean;
end

getDirectlyCov = 0;
if computeCov
    % Check if available
    getDirectlyCov = isStatAvailableDirectly( obj.myDisturbanceModel , 'cov' );
    computeCov = ~getDirectlyCov;
end

getDirectlyBoundsBox = 0;
if computeBoundsBox
    % Check if available
    getDirectlyBoundsBox = isStatAvailableDirectly( obj.myDisturbanceModel , 'bounds_boxtype' );
    computeBoundsBox = ~getDirectlyBoundsBox;
end

% Make a flag indicating if something needs to be compute
computeSomething = ( computeMean        || ...
                     computeCov         || ...
                     computeBoundsBox      ...
                   );

               
%% --------------------------------------------------------------------- %%
%% SPECIFY A FEW FILE PATH FOR SAVE THE DATA THAT WILL BE COMPUTED BELOW
% Get the Root Path for where to save everything
savePath_Root = constants_MachineSpecific.saveDataPath;

% Path for Save Disturbance Data
savePath_Dist = [savePath_Root,'savedDisturbances/'];
if ~(exist(savePath_Dist,'dir') == 7)
    mkdir(savePath_Dist);
end

% Save Path for this Dist
savePath_thisDist = [ savePath_Dist , class(obj.myDisturbanceModel) ,'/' ];
if ~(exist(savePath_thisDist,'dir') == 7)
    mkdir(savePath_thisDist);
end

% Specify the Save Path for the "mean" , "cov" , "bounds_boxtype"
% At the same time checking if these directories are full, and if so,
% making of the existing folder before emptying it
% Flag for whether to bother with a copy or not
tempCopyFlag = 1;
% Speciy the path:
if computeMean || getDirectlyMean
    savePath_mean               = bbConstants.createOrEmptyFolderWithCopyOption(savePath_thisDist , 'mean' , tempCopyFlag);
end
if computeCov || getDirectlyCov
    savePath_cov                = bbConstants.createOrEmptyFolderWithCopyOption(savePath_thisDist , 'cov' , tempCopyFlag);
end
if computeBoundsBox || getDirectlyBoundsBox
    savePath_bounds_boxtype     = bbConstants.createOrEmptyFolderWithCopyOption(savePath_thisDist , 'bounds_boxtype' , tempCopyFlag);
end
               

%% --------------------------------------------------------------------- %%
%% COMPUTE THE STATS FOR A "timeHorizon" AT EVERY STEP OF THE FULL DISTURBANCE MODEL TIME CYCLE

% Set the seed before starting so that things are reproducible
thisSeed = 20;

% Initialise the vectors for storing the statistics to be saved
% The idea here is to create the memory once, and always overwrite it, this
% should keep computations as fast as possible
% Basically we just need the size of a disturbance vector for "timeHorizon"
% time steps, but we shouldn't 
if isTimeCorrelated
    
else
    % Set the time horizon to 1
    timeHorizon = 1;
    
    % Get the size of the vector to store
    n_sample = n_xi;
    
    % Initialise a container for the data to be passed to the saving
    myMean                          = zeros( n_xi , distCycleTimeSteps );
    %saveData_cov  = zeros(n_xi , n_xi);
    myBounds_boxtype_lower   = zeros( n_xi);
    myBounds_boxtype_upper   = zeros( n_xi , distCycleTimeSteps );
    
    % Specify the save file names
    if computeMean || getDirectlyMean
        saveFile_mean                   = [ savePath_mean               , 'mean.mat' ];
    end
    if computeCov || getDirectlyCov
        saveFile_cov                    = [ savePath_cov                , 'cov.mat' ];
    end
    if computeBoundsBox || getDirectlyBoundsBox
        saveFile_bounds_boxtype_lower   = [ savePath_bounds_boxtype     , 'bounds_boxtype_lower.mat' ];
        saveFile_bounds_boxtype_upper   = [ savePath_bounds_boxtype     , 'bounds_boxtype_upper.mat' ];
    end
    
    
    % For bigger data sets it makes sense to pre-save a blank variable, and
    % then fill-in each part as the stats are computed
    if computeCov || getDirectlyCov
        % For the "cov" computations we need to create a saved file
        data = zeros( n_xi , n_xi , distCycleTimeSteps);
        save( saveFile_cov , 'data' , bbConstants.matlab_matFileVersion_forSave );
        clear data;
        % And also open the file so that it can be indexed into at each time
        % step
        matfile_cov = matfile( saveFile_cov , 'Writable',true);
    end    
    
end


% Initialise the variable used to compute the running quantities
if computeMean
    running_mean = double(zeros(n_sample,1));
end
if computeCov
    running_cov = double(zeros(n_sample,n_sample));
end
if computeBoundsBox
    running_boundsBox = double(zeros(n_sample,2));
    running_boundsBox(:,1) = inf;
    running_boundsBox(:,2) = -inf;
end

% Iterate through each step of the "Distrubance Model Cycle Time" (ie.
% "distCycleTimeSteps)
for iCycleTime = 1:distCycleTimeSteps
    % Keep the user updated
    disp( ['     Step ',num2str(iCycleTime,'%04d')] );
    % Only need to sample stuff is something needs to be computed
    if computeSomething
        % Iterate through collecting the number of sample required
        for iSamp = 1:numSamplesToCollect
            % Get a sample
            thisSamp = requestSampleFromTimeForDuration( obj.myDisturbanceModel , iCycleTime , timeHorizon );
            % Update the running statistics
            if computeMean
                running_mean = running_mean + thisSamp;
            end
            if computeCov
                running_cov = running_cov + thisSamp * thisSamp';
            end
            if computeBoundsBox
                running_boundsBox(:,1) = min(running_boundsBox(:,1),thisSamp);
                running_boundsBox(:,2) = max(running_boundsBox(:,2),thisSamp);
            end
        end
        % Finalise computing the statistics (as required)
        if computeMean
            running_mean = running_mean ./ numSamplesToCollect;
        end
        if computeCov
            running_cov = running_cov ./ numSamplesToCollect;
        end
    end
    
    % Get directly those stats that were available directly
    if getDirectlyMean
        thisStat = 'mean';
        [running_mean , successFlag] = requestStatDirectly( obj.myDisturbanceModel , thisStat );
        if ~successFlag
            disp([' ... ERROR: The Disturbance Model specified that ',thisStat,' was directly available']);
            disp(['            BUT, when the ',thisStat,' was requested from the Disturbance Model, it returned an error']);
            error(bbConstants.errorMsg);
        end
    end
    if getDirectlyCov
        thisStat = 'cov';
        [running_cov , successFlag] = requestStatDirectly( obj.myDisturbanceModel , thisStat );
        if ~successFlag
            disp([' ... ERROR: The Disturbance Model specified that ',thisStat,' was directly available']);
            disp(['            BUT, when the ',thisStat,' was requested from the Disturbance Model, it returned an error']);
            error(bbConstants.errorMsg);
        end
    end
    if getDirectlyBoundsBox
        thisStat = 'bounds_boxtype';
        [running_boundsBox , successFlag] = requestStatDirectly( obj.myDisturbanceModel , thisStat );
        if ~successFlag
            disp([' ... ERROR: The Disturbance Model specified that ',thisStat,' was directly available']);
            disp(['            BUT, when the ',thisStat,' was requested from the Disturbance Model, it returned an error']);
            error(bbConstants.errorMsg);
        end
    end
    
    % Put the "mean" into the container
    if computeMean || getDirectlyMean
        %myMean(iCycleTime,1) = iCycleTime;
        myMean(1:n_xi,iCycleTime) = running_mean;
    end
    
    % Put the "bounds_boxtype" into the container
    if computeBoundsBox || getDirectlyBoundsBox
        %myBounds_boxtype_lower(iCycleTime,1) = iCycleTime;
        myBounds_boxtype_lower(1:n_xi,iCycleTime) = running_boundsBox(:,1);
        
        %myBounds_boxtype_upper(iCycleTime,1) = iCycleTime;
        myBounds_boxtype_upper(1:n_xi,iCycleTime) = running_boundsBox(:,2);
    end
    
    % Save the "cov" to file (indexing directly into the matlab to save
    % loading the whole thing and resaving it)
    if computeCov || getDirectlyCov
        matfile_cov.data(:,:,iCycleTime) = running_cov;
    end
    
end


% Save the "mean" to file
if computeMean || getDirectlyMean
    data = myMean;
    save( saveFile_mean , 'data' , bbConstants.matlab_matFileVersion_forSave );
    clear data;
end

% Save the "bounds_boxtype" to file
if computeBoundsBox || getDirectlyBoundsBox
    data = myBounds_boxtype_lower;
    save( saveFile_bounds_boxtype_lower , 'data' , bbConstants.matlab_matFileVersion_forSave );
    clear data;
    data = myBounds_boxtype_upper;
    save( saveFile_bounds_boxtype_upper , 'data' , bbConstants.matlab_matFileVersion_forSave );
    clear data;
end

%% SET THE RETURN VARIABLE OF SUCCESS OR NOT
% If we made it to here then the Sampling, Computations, and Saving were
% all successful
returnSuccess = 1;




end
% END OF FUNCTION


%% --------------------------------------------------------------------- %%
%% A FEW MISCELLANEOUS NOTES:
%
% Another way to get the size of the disturbance vector would be to infer
% it from the length of a single sample taken from the Disturbance Model
% tempStartTime = 0;
% tempSample = getTraceFromTimeForDuration( obj.disturbanceModel , tempStartTime , timeHorizon );
% n_sample = length(tempSample);
% clear tempSample; clear tempStartTime;


