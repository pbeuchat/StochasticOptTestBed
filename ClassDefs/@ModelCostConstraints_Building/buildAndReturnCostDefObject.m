function returnCostDef = buildAndReturnCostDefObject( obj )
% Defined for the "Building_MoselCostConstraints", to build a "StateDef"
% object for this type of model
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

%% --------------------------------------------------------------------- %%
%% Check that this model object is valid
if ~( obj.isValid )
   disp([ ' ... ERROR: the of of class ',thisClassName,' is not valid (or the validation check has not been performed)']);
   disp('             hence a "ConstraintDef" object cannot be reliably created');
   error(bbConstants.errorMsg);
end

%% --------------------------------------------------------------------- %%
%% NOW WE CAN BLATANTLY PULL INFO STRAIGHT FROM THIS "obj"
costParams = obj.costParams;

checkForFields = { 'type' , 'c' , 'q' , 'r' , 'Q' , 'R' , 'S' };

numFields = length( checkForFields );

temp = cell(numFields,1);

for iField = 1:numFields
    % Get the string for this field
    thisField = checkForFields{iField};
    % If it is actually a field of the struct then:
    if isfield( costParams , thisField )
        %temp{iField,1} = getfield( constraintParams , thisField );
        temp{iField,1} = costParams.(thisField);
    else
        temp{iField,1} = [];
    end
end

subCosts_num    = costParams.subCosts_num;
subCosts_label  = costParams.subCosts_label;


%% --------------------------------------------------------------------- %%
%% FINALLY BUILD THE CONSTRAINT-DEF OBJECT FROM ALL THE VARIABLES ABOVE
% Syntax:
%  function obj = CostDef( inputStateDef , funcType , c , q , r , Q , R , S )

% Now call the constraint definiton object instantiation method:
returnCostDef = CostDef( obj.stateDef , temp{1} , temp{2} , temp{3} , temp{4} , temp{5} , temp{6} , temp{7} , subCosts_num , subCosts_label );


end
% END OF FUNCTION

%% SOME ADDITIONAL INFO
%
%% THE STRUCTURE OF THE "Buiding" CLASS OBJECT
% "obj.building" has the following properties:
%   .identifier
%   .building_model
%   .thermal_model_data
%   .EHF_model_declarations
%
% "obj.building.building_model" has the following properties:
%   .identifiers
%   .thermal_submodel
%   .EHF_submodels
%   .continuous_time_model
%   .discrete_time_model
%   .is_dirty
%   .Ts_hrs
%
% where the ".identifiers" property is the main one of interest because it
% specifies that state, input and disturbance details
% "obj.building.building_model.identifiers" has the following properties:
%   .x
%   .q
%   .u
%   .v
%   .y
%   .constraints
%
% "obj.building.thermal_model_data" has the following properties:
%   .zones
%   .building_elements
%   .constructions
%   .materials
%   .windows
%   .parameters
%   .nomass_constructions
%   .source_files
%   .is_dirty
% where ".zones" is an array of object of class "Zone", each having the
% following properties:
%   .identifier
%   .description
%   .area
%   .volume
%   .group
% where the ".identifier" properties is a string identifying the zone and
% is very important because this exact string is used in labelling the "x",
% "u" and "v" identifiers of the "obj.building.building_model"
%
%