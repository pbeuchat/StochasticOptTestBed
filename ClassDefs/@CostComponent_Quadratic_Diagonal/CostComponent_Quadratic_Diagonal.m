classdef CostComponent_Quadratic_Diagonal < CostComponent
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
        thisClassName@string = 'CostComponent_Quadratic_Diagonal';
        
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
        %   cost = Q' * x.^2  +  R' * u.^2  +  q' * x  +  r' * u  +  c
        
        % Vector for quadratic costs in the state
        Q@double;
        
        % Vector for quadratic costs in the input
        R@double;
        
        % Vector for linear costs in the state
        q@double;
        
        % Vector for linear costs in the input
        r@double;
        
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
        function obj = CostComponent_Quadratic_Diagonal( input_Q , input_R , input_q , input_r , input_c , inputStateDef )
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
                
                % Check that "R" is of size "n_u -by- n_u"
                if ~( (size(input_R,1) == inputStateDef.n_u) && (size(input_R,2) == inputStateDef.n_u) && ismatrix(input_R) )
                    disp( ' ... ERROR: the quadratic input coefficinet, "R", is not the expected size');
                    disp(['            size(R)            = ',num2str(size(input_R,1)),' -by- ',num2str(size(input_R,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_u),' -by- ',num2str(inputStateDef.n_u) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that "q" is of size "n_x -by- 1"
                if ~( (size(input_q,1) == inputStateDef.n_x) && (size(input_q,2) == 1) && isvector(input_q) )
                    disp( ' ... ERROR: the linear state coefficinet, "q", is not the expected size');
                    disp(['            size(q)            = ',num2str(size(input_q,1)),' -by- ',num2str(size(input_q,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that "r" is of size "n_u -by- 1"
                if ~( (size(input_r,1) == inputStateDef.n_u) && (size(input_r,2) == 1) && isvector(input_r) )
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
                
                % As everything is a vector we don't need to make things
                % sparse (though it is still likely to be beneficial if
                % the vector are passed in as sparse)

                % Store the co-efficients in the appropriate properties
                obj.Q       = input_Q;
                obj.R       = input_R;
                obj.S       = input_S;
                obj.q       = input_q;
                obj.r       = input_r;
                obj.c       = input_c;
                
                obj.stateDef = inputStateDef;
                
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
        
        % Define functions implemented in other files:
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
            returnCoefficients.R = obj.R;
            returnCoefficients.S = obj.S;
            returnCoefficients.q = obj.q;
            returnCoefficients.r = obj.r;
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

