function returnConstraintDef = buildAndReturnConstraintDefObject( obj )
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
constraintParams = obj.constraintParams;

checkForFields = { 'x_box' , 'x_rect_upper' , 'x_rect_lower' , 'x_poly_A' , 'x_poly_b' , 'x_poly_label' , 'u_box' , 'u_rect_upper' , 'u_rect_lower' , 'u_poly_A' , 'u_poly_b' , 'u_poly_label' };

numFields = length( checkForFields );

temp = cell(numFields,1);

for iField = 1:numFields
    % Get the string for this field
    thisField = checkForFields{iField};
    % If it is actually a field of the struct then:
    if isfield( constraintParams , thisField )
        %temp{iField,1} = getfield( constraintParams , thisField );
        temp{iField,1} = constraintParams.(thisField);
    else
        temp{iField,1} = [];
    end
end


%% --------------------------------------------------------------------- %%
%% FINALLY BUILD THE CONSTRAINT-DEF OBJECT FROM ALL THE VARIABLES ABOVE
% Syntax:
%  function obj = ConstraintDef( inputStateDef , x_box , x_rect_upper , x_rect_lower , x_poly_A , x_poly_b , x_poly_label , x_poly_mask , u_box , u_rect_upper , u_rect_lower , u_poly_A , u_poly_b , u_poly_label , u_poly_mask )

% Set the polytope mask to be full
x_poly_mask = true( obj.stateDef.n_x , 1 );
u_poly_mask = true( obj.stateDef.n_u , 1 );

% Now call the constraint definiton object instantiation method:
returnConstraintDef = ConstraintDef( obj.stateDef , temp{1} , temp{2} , temp{3} , temp{4} , temp{5} , temp{6} , x_poly_mask , temp{7} , temp{8} , temp{9} , temp{10} , temp{11} , temp{12} , u_poly_mask );


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