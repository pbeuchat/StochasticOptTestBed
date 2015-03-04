%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     load_BuildingDef.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnB , returnX0 , returnConstraintParams, returnCostParams, returnV, returnTmax , returnDims] = load_BuildingDef( inputBuildingIdentifierString , bbFullPath )

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
%% SPECIFY THE ROOT PATH WHERE THE REQUEST BUILDING DEFINITION IS LOCATED
thisBuildingDefFunctionString = [bbConstants.loadDefFunctionPrefix_forBuilding , inputBuildingIdentifierString , bbConstants.loadDefFolderSuffixTrue ];

thisBuildingDefFunctionHandle = str2func( thisBuildingDefFunctionString );

[returnB , returnX0 , returnConstraintParams, returnCostParams, returnV, returnTmax , returnDims] = thisBuildingDefFunctionHandle( inputBuildingIdentifierString , bbFullPath );


end
%% END OF FUNCTION

