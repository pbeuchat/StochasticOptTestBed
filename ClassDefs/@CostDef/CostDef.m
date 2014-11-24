classdef CostDef < handle
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
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(8);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'CostDef';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        % The type of cost function
        type@string;
        
        % The parameters of the cost function:
        %   -> For both Linear and Quadratic costs
        c@double;
        q@double;
        r@double;
        Q@double;
        R@double;
        S@double;
        
        
        % Flags for which constraints are "included"
        flag_separable@logical = false;
        
        
    end
    
    properties (Access = private)
        % The State Def Object
        stateDef@StateDef;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = CostDef( inputStateDef , funcType , c , q , r , Q , R , S )
            % Check if number of input arguments is correct
            if nargin ~= obj.n_properties
                %fprintf(' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties);
                disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
                error(bbConstants.errorMsg);
            end
            
            % ----------------------------------------------------- %
            % DO ALL THE CHECKS FOR THE "x" CONSTRAINTS
            % Check if the input State Definition object is of the
            % appropriate class
            if ~( isa( inputStateDef , 'StateDef' ) )
                disp( ' ... ERROR: the input State Definition object was not of class "StateDef".' );
                disp(['             Instead it was class(inputStateDef)  = ',class(inputStateDef)]);
                error(bbConstants.errorMsg);
            end

            
            % ---------------------------------------------------- %
            % NOW PUT ALL THE INPUT INTO THE APPROPRIATE VARIABLES OF THIS
            % OBJECT
            obj.stateDef        = inputStateDef;
            obj.type            = funcType;
            obj.c               = c;
            obj.q               = q;
            obj.r               = r;
            obj.Q               = Q;
            obj.R               = R;
            obj.S               = S;
            
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
        % FUNCTION:
        % END OF: "function [...] = xxx(...)"
        
 
        

        
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

