function returnData = getStatistic_fromData_withFormat_XiByTime( inputData , startTime , duration )
% Defined for the "Disturbance-ology" class, this function loads the
% ".data" property from a specified file
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



%% SETTING THE DURATION CONVENTION
% Does the "duration" include the "start time" step or not!?
%duration = duration - 1;

%% NOTE: ON SPEED OF "*.mat"  -versus-  FILES  -versus-  "obj.property"
%
% Matfiles are nice because you only "load" the data required, but that is
% a load from disk into ram, so multiple call to this are slow
% 
% obj.property referencing is nice because it is object orientated, but
% looking up the .property multiple times adds a bit of over-head
%
% Passing the obj.property data once seems to be the most efficient because
% it passes the handle to the data avoiding the need to look up the handle
% multiple times

%% DEPRECATED CODE: FOR GETTING A "matfile" OBJECT
% Get a "matfile" object for the data
%matfileWithData = matfile( loadFileFullPath , 'Writable',false );

%% GETTING THE SIZE AND DATUMS OF THE PROBLEM
% Get the size of the matrix stored
[numRows , numCols] = size( inputData );
% Interpret the size
n_xi = numRows;
Tmax = numCols;
% "mod" the start time to be within Tmax
startTime_mod = mod(startTime-1 , Tmax) + 1;
% Compute the end time and its mod
endTime = startTime_mod + duration - 1;
endTime_mod = mod(endTime-1 , Tmax) + 1;
% Check how many time we need to wrap through the disturbance cycle
numWraps = floor( double(endTime-1) / Tmax );


%% PUTTING THE REQUIRED DATA INTO THE RETURN VARIABLE
% If there is no wrapping, then handle it directly
if numWraps == 0
    numTimeStep = endTime - startTime_mod + 1;
    %getRangeRows = 1:n_xi;
    %getRangeCols = startTime_mod:endTime;
    returnData = reshape( inputData(1:n_xi,startTime_mod:endTime) , numTimeStep*n_xi , 1 );
% Else account for the wrapping
else
    % Initilise the return vairable
    returnData = zeros( n_xi * duration , 1 );
    % Fill in the part before the first wrap
    numTimeStep = Tmax - startTime_mod + 1;
    getRangeRows = 1:n_xi;
    getRangeCols = startTime_mod:Tmax;
    returnRange = 1 : (numTimeStep*n_xi);
    returnData(returnRange,1) = reshape( inputData(getRangeRows,getRangeCols) , numTimeStep*n_xi , 1 );
    currReturnRow = (numTimeStep*n_xi);
    % Iterate through the number of Wraps, filling in the return variable
    for iWrap = 1:numWraps-1
        numTimeStep = Tmax;
        getRangeRows = 1:n_xi;
        getRangeCols = 1:Tmax;
        returnRange = (currReturnRow+1) : (currReturnRow+(numTimeStep*n_xi));
        returnData(returnRange,1) = reshape( inputData(getRangeRows,getRangeCols) , numTimeStep*n_xi , 1 );
        currReturnRow = (currReturnRow+(numTimeStep*n_xi));
    end
    % Fill in the part after the last wrap
    numTimeStep = endTime_mod;
    getRangeRows = 1:n_xi;
    getRangeCols = 1:endTime_mod;
    returnRange = (currReturnRow+1) : (currReturnRow+(numTimeStep*n_xi));
    returnData(returnRange,1) = reshape( inputData(getRangeRows,getRangeCols) , numTimeStep*n_xi , 1 );
    currReturnRow = (currReturnRow+(numTimeStep*n_xi));

    % Check that the full "returnData" vector was filled in
    if ~( currReturnRow == (n_xi * duration) )
        disp(' ... ERROR: when extracting the data from file, less data than expected was extracted');
        error(bbConstants.errorMsg);
    end
end


end
% END OF FUNCTION
