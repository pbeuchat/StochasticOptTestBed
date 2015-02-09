close all;
%clear all;

%% SPECIFY THE RESULTS FOLDER TO PLOT
plotThisFolder = '2015-01-30_12h02m30s_PlusAndMinus';


%% ADD THE PATH
addpath(genpath( 'BlackBox' ));
addpath(genpath( 'Controllers' ));
addpath(genpath( 'Outputs' ));
addpath(genpath( 'Plotting' ));
addpath( 'ClassDefs' );
constants_MachineSpecific.addUserSpecifiedPaths();

%% LOAD THE "controllerSpecArray" FILE

% Get the Root Path for where to save everything
savePath_Root = constants_MachineSpecific.saveDataPath;

% Save Path for the time of this run
savePath_thisResults = [ savePath_Root , 'savedResults' , filesep , plotThisFolder , filesep ];

% Load the file
tempLoad = load( [savePath_thisResults , 'controllerSpecArray.mat' ] );
controllerSpecArray = tempLoad.controllerSpecArray;

%% PARSE THROUGH THE "controllerSpecArray" - GETTING THE NAMES OF SUB-FOLDERS

% Get the number of control techniques
numControllers = length(controllerSpecArray);

% Initialise a cell array for the folder names
subFolderNames = cell( numControllers , 1 );

% Iterate through the controller
for iController = 1:numControllers
    % Fill in the folder name for this controller
    subFolderNames{iController,1} = controllerSpecArray{iController,1}.saveFolderName;
end


%% BUILT UP THE "allResults" AND "savedDataFileNames"

% Initialise the variables
allResults = cell( numControllers , 1 );
allDataFileNames = cell( numControllers , 1 );

% Iterate through the controller
for iController = 1:numControllers
    % Get this folder name
    thisSubFolder = subFolderNames{iController,1};
    % Load the "savedDataFileNames" first
    tempPath = [ savePath_thisResults , thisSubFolder , filesep , 'savedDataFileNames.mat' ];
    tempLoad = load( tempPath );
    thisSavedDataFileNames = tempLoad.savedDataFileNames;
    
    % Get the number of files
    thisNumFiles = length( thisSavedDataFileNames );
    
    % Clear the variable for building the struct of results for this
    % controller
    clear thisResult;
    
    % Iterate through the files
    for iFile = 1:thisNumFiles
        % Get the name of the file
        thisFileName = thisSavedDataFileNames{iFile};
        % Load the file
        tempPath = [ savePath_thisResults , thisSubFolder , '/' , thisFileName , '.mat' ];
        tempLoad = load( tempPath );
        thisFile = tempLoad.(thisFileName);
        % Put the file into the results sturct for this controller
        thisResult.(thisFileName) = thisFile;
    end
    
    % Put the results and "savedDataFileNames" into the overall cell array
    allResults{iController,1} = thisResult;
    allDataFileNames{iController,1} = thisSavedDataFileNames;
    
end


% BUILD A STRUCT WITH THE SELECTED OPTIONS FOR THE PLOTTING
clear plotOptions;
plotOptions.unitsForTimeAxis                        = 'hours';
plotOptions.flag_plotResultsPerController           = false;
plotOptions.flag_plotResultsControllerComparison    = true;


% CALL THE GENERAL PLOTTING FUNCTION
% (the idea is that this function can be equally called separately to
% plot saved date)


% PLOT THE PER-CONTROLLER RESULTS
if plotOptions.flag_plotResultsPerController
    % Iterated through the controller specs
    for iController = 1:numControllers
        % Visualise the results for each controller
        Visualisation.visualise_singleController( controllerSpecArray{iController,1} , allResults{iController,1} , allDataFileNames{iController,1} , plotOptions );
    end
end
% END OF: "if flag_plotResultsPerController"

% PLOT THE A COMPARISON OF THE CONTROLLER RESULTS
if plotOptions.flag_plotResultsControllerComparison
    % Don't bother calling the plotting function if only 1 control
    % technique was simulated...
    if numControllers > 1
        % The cell array of "allDataFileNames" should be consolidated
        % to only include file names that exists for multiple
        % controllers
        % For now we will cheat and assume they all have 'x', 'u' and
        % 'cost'

        % Visualise the comparative results for ALL controller
        Visualisation.visualise_multipleControllers( controllerSpecArray(:,1) , allResults(:,1) , allDataFileNames{iController,1} , plotOptions );
    end

end


