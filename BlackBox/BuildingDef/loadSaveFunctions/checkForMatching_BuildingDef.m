function [returnIsMatch, returnModelMatch] = checkForMatching_BuildingDef( inputBuildingIdentifierString , bbFullPath , flag_deleteMatch )
%  checkForMatching_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function checks the "SavedDef" folder for an
%               extisting file matching the "inputBuildingIdentifierString"
%               
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


    %% --------------------------------------------------------------------- %%
    %% ATTEMPT TO LOAD THE SAVED BUILDING MODEL DIRECTLY


    % Construct the string for the name of the bulding model
    loadFileName = [ bbConstants.saveDefPrefix , inputBuildingIdentifierString , bbConstants.saveDefExtension ];

    % First check if the "index" file exists
    % (Note: the folder where it is located should already be on the path)
    existResult = exist( loadFileName , 'file' );

    % If it exists then load it (or delete it)
    if (existResult == 2)
        if ~flag_deleteMatch
            % Load the file, this should load the saved Building Model into a
            % struct propterty called:
            %     "savedData"
            disp( ' DEBUGGING: my bet is that the next line is where it often crashes' );
            tempLoad = load( loadFileName );
            disp( ' DEBUGGING: If this is displayed then I was wrong :-( #01' );

            returnModelMatch = tempLoad.savedData;
            disp( ' DEBUGGING: If this is displayed then I was wrong :-( #02' );
            returnIsMatch = 1;
            clear tempLoad;
            disp( ' DEBUGGING: If this is displayed then I was wrong :-( #03' );
        else
            deleteFilePath = [bbFullPath , '/' , 'BlackBox/BuildingDef/SavedDef' , '/' , loadFileName ];
            delete( deleteFilePath );
            returnIsMatch = 0;
            returnModelMatch = [];
        end

    else
        % Else return that there is no match
        returnIsMatch = 0;
        returnModelMatch = [];
    end

end  % <-- END OF FUNCTION

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
