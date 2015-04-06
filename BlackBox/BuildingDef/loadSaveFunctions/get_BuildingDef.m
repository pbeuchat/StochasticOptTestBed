function [returnB] = get_BuildingDef( inputBuildingIdentifierString , flags_EHFModelsToInclude , bbFullPath )
%  get_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This is based heavily on the "BCRM_DEMOFILE" distributed
%               with the BRCM Toolbox v1.01 - Building Resistance-
%               Capacitance Modeling for Model Predictive Control.
%               Copyright (C) 2013  Automatic Control Laboratory, ETH Zurich.
%               For more infomation check: www.brcm.ethz.ch.
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
%% CHECK FOR AN ALREADY SAVED MODEL OF THE REQUESTED BUILDING

[isMatch, modelMatch] = checkForMatching_BuildingDef( inputBuildingIdentifierString , bbFullPath , flags_EHFModelsToInclude.reconstructModel );
disp( ' DEBUGGING: If this is displayed then I was wrong :-( #04' );


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
    disp( ' DEBUGGING: If this is displayed then I was wrong :-( #05' );
    
end



end
%% END OF FUNCTION

