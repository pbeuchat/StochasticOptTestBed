classdef Simulation_Coordinator < handle
% This class interfaces the disturbance and system with the controller
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
        n_properties@uint64 = uint64(4);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Simulation_Coordinator';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % The Disturbance_Coordinator of the appropriate class
        distCoord@Disturbance_Coordinator;
        
        % The Control Coordinator of the appropriate class
        controlCoord@Control_Coordinator;
        
        % The Progress Model Engine of the appropriate class
        progModelEng@ProgressModelEngine;
        
        % The State Definition of the appropriate class
        stateDef@StateDef;
        
        % Flag to keep track of whether a simulation can be run (this
        % involves checking that the various components are all compatible
        % with eachother and that all fields are non-empty and sensible)
        flag_componentsAreCompatible@logical    = false;
        flag_readyToSimulate@logical            = false;
        
        
        % Parameters for running the simulation
        simTimeIndex_start@uint32; %   = uint32(1);
        simTimeIndex_end@uint32; %     = uint32(1);
        
        % Parameters for specifying what data to save
        flag_SaveResults@logical = false;
        
    end
    
    
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Simulation_Coordinator(inputDistCoor , inputControlCoord , inputProgModelEng , inputStateDef )
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

                % Check that each of the inputs are of the correct class
                % Check the input Disturance Coordinator is:
                if ~isa( inputDistCoor , 'Disturbance_Coordinator' )
                    disp(' ... ERROR: The Disturbance Coordinator object that was input is not of class "Disturbance_Coordinator"' );
                    disp('            Instead it has:');
                    disp(['            class(inputDistCoor) = ',class(inputDistCoor)]);
                    error(bbConstants.errorMsg);
                end

                % Check the input Control Coordinator is:
                if ~isa( inputControlCoord , 'Control_Coordinator' )
                    disp(' ... ERROR: The Control Coordinator object that was input is not of class "Control_Coordinator"' );
                    disp('            Instead it has:');
                    disp(['            class(inputControlCoord) = ',class(inputControlCoord)]);
                    error(bbConstants.errorMsg);
                end

                % Check the input Progress Engine Model is:
                if ~isa( inputProgModelEng , 'ProgressModelEngine' )
                    disp(' ... ERROR: The Progress Model Engine object that was input is not of class "ProgressModelEngine"' );
                    disp('            Instead it has:');
                    disp(['            class(inputProgModelEng) = ',class(inputProgModelEng)]);
                    error(bbConstants.errorMsg);
                end
                
                % Check the input State Defintion is:
                if ~isa( inputStateDef , 'StateDef' )
                    disp(' ... ERROR: The Progress Model Engine object that was input is not of class "ProgressModelEngine"' );
                    disp('            Instead it has:');
                    disp(['            class(inputProgModelEng) = ',class(inputProgModelEng)]);
                    error(bbConstants.errorMsg);
                end

                

                % Set the handles to the appropriate properties
                obj.distCoord       = inputDistCoor;
                obj.controlCoord    = inputControlCoord;
                obj.progModelEng    = inputProgModelEng;
                obj.stateDef        = inputStateDef;
                
                % Now check that the interfaces between the components are
                % compatible
                % Actually we will do this separately
                %flag_throwError = false;
                %returnIsCompatible = checkSimulationCompatability( obj , flag_throwError );
                %obj.flag_componentsAreCompatible = returnIsCompatible;
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
        
        returnIsCompatible = checkSimulationCompatability( obj , flag_throwError );
        
        returnIsReady = checkSimulationIsReadyToRun( obj , flag_throwError );
        
        
        function [ ] = specifySimulationParameters(obj, inputTimeIndex_start , inputTimeIndex_end , inputFlagSaveResults)
            obj.simTimeIndex_start  = uint32( inputTimeIndex_start );
            obj.simTimeIndex_end    = uint32( inputTimeIndex_end );
            obj.flag_SaveResults     = inputFlagSaveResults;
        end
        
        
        returnCompletedSuccessfully = runSimulation( obj );
        
        
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

