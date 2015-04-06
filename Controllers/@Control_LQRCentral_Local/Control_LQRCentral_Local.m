classdef Control_LQRCentral_Local < Control_LocalController
% This class runs the local control algorithms
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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



    properties (Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(2);
        n_argin_instantiation@uint64 = uint64(4);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Control_LQRCentral_Local';
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
        P@cell;
        p@cell;
        s@cell;
        
        K@cell;
        
        computeKEveryNumSteps@uint32 = uint32(1);
        
        iterationCounter@uint32;
                
        computeAllKsAtInitialisation@logical;
        
        usePreviouslySavedKs@logical;
        
        numKsInitialised@uint32;
        
        % Specify the trade off to be used for the multi-objective
        energyToComfortScaling@double;
        
        % Specify how the control action should be clipped back into the
        % constraint set
        clippingMethod@string;
        
    end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_LQRCentral_Local( input_idnum , inputStateDef , inputConstraintDef , inputGlobalControlObject)
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                if nargin == obj.n_argin_instantiation
                
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
                    
                else
                    % Let the use know the problem
                    disp( ' ... ERROR: ' );
                    error(bbConstants.errorMsg);
                    
                    
                end
                
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
        [flag_successfullyInitialised , flag_requestDisturbanceData] = initialise_localControl( obj , inputModelType , inputModel , vararginLocal);
        
        [flag_successfullyInitialised , flag_requestDisturbanceData] = initialise_localControl_withDisturbanceInfo( obj , inputModelID , inputDisturbanceID , inputDistCoord , vararginLocal);
        
        
        
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    %methods (Static = true , Access = public)
    %end
    % END OF: "methods (Static = true , Access = public)"
        
    methods (Static = true , Access = private)
        
        % --------------------------------------------------------------- %
        % FUNCTIONS SPECIFIC TO THIS CONTROLLER
        
        % FUNCTOIN: To save, load, or check for an existing result
        %           Where the "inputInstruction" specifies which to do
        [flag_success , loadedObject] = saveLoadCheckFor( inputInstruction , inputObject );
        
        % FUNCTION: to step backward in a the LQR Recursion
        [Pnew , pnew, snew, u0new, Fnew] = performLQR_singleIteration( discountFactor, P_tp1, p_tp1, s_tp1, Exi, Exixi, A, Bu, Bxi, Q, R, S, q, r, c );
        
    end
    % END OF: "methods (Static = true , Access = private)"
    
end

