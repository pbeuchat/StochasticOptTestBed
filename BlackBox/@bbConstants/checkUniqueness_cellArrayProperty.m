function [returnFlag_isUnique , return_propertyValues , returnFlag_valueNeedsToBeChanged] = checkUniqueness_cellArrayProperty( inputCellArray , inputPropertyName )
% Defined for the "ccConstants" class, this function checks that the
% "inputPropertyName" is unique for every cell of the "inputCellArray" (ie.
% the "inputCellArray" should be a cell array of structs, if it is not this
% function will not fail, but the result may be less meaningful)
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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
%% CHECK THAT THE INPUT ARE OF THE CORRECT TYPE

% If "inputCellArray" is not a cell array, then exit the function
if not( iscell(inputCellArray) )
    disp( ' ... ERROR: the "inputCellArray" was not a cell array, it had class:' );
    disp(['            class(inputCellArray) = ', class(inputCellArray) ]);
    disp( '            Exiting function now' );
    returnFlag_isUnique = true;
    return_propertyValues = [];
    returnFlag_valueNeedsToBeChanged = [];
    return;
end
    
% If the "inputPropertyName" is not a string, then exit the function
if not( ischar(inputPropertyName) )
    disp( ' ... ERROR: the "inputPropertyName" was not a string, it had class:' );
    disp(['            class(inputPropertyName) = ', class(inputPropertyName) ]);
    disp( '            Exiting function now' );
    returnFlag_isUnique = true;
    return_propertyValues = [];
    returnFlag_valueNeedsToBeChanged = [];
    return;
end



%% --------------------------------------------------------------------- %%
%% GET THE SIZE OF THE CELL ARRAY (this function supports 2D cell arrays)

[ n_rows , n_cols ] = size( inputCellArray );



%% --------------------------------------------------------------------- %%
%% INITIALISE THE RETURN VARIABLES

return_propertyValues           = cell (n_rows,n_cols);
return_propertyValues(:,1) = {'-999'};
returnFlag_valueNeedsToBeChanged = false(n_rows,n_cols);

%running_propertyValues = cell(n_rows*n_cols,1);

% Assume that the cell array is unique, and set the return flag otherwise
% when we find a non-unique element
returnFlag_isUnique = true;



%% --------------------------------------------------------------------- %%
%% STEP THROUGH EACH CELL IN THE ARRAY

% Counter for indexing into the "running_propertyValues" array
iRunning = 0;

for iRow = 1:n_rows
    for iCol = 1:n_cols
        % Increment the "running" counter
        iRunning = iRunning + 1;
        % Check that the cell is a struct and that the "inputPropertyName"
        % field exists
        thisFlag_isStruct = isstruct( inputCellArray{iRow,iCol} );
        if thisFlag_isStruct
            thisFlag_hasProperty = isfield( inputCellArray{iRow,iCol} , inputPropertyName );
            % If is exists then check its uniqueness
            if thisFlag_hasProperty
                % Get the property value for this cell of the array
                thisPropertyValue = inputCellArray{iRow,iCol}.(inputPropertyName);
                % Check if it is a member of the running cell array
                thisFlag_isMember = ismember( thisPropertyValue , return_propertyValues );
                % If it is NOT a member, then it is unique at this stage,
                % so simply add it
                if not( thisFlag_isMember )
                    %running_propertyValues{iRunning,1} = thisPropertyValue;
                    return_propertyValues{iRow,iCol} = thisPropertyValue;
                    returnFlag_valueNeedsToBeChanged(iRow,iCol) = false;
                % ELSE: it is a member and hence not unique, therefore
                %       generate a new unique value to use
                else
                    % If the value is a "string" then, append the current
                    % clock to the end
                    if ischar( thisPropertyValue )
                        % Get the current clock string
                        [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();
                        tempCurrentClockString = [currDateStr, '_', currTimeStr];
                        % Append it to the end of the exiting string
                        thisNewPropertyValue = [ thisPropertyValue , '_' , tempCurrentClockString ];
                        % Put the results into the return variables
                        %running_propertyValues{iRunning,1} = thisNewPropertyValue;
                        return_propertyValues{iRow,iCol} = thisNewPropertyValue;
                        returnFlag_valueNeedsToBeChanged(iRow,iCol) = true;
                        % Update the overall "uniqueness flag"
                        returnFlag_isUnique = false;
                    else
                        % Set things to be blank for this iteration
                        return_propertyValues{iRow,iCol} = '';
                        returnFlag_valueNeedsToBeChanged(iRow,iCol) = false;
                    end
                end
            % Else skip to the next cell in the array
            else
                % Set things to be blank for this iteration
                %running_propertyValues{iRunning,1} = '';
                return_propertyValues{iRow,iCol} = '';
                returnFlag_valueNeedsToBeChanged(iRow,iCol) = false;
            end
        % Else skip to the next cell in the array
        else
            % Set things to be blank for this iteration
            %running_propertyValues{iRunning,1} = '';
            return_propertyValues{iRow,iCol} = '';
            returnFlag_valueNeedsToBeChanged(iRow,iCol) = false;
        end
    end 
end




%% PUT TOGETHER THE RETURN VARIABLES
% The script will have terminated by here if the checks were not successful
%returnSuccess = 1;

