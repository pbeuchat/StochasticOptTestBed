classdef Control_MPC_Local < Control_LocalController
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



    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(2);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Control_MPC_Local';
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
        computeMPCEveryNumSteps@uint32 = uint32(1);
        
        iterationCounter@uint32;
        
        u_MPC_fullHorizon@double;
        
        energyToComfortScaling@double;
        
        flag_hasBilinearTerms@logical;
        flag_hasBilinearTerm_Bxu@logical;
        flag_hasBilinearTerm_Bxiu@logical;
        
        % Model matrices (this is to allow for a different discreteisation
        % to be used compared to that from the one contained in the "model"
        % property)
        A@double;
        Bu@double;
        Bxi@double;
        
        Bxu_stacked@double;
        Bxiu_stacked@double;
        
        % MPC Matrices - these are the matrices that predict the future
        % Storing here helps with speed up of the code
        A_mpc@double;
        Bu_mpc@double;
        Bxi_mpc@double;
        
        Q_mpc@double;
        R_mpc@double;
        S_mpc@double;
        q_mpc@double;
        r_mpc@double;
        c_mpc@double;
        
        A_ineq_input@double;
        b_ineq_input@double;
        
        % Combined matrices to speed things up further
        % For "R"
        Bu_Q_Bu@double;
        Bu_S@double;

        % For "r"
        A_Q_Bu@double;
        Bxi_Q_Bu@double;
        A_S@double;
        q_Bu@double;

        % For "c"
        A_Q_A@double;
        Bxi_Q_Bxi@double;
        A_Q_Bxi@double;
        q_A@double;
        q_Bxi@double;

        
    end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_MPC_Local( input_idnum , inputStateDef , inputConstraintDef , inputGlobalControlObject)
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
        [flag_successfullyInitialised , flag_requestDisturbanceData] = initialise_localControl( obj , inputModelType , inputModel , vararginLocal);
        
        % --------------------------------------------------------------- %
        % FUNCTIONS SPECIFIC TO THIS CONTROLLER
        %[Pnew , pnew, snew] = performADP_singleIteration_bySampling_LSFit( obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper );
        
        % Build the MPC matrices that are specific to the controller
        [ ] = buildMPCMatrices_specific( obj );
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    methods (Static = false , Access = private)
        % Build the MPC matrices that account of the linearisation of the
        % Bi-linear terms
        [ ] = buildMPCMatrices_updateForLinearisedTerms( obj, T, Bxu_linearised , Bxiu_linearised)
    end
    % END OF: "methods (Static = false , Access = private)"
        
        
    %methods (Static = true , Access = public)
    %end
    % END OF: "methods (Static = true , Access = public)"
        
    methods (Static = true , Access = private)
        % --------------------------------------------------------------- %
        % FUNCTIONS SPECIFIC TO THIS CONTROLLER
        % Build the MPC matrices that are independent of the controller
        [A_new, Bu_new, Bxi_new, Q_new, R_new, S_new, q_new, r_new, c_new ] = buildMPCMatrices_static( T, A_k, Bu_k, Bxi_k, Q_k, R_k, S_k, q_k, r_k, c_k);
        
        % Build the MPC matrices needed for each computation
        %[R_new, r_new, c_new, A_new, Bu_new, Bxi_new] = buildMPCMatrices( T, x0, A, Bu, Bxi, Q, R, S, q, r, c, thisExi, thisExixi );
        [R_new, r_new, c_new] = buildMPCMatrices_given_x0( T, x0, thisExi, thisExixi );
        
        % Build the constraints
        [return_A_ineq, return_b_ineq] = buildMPC_inputConstraints_fromConstraintDefObject( T, constraintDef );
    end
    % END OF: "methods (Static = true , Access = private)"
    
end

