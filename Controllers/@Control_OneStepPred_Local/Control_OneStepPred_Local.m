classdef Control_OneStepPred_Local < Control_LocalController
% This class runs the local control algorithms
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(2);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Control_Null_Local';
    end
   
    properties (Access = public)
        % A cell array of strings with the statistics required
        statsRequired@cell = {'mean','cov'};
        statsPredictionHorizon@uint32 = uint32(1);
        
        % The Identifiaction Number that specifies which sub-system 
        % this local controller is
        idnum@uint32;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        
        % Size of the input vector that must be returned
        % (Default set to "0" so that an error occurs if not changed)
        n_u@uint32 = uint32(0);
        
        % The type of model that is being controller
        modelType@string = '';
        
        % The model of the system
        model@ModelCostConstraints
        
        % The State Definiton object
        stateDef@StateDef;
        
        % The Constraints Definiton object
        constraintDef@ConstraintDef;
        
        % The object which every local controller should be given the same
        % handle to so that a Global Control/Coordinator can be implemented
        globalController@Control_GlobalController;
        
        
        % --------------------------------------------------------------- %
        % VARIABLES SPECIFIC TO THIS CONTROLLER
        optYalmip;
        
        %P@cell;
        %p@cell;
        %s@cell;
        
        %computeVEveryNumSteps@uint32 = uint32(6);
        
        %iterationCounter@uint32;
        
        % Model matrices (this is to allow for a different discreteisation
        % to be used compared to that from the one contained in the "model"
        % property
        A@double;
        Bu@double;
        Bxi@double;
        
        
    end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_OneStepPred_Local( input_idnum , inputStateDef , inputConstraintDef , inputGlobalControlObject)
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                % Check that the Identifiaction Number (i.e. "input_idnum")
                % is of the correct type
                if ~isa( input_idnum , 'uint32' )
                    disp( ' ... ERROR: the input Identifiaction Number for this local controller is not of the expected "uint32" type');
                    disp(['            It was input as type(input_idnum) = ',type(input_idnum) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that the State Definition  (i.e. "inputStateDef")
                % is of the correct type
                if ~isa( inputStateDef , 'StateDef' )
                    disp( ' ... ERROR: the input Identifiaction Number for this local controller is not of the expected "StateDef" type');
                    disp(['            It was input as type(inputStateDef) = ',type(inputStateDef) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that the Constraint Definition
                % (i.e. "inputConstraintDef") is of the correct type
                if ~isa( inputConstraintDef , 'ConstraintDef' )
                    disp( ' ... ERROR: the input Identifiaction Number for this local controller is not of the expected "ConstraintDef" type');
                    disp(['            It was input as type(inputConstraintDef) = ',type(inputConstraintDef) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that the Gloabl Control Object
                % (i.e. "inputGlobalControlObject") is of the correct type
                if ( ~isempty(inputGlobalControlObject)  &&  ~isa( inputGlobalControlObject , 'Control_GlobalController' ) )
                    disp( ' ... ERROR: the input Identifiaction Number for this local controller is not of the expected "Control_GlobalController" type');
                    disp(['            It was input as type(inputGlobalControlObject) = ',type(inputGlobalControlObject) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Perform all the initialisation here
                obj.idnum               = input_idnum;
                obj.n_u                 = inputStateDef.n_u;
                obj.stateDef            = inputStateDef;
                obj.constraintDef       = inputConstraintDef;
                obj.globalController    = inputGlobalControlObject;
                
            end
            % END OF: "if nargin > 0"
            
        end
        % END OF: "function obj = Control_LocalInterface(inputHandleMain , inputModelType)"
        
%         % GET and SET Access methods
%         function obj = set.controllerConfig_Static(obj,value)
%             obj.controllerConfig_Static = value;
%         end
%         
%         function obj = set.controllerConfig_Mutable(obj,value)
%             obj.controllerConfig_Mutable = value;
%         end
            
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    methods (Static = false , Access = public)
        % This function will be called at every time step and must return
        % the input vector to be applied
        u = computeControlAction( obj , currentTime , x , xi_prev , stageCost_prev , stageCost_this_ss_prev , predictions );
        
        % This function will be called once before the simulation is
        % started
        % This function should be used to perform off-line possible
        % computations so that the controller computation speed during
        % simulation run-time is faster
        flag_successfullyInitialised = initialise_localControl( obj , inputModelType , inputModel , vararginLocal);
        
        % --------------------------------------------------------------- %
        % FUNCTIONS SPECIFIC TO THIS CONTROLLER
        [Pnew , pnew, snew] = performADP_singleIteration_bySampling_LSFit( obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper );
        
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

