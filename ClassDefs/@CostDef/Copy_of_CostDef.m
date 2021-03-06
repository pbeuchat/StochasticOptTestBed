classdef Copy_of_CostDef < handle
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
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(5);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'CostDef';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        
        % These properties allows for other objects to know how many
        % "additive components" make up the "single objective"
        % This object also allows for information about part of the cost to
        % be computed and passed around
        subCosts_num@uint32;
        subCosts_label@cell;
        
        
    end
    
    properties (Access = private)
        % The State Def Object
        stateDef@StateDef;
        
        % The array of "Cost Components"
        %costComponentsArray@CostComponent;
        costComponentsCellArray@cell;
        
        % The scaling for each component
        costComponentScaling@double;
        
        % The number of sub-systems defined directly from the "stateDef"
        % odject
        % It is IMPORTANT to use this property instead of
        % "obj.stateDef.n_ss" because the "stateDef" object is common
        % across many classes and may change during the execution of the
        % code
        n_ss@uint32;
        
    end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = Copy_of_CostDef( inputStateDef , inputSubCosts_num , inputSubCosts_label , inputCostComponentsCellArray, inputCostComponentScaling )
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
            if ( isempty(inputSubCosts_num) || isempty(inputSubCosts_label) || isempty(inputCostComponentsCellArray) )
                inputSubCosts_num = 0;
                inputSubCosts_label = cell(0,1);
                inputCostComponentsCellArray = [];
                inputCostComponentScaling = 0;
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
                    disp(['            size(inputSubCosts_label)  = ',num2str(size(inputSubCosts_label,1)),' -by- ',num2str(size(inputSubCosts_label,2)) ]);
                    disp(['            expected size()            = ',num2str(inputSubCosts_num),' -by- 1' ]);
                end
                
                % Check that the "CostComponentsArray" is a the correct
                % type and also of the same size
                if ~iscell(inputCostComponentsCellArray) || ~(size(inputCostComponentsCellArray,1) == inputSubCosts_num) || ~(size(inputCostComponentsCellArray,2) == 1)
                    disp( ' ... ERROR: the "inputCostComponentsCellArray" for specifying the additional cost component function must be ');
                    disp('             of class "cell" and must have a size that agrees with "inputSubCosts_num"');
                    disp(['            class(inputCostComponentsArray) = ',class(inputCostComponentsCellArray) ]);
                    disp(['            size(inputCostComponentsArray)  = ',num2str(size(inputCostComponentsCellArray,1)),' -by- ',num2str(size(inputCostComponentsCellArray,2)) ]);
                    disp(['            expected size()                 = ',num2str(inputSubCosts_num),' -by- 1' ]);
                end
                % Check that the "CostComponentScaling" is a the correct
                % type and also of the same size
                if ~isfloat(inputCostComponentScaling) || ~( (length(inputCostComponentScaling) == inputSubCosts_num) && isvector(inputCostComponentScaling) )
                    disp( ' ... ERROR: the "inputCostComponentScaling" for specifying the ratio used to combine the cost components must be ');
                    disp('             of data type "float" (ie. double or single) and must have a size that agrees with "inputSubCosts_num"');
                    disp(['            class(inputCostComponentsArray) = ',class(inputCostComponentScaling) ]);
                    disp(['            size(inputCostComponentsArray)  = ',num2str(size(inputCostComponentScaling,1)),' -by- ',num2str(size(inputCostComponentScaling,1)) ]);
                    disp(['            expected size()                 = ',num2str(inputSubCosts_num),' -by- 1' ]);
                end
                
            end

            
            % ---------------------------------------------------- %
            % NOW PUT ALL THE INPUT INTO THE APPROPRIATE VARIABLES OF THIS
            % OBJECT
            obj.stateDef                = inputStateDef;
            obj.subCosts_num            = inputSubCosts_num;
            obj.subCosts_label          = inputSubCosts_label;
            obj.costComponentsCellArray = inputCostComponentsCellArray;
            obj.costComponentScaling    = inputCostComponentScaling;
            
            obj.n_ss                    = inputStateDef.n_ss;
            
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
        
        

     
        function [returnCost , returnCostPerSubSystem] = computeCostTake2( obj , x , u , xi , currentTime )
            % Initialise return vector for the "system-wide" costs
            returnCost = zeros( obj.subCosts_num+1 , 1 );
            % Initialise return cell array for the "per-sub-system" costs
            %returnCostPerSubSystem = cell( obj.subCosts_num+1 , 1 );
            returnCostPerSubSystem = zeros( obj.subCosts_num+1 , obj.n_ss );

            
% for iComponent = 1:numComponents
%     
%     if per_sub_system_available
%         
%         for i_ss = 1:n_ss
%         this_type = costComponentCellArray{iComponent,1}
%         
%         
%     else
%         
%     end
%     
% end
            
            % Iterate through the number of Cost Components
            for iCost = 1 : obj.subCosts_num
                % Get the number of sub-components for this cost
                num_sub_costComponents = obj.subCosts_num(iCost);
                % Get the type of the sub-components for this cost
                type_sub_costComponents = obj.subCosts_num(iCost);
                % Pre-allocate a vector for storing each sub-cost-component
                % as it is calculated
                cost_per_sub_costComponent = zeros(num_sub_costComponents,1);
                % Now iterate through each component
                for iSubCost = 1:num_sub_costComponents
                    % Switch to the appropriate cost computation function
                    % depending on the type
                    switch type_sub_costComponents(iSubCost)
                        case 0
                            cost_per_sub_costComponent(iSubCost) = computeCost_linear( coefficients, x , u );
                        case 1
                            cost_per_sub_costComponent(iSubCost) = computeCost_linear_stateOnly( coefficients, x );
                        case 2
                            cost_per_sub_costComponent(iSubCost) = computeCost_linear_inputOnly( coefficients, u );
                        otherwise
                            disp( ' ... ERROR: The sub-cost-component type was not recognised' );
                    end
                    
                end
                % Compute the cost for this component
                [ thisCostForComponent , thisCostPerSubSystem ] = computeCostComponent( obj.costComponentsArray(iCost,1) , x , u , xi , currentTime );
                % Apply the cost component scaling
                returnCost( iCost+1 , 1 ) = thisCostForComponent * obj.costComponentScaling(iCost);
                returnCostPerSubSystem( iCost+1 , : ) = thisCostPerSubSystem' .* obj.costComponentScaling(iCost);
            end
            % Put in the total as the sum of the components
            returnCost(1,1) = sum( returnCost(2:obj.subCosts_num+1,1) );

            % Putting in the total for each sub-system is more tedious
            % because it requires the assumption that every Cost Component
            % (e.g. energy and comfort) returns a "CostPerSubSystem" vector
            % of the same length
            returnCostPerSubSystem(1,:) = sum( returnCostPerSubSystem( 2:(obj.subCosts_num+1) , : ) , 1 );
            %returnCostPerSubSystem{1,1} = sparse([],[],[], length(returnCostPerSubSystem{2,1}) , 1 , 0 );
            %for iCost = 1 : obj.subCosts_num
            %    returnCostPerSubSystem{1,1} = returnCostPerSubSystem{1,1} + returnCostPerSubSystem{iCost+1,1};
            %end

        end
        % END OF: "function [...] = computeCost(...)"

        
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: Compute the Cost by compute the cost of each component
        function [returnCost , returnCostPerSubSystem] = computeCost( obj , x , u , xi , currentTime )
            % Initialise return vector for the "system-wide" costs
            returnCost = zeros( obj.subCosts_num+1 , 1 );
            % Initialise return cell array for the "per-sub-system" costs
            %returnCostPerSubSystem = cell( obj.subCosts_num+1 , 1 );
            returnCostPerSubSystem = zeros( obj.subCosts_num+1 , obj.n_ss );

            % Iterate through the number of Cost Components
            for iCost = 1 : obj.subCosts_num
                % Compute the cost for this component
                [ thisCostForComponent , thisCostPerSubSystem ] = computeCostComponent( obj.costComponentsArray(iCost,1) , x , u , xi , currentTime );
                % Apply the cost component scaling
                returnCost( iCost+1 , 1 ) = thisCostForComponent * obj.costComponentScaling(iCost);
                returnCostPerSubSystem( iCost+1 , : ) = thisCostPerSubSystem' .* obj.costComponentScaling(iCost);
            end
            % Put in the total as the sum of the components
            returnCost(1,1) = sum( returnCost(2:obj.subCosts_num+1,1) );

            % Putting in the total for each sub-system is more tedious
            % because it requires the assumption that every Cost Component
            % (e.g. energy and comfort) returns a "CostPerSubSystem" vector
            % of the same length
            returnCostPerSubSystem(1,:) = sum( returnCostPerSubSystem( 2:(obj.subCosts_num+1) , : ) , 1 );
            %returnCostPerSubSystem{1,1} = sparse([],[],[], length(returnCostPerSubSystem{2,1}) , 1 , 0 );
            %for iCost = 1 : obj.subCosts_num
            %    returnCostPerSubSystem{1,1} = returnCostPerSubSystem{1,1} + returnCostPerSubSystem{iCost+1,1};
            %end

        end
        % END OF: "function [...] = computeCost(...)"

        
        
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
            for iCost = 1 : obj.subCosts_num
                
                % Get the type of this cost component
                thisCostComponentType = obj.costComponentsArray(iCost,1).functionType;
                
                % If the function type is "linear" or "quadratic" then
                % extract the Cost Coefficients directly
                if ( strcmp(thisCostComponentType,'linear') || strcmp(thisCostComponentType,'quadratic') )
                    % Get the co-efficients of the cost (this will be a
                    % struct containing any subset of: Q,R,S,q,r,c
                    thisReturnCoefficients = getCostCoefficients( obj.subSystemCosts_array(iCost,1) , currentTime );
                    
                    % Get the properties of this struct
                    thisProperties = fieldnames(thisReturnCoefficients);
                    % Step through each property and add it to the return
                    % struct
                    for iField = 1:length(thisProperties)
                        returnCoefficients.(thisProperties{iField}) = returnCoefficients.(thisProperties{iField}) + thisReturnCoefficients.(thisProperties{iField});
                    end
                    
                    
                elseif strcmp(thisCostComponentType,'persubsystem')
                    % Else, if it is a combination, then call the function
                    % that get all the coefficients
                    [thisReturnCoefficients , thisflag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( obj.costComponentsArray(iCost,1) , currentTime );
                    
                    % Get the properties of this struct
                    thisProperties = fieldnames(thisReturnCoefficients);
                    % Step through each property and add it to the return
                    % struct
                    for iField = 1:length(thisProperties)
                        returnCoefficients.(thisProperties{iField}) = returnCoefficients.(thisProperties{iField}) + thisReturnCoefficients.(thisProperties{iField});
                    end
                    
                    % Put the flag into the return variable
                    if not(thisflag_allCostComponentsIncluded)
                        flag_allCostComponentsIncluded = false;
                    end
                    
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
        
        
    methods (Static = true , Access = public)

        % MAPPING FROM COST "type_string" TO COST "type_id"
        %  ID   STRING             
        %   1   linear
        %   2   linear_stateonly
        %   3   linear_inputonly
        %   4   quadratic
        %   5   quadratic_diagonal
        %   6   quadratic_stateonly
        %   7   quadratic_diagonal_stateonly
        %   8   quadratic_inputonly
        %   9   quadratic_diagonal_inputonly
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_Linear( input_q , input_r , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'linear';
            returnCostComponent.type_id     = 1;
            returnCostComponent.coefficients.q = sparse(input_q);
            returnCostComponent.coefficients.r = sparse(input_r);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_linear_stateOnly( input_q , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'linear_stateonly';
            returnCostComponent.type_id     = 2;
            returnCostComponent.coefficients.q = sparse(input_q);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_linear_inputOnly( input_r , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'linear_stateonly';
            returnCostComponent.type_id     = 3;
            returnCostComponent.coefficients.r = sparse(input_r);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_quadratic( input_Q, input_R, input_S, input_q , input_r , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'quadratic';
            returnCostComponent.type_id     = 4;
            returnCostComponent.coefficients.Q = sparse(input_Q);
            returnCostComponent.coefficients.R = sparse(input_R);
            returnCostComponent.coefficients.S = sparse(input_S);
            returnCostComponent.coefficients.q = sparse(input_q);
            returnCostComponent.coefficients.r = sparse(input_r);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_quadratic_diagonal( input_Q, input_R, input_q , input_r , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'quadratic_diagonal';
            returnCostComponent.type_id     = 5;
            returnCostComponent.coefficients.Q = sparse(input_Q);
            returnCostComponent.coefficients.R = sparse(input_R);
            returnCostComponent.coefficients.q = sparse(input_q);
            returnCostComponent.coefficients.r = sparse(input_r);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_quadratic_stateOnly( input_Q, input_q , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'quadratic_stateonly';
            returnCostComponent.type_id     = 6;
            returnCostComponent.coefficients.Q = sparse(input_Q);
            returnCostComponent.coefficients.q = sparse(input_q);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_quadratic_diagonal_stateOnly( input_Q, input_q , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'quadratic_diagonal_stateonly';
            returnCostComponent.type_id     = 7;
            returnCostComponent.coefficients.Q = sparse(input_Q);
            returnCostComponent.coefficients.q = sparse(input_q);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_quadratic_inputOnly( input_R, input_r , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'quadratic_inputonly';
            returnCostComponent.type_id     = 8;
            returnCostComponent.coefficients.R = sparse(input_R);
            returnCostComponent.coefficients.r = sparse(input_r);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        % --------------------------------------------------------------- %
        function [returnCostComponent] = createCostComponent_quadratic_diagonal_inputOnly( input_R, input_r , input_const , stateDefObject )
            
            returnCostComponent.type_string = 'quadratic_diagonal_inputonly';
            returnCostComponent.type_id     = 9;
            returnCostComponent.coefficients.R = sparse(input_R);
            returnCostComponent.coefficients.r = sparse(input_r);
            returnCostComponent.coefficients.c = sparse(input_const);
            
        end
        
        
    end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

