%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     checkForFields.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnSuccess] = checkForFields( inputStruct , inputFieldsCell , throwError )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Common Function
%
%  DESCRIPTION: > Function to call the appropritate solver for performaing
%                   an approximate dynamic programming analysis 
%               

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
    if throwError
        error('Terminating now :-( See previous messages and ammend');
    end
end

%% --------------------------------------------------------------------- %%
%% PERFORM THE CHECK OF THE FIELDS
% First: get the number of fields to be checked for
numFields = length(inputFieldsCell);

% CHECK FOR "struct" INPUTS
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
        returnSuccess = false;
        if throwError
            error('Terminating now :-( See previous messages and ammend');
        end
    else
        returnSuccess = true;
    end
    
% CHECK FOR "cell" INPUTS
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
        returnSuccess = false;
        if throwError
            error('Terminating now :-( See previous messages and ammend');
        end
    else
        returnSuccess = true;
    end
else
    returnSuccess = false;
end
    
%% PUT TOGETHER THE RETURN VARIABLES
% The script will have terminated by here if the checks were not successful
%returnSuccess = 1;

