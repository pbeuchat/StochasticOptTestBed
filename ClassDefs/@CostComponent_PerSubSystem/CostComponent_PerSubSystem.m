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
        subSystemCostsArray@CostComponent;
        numSubSystemCosts@uint32;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = CostComponent_Linear( inputCostArray , inputStateDef )
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
                
                % Check that "q" is of size "n_x -by- 1"
                if ~( (size(input_q,1) == inputStateDef.n_x) && (size(input_q,2) == 1) && isvector(input_q) )
                    disp( ' ... ERROR: the linear state coefficinet, "q", is not the expected size');
                    disp(['            size(q)            = ',num2str(size(input_q,1)),' -by- ',num2str(size(input_q,2)) ]);
                    disp(['            size("expected")   = ',num2str(inputStateDef.n_x),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that "inputCostArray" is of size "n_ss -by- 1"
                if ~( (size(inputCostArray,1) == inputStateDef.n_ss) && (size(inputCostArray,2) == 1) && isvector(input_r) )
                    disp( ' ... ERROR: the input Sub-System Costs Array is not the expected size');
                    disp(['            size(inputCostArray)   = ',num2str(size(inputCostArray,1)),' -by- ',num2str(size(inputCostArray,2)) ]);
                    disp(['            size("expected")       = ',num2str(inputStateDef.n_ss),' -by- 1' ]);
                    error(bbConstants.errorMsg);
                end
                
                
                % Store the co-efficients in the appropriate properties
                obj.subSystemCostsArray = inputCostArray;
                obj.numSubSystemCosts   = uint32( size(inputCostArray,1) );
                
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
        
        % FUNCTION: to compute the cost component
        [returnCost , returnCostPerSubSystem] = computeCostComponent( obj , x , u , xi , currentTime );
        
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

