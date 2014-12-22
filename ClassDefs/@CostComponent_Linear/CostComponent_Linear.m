classdef CostComponent_Linear < CostComponent
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


    properties(Hidden,Constant)
        % Name of this class for displaying relevant messages
        thisClassName@string = 'CostComponent_Linear';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        % The type of cost function
        %type@string;
        
    end
    
    properties (Access = private)
        
        % The Linear Cost Component is based on the function:
        %   cost = q' * x  +  r' * u  +  c
        
        % Vector for linear costs in the state
        q@double;
        
        % Vector for linear costs in the input
        r@double;
        
        % Scalar for cost constants
        c@double;
        
        % The state definition object
        stateDef@StateDef;
        
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
        function obj = CostComponent_Linear( input_q , input_r , input_c , inputStateDef )
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                % The "state definition" object is used here to check the
                % size of the cost function coefficients. This is done
                % because no checking will be performed in the
                % "computeCostComponent" function to avoid slow down
                
                % Check that "q" is of size "n_x -by- 1"
                if ~( (size(input_q,1) == inputStateDef.n_x) && (size(input_q,2) == 1) )
                    disp( ' ... ERROR: the linear state coefficinet, "q", is not the expected size');
                    disp(['            size(q)            = ',num2str(size(input_q,1)),' -by- ',num2str(size(input_q,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that "r" is of size "n_u -by- 1"
                if ~( (size(input_r,1) == inputStateDef.n_u) && (size(input_r,2) == 1) )
                    disp( ' ... ERROR: the linear input coefficinet, "r", is not the expected size');
                    disp(['            size(r)            = ',num2str(size(input_r,1)),' -by- ',num2str(size(input_r,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_u),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that "c" is of size "1 -by- 1"
                if ~( isscalar(input_c) )
                    disp( ' ... ERROR: the constant, "c", is not a scalar');
                    disp(['            size(c)            = ',num2str(size(input_c,1)),' -by- ',num2str(size(input_c,2)) ]);
                    disp( '            size("expected")   = 1 -by- 1' );
                    error(bbConstants.errorMsg);
                end
                
                % Store the co-efficients in the appropriate properties
                obj.q       = input_q;
                obj.r       = input_r;
                obj.c       = input_c;
                
                obj.stateDef = inputStateDef;
                
                
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
        
        % FUNCTION: to compute the cost component
        returnCost = computeCostComponent( obj , x , u , xi , currentTime );
        
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

