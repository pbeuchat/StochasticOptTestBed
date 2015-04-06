function [flag_successfullyInitialised , flag_requestDisturbanceData] = initialise_localControl( obj , inputModelType , inputModel , vararginLocal)
% Defined for the "Control_LocalControl" class, this function will be
% called once before the simulation is started
% This function should be used to perform off-line possible
% computations so that the controller computation speed during
% simulation run-time is faster
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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



    % You can except the "inputModel" parameter to be empty when the
    % control is specified to be "Model-Free" and non-empty otherwise
    
    % In general this "flag_requestDisturbanceData" flag should be left as
    % "false" and only set to true if access to the disturbance data is
    % required for computational speed up purposes
    flag_requestDisturbanceData = false;
    
    % When using the "Null" controller as a template, insert your code here
    % to pre-compute off-line parts of your controllers so the the "on-line
    % computation time is minimised when the "copmuteControlAction"
    % function is called at each time step
    
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % Store the model type in the appropriate property
    obj.modelType = inputModelType;
    
    % Stor the model
    obj.model = inputModel;
    
    %obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
    %obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
    %obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
    
    %obj.iterationCounter = obj.computeVEveryNumSteps;
    
    % Initialise a flag for whether to use the discrete model from the
    % "inputModel" or not
    flag_useInputModelDiscreteTimeModel = true;
    
    % Check is a discretisation method" property is defined for the
    % "VARiable ARGuments INput"
    if isfield(vararginLocal,'discretisationMethod')
        % If the option was set to "euler" then update the model to be used
        if strcmp(vararginLocal.discretisationMethod , 'euler')
            % Get the discretisation time step from the "inputModel"
            secondsPerHours = 60 * 60;
            Ts_seconds = inputModel.building.building_model.Ts_hrs * secondsPerHours;
            
            temp_n_x = size( inputModel.building.building_model.continuous_time_model.A , 1 );
            
            obj.A    =  speye(temp_n_x) + sparse( inputModel.building.building_model.continuous_time_model.A   .* Ts_seconds );
            obj.Bu   =                    sparse( inputModel.building.building_model.continuous_time_model.Bu  .* Ts_seconds );
            obj.Bxi  =                    sparse( inputModel.building.building_model.continuous_time_model.Bv  .* Ts_seconds );
            
            % Set the flag to prevent this been over-written
            flag_useInputModelDiscreteTimeModel = false;
        end
    end
    
    
    % Use the discrete time model from the "inputModel" variable if
    % required
    if flag_useInputModelDiscreteTimeModel
        obj.A    =  sparse(  inputModel.building.building_model.discrete_time_model.A   );
        obj.Bu   =  sparse(  inputModel.building.building_model.discrete_time_model.Bu  );
        obj.Bxi  =  sparse(  inputModel.building.building_model.discrete_time_model.Bv  );
    end
    
            
end
% END OF FUNCTION