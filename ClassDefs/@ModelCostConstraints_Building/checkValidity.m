function returnIsValid = checkValidity(obj)
% Defined for the "Building_MoselCostConstraints", this function the
% validity given that the "obj" is already know to be of type "building"
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > Check the validity of an obj of this class
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



    % Check that the following private properties are not empty:
    % .building
    % .costParams
    % .constraintParams
    if ( isempty(obj.building) || isempty(obj.costDef) || isempty(obj.constraintParams) )
       disp( ' ... ERROR: The private properties of the instantiated object of class "Building_ModelCostConstraints" are not all filled in' );
       error(bbConstants.errorMsg);
    end

    % Check if input is a Building object
    if ~isa(obj.building,Constants.building_classname_str)
        disp( ' ... ERROR: The input model of type "building" requires a property of class type "building"' );
        error(bbConstants.errorMsg);
    end

     % Check if the continuous-time thermal model exists
    if isempty(obj.building.building_model.thermal_submodel)
        disp( ' ... ERROR: The input model of type "building" r must contain at least a thermal model.' );
        error(bbConstants.errorMsg);
    end

    % Check if sampling time was set in the building model
    if isempty(obj.building.building_model.Ts_hrs)
        disp( ' ... ERROR: The input model of type "building" must have a set sampling time.' );
        error(bbConstants.errorMsg);
    end

    % check if at the continuous-time building model exists
    if isempty(obj.building.building_model.continuous_time_model) && isempty(obj.building.building_model.discrete_time_model)
        disp( ' ... ERROR: The input model of type "building" does not contain a building model. Only simulation of the thermal model will be possible' );
    elseif obj.building.building_model.is_dirty % If it exists, check if BuildingModel object is not dirty
        disp( ' ... ERROR: The input model of type "building" must not be ''dirty''. Please re-generate the building model and try again.\n' );
        error(bbConstants.errorMsg);
    end
    
    % If the function made it here then the model is valid
    returnIsValid = true;



end
% END OF FUNCTION