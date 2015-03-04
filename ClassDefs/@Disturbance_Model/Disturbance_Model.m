classdef (Abstract) Disturbance_Model < handle
% This class defines an Abstract class that all disturbance model classes
% must follow
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > 
% ----------------------------------------------------------------------- %


    properties(Hidden,Constant)
        % Name of this class for displaying relevant messages
        thisAbstractClassName@string = 'Disturbane_Model';
    end

    properties (Access = public , Abstract = true)
        % A flag showing if the model is valid or not
        isValid@uint8;
        
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
    %end
    
    
    methods
        
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = Disturbance_Model()
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
        % FUNCTION: to get a trace for the full length of the cycle
        returnSample = requestSampleForFullCylce( obj );
        
        % FUNCTION: to call for a state update externally
        returnSample = requestSampleFromTimeForDuration( obj , startTime , duration , startXi );
        
        % FUNCTION: to check if a statistics is available directly
        returnCheck = isStatAvailableDirectly( obj , statDesired );
        
        % FUNCTION: to return a statistics directly
        [returnStat , returnSuccess] = requestStatDirectly( obj , statDesired )
        
        
        
    end % END OF: "methods (Static = false , Access = private , Abstract = true )"

    
    methods (Static = false , Access = {?Disturbance_Model,?Disturbance_ology,?Disturbance_Coordinator})
        % NOTE: that this class (ie. "Disturbance_Model") must be included
        % in the access list so that its sub-classes will have acccess
        
        % FUNCTION: to initialise a "RandStream" from details
        returnSuccess = initialiseDisturbanceRandStreamWithSeedAndDetails( obj , inputSeed , inputDetails );
        
        % FUNCTION: to initialise a "RandStream" directly with a given
        % "RandStream" object
        returnSuccess = initialiseDisturbanceRandStreamWithRandStream( obj , inputRandStream );
        
        % FUNCTION: to set the stream number of the Random Stream object
        setSubStreamNumberForDisturbanceRandStream( thisDistCoord , thisStream );
    end
    
    
    methods (Static = false , Access = {?Disturbance_Model,?Disturbance_ology,?Disturbance_Coordinator})
        % NOTE: that this class (ie. "Disturbance_Model") must be included
        % in the access list so that its sub-classes will have acccess
        
        % FUNCTION: to get a trace for the full length of the cycle
        % This violates the "all properties should be private" structure
        % But is required for interfacing with other components
        returnSize = getDisturbanceVectorSizePerTimeStep( obj );
        
        % FUNCTION: to get a trace for the full length of the cycle
        % This violates the "all properties should be private" structure
        % But is required for interfacing with other components
        returnTinc = getTimeIncrement( obj );
    end
    % END OF: "methods (Static = false , Access = {?Disturbance_ology,?Disturbance_Coordinator})"
    
    
    methods (Static = false , Access = {?Disturbance_Model,?Disturbance_ology,?Disturbance_Coordinator})
        % FUNCTION: to check if the Disturbance Model is TIME correlated
        % This violates the "all properties should be private" structure
        % See more notes at end for reasoning
        returnCorrelated = isDisturbanceModelTimeCorrelated( obj );
        
        % FUNCTION: get the Full Time Cycle of the Disturbance Model
        % This violates the "all properties should be private" structure
        % See more notes at end for reasoning
        returnFullTimeCycleSteps = getDisturbanceModelFullTimeCycle( obj );
        
    end
    % END OF: "methods (Static = false , Access = {?Disturbance_ology})"
    
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


%% EXTRA NOTES ABOUT THE FUNCTIONS THAT VIOLATE THE PRIVATE PROPERTIES IDEAL
%
% > In relation to the function: "isDisturbanceModelTimeCorrelated"
%   This violates the "all properties should be private" structure
%   because it is essentially a "getter" method. It makes sense that
%   this violate the structure because NO-ONE else deserves to know
%   if the Disturbance Model is TIME correlated or not.
%   BUT... it saves the Disturbance-ology Department a lot of trouble
%   in terms of having to sample over a time horizon at every time
%   step
%   Hence the method is set to only be accessible by the
%   "disturbance-ologists"
%
%
% > In relation to the function: "getDisturbanceModelFullTimeCycle"
%   This violates the "all properties should be private" structure
%   because it is essentially a "getter" method. It makes sense that
%   this violate the structure because NO-ONE else deserves to know
%   the time cycle on which the Disturbance Model repeats itself.
%   BUT... it saves the Disturbance-ology Department a lot of trouble
%   in terms of having to sample over a long time horizon and instead
%   allows then to provide arbitarily long predicitons
%   Hence the method is set to only be accessible by the
%   "disturbance-ologists"
%
%



