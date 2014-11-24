%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     checkForMatching_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnIsMatch, returnModelMatch] = checkForMatching_BuildingDef( inputBuildingIdentifierString )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function checks the "SavedDef" folder for an
%               extisting file matching the "inputBuildingIdentifierString"
%               


%% --------------------------------------------------------------------- %%
%% ATTEMPT TO LOAD THE SAVED BUILDING MODEL DIRECTLY


% Construct the string for the name of the bulding model
loadFileName = [ bbConstants.saveDefPrefix , inputBuildingIdentifierString , bbConstants.saveDefExtension ];

% First check if the "index" file exists
% (Note: the folder where it is located should already be on the path)
existResult = exist( loadFileName , 'file' );

% If it exists then load it
if (existResult == 2)
    % Load the file, this should store the saved Building Model into a
    % struct propterty called:
    %     "savedData"
    tempLoad = load( loadFileName );
    returnModelMatch = tempLoad.savedData;
    returnIsMatch = 1;
    clear tempLoad;
        
else
    % Else return that there is no match
    returnIsMatch = 0;
    returnModelMatch = [];
end



%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
% The possible return codes of the Matlab "exist" function:
%       0 if A does not exist
%       1 if A is a variable in the workspace
%       2 if A is an M-file on MATLAB's search path.  It also returns 2 
%            when A is the full pathname to a file or when A is the name of
%            an ordinary file on MATLAB's search path
%       3 if A is a MEX-file on MATLAB's search path
%       4 if A is a Simulink model or library file on MATLAB's search path
%       5 if A is a built-in MATLAB function
%       6 if A is a P-file on MATLAB's search path
%       7 if A is a directory
%       8 if A is a class (exist returns 0 for Java classes if you
%            start MATLAB with the -nojvm option.)
%
