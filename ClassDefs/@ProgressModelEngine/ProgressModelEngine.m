classdef ProgressModelEngine < handle
% This class progress the model by one time step
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This class is the heart of the simulator
%               > It has the high-level function to take in the:
%                   - current state
%                   - current input
%                   - current disturbance
%               > The model is porgressed
%               > And the following are returned:
%                   - updated state
%                   - stage cost
%                   - infomation about constraint satisfaction
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


    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(2);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'ProgressModelEngine';
        % Model type for knowing how to handle the model object
        modelTypesRecognised@cell = {'building'};
    end
   
    properties (Access = public)
        % The absolute time increment per step, taken from the "model"
        % Needed as public so that the simulator can track time
        % (instead we really should pass back the absolute time increment
        % with every "performStateUpdate" step. That would allow for varied
        % absolute time steps to be taken
        t_perInc_hrs@double = 0;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % Model for which the simulation will be done
        model@ModelCostConstraints;
        
        % Model type for knowing how to handle the model object
        modelType@string;
        
        % State, Input and Uncertainty, taken in
        x@double;
        u@double;
        xi@double;
        
        % Current time in steps and time
        k@uint64 = uint64(0);
        t@double = 0;
        
        % State, Stage Cost and Constraint Satisfaction returned
        xnew@double;
        l@double;
        constraintSatisfaction@struct;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = ProgressModelEngine(inputModel,inputModelType)
            % Check if number of input arguments is correct
            if nargin ~= obj.n_properties
                %fprintf( ' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties );
                disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
                error(bbConstants.errorMsg);
            end

            % Check if the "input model type" is a string
            if ( ~ischar(inputModelType) || isempty(inputModelType) )
                 disp( ' ... ERROR: The model type input must be a string. The model type that was input is:' );
                 disp inputModelType;
                error(bbConstants.errorMsg);
            end

            % Check if the input type is in the list of recognised type
            if ~( sum( ismember(obj.modelTypesRecognised , inputModelType) ) )
                disp( ' ... ERROR: The model type "',inputModelType,'" input to the "ProgressModelEngine" class is not recognised.' );
                error(bbConstants.errorMsg);
            end

            % Check if the input model is valid
            if ~( inputModel.isValid)
                % If not valid then attempt the validity check again
                returnIsValid = attemptValidityCheck(inputModel);
                if ~returnIsValid
                    disp( ' ... ERROR: The input model of type "',inputModelType,'" was not valid.' );
                    error(bbConstants.errorMsg);
                end
            end
            
            % Make deep copy of the Building object in order to prevent changes of data in object from outside of SimulationExperiment
            obj.model = copy(inputModel);
            obj.modelType = inputModelType;
            
            obj.t_perInc_hrs = inputModel.t_perInc_hrs;

        end
        % END OF: "function [..] = ProgressModelEngine(...)"
      
        % Augment the deconstructor method
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    
    methods (Static = false , Access = public)
        % Define functions implemented in other files:
        % -----------------------------------------------
        
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: to call the state update routine externally
        function [xnew , u, l , l_per_ss , constraintSatisfaction] = performStateUpdate(obj,x,u,xi,currentTime)
            % The model property is a class that implements the state
            % update appropriate to the model type
            [xnew , u, l , l_per_ss , constraintSatisfaction] = requestStateUpdate(obj.model,x,u,xi,currentTime);
            
            % Keep the local object updated with the new state
            obj.x   = xnew;
            obj.u   = u;
            obj.xi  = xi;
            
            % Increment the time counter and time
            obj.k = obj.k + 1;
            obj.t = obj.t + currentTime.abs_increment_hrs;
        end
        % END OF: "function [...] = performStateUpdate(...)"
        
        
        % FUNCTION: to externally check the time is in agreement
        function returnCheck = isTimeConsistent( obj , t )
            returnCheck = (obj.t == t);
        end
        % END OF: "function [...] = isTimeConsisten(...)"
        
        
        % FUNCTION: to check that the model is valid (and attempt to
        % validate it if it is not currently valid)
        function returnIsValid = checkModelIsValid(obj)
            modelIsValid = obj.model.isValid;
            % Check if the model is valid
            if ~modelIsValid
                % If not valid then attempt the validity check again
                modelIsValid = attemptValidityCheck(inputModel);
                if ~modelIsValid
                    disp( ' ... ERROR: The input model of type "',inputModelType,'" was not valid.' );
                    error(bbConstants.errorMsg);
                else
                    returnIsValid = modelIsValid;
                end
            else
                returnIsValid = modelIsValid;
            end
        end
        % END OF: "function [...] = checkInputModelIsValid(...)"
        
        % FUNCTION: to update the masks of the StateDef Object in the model
        function updateStateDefMasks( obj , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss )
            % Put the input objects directly into the variables assuming
            % they have been checked via the "checkMasksAreValid" function
            updateMasks( obj.model.stateDef , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss );
        end
        % END OF: "function [...] = updateStateDefMasks(...)"
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    
    
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    %methods (Static = true , Access = public)
    %end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

