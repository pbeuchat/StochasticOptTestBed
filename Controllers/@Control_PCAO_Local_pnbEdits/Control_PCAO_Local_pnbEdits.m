classdef Control_PCAO_Local_pnbEdits < Control_LocalController
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
        statsPredictionHorizon@uint32 = uint32(10);
        
        % The Identifiaction Number that specifies which sub-system 
        % this local controller is
        idnum@uint32;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        
        % The state definiton object
        stateDef@StateDef;
        
        % The type of model that is being controller
        modelType@string = '';
        
        % The Constraints Definiton object
        constraintDef@ConstraintDef;
        
        % The object which every local controller should be given the same
        % handle to so that a Global Control/Coordinator can be implemented
        globalController@Control_GlobalController;
        
    end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_PCAO_Local_pnbEdits( input_idnum , inputStateDef , inputConstraintDef , inputGlobalControlObject)
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
        [flag_successfullyInitialised , flag_requestedDisturbanceData] = initialise_localControl( obj , inputModelType , inputModel , vararginLocal);
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    %methods (Static = true , Access = public)
    %end
    % END OF: "methods (Static = true , Access = public)"
        
    methods (Static = true , Access = private)
        
        [MEASUREData_t] = DefineMeasurements(Param,Cost_vector,current_folder,System,x,xi,predictions,actions )
        [u_tt]=CAO_AUX_CALC( SIMULparam, MEASUREData, UpDateFlag, current_folder,Symbolic_folder,ubarBCS,System,iteration )
        [ L, n, m, num_of_dist, e1, e2, max_order, monomial_number, perturb_num,T_buffer, pole, w_norm, PredictDistHorizon, number_of_constraints, alpha, eta,U_MIN, U_MAX, CHI_MIN, CHI_MAX, lambda,PerturbValidationMethod, PerturbCenter,GlobalCapBuffer,NoSystems,dt,Astep] = readSIMCONSTANTdata(SIMULparam)
        [ chi_t, u_t, dist_t, predict_dist_t, chi_s, u_s, dist_s, predict_dist_s, cost_t, cost_s, t]= readSIMdata_mod(n, m, num_of_dist, predict_horizon, data)
        [GC_temp, GC_humid, temp_sigma, humid_sigma] = beta_creation( L, y_max, y_min )
        [ fh_Jacobian_xbar, fh_Jacobian_SQRT_beta, fh_sigma ] = symbolic_calculations( n, m, num_of_dist, PredictDistHorizon, number_of_constraints,L, alpha, eta, GC_temp, GC_humid, temp_sigma, humid_sigma, U_min, U_max, lambda,current_folder,System )
        [ u ] = sigmoid( u_bar, lambda, min_value, max_value, sym_flag)
        [ dV, V_t, V_s, E_t ] = calcLYAP( z_old, z_new, P_ij, cost, dt )
        [ P_blk, P_ij ] = genPDMrandomly( e1, e2, L, dim_subP )
        [ beta ] = timestep_calc_beta( L, chi, GC_temp, GC_humid, temp_sigma, humid_sigma, sym_flag )
        [ Mx ] = timestep_calc_Mx( L, x_bar, x_bar_des, x, beta_multi, fh_Jacobian_xbar, fh_Jacobian_SQRT_beta,current_folder,Symbolic_folder )
        [ z ] = timestep_calc_z( L, beta_multi, x_bar, sym_flag )
        [ P_ij ] = unvectorise3Dmatrix( P_vec, L )
        [ P_ij_buffer, E_buffer, E_est_buffer, Cost_buffer, X_buffer, V_buffer, Beta_buffer ] = updateBuffer( P_ij, P_ij_buffer, Etot, E_buffer,E_est, E_est_buffer, dailyCost, Cost_buffer, x_cur, X_buffer, V_t, V_buffer, ActiveBeta_t, Beta_buffer, T_buffer, timestep_counter )
        [ P_vec ] = vectorise3Dmatrix( P_ij )
        [ P ] = constructBLK( P_ij )
        [ NORMAL_period_total_cost, NORMAL_period_total_error ] = CAOnormBCS_mod (CAO_period_cost, dV, dt, MainPath, UpdateFreq)
        [ best, Global_Cost_buffer ] = CAO_PERTB_CENTER( Systems,day)
        CAO_TRAIN_EST( CenterPosition, Global_Cost_buffer,day,Systems )
        [ theta, orders, bounds ] = LIP_approximation( max_order, monomial_number, X_buffer, P_ij_buffer, E_buffer, Global_Cost_buffer, GlobalCapBuffer, w ) 
        [ x ] = createTRAININGdata(X_buffer, P_ij_buffer, Global_Cost_buffer, GlobalCapBuffer, i)
        [ orders ] = monomialRANDOMorders( monomial_number, X_elements, max_order )
        [ Y, bounds ] = normalise( X, w )
        [ phi ] = calcPHI( x, orders )
        [ P_ij_best, Ecur_est_best ] = perturbPvalidation( X_buffer, Global_Cost_buffer, P_ij,theta, orders, bounds, e1, e2, a, perturb_num, w, GlobalCapBuffer, PerturbValidationMethod )
        [ y ] = vectorBOUNDnormalisation( x, bounds, w )
        [ P_ij_perturb ] = perturbPDMrandomly( P_ij, a, e1, e2 )
        [ localBuffer ] = localiseBuffer( generalBuffer, Beta_buffer, CurrentActiveBeta, T_localBuffer )
        [ a ] = calcPERTURBstep( a0, timestep_counter )         
 
        
    end
    % END OF: "methods (Static = true , Access = private)"
    
end

