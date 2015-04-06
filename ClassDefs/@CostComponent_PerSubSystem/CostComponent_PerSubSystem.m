classdef CostComponent_PerSubSystem < CostComponent
% This class keeps track of the state, input and disturbance defintions for
% a pariticular porblem instance
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               
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
        % Name of this class for displaying relevant messages
        thisClassName@string = 'CostComponent_PerSubSystem';
        
        % DEFINED IN THE SUPER-CLASS (but not as Abstract)
        % Name of this class for displaying relevant messages
        %thisSuperClassName@string = 'CostComponent';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        % DEFINED IN THE SUPER-CLASS as ABSTRACT
        % The function type of cost function
        functionType@string;
        
    end
    
    properties (Access = private)
        
        % Private properties cannot be defined in the Abstract super-class
        % by definition.
        % ALL THESE PROPERTIES HERE ARE REQUIRED FOR THIS PARTICULAR
        % FUNCTION TYPE:
        
        % The state definition object
        stateDef@StateDef;

        % An Array for the "Cost Component" class objects contributed by 
        % each sub-system
        % NOTE: that this is not generic, but is specific to the sub-system
        % definition that was used to specify the coefficients of the
        % "component" costs
        subSystemCosts_array@CostComponent;
        subSystemCosts_num@uint32;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = CostComponent_PerSubSystem( inputCostArray , inputStateDef )
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                % The "state definition" object is used here to check that
                % the size of the "inputCostArray" is consistent with the
                % number of sub-systems defined in the "State Definition"
                % object.
                % Recalling that when a controller is initialised it has
                % the oppurtunity to change the "number of sub-systems"
                % ("n_ss") property of the "State Definition", but the
                % "Cost Definition" should be constructed at the same time
                % as the system definition being construct, hence the
                % "n_ss" is expected to agree at this stage
                
                
                % Check that "inputCostArray" is of size "n_ss -by- 1"
                if ~( (size(inputCostArray,1) == inputStateDef.n_ss) && (size(inputCostArray,2) == 1) )
                    disp( ' ... ERROR: the input Sub-System Costs Array is not the expected size');
                    disp(['            size(inputCostArray)   = ',num2str(size(inputCostArray,1)),' -by- ',num2str(size(inputCostArray,2)) ]);
                    disp(['            size("expected")       = ',num2str(inputStateDef.n_ss),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                
                
                % Store the co-efficients in the appropriate properties
                obj.subSystemCosts_array = inputCostArray;
                obj.subSystemCosts_num   = uint32( size(inputCostArray,1) );
                
                obj.stateDef = inputStateDef;
                
                obj.functionType = 'persubsystem';
                
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function [..] = CostComponent(...)"
      
        % Augment the deconstructor method
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    
    methods (Static = false , Access = public)
        
        % Define functions implemented in other files:
        % -----------------------------------------------
        % FUNCTION: to compute the cost component
        [returnCost , returnCostPerSubSystem] = computeCostComponent( obj , x , u , xi , currentTime );
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: Parse through all of the Cost Components and extract
        % the coefficients where possible (i.e. for linear or quadratic
        % cost functions)
        function [returnCoefficients , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( obj , currentTime )
            
            % Set the flag to "true" and it will be set to "false" if any
            % exceptions are found
            flag_allCostComponentsIncluded = true;
            
            % Initialise the return struct
            n_x = double(obj.stateDef.n_x);
            n_u = double(obj.stateDef.n_u);
            returnCoefficients.Q = sparse( [], [], [], n_x , n_x , 0);
            returnCoefficients.R = sparse( [], [], [], n_u , n_u , 0);
            returnCoefficients.S = sparse( [], [], [], n_u , n_x , 0);
            returnCoefficients.q = sparse( [], [], [], n_x , 1   , 0);
            returnCoefficients.r = sparse( [], [], [], n_u , 1   , 0);
            returnCoefficients.c = sparse( [], [], [], 1   , 1   , 0);
            
            % Iterate through the number of Cost Components
            for iCost = 1 : obj.subSystemCosts_num
                
                % Get the type of this cost component
                thisCostComponentType = obj.subSystemCosts_array(iCost,1).functionType;
                
                % If the function type is "linear" or "quadratic" then
                % extract the Cost Coefficients
                if ( strcmp(thisCostComponentType,'linear') || strcmp(thisCostComponentType,'quadratic') )
                    % Get the co-efficients of the cost (this will be a
                    % struct containing any subset of: Q,R,S,q,r,c
                    thisReturnCoefficients = getCostCoefficients( obj.subSystemCosts_array(iCost,1) , currentTime );
                    
                    % Get the properties of this struct
                    thisProperties = fieldnames(thisReturnCoefficients);
                    
                    for iField = 1:length(thisProperties)
                        returnCoefficients.(thisProperties{iField}) = returnCoefficients.(thisProperties{iField}) + thisReturnCoefficients.(thisProperties{iField});
                    end
                    
                    % Step through each property and add it to the return
                    % struct
                    
                    
                else
                    % Else, set the flag that we didn't get the
                    % co-efficients for every cost component
                    flag_allCostComponentsIncluded = false;
                end
                
            end
            

        end
        % END OF: "function [...] = getCostCoefficients_uptoQuadratic(...)"
        
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

