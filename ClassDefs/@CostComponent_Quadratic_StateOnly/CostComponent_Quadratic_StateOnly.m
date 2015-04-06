classdef CostComponent_Quadratic_StateOnly < CostComponent
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
        thisClassName@string = 'CostComponent_Linear';
        
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
        
        % The Linear Cost Component is based on the function:
        %   cost = x' * Q * x  +  u' * R * u  +  2 * u' * S * x  +  q' * x  +  r' * u  +  c
        
        % Matrix for quadratic costs in the state
        Q@double;
        
        % Vector for linear costs in the state
        q@double;
        
        % Scalar for cost constants
        c@double;
        
        % The state definition object
        stateDef@StateDef;

        % The number of sub-systems defined directly from the "stateDef"
        % odject
        n_ss@uint32;
        
        % An Array for the "Cost Component" contributed by each sub-system
        % NOTE: that this is not generic, but is specific to the sub-system
        % definition that was used to specify the coefficients of the
        % "component" costs
        subSystemCostsArray@CostComponent;
        flag_hasSubComponentCosts@logical = false;

        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = CostComponent_Quadratic_StateOnly( input_Q , input_q , input_c , inputStateDef )
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                % The "state definition" object is used here to check the
                % size of the cost function coefficients. This is done
                % because no checking will be performed in the
                % "computeCostComponent" function to avoid slow down
                
                % Check that "Q" is of size "n_x -by- n_x"
                if ~( (size(input_Q,1) == inputStateDef.n_x) && (size(input_Q,2) == inputStateDef.n_x) && ismatrix(input_Q) )
                    disp( ' ... ERROR: the quadratic state coefficinet, "Q", is not the expected size');
                    disp(['            size(Q)            = ',num2str(size(input_Q,1)),' -by- ',num2str(size(input_Q,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_x),' -by- ',num2str(inputStateDef.n_x) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that "q" is of size "n_x -by- 1"
                if ~( (size(input_q,1) == inputStateDef.n_x) && (size(input_q,2) == 1) && isvector(input_q) )
                    disp( ' ... ERROR: the linear state coefficinet, "q", is not the expected size');
                    disp(['            size(q)            = ',num2str(size(input_q,1)),' -by- ',num2str(size(input_q,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                % Check that "c" is of size "1 -by- 1"
                if ~( isscalar(input_c) )
                    disp( ' ... ERROR: the constant, "c", is not a scalar');
                    disp(['            size(c)            = ',num2str(size(input_c,1)),' -by- ',num2str(size(input_c,2)) ]);
                    disp( '            size("expected")   = 1 -by- 1' );
                    error(bbConstants.errorMsg);
                end
                
                % Make the matrices sparse if they are not already
                if ~issparse(input_Q)
                    input_Q = sparse( input_Q );
                end
                
                % Store the co-efficients in the appropriate properties
                obj.Q       = input_Q;
                obj.q       = input_q;
                obj.c       = input_c;
                
                obj.stateDef = inputStateDef;
                
                obj.n_ss     = inputStateDef.n_ss;
                
                obj.functionType = 'quadratic';
                
                
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
        
        % Define functions directly in other files:
        % -----------------------------------------------
        % FUNCTION: to compute the cost component
        [returnCost , returnCostPerSubSystem] = computeCostComponent( obj , x , u , xi , currentTime );
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: to return the cost coefficients as a struct
        function returnCoefficients = getCostCoefficients( obj , currentTime )
            % Return all the coefficients and the calling function will
            % parse and use them apropriately
            returnCoefficients.Q = obj.Q;
            returnCoefficients.q = obj.q;
            returnCoefficients.c = obj.c;
            
        end
        
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

