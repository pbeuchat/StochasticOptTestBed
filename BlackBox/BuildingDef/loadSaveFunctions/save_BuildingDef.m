%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     save_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnSuccess] = save_BuildingDef( inputBuildingIdentifierString , inputB , inputConstraintParams , inputCostParams , inputV , inputX0 , inputTmax , inputDims , bbFullPath )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        03-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%
%  DESCRIPTION: > This functions combines the input varaible into one
%               struct and saves that into the "SavedDef" folder
%               

%% --------------------------------------------------------------------- %%
%% PUT TOGETHER THE STRUCT TO BE SAVE TO FILE
clear savedData;
savedData = struct();
savedData.B                     = inputB;
savedData.constraintParams      = inputConstraintParams;
savedData.costParams            = inputCostParams;
savedData.V                     = inputV;
savedData.Tmax                  = inputTmax;
savedData.X0                    = inputX0;
savedData.n_dims                = inputDims;

%% --------------------------------------------------------------------- %%
%% SAVE THE CONSTRUCT VARIABLE ("savedData") TO FILE

% Construct the string for the name of the bulding model save fjle
saveFileName = [ bbConstants.saveDefPrefix , inputBuildingIdentifierString , bbConstants.saveDefExtension ];

% COnstruct the path for the save folder
savePath = [bbFullPath , '/' , 'BlackBox/BuildingDef/SavedDef'];

% First check if a file with the same name exists
% (Note: the folder where it is located should already be on the path)
existResult = exist( saveFileName , 'file' );

% If it exists then delete the exsting file of the same name
if (existResult == 2)
    % Keep the user updated
    disp(' ... NOTE: this same building model has been saved previously, the previous save is been deleted');
    % Delete the old file
    delete(saveFileName);
    % Save
end

% Save the data to file
save([savePath,'/',saveFileName],'savedData','-v7.3');

% Keep the memory clear
clear savedData;


%% SET THE RETURN VARIABLES
% If we made it to here then things were successful
returnSuccess = 1;


%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
%  HOW TO USE:  1) ...
%
% INPUTS:
%       > xxx
%
% OUTPUTS:
%       > yyy
