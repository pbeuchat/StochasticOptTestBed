classdef Disturbance_Coordinator < matlab.mixin.Copyable
% This class interfaces the disturbance with everything else
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > 
% ----------------------------------------------------------------------- %


    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(1);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Disturbance_Coordinator';
    end
   
    properties (Access = public)
        % A token public property to confirm that copies are deep
        tokenPublicProperty@double = 1;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % An object from the "Disturbance_Model" class, this will be the
        % true underlying disturbance model
        myDisturbanceModel@Disturbance_Model;
        
        % The "disturbance-ology" class that samples the true model,
        % analyses the samples and makes predicitons about the uncertainty
        % set so that they can be passed to the model and controller
        myDisturbance_ology@Disturbance_ology;
        
        
        % Model type for knowing how to handle the model object
        disturbance_ModelIdentifier@string;
        
        % Flag for whether the disturbance model is time correlated or not
        isTimeCorrelated@logical;
        
        % A flag to reduce the number of checks required during online
        % computation
        flag_statsAreAvailableAndPathsExist@uint8 = uint8(0);
        
    end
    
    
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Disturbance_Coordinator( inputDistModelIdentifier )
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

                % Check if the "input model identifier" is a string
                if ( ~ischar(inputDistModelIdentifier) || isempty(inputDistModelIdentifier) )
                    disp( ' ... ERROR: The disturbance model identifier must be input as a string. The identifier that was input is:' );
                    disp inputDistModelIdentifier;
                    error(bbConstants.errorMsg);
                end

                
                % Create an object of this disturbance model
                % Make a string of the name
                tempDistModelString = ['Disturbance_Model_',inputDistModelIdentifier];
                % Check the name exists as a class on the current Matlab path
                if ~(exist(tempDistModelString,'class') == 8)
                    disp([' ... ERROR: a disturbance model class with identifier "',inputDistModelIdentifier,'" was not found on the current Matlab path']);
                    error(bbConstants.errorMsg);
                end
                % Now make a function handle to the class constructor
                tempDistModelHandle = str2func(tempDistModelString);
                
                % Create the object
                tempNothing = 1;
                tempDistModelObject = tempDistModelHandle(tempNothing);
                
                % Before creating the object, check that this Disturbance Model Class is a
                % subclass of "Disturbance_Model" and that it is a concrete class:
                bbConstants.checkObjIsSubclassOf(tempDistModelObject,'Disturbance_Model',1);
                bbConstants.checkObjConcrete(tempDistModelObject,1);
                
                
                % Add the Disturbance Model to the Coordinator Object
                obj.myDisturbanceModel      = tempDistModelObject;
                
                % Create a disturbance-ology object
                obj.myDisturbance_ology     = Disturbance_ology(obj.myDisturbanceModel);

                % Set the time-correlated property
                obj.isTimeCorrelated = isDisturbanceModelTimeCorrelated( tempDistModelObject );
                
                % Set the handles to the appropriate properties
                %obj.myDisturbanceModel      = tempDistModel;
                %obj.myDisturbance_ology     = inputDist_ology;
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function obj = ProgressModelEngine(inputModel,inputModelType)"
      
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    
    
    methods (Static = false , Access = public)
        
        
        % FUNCTION: to initialise a "RandStream" from details
        function returnSuccess = initialiseDisturbanceRandStreamWithSeedAndDetails( obj , inputSeed , inputDetails )
            returnSuccess = initialiseDisturbanceRandStreamWithSeedAndDetails( obj.myDisturbanceModel , inputSeed , inputDetails );
        end
        
        % FUNCTION: to initialise a "RandStream" directly with a given
        % "RandStream" object
        function returnSuccess = initialiseDisturbanceRandStreamWithRandStream( obj , inputRandStream )
            returnSuccess = initialiseDisturbanceRandStreamWithRandStream( obj.myDisturbanceModel , inputRandStream );
        end
        
        % FUNCTION: to set the stream number of the Random Stream object
        function setSubStreamNumberForDisturbanceRandStream( obj , inputSubStream )
            setSubStreamNumberForDisturbanceRandStream( obj.myDisturbanceModel , inputSubStream );
        end
        
        
        % FUNCTION: 
        function returnSuccess = checkStatsAreAvailable_ComputingAsRequired( obj, requestedStats , flag_RecomputeStats )
            
            % If requested to recompute the stats then call the function
            % directly
            if flag_RecomputeStats
                returnSuccess = sampleAndComputePredictions( obj , requestedStats );
            else
                % Check with the Disturbance-ology department what stats
                % were already computed in the past
                % (where the "isCorrelated" is important information
                % because it changes the file names for already computed
                % stats)
                %flag_statsAvailable = checkForStatsAlreadyComputed( obj.myDisturbance_ology , requestedStats , isCorrelated );
                [flag_AlreadyComputedPerStat , flag_overallSuccess] = checkForStatsAlreadyComputed( obj.myDisturbance_ology , requestedStats , obj.isTimeCorrelated );
                
                % If "flag_overallSuccess" is true, then all the required
                % stats are alredy computed
                if flag_overallSuccess
                    returnSuccess = 1;
                else
                    % Get the sub-list of stats needing computation
                    statsNeedingComputation = requestedStats(~flag_AlreadyComputedPerStat);
                    % Request the compuation of these stats
                    returnSuccess = sampleAndComputePredictions( obj , statsNeedingComputation );
                end
            end
            obj.flag_statsAreAvailableAndPathsExist = uint8(returnSuccess);
            if returnSuccess
                setPathsToData( obj.myDisturbance_ology );
            end
        end
        
        % FUNCTION: 
        function returnSuccess = sampleAndComputePredictions( obj , requestedStats )
            % Check if the Disturbance Model is Time Correlated
            isCorrelated = obj.isTimeCorrelated;
            % If it is time correlated then we should specify the Time
            % Horizon over which to compute the predicitions
            if isCorrelated
                thisTimeHorizon = 12;
            else
                thisTimeHorizon = [];
            end
            
            % Get the "Full Cycle Time" of the Disturbance Model
            distCycleTimeSteps = getDisturbanceModelFullTimeCycle( obj.myDisturbanceModel );
            
            % Get the size of the disturbance vector per time step (ie.
            % "n_\xi")
            n_xi = getDisturbanceVectorSizePerTimeStep( obj.myDisturbanceModel );
            
            % We leave the Disturbance-ologists to get traces in the case
            % that the Disturbance Model is Time Correlated
            returnSuccess = sampleComputeAndSaveStatistics( obj.myDisturbance_ology , requestedStats , distCycleTimeSteps , n_xi , isCorrelated , thisTimeHorizon);
        end
        %END OF: "function ... = sampleAndComputePredictions()"
        
        
        % FUNCTION:
        function returnPred = getPredictions( obj , statsRequired , startTime , duration)
            % Check if the Disturbance Model is Time Correlated
            isCorrelated = obj.isTimeCorrelated;
            % If it is time correlated then we should specify the Time
            % Horizon over which to compute the predicitions
            if isCorrelated
                thisTrace = 12;
            else
                thisTrace = [];
            end
            % Request the Predictions from the Disturbance-ology Group
            returnPred = getPredictions( obj.myDisturbance_ology , statsRequired , isCorrelated , startTime , duration , thisTrace , obj.flag_statsAreAvailableAndPathsExist );
        end
        %END OF: "function ... = sampleAndComputePredictions()"
        
        
        
        % FUNCTION:
        function returnSample = getDisturbanceSampleForOneTimeStep( obj , inputTime )
            timeHorizon = 1;
            startXi = [];
            returnSample = requestSampleFromTimeForDuration( obj.myDisturbanceModel , inputTime , timeHorizon , startXi );
        end
        %END OF: "function ... = sampleAndComputePredictions()"

        % FUNCTION: 
        function returnSample = getDisturbanceSampleForOneTimeStep_withRandInput( obj , inputTime , inputRandomNumbers )
            timeHorizon = 1;
            startXi = [];
            returnSample = requestSampleFromTimeForDuration_withRandInput( obj.myDisturbanceModel , inputTime , timeHorizon , startXi , inputRandomNumbers );
        end
        %END OF: "function ... = sampleAndComputePredictions()"
        
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    methods (Static = false , Access = {?Control_LocalController})
        % FUNCTION: to get the Full Time Cycle for Local Controllers that
        % need to do initialisation using disturbance information for
        % computational reasons
        % Additionally, this violates the "all properties should be
        % private" structure. See more notes at end for reasoning
        function returnCorrelated = isDisturbanceModelTimeCorrelated( obj )
            returnCorrelated = obj.isTimeCorrelated;
        end
        
        % FUNCTION: get the Full Time Cycle of the Disturbance Model
        
        function returnFullTimeCycleSteps = getDisturbanceModelFullTimeCycle_forLocalController( obj , requestingFileName )
            if strcmp( requestingFileName , 'initialise_localControl_withDisturbanceInfo' )
                returnFullTimeCycleSteps = getDisturbanceModelFullTimeCycle( obj.myDisturbanceModel );
            else
                disp([' ... ERROR: The requesting file name was: "',requestingFileName,'"' ]);
                disp( '            It was expected to be: "initialise_localControl_withDisturbanceInfo"' );
                disp( '            Hence the Full Cycle Time of the Disturbance Model has NOT been provided');
                returnFullTimeCycleSteps = 0;
            end
        end
        
    end
    % END OF: "methods (Static = false , Access = {?Disturbance_ology})"
    
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


% > In relation to the function: "getDisturbanceModelFullTimeCycle", the
% following is the justification for making it available to the
% "disturbancologist"
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
%   For a "Control_LocalController" it is a similar line of reasoning,
%   having access to this information allows the local controller to
%   pre-compute a set of value functions that can be plat for an arbitarily
%   long time horizon


