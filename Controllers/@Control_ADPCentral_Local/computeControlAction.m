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
    
    
    %% COMPUTE THE VALUE FUNCTIONS
    % We now need to compute the Value Functions for the next 
    % "obj.statsPredictionHorizon" time steps by stepping backwards through
    % the time horizon, given that we have E[\xi] and E[\xi\xi'] for each
    % time step
    
    % Define a few flags for how to run the computations
    %mask_P = diag( true(n_x,1) );
    
    
    if ~obj.computeAllVsAtInitialisation
        
        if obj.iterationCounter > obj.computeVEveryNumSteps
        
            % Reset the iteration counter to one
            obj.iterationCounter = uint32(1);

            % SPECIFY THE FITTIG RANGE
            %x_lower = myConstraints.x_rect_lower;
            %x_upper = myConstraints.x_rect_upper;

            internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';

            x_lower = obj.VFitting_xInternal_lower * internalStates  +  obj.VFitting_xExternal_lower * ~internalStates;
            x_upper = obj.VFitting_xInternal_upper * internalStates  +  obj.VFitting_xExternal_upper * ~internalStates;

            %x_lower = 10 * internalStates  +  10 * ~internalStates;
            %x_upper = 30 * internalStates  +  20 * ~internalStates;


            % TODO: this is a hack
            %x_lower = 0 * ones(n_x,1);
            %x_upper = 50 * ones(n_x,1);

            u_lower = myConstraints.u_rect_lower;
            u_upper = myConstraints.u_rect_upper;


            % Initialise the TERMINAL VALUE FUNCITON needed for the first
            % iteration
            % To be a zero value function
            %obj.P{obj.statsPredictionHorizon+1} = sparse( [],[],[], double(n_x) , 1 , 0 );
            %obj.p{obj.statsPredictionHorizon+1} = sparse( [],[],[], double(n_x) , 1 , 0 );
            %obj.s{obj.statsPredictionHorizon+1} = sparse( [],[],[], 1 , 1 , 0 );

            % To be purely the comfort cost
            obj.P{obj.statsPredictionHorizon+1} = Q;
            obj.p{obj.statsPredictionHorizon+1} = q;  % <<---- NOTE THE "0.5" HERE, OR THE LACK OF IT!!!!
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
                thisP = obj.P{iTime+1};
                thisp = obj.p{iTime+1};
                thiss = obj.s{iTime+1};

                % Pass everything to a ADP Sampling method
                if obj.useMethod_samplingWithLSFit
                    [Pnew , pnew, snew] = performADP_singleIteration_bySampling_LSFit(  obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper , obj.PMatrixStructure );
                elseif obj.useMethod_bellmanIneq
                    [Pnew , pnew, snew] = performADP_singleIteration_byBellmanIneq(     obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper , obj.PMatrixStructure);
                else
                    disp( ' ... ERROR: the selected ADP method was NOT recognised');
                    Pnew = 0 * thisP; pnew = 0 * pnew; snew = 0 * thiss;
                end

                obj.P{iTime,1} = Pnew;
                obj.p{iTime,1} = pnew;
                obj.s{iTime,1} = snew;

                % Delete this time step with backspaces
                %fprintf(' \b\b\b\b\b\b\b\b');

            end


        end   % END OF: "if obj.iterationCounter > obj.computeVEveryNumSteps"
        
    else
        % If we go beyond the "number of Value Functions initialised", then
        % (Note: "numVsInitialised" is set to be the Full Cycle Time of the
        % disturbance model)
        if obj.iterationCounter > obj.numVsInitialised
            % Reset the iteration counter to one
            obj.iterationCounter = uint32(1);
        end
    end   % END OF: "if ~obj.computeAllVsAtInitialisation"
    
    
    % Get the value function coefficiens to use for this time step
    thisP = obj.P{obj.iterationCounter,1};
    thisp = obj.p{obj.iterationCounter,1};
    thiss = obj.s{obj.iterationCounter,1};
    
    % The the predictions for the next time step
    thisRange = 1 : n_xi;
    Exi     = predictions.mean(thisRange,1);
    Exixi   = predictions.cov(thisRange,thisRange);
    
    
    R_new = sparse( Bu'*thisP*Bu );
    r_new = (2*x'*A'*thisP + 2*Exi'*Bxi'*thisP + thisp') * Bu;
    r_new = r_new';
    c_new = 0;
    
    % Some things that need to be passed to the solver
    A_eq_input = sparse([],[],[],0,double(n_u),0);
    b_eq_input = sparse([],[],[],0,1,0);
    tempModelSense = 'min';
    tempVerboseOptDisplay = false;

    % Pass the problem to a solver
    % RETURN SYNTAX: [x , objVal, lambda, flag_solvedSuccessfully] = = solveQP_viaGurobi( H, f, c, A_ineq, b_ineq, A_eq, b_eq, inputModelSense, verboseOptDisplay )
    [u , ~, ~, flag_solvedSuccessfully ] = opt.solveQP_viaGurobi( R_new, r_new, c_new, myConstraints.u_all_A, myConstraints.u_all_b, A_eq_input, b_eq_input, tempModelSense, tempVerboseOptDisplay );
    
    
    % Handle the case that the problem was not successfully solved
    if ~flag_solvedSuccessfully
        disp([' ... ERROR: The optimisation for "u" via  ADP failed at time step: ',num2str(currentTime.index) ]);
        error(bbConstants.errorMsg);
    end
    
    
%     % Now formulate the optimisation problem to solve for u
%     u = sdpvar( double(n_u) , 1 , 'full' );
%     
%     thisObj =   r' * u ...
%               + x' * Q * x + q' * x + c ...
%               + u' * Bu'*thisP*Bu * u ...
%               + (2*x'*A'*thisP + 2*Exi'*Bxi'*thisP + thisp') * Bu * u ...
%               + x'*A'*thisP*A*x ...
%               + trace( Bxi'*thisP*Bxi*Exixi ) ...
%               + 2*x'*A'*thisP*Bxi*Exi ...
%               + thisp'*A*x ...
%               + thisp'*Bxi*Exi ...
%               + thiss;
%     
% 	thisCons = ( myConstraints.u_all_A * u <= myConstraints.u_all_b );
%           
%     
%         % Inform the user that we are about to call the solver
%     %disp([' ... calling solver now (calling "',thisSolverStr,'" via Yalmip)'])
%     
%     % Define the options
%     thisOptions          = sdpsettings;
%     thisOptions.debug    = false;
%     thisOptions.verbose  = false;
%     
%     % Call the solver via Yalmip
%     % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
%     diagnostics = solvesdp(thisCons,thisObj,thisOptions);
% 
%     % Interpret the results
%     if diagnostics.problem == 0
%         %disp(' ... the optimisation formulation was Feasible and has been solved')
%     elseif diagnostics.problem == 1
%         disp(' ... the optimisation formulation was Infeasible');
%         error(' Terminating :-( See previous messages and ammend');
%     else
%         disp(' ... the optimisation formulation was strange, it was neither "Feasible" nor "Infeasible", something else happened...');
%         error(' Terminating :-( See previous messages and ammend');
%     end
% 
%     u = double( u );
%     temp = 1;
    
end
% END OF FUNCTION