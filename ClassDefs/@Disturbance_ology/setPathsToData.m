function returnSuccess = setPathsToData( obj )
% Defined for the "Disturbance-ology" class, this function ...
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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



returnSuccess = false;


%% KEEP THE USER UPDATES ABOUT WHAT IS HAPPENING
%disp([' ... Now loading the predictions information at time step ',num2str(startTime),' for a prediction horizon of ',num2str(duration) ]);




%% --------------------------------------------------------------------- %%
%% SPECIFY A FEW FILE PATH POINTING TO THE SAVED THE DATA
% Get the Root Path for where to load everything
loadPath_Root = constants_MachineSpecific.saveDataPath;

% Check there exists a folder path for this disturbance
flag_throwError = true;
thisFolders = { 'savedDisturbances' , class(obj.myDisturbanceModel) };
thisErrorMsg = '            some stats need to be computed before any predicitons can be made';
[ loadPath_thisDist , thisSuccess ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_Root , thisFolders, [] , thisErrorMsg , flag_throwError);
returnSuccess = (returnSuccess && thisSuccess);
    

%if ~traceRequired
    % Specify the Load Path for the files containing the stats to be
    % loaded (checking that they exist)
    flag_throwError = false;
    thisErrorMsg = '            this stat needs to be computed before any predicitons can be made';

    % MEAN
    thisFolders = {'mean'};
    thisFiles = 'mean.mat';
    [loadFile_mean , thisSuccess ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , thisFolders, thisFiles , thisErrorMsg , flag_throwError);
    returnSuccess = (returnSuccess && thisSuccess);

    % COVARIANCE
    thisFolders = 'cov';
    thisFiles = 'cov.mat';
    [loadFile_cov , thisSuccess ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , thisFolders, thisFiles , thisErrorMsg , flag_throwError);
    returnSuccess = (returnSuccess && thisSuccess);

    % BOUNDS - BOX TYPE
    thisFolders = 'bounds_boxtype';
    thisFiles = {'bounds_boxtype_lower.mat','bounds_boxtype_upper.mat'};
    [tempPaths , thisSuccess ] = bbConstants.checkExistenceOfFolderAndFiles(loadPath_thisDist , thisFolders, thisFiles , thisErrorMsg , flag_throwError);
    returnSuccess = (returnSuccess && thisSuccess);
    loadFile_bounds_boxtype_lower = tempPaths{1};
    loadFile_bounds_boxtype_upper = tempPaths{2};
%else
    % Load the files when a trace is required
%end

%% SET THE PATHS FOR THIS "OBJ"
obj.path_mean = loadFile_mean;
obj.path_cov = loadFile_cov;
obj.path_bounds_boxtype_lower = loadFile_bounds_boxtype_lower;
obj.path_bounds_boxtype_upper = loadFile_bounds_boxtype_upper;


%% SET THE DATA ALSO
temp                            = load( loadFile_mean );
obj.data_mean                   = temp.data;
clear temp;

temp                            = load( loadFile_cov                    , '-mat' , 'data' );
obj.data_cov                    = temp.data;
clear temp;

temp                            = load( loadFile_bounds_boxtype_lower   , '-mat' , 'data' );
obj.data_bounds_boxtype_lower   = temp.data;
clear temp;

temp                            = load( loadFile_bounds_boxtype_upper   , '-mat' , 'data' );
obj.data_bounds_boxtype_upper   = temp.data;
clear temp;


%% SET SOME OTHER THINGS TO TEST SPEED UP
n_xi = obj.n_xi;
duration = obj.N_max;
n_xi2 = n_xi*n_xi;
num_nonZeroFull = n_xi2 * duration;


i_full = zeros( num_nonZeroFull , 1 );
for iStep = 1 : duration
   i_full( ((iStep-1)*n_xi2+1) : (iStep*n_xi2) , 1 ) = repmat( ( ((iStep-1)*n_xi+1) : (iStep*n_xi) )' , n_xi , 1 );
end

j_full =  zeros( num_nonZeroFull , 1 );
for iStep = 1 : (n_xi*duration)
   j_full( ((iStep-1)*n_xi+1) : (iStep*n_xi) , 1 ) = iStep;
end

obj.i_blkDiag_nxi_by_nxi = i_full;
obj.j_blkDiag_nxi_by_nxi = j_full;


%% SET THE RETURN VARIABLE OF SUCCESS OR NOT
% This was set above as the check were made



end
% END OF FUNCTION
