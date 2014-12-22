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
        n_properties@uint64 = uint64(4);
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
        
        % Flags for where the cost can be separated per-sub-system
        flag_separable@logical = false;
        
        % This object also allows for information about part of the cost to
        % be computed and passed around
        subCosts_num@uint32;
        subCosts_label@cell;
        
        
    end
    
    properties (Access = private)
        % The State Def Object
        stateDef@StateDef;
        
        % The array of "Cost Components"
        costComponentsArray@CostComponent;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = CostDef( inputStateDef , inputSubCosts_num , inputSubCosts_label , inputCostComponentsArray )
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
            
            
            % Check the Cost Components input are not empty
            if ( isempty(inputSubCosts_num) || isempty(inputSubCosts_label) || isempty(inputCostComponentsArray) )
                inputSubCosts_num = 0;
                inputSubCosts_label = cell(0,1);
                inputCostComponentsArray = [];
            else
                % And check that they are the right format
                % Check that the "number" specified is a "uint32" scalar
                if ~isa(inputSubCosts_num,'uint32') || ~isscalar(inputSubCosts_num)
                    disp( ' ... ERROR: the "inputSubCosts_num" for the number of additional cost components must be of class "uint32" and must be a scalar');
                    disp(['            class(inputSubCosts_num) = ',class(inputSubCosts_num) ]);
                    disp(['            size(inputSubCosts_num)  = ',num2str(size(inputSubCosts_num,1)),' -by- ',num2str(size(inputSubCosts_num,1)) ]);
                end
                
                % Check that the "label" is a cell array of strings of the
                % same size
                if ~iscellstr(inputSubCosts_label) || ~(size(inputSubCosts_label,1) == inputSubCosts_num) || ~(size(inputSubCosts_label,2) == 1)
                    disp( ' ... ERROR: the "inputSubCosts_label" for describing the additional cost components must be cell array of string and must have a size that agrees with "inputSubCosts_num"');
                    disp(['            class(inputSubCosts_label) = ',class(inputSubCosts_label) ]);
                    disp(['            size(inputSubCosts_label)  = ',num2str(size(inputSubCosts_label,1)),' -by- ',num2str(size(inputSubCosts_label,1)) ]);
                    disp(['            expected size()            = ',num2str(inputSubCosts_num),' -by- 1' ]);
                end
                
                % Check that the "CostComponentsArray" is a the correct
                % type and also of the same size
                if ~isa(inputCostComponentsArray,'CostComponent') || ~(size(inputCostComponentsArray,1) == inputSubCosts_num) || ~(size(inputCostComponentsArray,2) == 1)
                    disp( ' ... ERROR: the "inputCostComponentsArray" for specifying the additional cost component function must be ');
                    disp('             of class "CostComponent" and must have a size that agrees with "inputSubCosts_num"');
                    disp(['            class(inputCostComponentsArray) = ',class(inputCostComponentsArray) ]);
                    disp(['            size(inputCostComponentsArray)  = ',num2str(size(inputCostComponentsArray,1)),' -by- ',num2str(size(inputCostComponentsArray,1)) ]);
                    disp(['            expected size()                 = ',num2str(inputSubCosts_num),' -by- 1' ]);
                end
                
            end

            
            % ---------------------------------------------------- %
            % NOW PUT ALL THE INPUT INTO THE APPROPRIATE VARIABLES OF THIS
            % OBJECT
            obj.stateDef                = inputStateDef;
            obj.subCosts_num            = inputSubCosts_num;
            obj.subCosts_label          = inputSubCosts_label;
            obj.costComponentsArray     = inputCostComponentsArray;
            
            
            %obj.type            = funcType;
            
            %obj.c               = c;
            %obj.q               = q;
            %obj.r               = r;
            %obj.Q               = Q;
            %obj.R               = R;
            %obj.S               = S;
            
            
            
        end
        % END OF: "function [..] = ProgressModelEngine(...)"
        
        
        
%         % -----------------------------------------------
%         % FUNCTION: the CONSTRUCTOR method for this class
%         function obj = CostDef( inputStateDef , funcType , c , q , r , Q , R , S , inputSubCosts_num , inputSubCosts_label )
%             % Check if number of input arguments is correct
%             if nargin ~= obj.n_properties
%                 %fprintf(' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties);
%                 disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
%                 error(bbConstants.errorMsg);
%             end
%             
%             % ----------------------------------------------------- %
%             % DO ALL THE CHECKS FOR THE "x" CONSTRAINTS
%             % Check if the input State Definition object is of the
%             % appropriate class
%             if ~( isa( inputStateDef , 'StateDef' ) )
%                 disp( ' ... ERROR: the input State Definition object was not of class "StateDef".' );
%                 disp(['             Instead it was class(inputStateDef)  = ',class(inputStateDef)]);
%                 error(bbConstants.errorMsg);
%             end
%             
%             
%             % Check the Sub Costs input
%             if ( isempty(inputSubCosts_num) || isempty(inputSubCosts_label) )
%                 inputSubCosts_num = 0;
%                 inputSubCosts_label = cell(0,1);
%             else
%                 % Check they are the right format
%                 if ~isa(inputSubCosts_num,'uint32') || ~isscalar(inputSubCosts_num)
%                     disp( ' ... ERROR: the "inputSubCosts_num" for the number of additional cost components must be of class "uint32" and must be a scalar');
%                     disp(['            class(inputSubCosts_num) = ',class(inputSubCosts_num) ]);
%                     disp(['            size(inputSubCosts_num)  = ',num2str(size(inputSubCosts_num,1)),' -by- ',num2str(size(inputSubCosts_num,1)) ]);
%                 end
%                 
%                 % Check they are the right format
%                 if ~iscellstr(inputSubCosts_label) || ~(size(inputSubCosts_label,1) == inputSubCosts_num) || ~(size(inputSubCosts_label,2) == 1)
%                     disp( ' ... ERROR: the "inputSubCosts_label" for describing the additional cost components must be cell array of string and must have a size that agrees with "inputSubCosts_num"');
%                     disp(['            class(inputSubCosts_label) = ',class(inputSubCosts_label) ]);
%                     disp(['            size(inputSubCosts_label)  = ',num2str(size(inputSubCosts_label,1)),' -by- ',num2str(size(inputSubCosts_label,1)) ]);
%                     disp(['            expected size()            = ',num2str(inputSubCosts_num),' -by- 1' ]);
%                 end
%             end
% 
%             
%             % ---------------------------------------------------- %
%             % NOW PUT ALL THE INPUT INTO THE APPROPRIATE VARIABLES OF THIS
%             % OBJECT
%             obj.stateDef        = inputStateDef;
%             obj.type            = funcType;
%             obj.c               = c;
%             obj.q               = q;
%             obj.r               = r;
%             obj.Q               = Q;
%             obj.R               = R;
%             obj.S               = S;
%             
%             obj.subCosts_num    = inputSubCosts_num;
%             obj.subCosts_label  = inputSubCosts_label;
%             
%         end
%         % END OF: "function [..] = ProgressModelEngine(...)"



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
        % FUNCTION: Compute the Cost by compute the cost of each component
        function returnCost = computeCost( obj , x , u , xi , currentTime )
            % Initialise return vector
            returnCost = zeros( obj.numSubCosts+1 , 1 );
            % Iterate should the number of Cost Components
            for iCost = 1 : obj.numSubCosts
                % Compute the cost for this component
                returnCost( iCost+1 , 1 ) = computeCostComponent( obj.costComponentsArray(iCost,1) , x , u , xi , currentTime );
            end
            % Put in the total as the sum of the components
            returnCost(1,1) = sum( returnCost(2:obj.numSubCosts,1) );
        end
        
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

