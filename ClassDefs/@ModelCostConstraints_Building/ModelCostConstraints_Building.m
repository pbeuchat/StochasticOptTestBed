classdef ModelCostConstraints_Building < ModelCostConstraints
% A class for combining a Building model, its cost and constraint
% parameters into one class
% Note: that "ModelCostsConstraints" is a subclass of:
%    "< matlab.mixin.Copyable"
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
% The "< handle" syntax means that "ProgressModelEngine" is a subclass of
% the "handle" superclass. Where the "handle" class is a default MATLAB
% class
    
    properties(Hidden,Constant)
        % Name of this class for displaying relevant messages
        thisClassName@string = 'ModelCostConstraints_Building';
        
        % DEFINED IN THE SUPER-CLASS (but not as Abstract)
        % Number of properties required for object instantation
        %n_properties@uint64 = uint64(2);
        % Name of this class for displaying relevant messages
        %thisSuperClassName@string = 'ModelCostConstraints';
        % Model type for knowing how to handle the model object
        %modelTypesRecognised@cell = {'building'};
    end

    properties (Access = public)
        % DEFINED IN THE SUPER-CLASS as ABSTRACT
        % A flag showing if the model is valid or not
        isValid@logical = false;
        
        % The Absolute Time elapsed per time step
        t_perInc_hrs@double;
        
        % PROPERTIES REQUIRED FOR BUILDINGS
        % These sort of have to be public
        % Building Model
        building@Building;
        
        % Size of the State, Input and Uncertainty vectors
        stateDef@StateDef;
        
        % The Constraint Definition Object
        constraintDef@ConstraintDef
        
        % The Cost Definition Object
        costDef@CostDef;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % DEFINED IN THE SUPER-CLASS as ABSTRACT
        % The Model
        model = [];
        % Model type for knowing how to handle the model object
        modelType@string;
        
        
        % EXTRA PROPERTIES REQUIRED FOR BUILDINGS
        % Building Model
        %building@Building;
        
        % Cost Parameters
        costParams@struct;
        
        % Constraints Parameters
        constraintParams@struct;
        
        % The initial condition
        x0@double;
        
        % TO SPEED UP THE "performStateUpdate" FUNCTION
        % Store the system matricies to reduce the number of ".property"
        % references
        n_x@uint32;
        n_u@uint32;
        n_xi@uint32;
        A@double;
        Bu@double;
        Bxi@double;
        %Bxu@double;
        %Bxiu@double;
        % The stacked form is used to speed up computations even further
        Bxu_stacked@double;
        Bxiu_stacked@double;
        
    end
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = ModelCostConstraints_Building( inputBuilding , inputModelType )
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                % Check if number of input arguments is correct
                if nargin ~= obj.n_properties
                    %disp( ' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties );
                    disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
                    error(bbConstants.errorMsg);
                end

                % Now check "inputBuilding" has the required properties
                % An "inputModel" of type "building" should have:
                %  ".building"  , ".costs"  ,  ".constraints"
                inputBuildingFields = {'building','stateDef','costDef','constraints','x0'};
                checkBuilding = checkForFields(inputBuilding,inputBuildingFields);
                if ~checkBuilding
                    disp( ' ... ERROR: The "inputBuilding" variable was a struct but did not have the correct fields');
                    error(bbConstants.errorMsg);
                end

                
                % Check if the input type is in the list of recognised type
                if ~( sum( ismember(obj.modelTypesRecognised , inputModelType) ) )
                    disp( ' ... ERROR: The model type "',inputModelType,'" input to the "ProgressModelEngine" class is not recognised.' );
                    error(bbConstants.errorMsg);
                end

                % Store the inputs into the properties of this "obj"
                obj.building            = copy(inputBuilding.building);
                obj.stateDef             = inputBuilding.stateDef;
                obj.costDef             = inputBuilding.costDef;
                obj.constraintParams    = inputBuilding.constraints;
                obj.x0                  = inputBuilding.x0;
                
                % Check that the model is valid, and store the result
                returnIsValid   = checkValidity(obj);
                obj.isValid     = returnIsValid;
                
                % Store the time increment elaspsed per discrete time step
                obj.t_perInc_hrs = inputBuilding.building.building_model.Ts_hrs;
                
                
                % TO SPEED UP THE "performStateUpdate" FUNCTION
                % Store the matrices of the building model
                obj.n_x     = uint32( length( inputBuilding.building.building_model.identifiers.x ) );
                obj.n_u     = uint32( length( inputBuilding.building.building_model.identifiers.u ) );
                obj.n_xi    = uint32( length( inputBuilding.building.building_model.identifiers.v ) );
                obj.A       = sparse( inputBuilding.building.building_model.discrete_time_model.A );
                obj.Bu      = sparse( inputBuilding.building.building_model.discrete_time_model.Bu );
                obj.Bxi     = sparse( inputBuilding.building.building_model.discrete_time_model.Bv );
                %obj.Bxu     = inputBuilding.building.building_model.discrete_time_model.Bxu;
                %obj.Bxiu    = inputBuilding.building.building_model.discrete_time_model.Bvu;
                % The stacked form is used to speed up computations even further
                obj.Bxu_stacked   = sparse( reshape( inputBuilding.building.building_model.discrete_time_model.Bxu , size(obj.A,1) , [] ) );
                obj.Bxiu_stacked  = sparse( reshape( inputBuilding.building.building_model.discrete_time_model.Bvu , size(obj.A,1) , [] ) );
                
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function [...] = BuildingModelCostConstraints(...)"
      
        % Augment the deconstructor method
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    %% methods (Static = false , Access = public)
    methods (Static = false , Access = public)
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: to call a validity check externally
        %       > This function is defined in the SUPER-CLASS as ABSTRACT
        function returnIsValid = attemptValidityCheck(obj)
            returnIsValid   = checkValidity(obj);
            obj.isValid     = returnIsValid;
        end
        % END OF: "function [...] = attemptValidityCheck(...)"
        
        % FUNCTION: to call for a state update externally
        %       > This function is defined in the SUPER-CLASS as ABSTRACT
        function [xnew , l , l_per_ss , constraintSatisfaction] = requestStateUpdate( obj , x , u , xi , delta_t )
            [xnew , l , l_per_ss , constraintSatisfaction] = performStateUpdate( obj , x , u , xi , delta_t );
        end
        % END OF: "function [...] = requestStateUpdate(...)"
        
        % FUNCTION: to build a "StateDef" object from the model
        %       > This function is defined in the SUPER-CLASS as ABSTRACT
        function returnStateDef = requestStateDefObject( obj )
            returnStateDef = buildAndReturnStateDefObject( obj );
            obj.stateDef = returnStateDef;
        end
        % END OF: "function [...] = requestStateUpdate(...)"
        
        % FUNCTION: to build a "ConstraintDef" object from the model
        %       > This function is defined in the SUPER-CLASS as ABSTRACT
        function returnConstraintDef = requestConstraintDefObject( obj )
            returnConstraintDef = buildAndReturnConstraintDefObject( obj );
            createCombinedConstraintDescription( returnConstraintDef );
            obj.constraintDef = returnConstraintDef;
        end
        % END OF: "function [...] = requestStateUpdate(...)"
        
        % FUNCTION: to build a "CostDef" object from the model
        %       > This function is defined in the SUPER-CLASS as ABSTRACT
        function returnCostDef = requestCostDefObject( obj )
            %returnCostDef = buildAndReturnCostDefObject( obj );
            %obj.costDef = returnCostDef;
            returnCostDef = obj.costDef;
        end
        % END OF: "function [...] = requestCostDefObject(...)"
        
        
        
    end % END OF: "methods (Static = false , Access = public)"
    
    
    %% methods (Static = true , Access = public)
    methods (Static = true , Access = public)
        % FUNCTION: to build a "StateDef" object for this type of model
        returnStateDef = buildStateDefObjectFromBuildingObject( B , x0 );
        
    end
    % END OF: "methods (Static = false , Access = private)"
    
    
    %% methods (Static = false , Access = private)
    methods (Static = false , Access = private)
        % Define functions implemented in other files:
        % -----------------------------------------------
        % FUNCTION: to perform the validity checks specific to this type of
        % model
        returnIsValid = checkValidity(obj);
        
        % FUNCTION: to update the state for this type of model
        [xnew , l , l_per_ss , constraintSatisfaction] = performStateUpdate( obj , x , u , xi , currentTime );
       
        % FUNCTION: to build a "StateDef" object for this type of model
        returnStateDef = buildAndReturnStateDefObject( obj );
        
        % FUNCTION: to build a "ConstraintDef" object for this type of model
        returnConstraintDef = buildAndReturnConstraintDefObject( obj );
        
        % FUNCTION: to build a "CostDef" object for this type of model
        returnCostDef = buildAndReturnCostDefObject( obj );
        
    end
    % END OF: "methods (Static = false , Access = private)"

    
    
    
end

