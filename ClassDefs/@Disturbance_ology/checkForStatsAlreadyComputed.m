function [returnFlagPerStat , returnFlagOverall] = checkForStatsAlreadyComputed( obj , statsRequired , isTimeCorrelated )
% Defined for the "Disturbance-ology" class, this function returns a
% true/false value for whether each of the stats is already computed
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               
% ----------------------------------------------------------------------- %


%% KEEP THE USER UPDATES ABOUT WHAT IS HAPPENING
%disp([' ... Now loading the predictions information at time step ',num2str(startTime),' for a prediction horizon of ',num2str(duration) ]);


%% --------------------------------------------------------------------- %%
%% CHECK THAT THE INPUTS FOLLOW THE REQUIRED CONVENTION

% First check that "statsRequired" is a cell array and not empty
if isempty(statsRequired)
    disp(' ... NOTE: The "statsRequied" object is empty and hence this function has nothing to check for');
    disp('           Returning an empty success flag');
    returnFlagPerStat = [];
    returnFlagOverall = true;
    return;
end
if ~iscell(statsRequired)
    disp(' ... ERROR: The "statsRequied" object is not a cell array');
    error(bbConstants.errorMsg);
end



%% --------------------------------------------------------------------- %%
%% INITIALISE THE RETURN VARIABLE
% Get the number of stats required
numStatsRequired = length(statsRequired);
% Initialise all the flags as "false"
flag_computable = false(numStatsRequired,1);
flag_computed   = false(numStatsRequired,1);

%% --------------------------------------------------------------------- %%
%% CHECK IF THE "statsRequired" COULD HAVE BEEN COMPUTED FOR THE DISTURBANCE MODEL

% Check if any of the required stats were not computable
for iStat = 1:numStatsRequired
    thisStat = statsRequired{iStat};
    if ismember(thisStat,obj.statsComputationsAvailable)
        flag_computable(iStat,1) = true;
    else
        disp([' ERROR: the statistic "',thisStat,'" is required ...']);
        disp('        but sadly this "disturbance-ology" department does not have the implemented expertise to compute it ...');
        disp('        therefore, even if the statistic is available, we don''t know how to find it, please upgrade us!!');
        %error(bbConstants.errorMsg);
    end
end



%% --------------------------------------------------------------------- %%
%% For the "computable" stats, CHECK IF THEY ARE ALREADY COMPUTED
% This will be checked by simply checking if the file exists
% Get the Root Path for where to load everything
loadPath_Root = constants_MachineSpecific.saveDataPath;
% Check there exists a folder path for this disturbance
thisFolders = { 'savedDisturbances' , class(obj.myDisturbanceModel) };
thisErrorMsg = '';
flag_throwError = false;
[loadPath_thisDist , flag_success] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_Root , thisFolders, [] , thisErrorMsg , flag_throwError );

% If this check was not successful, then none of the statistics are already
% computed ... therefore nothing more to do

% If successful then check one-by-by if the computatble stats have already
% been computed
if flag_success
    % Remembering that the file structure is different depending on if
    % "isTimeCorrelated" or not
    if ~isTimeCorrelated
        thisErrorMsg = '';
        flag_throwError = false;
        for iStat = 1:numStatsRequired
            thisStat = statsRequired{iStat};
            if flag_computable(iStat,1)
                % Again shamelessly hardcoded because each stat has a different
                % path and file name
                % @TODO: I probably should define a property that specifies the
                % folder and filename convention for each computable
                % statistic...

                if strcmp( thisStat , 'mean' )
                    [~ , flag_success] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , 'mean', 'mean.mat' , thisErrorMsg , flag_throwError);
                    flag_computed(iStat,1) = flag_success;
                elseif strcmp( thisStat , 'cov' )
                    [~ , flag_success] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , 'cov', 'cov.mat' , thisErrorMsg , flag_throwError);
                    flag_computed(iStat,1) = flag_success;
                elseif strcmp( thisStat , 'bounds_boxtype' )
                    [~ , flag_success] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , 'bounds_boxtype', {'bounds_boxtype_lower.mat','bounds_boxtype_upper.mat'} , thisErrorMsg , flag_throwError);
                    flag_computed(iStat,1) = flag_success;
                end
            end
        end
    else
        % CODE HERE FOR IF NOT TIME CORRELATED
    end
end
            



%% SET THE RETURN VARIABLE BASED ON THE "COMPUTABLE" AND "COMPUTED" FLAGS
returnFlagPerStat = and(flag_computable , flag_computed);
returnFlagOverall = ( sum(returnFlagPerStat) == numStatsRequired );



end
% END OF FUNCTION
