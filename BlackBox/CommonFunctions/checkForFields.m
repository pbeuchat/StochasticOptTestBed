function [returnSuccess] = checkForFields( inputStruct , inputFieldsCell )
%  checkForFields.m
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Common Function
%
%  DESCRIPTION: > Function to call the appropritate solver for performaing
%                   an approximate dynamic programming analysis 
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
%% EXTRACT THE INFORMATION FROM THE INPUT
% First check that the inputs are a "struct" and "cell array" respectively
check1 = isstruct( inputStruct )   ||  iscell  ( inputStruct ) ;
check2 = iscell  ( inputFieldsCell );
if not(check1)
    disp(' ... ERROR: in "checkForFields" function, the first input was NOT of type "struct" or of type "cell"');
end
if not(check2)
    disp(' ... ERROR: in "checkForFields" function, the second input was NOT of type "cell"');
end
if ( not(check1) || not(check2) )
    error('Terminating now :-( See previous messages and ammend');
end

%% --------------------------------------------------------------------- %%
%% PERFORM THE CHECK OF THE FIELDS
% First: get the number of fields to be checked for
numFields = length(inputFieldsCell);

if isstruct( inputStruct )
    % Second: check for all fields at once
    checkAll = isfield( inputStruct , inputFieldsCell );

    % Third: iterate through the check and let the user know which ones failed
    for iField = 1:numFields
        thisField = inputFieldsCell{iField};
        thisCheck = checkAll(iField);
        if not(thisCheck)
            disp(' ... ERROR: The stuct (cell array) passed in does not contain the field (string):');
            disp(['            "',thisField,'"']);
        end
    end

    if not( sum(checkAll) == numFields )
        error('Terminating now :-( See previous messages and ammend');
    end
elseif iscell( inputStruct )
    errorFound = 0;
    for iField = 1:numFields
        thisField = inputFieldsCell{iField};
        thisCheck = ismember(inputStruct,thisField);
        if not(thisCheck)
            disp(' ... ERROR: The stuct (cell array) passed in does not contain the field (string):');
            disp(['            "',thisField,'"']);
            errorFound = 1;
        end
    end
    
    if errorFound
        error('Terminating now :-( See previous messages and ammend');
    end
else
    
end
    
%% PUT TOGETHER THE RETURN VARIABLES
% The script will have terminated by here if the checks were not successful
returnSuccess = 1;

