function returnStateDef = buildAndReturnStateDefObject( obj )
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
   disp('             hence a "StateDef" object cannot be reliably created');
   error(bbConstants.errorMsg);
end

%% --------------------------------------------------------------------- %%
%% NOW WE CAN BLATANTLY PULL INFO STRAIGHT FROM THIS "obj"

%% PULL THE LABELS AND SIZES FOR THE STATES, INPUTS and DISTURBANCES
% Get the identiers directly from the building model (these should be a
% cell array of strings, and hence satisfy "iscellstr() == true" )
%tempBuilding = obj.building;
label_x     = obj.building.building_model.identifiers.x;
label_u     = obj.building.building_model.identifiers.u;
label_xi    = obj.building.building_model.identifiers.v;

% Get the size of each from this 
n_x     = uint32( length( label_x  ) );
n_u     = uint32( length( label_u  ) );
n_xi    = uint32( length( label_xi ) );

%% PULL THE INFO ABOUT THE ZONES
% Get the info about the Zones
% Get the array of "Zone" objects
array_zones = obj.building.thermal_model_data.zones;
% Get the number of zones
n_zones     = uint32( length( array_zones ) );
% Get the labels of the zones as a cell array of strings
label_zones = cell(n_zones,1);
for iZone = 1:n_zones
    label_zones{iZone,1} = array_zones(iZone).identifier;
end


%% CONSTRUCT THE INFO ABOUT THE SUB-SYSTEMS, AND HENCE ALSO THE "MASKS"

% For the Builing Models, each zone is considered a sub-system:
n_ss = n_zones;

% Initialise blank arrays for the masks:
mask_x_ss   = false( n_x  , n_ss );
mask_u_ss   = false( n_u  , n_ss );
mask_xi_ss  = false( n_xi , n_ss );

% The label for each state shuold be something like the following:
%       'x_Z0001'
% or    'x_B0001_L1_s1_AMBZ0001'
% or    'x_B0011_L1_s1_Z0001Z0004'
%
% So the simple way to associate the state with a sub-system is to check if
% the label for a particular state contains the label for that sub-system
% (ie. zone)

% Iterate through the zones:
for iZone = 1 : n_zones
    thisZone = label_zones{iZone};
    mask_x_ss(:,iZone)  = ~cellfun( 'isempty' , strfind( label_x  , thisZone ) );
    mask_u_ss(:,iZone)  = ~cellfun( 'isempty' , strfind( label_u  , thisZone ) );
    mask_xi_ss(:,iZone) = ~cellfun( 'isempty' , strfind( label_xi , thisZone ) );
end

% Some extra processing for the disturbances to check for those
% disturbances that affect (and hence should be available) to all zones
indicies_AllZones =  ~cellfun( 'isempty' , strfind( label_xi , 'ZALL'   ) ) ;
indicies_AmbTemp  =  ~cellfun( 'isempty' , strfind( label_xi , 'v_Tamb' ) ) ;

mask_xi_ss(indicies_AllZones,:) = true;
mask_xi_ss(indicies_AmbTemp ,:) = true;


% Sparsify all the masks because they are likely to be mostly "falses"
mask_x_ss  = sparse( mask_x_ss  );
mask_u_ss  = sparse( mask_u_ss  );
mask_xi_ss = sparse( mask_xi_ss );


%% SPECIFY THE INITIAL CONDITION
% 
x0 = obj.x0;


%% --------------------------------------------------------------------- %%
%% FINALLY BUILD THE STATE-DEF OBJECT FROM ALL THE VARIABLES ABOVE
returnStateDef = StateDef( n_x , n_u , n_xi , label_x , label_u , label_xi , n_ss , mask_x_ss , mask_u_ss , mask_xi_ss , x0);


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