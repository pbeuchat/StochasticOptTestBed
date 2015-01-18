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
    
    A       = sparse( myBuilding.building_model.discrete_time_model.A   );
    Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
    Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
    %Bxu     = myBuilding.building_model.discrete_time_model.Bxu;
    %Bxiu    = myBuilding.building_model.discrete_time_model.Bvu;
    
    % Get the coefficients for a quadratic cost
    [costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( myCosts , currentTime );

    Q       = costCoeff.Q;
    R       = costCoeff.R;
    S       = costCoeff.S;
    q       = costCoeff.q;
    r       = costCoeff.r;
    c       = costCoeff.c;
    
    r = 0*r;
    
    % Display an error message if all Cost Components are not included
    if not(flag_allCostComponentsIncluded)
        disp( ' ... ERROR: not all of the cost components could be retireived');
        disp( '            This likely because at least one of the components is NOT a quadratic or linear function');
        disp( '            and this ADP implementation can only handle linear or quadratic cost terms');
    end
    
    n_x  = obj.stateDef.n_x;
    n_u  = obj.stateDef.n_u;
    n_xi = obj.stateDef.n_xi;
    
    %x_lower = myConstraints.x_rect_lower;
    %x_upper = myConstraints.x_rect_upper;
    
    internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';

    x_lower = 20*internalStates + 14 * ~internalStates;
    x_upper = 23*internalStates + 18 * ~internalStates;

    
    
    % TODO: this is a hack
    %x_lower = 0 * ones(n_x,1);
    %x_upper = 50 * ones(n_x,1);
    
    u_lower = myConstraints.u_rect_lower;
    u_upper = myConstraints.u_rect_upper;
    
    
    
    %% COMPUTE THE VALUE FUNCTIONS
    % We now need to compute the Value Functions for the next 
    % "obj.statsPredictionHorizon" time steps by stepping backwards through
    % the time horizon, given that we have E[\xi] and E[\xi\xi'] for each
    % time step
    
    % Define a few flags for how to run the computations
    %mask_P = diag( true(n_x,1) );
    
    if obj.iterationCounter > obj.computeVEveryNumSteps
        
        % Reset the iteration counter to one
        obj.iterationCounter = uint32(1);
    
        % Initialise the TERMINAL VALUE FUNCITON needed for the first
        % iteration
        % To be a zero value function
        %obj.P{obj.statsPredictionHorizon+1} = sparse( [],[],[], double(n_x) , 1 , 0 );
        %obj.p{obj.statsPredictionHorizon+1} = sparse( [],[],[], double(n_x) , 1 , 0 );
        %obj.s{obj.statsPredictionHorizon+1} = sparse( [],[],[], 1 , 1 , 0 );

        % To be purely the comfort cost
        obj.P{obj.statsPredictionHorizon+1} = Q;
        obj.p{obj.statsPredictionHorizon+1} = 0.5*q;
        obj.s{obj.statsPredictionHorizon+1} = c;
        
        % Print out a few things for where we are at:
        %mainfprintf('T=');

        % Now iterate backwards through the time steps
        for iTime = obj.statsPredictionHorizon : -1 : 1
            
            % Print this time step
            %fprintf('%8d',iTime);
            
            % Get the first and second moment from the input prediciton struct
            thisRange = ((iTime-1)*n_xi+1) : (iTime*n_xi);
            thisExi     = predictions.mean(thisRange,1);
            thisExixi   = predictions.cov(thisRange,thisRange);

            % Get the value function for the future time step
            thisP = obj.P{obj.statsPredictionHorizon+1};
            thisp = obj.p{obj.statsPredictionHorizon+1};
            thiss = obj.s{obj.statsPredictionHorizon+1};

            % Pass everything to a ADP Sampling method
            [Pnew , pnew, snew] = performADP_singleIteration_byBellmanIneq( obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper );
            
            obj.P{iTime,1} = Pnew;
            obj.p{iTime,1} = pnew;
            obj.s{iTime,1} = snew;

            % Delete this time step with backspaces
            %fprintf(' \b\b\b\b\b\b\b\b');
            
        end
        
        % Delete "T=" with backspaces
        %fprintf('\b\b');
    end
    
    % Get the value function coefficiens to use for this time step
    thisP = obj.P{obj.iterationCounter,1};
    thisp = obj.p{obj.iterationCounter,1};
    thiss = obj.s{obj.iterationCounter,1};
    
    % The the predictions for the next time step
    thisRange = 1 : n_xi;
    Exi     = predictions.mean(thisRange,1);
    Exixi   = predictions.cov(thisRange,thisRange);
    
    
    % Now formulate the optimisation problem to solve for u
    u = sdpvar( double(n_u) , 1 , 'full' );
    
    thisObj =   r' * u ...
              + x' * Q * x + q' * x + c ...
              + u' * Bu'*thisP*Bu * u ...
              + (2*x'*A'*thisP + 2*Exi'*Bxi'*thisP + 2*thisp') * Bu * u ...
              + x'*A'*thisP*A*x ...
              + trace( Bxi'*thisP*Bxi*Exixi ) ...
              + 2*x'*A'*thisP*Bxi*Exi ...
              + 2*thisp'*A*x ...
              + 2*thisp'*Bxi*Exi ...
              + thiss;
    
	thisCons = ( myConstraints.u_all_A * u <= myConstraints.u_all_b );
          
    
        % Inform the user that we are about to call the solver
    %disp([' ... calling solver now (calling "',thisSolverStr,'" via Yalmip)'])
    
    % Define the options
    thisOptions          = sdpsettings;
    thisOptions.debug    = false;
    thisOptions.verbose  = false;
    
    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    diagnostics = solvesdp(thisCons,thisObj,thisOptions);

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

    u = double( u );
    temp = 1;
    
end
% END OF FUNCTION