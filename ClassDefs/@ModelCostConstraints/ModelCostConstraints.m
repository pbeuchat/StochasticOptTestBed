classdef (Abstract) ModelCostConstraints < matlab.mixin.Copyable
% A class for combining a Building model, its cost and constraint
% parameters into one class
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
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(2);
        % Name of this class for displaying relevant messages
        thisAbstractClassName@string = 'ModelCostConstraints';
        % Model type for knowing how to handle the model object
        modelTypesRecognised@cell = {'building'};
    end

    properties (Access = public , Abstract = true)
        % A flag showing if the model is valid or not
        isValid@logical;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    %properties (Access = private , Abstract = true)
        % In general, properties should be set as PRIVATE, but...
        % Private properties make no sense for an Abstract class because
        % they are not visible to sub-classes.
        % So it is the prerogative of the sub-class to have any properties
        % it needs, and this Abstract class is mainly specifying the
        % functions that MUST be implement for a sub-class to be CONCRETE
        
        % The Model
        %model;
        % Model type for knowing how to handle the model object
        %modelType@string;
        % Size of the State, Input and Uncertainty vectors
        %n_x@double;
        %n_u@double;
        %n_xi@double;
    %end
    
    
    methods
        
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = ModelCostConstraints(~,~)
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                % A CONSTRUCTOR for "nargin > 0" is not really required
                % because an ABSTRACT class cannot be instantiated
                %obj.isValid     = uint8(0);
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
    
    
    methods (Static = false , Access = public , Abstract = true )
        % FUNCTION: to call a validity check externally
        returnIsValid = attemptValidityCheck(obj)
        
        % FUNCTION: to call for a state update externally
        [xnew , l , constraintSatisfaction] = requestStateUpdate( obj , x , u , xi , delta_t )
        
        % FUNCTION: to build a "StateDef" object from the model
        returnStateDef = requestStateDefObject( obj );
        
    end % END OF: "methods (Static = false , Access = private , Abstract = true )"

    
    % ABSTRACT, PRIVATE methods make no sense because: (some answers from
    % the internet)
    %  > "private methods cannot be overridden in subclasses."
    %  > "A private member is visible only to the class that declares it.Specifically, 
    %     a private member is not visible to subclasses. An abstract method is a 
    %     method where a subclass is expected to provide the implementation. But a 
    %     subclass couldn't see the declaration of the signature if the signature were 
    %     private"
    %  > "The super class can not see a private member of a derived class, and a
    %     derived class cannot change the behaviour of any private methods in
    %     the super class."
    
    %methods (Static = false , Access = private , Abstract = true)
        % FUNCTION: to perform the validity checks specific to this type of
        % model
        %returnIsValid = checkValidity(obj)
        
        % FUNCTION: to update the state for this type of model
        %[xnew , l , constraintSatisfaction] = performStateUpdate( obj , x , u , xi , delta_t )
    %end
    % END OF: "methods (Static = false , Access = private , Abstract = true )"

    
end

