%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     get_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnB] = get_BuildingDef( inputBuildingIdentifierString , flags_EHFModelsToInclude , bbFullPath )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This is based heavily on the "BCRM_DEMOFILE" distributed
%               with the BRCM Toolbox v1.01 - Building Resistance-
%               Capacitance Modeling for Model Predictive Control.
%               Copyright (C) 2013  Automatic Control Laboratory, ETH Zurich.
%               For more infomation check: www.brcm.ethz.ch.
%



%% --------------------------------------------------------------------- %%
%% CHECK FOR AN ALREADY SAVED MODEL OF THE REQUESTED BUILDING

[isMatch, modelMatch] = checkForMatching_BuildingDef( inputBuildingIdentifierString , bbFullPath , flags_EHFModelsToInclude.reconstructModel );


%% --------------------------------------------------------------------- %%
%% IF NOT A MATCH, THEN GENERATE AND SAVE THE REQUESTED BUILDING MODEL

if not( isMatch )
    % Keep the user updated
    disp('******************************************************************');
    disp(' Black-Box: Building Model not previously generated');
    % Generate a Building Model with the BRCM Toolbox
    returnB = construct_Building_BRCM_Model( inputBuildingIdentifierString , flags_EHFModelsToInclude , bbFullPath );
    
    % Save the Building Model
    saveSuccess = save_Building_BRCM_Model( inputBuildingIdentifierString , returnB , bbFullPath );
    
    % Throw an error if the save was not successful
    if not(saveSuccess)
        disp(' ... ERROR: The building model generated could not be saved for some reason');
        error('Terminating now :-( See previous messages and ammend');
    end
    
else
    disp('******************************************************************');
    disp(' Black-Box: successfully loaded a previously generated Building Model');
    % Extract the return variables from the "modelMatch" struct that was
    % loaded
    returnB     = modelMatch.B;
    
end



end
%% END OF FUNCTION

