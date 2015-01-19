function u = computeControlAction( obj , currentTime , x , xi_prev , stageCost_prev , stageCost_this_ss_prev , predictions )
 %timeStepIndex , timeStepAbsolute
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    %% INCREMENT THE ITERATION COUNTER
    obj.iterationCounter = obj.iterationCounter + uint32(1);

    %% Extract the system matrices from the model
    myBuilding      = obj.model.building;
    myCosts         = obj.model.costDef;
    myConstraints   = obj.model.constraintDef;
    
    %A       = sparse( myBuilding.building_model.discrete_time_model.A   );
    %Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
    %Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
    %Bxu     = myBuilding.building_model.discrete_time_model.Bxu;
    %Bxiu    = myBuilding.building_model.discrete_time_model.Bvu;
    %A       = obj.A;
    %Bu      = obj.Bu;
    %Bxi     = obj.Bxi;
    
    % Get the coefficients for a quadratic cost
    [costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( myCosts , currentTime );

    Q_k     = costCoeff.Q;
    R_k     = costCoeff.R;
    S_k     = costCoeff.S;
    q_k     = costCoeff.q;
    r_k     = costCoeff.r;
    c_k     = costCoeff.c;
    
    r_k = 0*r_k;
    
    % Display an error message if all Cost Components are not included
    if not(flag_allCostComponentsIncluded)
        disp( ' ... ERROR: not all of the cost components could be retireived');
        disp( '            This likely because at least one of the components is NOT a quadratic or linear function');
        disp( '            and this ADP implementation can only handle linear or quadratic cost terms');
    end
    
    %n_x  = obj.stateDef.n_x;
    n_u  = obj.stateDef.n_u;
    %n_xi = obj.stateDef.n_xi;
    
    %x_lower = myConstraints.x_rect_lower;
    %x_upper = myConstraints.x_rect_upper;
    
    %internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';

    %x_lower = 20*internalStates + 14 * ~internalStates;
    %x_upper = 23*internalStates + 18 * ~internalStates;

    
    
    % TODO: this is a hack
    %x_lower = 0 * ones(n_x,1);
    %x_upper = 50 * ones(n_x,1);
    
    %u_lower = myConstraints.u_rect_lower;
    %u_upper = myConstraints.u_rect_upper;
    
    
    
    %% COMPUTE THE MPC CONTROL ACTIONS
    % We now compute the MPC Controller based on the expected value of the
    % uncertainty
    
    
    if obj.iterationCounter > obj.computeMPCEveryNumSteps
        
        % Reset the iteration counter to one
        obj.iterationCounter = uint32(1);
        
        % Specify the time horizon
        thisTimeHorizon = double(obj.statsPredictionHorizon);
    
        % The the predictions for the next time step
        %thisRange = 1 : n_xi;
        %Exi     = predictions.mean(thisRange,1);
        %Exixi   = predictions.cov(thisRange,thisRange);
        
        % Build the matrices for the MPC formulation        
        [R_new, r_new, c_new, A_new, Bu_new, Bxi_new] = Control_MPC_Local.buildMPCMatrices( thisTimeHorizon, x, obj.A, obj.Bu, obj.Bxi, Q_k, R_k, S_k, q_k, r_k, c_k, predictions.mean, predictions.cov );
        
        % Get the constraints
        [A_ineq_input, b_ineq_input] = Control_MPC_Local.buildMPC_inputConstraints_fromConstraintDefObject( thisTimeHorizon, obj.constraintDef );
        
        
        % NOW DEFINE AND SOLVE THE MPC OPTIMISATION FORMULATION
        
        % Specify the decision vector
        u_fullHorizon = sdpvar( double(n_u)*thisTimeHorizon , 1 , 'full' );
        
        % Specify the objective
        thisObj_fullHorizon = u_fullHorizon' * R_new * u_fullHorizon + r_new' * u_fullHorizon + c_new;
        
        % Specify the constraints
        thisCons_fullHorizon = [ A_ineq_input * u_fullHorizon <= b_ineq_input ];
        
        % Define the options
        thisOptions          = sdpsettings;
        thisOptions.debug    = false;
        thisOptions.verbose  = false;

        % Call the solver via Yalmip
        % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
        diagnostics = solvesdp(thisCons_fullHorizon,thisObj_fullHorizon,thisOptions);

        % Interpret the results
        if diagnostics.problem == 0
            %disp(' ... the optimisation formulation was Feasible and has been solved')
        elseif diagnostics.problem == 1
            disp(' ... the optimisation formulation was Infeasible');
            error(' Terminating :-( See previous messages and ammend');
        else
            disp(' ... the optimisation formulation was strange, it was neither "Feasible" nor "Infeasible", something else happened...');
            error(' Terminating :-( See previous messages and ammend');
        end
        
        obj.u_MPC_fullHorizon = double( u_fullHorizon );
        
    end
    
    % Select the u for this step within the MPC solution
    thisRange = ( (obj.iterationCounter - 1) * n_u + 1 ) : (obj.iterationCounter * n_u);
    u = obj.u_MPC_fullHorizon(thisRange,1);
    temp = 1;
    
end
% END OF FUNCTION