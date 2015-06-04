classdef Control_Coordinator < handle
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
        n_properties@uint64 = uint64(9);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Control_Coordinator';
        % Model type for knowing how to handle the model object
        modelTypesRecognised@cell = {'building'};
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        distStatsRequired@cell;
        distStatsHorizon@uint32;
        
        % The "StateDef" object with the size of the State, Input and
        % Uncertainty vectors, there labels and the masks
        stateDef@StateDef;
        
    end
    
    properties (Access = private)
        % Class Name for the Local Controller object
        classNameLocal@string;
        
        % Class Name for the Global Controller object
        classNameGlobal@string;
        
        % The Global Controller
        globalController@Control_GlobalController;
        
        % A Cell array of the Local controllers
        localControllerArray@Control_LocalController;
        
        % Model for which the simulation will be done
        %model;
        
        % Model type for knowing how to handle the model object
        modelType@string;
        
        % Model and Disturbance ID's for saving results to avoid repeat
        % computations
        modelID@string;
        disturbanceID@string;
        
        % Flag to keep track of whether already Initialised
        initialised@logical = false;
        
        % Variable Arguments to be passed to the controller
        vararginLocal;
        vararginGlobal;
        

        % The "ConstraintDef" object with the definiton of the constraints
        constraintDef@ConstraintDef;
        
        % The size of the controller array (ie. the number of "local"
        % sub-controllers)
        numControllers@uint32;

    end
    
    
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_Coordinator(inputClassNameLocal , inputClassNameGlobal , inputVararginLocal , inputVararginGlobal , inputStateDef , inputConstraintDef , inputModelType , inputModelID , inputDisturbanceID )
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

                % Check if the "input model type" is a string
                if ( ~ischar(inputModelType) || isempty(inputModelType) )
                    disp( ' ... ERROR: The model type input must be a string. The model type that was input is:' );
                    disp inputModelType;
                    error(bbConstants.errorMsg);
                end

                % Check if the input type is in the list of recognised type
                if ~( sum( ismember(obj.modelTypesRecognised , inputModelType) ) )
                    disp( ' ... ERROR: The model type "',inputModelType,'" input to the "ProgressModelEngine" class is not recognised.' );
                    error(bbConstants.errorMsg);
                end
                
                % Check if the "input model type" is a string
                if ( ~ischar(inputModelID) || isempty(inputModelType) )
                    disp( ' ... ERROR: The model ID input must be a string. The model ID that was input is:' );
                    disp inputModelID;
                    error(bbConstants.errorMsg);
                end
                
                % Check if the "input model type" is a string
                if ( ~ischar(inputDisturbanceID) || isempty(inputDisturbanceID) )
                    disp( ' ... ERROR: The disturbance ID input must be a string. The disturbance ID that was input is:' );
                    disp inputDisturbanceID;
                    error(bbConstants.errorMsg);
                end
                

                % Check that the input handles exists on the current Matlab
                % path as files of the same name
                if ~( exist( inputClassNameLocal , 'class' ) == 8 )
                    disp( ' ... ERROR: The Local Controller Class Name specified did not correspond to a class on the current Matlab path.' );
                    disp( '            The path was searched for a class named:' );
                    disp(['            "',inputClassNameLocal,'"']);
                    error(bbConstants.errorMsg);
                end
                if ~isempty(inputClassNameGlobal) &&  ~( exist( inputClassNameGlobal , 'class' ) == 8 )
                    disp( ' ... ERROR: The Global Controller Class Name did not correspond to a class on the current Matlab path.' );
                    disp( '            The path was searched for a class named:' );
                    disp(['            "',func2str(inputClassNameGlobal),'"']);
                    error(bbConstants.errorMsg);
                end
                if isempty(inputClassNameGlobal)
                    inputClassNameGlobal = '';
                end
                
                % Check that the "inputStateDef" is a of the correct class
                if ~isa( inputStateDef , 'StateDef' )
                    disp( ' ... ERROR: The Input State Definition variable (i.e. "inputStateDef") is not an object of class "StateDef"' );
                    disp(['             class(inputStateDef) = ',class(inputStateDef) ]);
                    disp(inputStateDef);
                    error(bbConstants.errorMsg);
                end
                
                % Check that the "inputConstraintDef" is a of the correct
                % class
                if ~isa( inputConstraintDef , 'ConstraintDef' )
                    disp( ' ... ERROR: The Input Constraint Definition variable (i.e. "inputConstraintDef") is not an object of class "ConstraintDef"' );
                    disp(['             class(inputConstraintDef) = ',class(inputConstraintDef) ]);
                    disp(inputConstraintDef);
                    error(bbConstants.errorMsg);
                end

                % Set the handles to the appropriate properties
                obj.classNameLocal  = inputClassNameLocal;
                obj.classNameGlobal = inputClassNameGlobal;
                obj.vararginLocal   = inputVararginLocal;
                obj.vararginGlobal  = inputVararginGlobal;
                obj.modelType       = inputModelType;
                obj.modelID         = inputModelID;
                obj.disturbanceID   = inputDisturbanceID;
                obj.stateDef        = copy( inputStateDef );
                obj.constraintDef   = inputConstraintDef;
                
                
                % We make a copy of the State Definition Object here
                % because each "Control_Coordinator" may want to adapt its
                % "stateDef" object if the control structure is changed
                % i.e. the properties "mask_..." and "n_ss" properties may
                % be changed, the other properties should not be altered!!
                
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
        
        [ ] = initialiseControllers(obj , inputSettings , inputModel , inputDisturbance_ology)
        
        [u , computationTime_per_ss , diagnostics] = computeControlAction( obj , currTime , x , xi , stageCost , stageCost_per_ss , prediciton , statsRequired_mask , timeHorizon );
        
        
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

