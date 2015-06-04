function returnPred = getPredictions( obj , statsRequired , isTimeCorrelated , startTime , duration , trace , flag_checkValid)
% Defined for the "Disturbance-ology" class, this function returns the
% predicitons required at each time step
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               > The "trace" input is optional
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




%% KEEP THE USER UPDATES ABOUT WHAT IS HAPPENING
%disp([' ... Now loading the predictions information at time step ',num2str(startTime),' for a prediction horizon of ',num2str(duration) ]);


%% --------------------------------------------------------------------- %%
%% CHECK IF THE "statsRequired" COULD HAVE BEEN COMPUTED FOR THE DISTURBANCE MODEL

% First check that "statsRequired" is a cell array and not empty
if ~flag_checkValid
    if isempty(statsRequired)
        disp(' ... NOTE: The "statsRequied" object is empty and hence this function has nothing to predict');
        disp('           Returning a blank predicition');
        returnPred = [];
        return;
    end
    if ~iscell(statsRequired) || ~islogical(statsRequired)
        disp(' ... ERROR: The "statsRequied" object is not a cell array');
        error(bbConstants.errorMsg);
    end
end

% Now check that it is possible to compute each one
% Iterate through each of the implemented stat computations, checking if is
% required and setting a flag
% NOTE: that the masking convention is defined in the constants file
if islogical(statsRequired)
    getMean         = statsRequired(1,1);
    getCov          = statsRequired(2,1);
    getBoundsBox    = statsRequired(3,1);
else
    if ismember('mean',statsRequired)
        getMean = 1;
    else
        getMean = 0;
    end
    if ismember('cov',statsRequired)
        getCov = 1;
    else
        getCov = 0;
    end
    if ismember('bounds_boxtype',statsRequired)
        getBoundsBox = 1;
    else
        getBoundsBox = 0;
    end
end


% Availability of the stats does not need to be checked if this flag says
% it is ok
if ~flag_checkValid
    % Check if any of the required stats were not computable
    numStatsRequired = length(statsRequired);
    for iStat = 1:numStatsRequired
        thisStat = statsRequired{iStat};
        if ~ismember(thisStat,obj.statsComputationsAvailable)
            disp([' ERROR: the statistic "',thisStat,'" is required but a method for computing it is not implemented']);
            disp('        and hence a prediction cannot be given');
            error(bbConstants.errorMsg);
        end
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
%% SPECIFY A FEW FILE PATH FOR SAVE THE DATA THAT WILL BE LOADED
% Get the Root Path for where to load everything
loadPath_Root = constants_MachineSpecific.saveDataPath;

% Specify paths directly if this flag says it is ok
if ~flag_checkValid
    % Check there exists a folder path for this disturbance
    flag_throwError = true;
    thisFolders = { 'savedDisturbances' , class(obj.myDisturbanceModel) };
    thisErrorMsg = '            some stats need to be computed before any predicitons can be made';
    [ loadPath_thisDist , ~ ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_Root , thisFolders, [] , thisErrorMsg , flag_throwError);
end
    

if ~traceRequired
    % Specify paths directly if this flag says it is ok
    if ~flag_checkValid
        % Specify the Load Path for the files containing the stats to be
        % loaded (checking that they exist)
        flag_throwError = true;
        thisErrorMsg = '            this stat needs to be computed before any predicitons can be made';

        % MEAN
        if getMean
            thisFolders = {'mean'};
            thisFiles = 'mean.mat';
            [loadFile_mean , ~ ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , thisFolders, thisFiles , thisErrorMsg , flag_throwError);
            obj.path_mean = loadFile_mean;
            temp = load( loadFile_mean );
            obj.data_mean = temp.data;
            clear temp;
        end

        % COVARIANCE
        if getCov
            thisFolders = 'cov';
            thisFiles = 'cov.mat';
            [loadFile_cov , ~ ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , thisFolders, thisFiles , thisErrorMsg , flag_throwError);
        end

        % BOUNDS - BOX TYPE
        if getBoundsBox
            thisFolders = 'bounds_boxtype';
            thisFiles = {'bounds_boxtype_lower.mat','bounds_boxtype_upper.mat'};
            [tempPaths , ~] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , thisFolders, thisFiles , thisErrorMsg , flag_throwError);
            loadFile_bounds_boxtype_lower = tempPaths{1};
            loadFile_bounds_boxtype_upper = tempPaths{2};
        end
    end    
else
    % Load the files when a trace is required
end


%% --------------------------------------------------------------------- %%
%% LOAD THE STATS FOR A "duration" STARTING FROM THE "startTime" SPECIFIED


%% LOAD THE "MEAN"
if getMean
    returnPred.mean = obj.getStatistic_fromData_withFormat_XiByTime( obj.data_mean , startTime , duration );
end


%% LOAD THE "COV"
if getCov
    returnPred.cov = obj.getStatistic_fromData_withFormat_XiByXiByTime( obj.data_cov , startTime , duration , obj.i_blkDiag_nxi_by_nxi , obj.j_blkDiag_nxi_by_nxi );
end


%% LOAD THE "BOUNDS BOX-TYPE"
if getBoundsBox
    returnPred.bounds_boxtype_lower = obj.getStatistic_fromData_withFormat_XiByTime( obj.data_bounds_boxtype_lower , startTime , duration );
    returnPred.bounds_boxtype_upper = obj.getStatistic_fromData_withFormat_XiByTime( obj.data_bounds_boxtype_upper , startTime , duration );
end



%% SET THE RETURN VARIABLE OF SUCCESS OR NOT
% if getMean
%     returnPred.mean = returnMean;
% end
% 
% if getCov
%     returnPred.cov = returnCov;
% end
% 
% if getBoundsBox
%     returnPred.bounds_boxtype_lower = reutrnBounds_boxtype_lower;
%     returnPred.bounds_boxtype_upper = reutrnBounds_boxtype_upper;
% end




end
% END OF FUNCTION
