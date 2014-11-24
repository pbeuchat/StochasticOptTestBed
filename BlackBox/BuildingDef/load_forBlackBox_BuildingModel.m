%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     load_forBlackBox_BuildingModel.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnB , returnConstraintParams , returnCostParams , returnV , returnX0 , returnTmax , returnDims] = load_forBlackBox_BuildingModel( inputBuildingIdentifierString , bbFullPath )

%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function runs the following sequence:
%                   - Check for an already saved model of the requested
%                     building
%                   - If not an already saved model then:
%                       - Generate a model from the Definition
%                       - Save the generated model
%                   - Else:
%                       - Load the saved model`
%

%% --------------------------------------------------------------------- %%
%% CHECK FOR AN ALREADY SAVED MODEL OF THE REQUESTED BUILDING

[isMatch, modelMatch] = checkForMatching_BuildingDef( inputBuildingIdentifierString );



%% --------------------------------------------------------------------- %%
%% IF NOT A MATCH, THEN GENERATE AND SAVE THE REQUESTED BUILDING MODEL

if not( isMatch )
    % Keep the user updated
    disp('******************************************************************');
    disp(' Black-Box: Building Model not previously generated');
    % Generate a Building Model with the BRCM Toolbox
    [returnB , returnConstraintParams , returnCostParams , returnV , returnX0 , returnTmax , returnDims] = load_BuildingDef( inputBuildingIdentifierString , bbFullPath );
    
    % Save the Building Model
    saveSuccess = save_BuildingDef( inputBuildingIdentifierString , returnB , returnConstraintParams , returnCostParams , returnV , returnX0 , returnTmax , returnDims , bbFullPath );
    
    if not(saveSuccess)
        disp(' ... ERROR: The building model generated could not be saved for some reason');
        error('Terminating now :-( See previous messages and ammend');
    end
    
else
    disp('******************************************************************');
    disp(' Black-Box: successfully loaded a previously generated Building Model');
    % Extract the return variables from the "modelMatch" struct that was
    % loaded
    returnB                     = modelMatch.B;
    returnConstraintParams      = modelMatch.constraintParams;
    returnCostParams            = modelMatch.costParams;
    returnV                     = modelMatch.V;
    returnX0                    = modelMatch.X0;
    returnTmax                  = modelMatch.Tmax;
    returnDims                  = modelMatch.n_dims;
end


%% --------------------------------------------------------------------- %%
%% A MODEL IS LOADED BY NOW, CHECK A FEW THINGS AND RETURN IT
% Check the ...



end
%% END OF FUNCTION

