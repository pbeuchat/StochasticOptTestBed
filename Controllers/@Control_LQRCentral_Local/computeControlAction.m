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



    %% INCREMENT THE ITERATION COUNTER
    obj.iterationCounter = obj.iterationCounter + uint32(1);

    %% Extract the system size from the state definition
    
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
    
    
    if ~obj.computeAllKsAtInitialisation
        
        if obj.iterationCounter > obj.computeKEveryNumSteps
        
            % Reset the iteration counter to one
            obj.iterationCounter = uint32(1);

            % Extraxt the systems details required
            myBuilding      = obj.model.building;
            myCosts         = obj.model.costDef;
            
            A       = sparse( myBuilding.building_model.discrete_time_model.A   );
            Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
            Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
            %Bxu     = myBuilding.building_model.discrete_time_model.Bxu;
            %Bxiu    = myBuilding.building_model.discrete_time_model.Bvu;

            % Get the coefficients for a quadratic cost
            flag_requestCostCoeff = false;
            if flag_requestCostCoeff
                % SYNTAX: "[costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( myCosts , currentTime )"
                [costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( myCosts , currentTime );

                Q       = costCoeff.Q;
                R       = costCoeff.R;
                S       = costCoeff.S;
                q       = costCoeff.q;
                r       = costCoeff.r;
                c       = costCoeff.c;
            else
                Q       = obj.costCoeff_Q;
                R       = obj.costCoeff_R;
                S       = obj.costCoeff_S;
                q       = obj.costCoeff_q;
                r       = obj.costCoeff_r;
                c       = obj.costCoeff_c;

                flag_allCostComponentsIncluded = true;
            end

            % APPLY THE ENERGY TO COMFORT SCALING
            % If the "S" term is non-zero then this scaling doesn't make as
            % much sense
            r = obj.energyToComfortScaling*r;
            %R = obj.energyToComfortScaling*R;

            % Display an error message if all Cost Components are not included
            if not(flag_allCostComponentsIncluded)
                disp( ' ... ERROR: not all of the cost components could be retireived');
                disp( '            This likely because at least one of the components is NOT a quadratic or linear function');
                disp( '            and this ADP implementation can only handle linear or quadratic cost terms');
            end
            

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

            % > To be the solution of the Lyapunov Equation for this
            % system (ie. the infinte horizon autonomous cost to go)
            % Note: this only work if the system is stable
            %P_lyapunov = dlyap(A,Q);                
            % BUT DOES THIS MAKE SENSE?? Because we want to penalise
            % stable autonomous decay to the set-point, not to zero??


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

                % Pass everything to a LQR Recursion Method
                discountFactor = 1;
                [Pnew , pnew, snew, u0new, Knew] = Control_LQRCentral_Local.performLQR_singleIteration( discountFactor, thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c );

                obj.P{iTime,1} = Pnew;
                obj.p{iTime,1} = pnew;
                obj.s{iTime,1} = snew;

                obj.K{iTime,1} = [u0new , Knew];

                % Delete this time step with backspaces
                %fprintf(' \b\b\b\b\b\b\b\b');

            end


        end   % END OF: "if obj.iterationCounter > obj.computeVEveryNumSteps"
        
    else
        % If we go beyond the "number of Value Functions initialised", then
        % (Note: "numVsInitialised" is set to be the Full Cycle Time of the
        % disturbance model)
        if obj.iterationCounter > obj.numKsInitialised
            % Reset the iteration counter to one
            obj.iterationCounter = uint32(1);
        end
    end   % END OF: "if ~obj.computeAllKsAtInitialisation"
    
    
    %% COMPUTE THE UNCONSTRAINED CONTROL ACTION: u = u0 + K x
    thisK = obj.K{obj.iterationCounter,1};
    u = thisK * [1 ; x];


    %% APPLY THE INPUT CONSTRAINTS TO MAP "u" BACK INTO "\mathcal{U}" (if required)

    % Extract the constraint definition from the model
    myConstraints   = obj.model.constraintDef;
    
    % Check if the LQR input violtes any of the constraints
    violatingIndices_all_01 = (myConstraints.u_all_A * u > myConstraints.u_all_b);
    if any(violatingIndices_all_01)
    
        flag_specifiedClippingMethodFailed = true;
        if strcmp( obj.clippingMethod , 'closest_2norm' )
            % Formulate an optimisation to map "u" to the nearest point in the
            % constraint (where the euclidian norm based defines nearest)
            H_tomapu = speye( n_u );
            f_tomapu = -2*u;
            c_tomapu = u'*u;

            % Some things that need to be passed to the solver
            A_eq_input = sparse([],[],[],0,double(n_u),0);
            b_eq_input = sparse([],[],[],0,1,0);
            tempModelSense = 'min';
            tempVerboseOptDisplay = false;

            % Pass the problem to a solver
            % RETURN SYNTAX: [x , objVal, lambda, flag_solvedSuccessfully] = = solveQP_viaGurobi( H, f, c, A_ineq, b_ineq, A_eq, b_eq, lb, ub, inputModelSense, verboseOptDisplay )
            [u_closest , ~, ~, flag_solvedSuccessfully ] = opt.solveQP_viaGurobi( H_tomapu, f_tomapu, c_tomapu, myConstraints.u_all_A, myConstraints.u_all_b, A_eq_input, b_eq_input, [], [], tempModelSense, tempVerboseOptDisplay );

            % Check that this closest "u" doesn't violate any of the constraints
            if flag_solvedSuccessfully
                threshhold = 10e-4;
                violatingIndices_all_02 = (myConstraints.u_all_A * u_closest - myConstraints.u_all_b > threshhold);
                if any(violatingIndices_all_02)
                    flag_manuallyMapU = true;
                else
                    u = u_closest;
                    flag_manuallyMapU = false;
                end
            else
                flag_manuallyMapU = true;
            end
        else
            flag_manuallyMapU = true;
            flag_specifiedClippingMethodFailed = false;
        end

        if flag_manuallyMapU
            if flag_specifiedClippingMethodFailed
                disp( ' ... ERROR: this is wierd. The closest point mapping did NOT return a solution within the feasible constraint set!!!' );
            end
            % First apply any "per-dimension" clipping based on any "box" or
            % "hyper-rectangle" sets
            if myConstraints.flag_inc_u_box
                violatingIndices_above = ( u > myConstraints.u_box );
                if any(violatingIndices_above)
                    u(violatingIndices_above) = myConstraints.u_box(violatingIndices_above);
                end
                violatingIndices_below = ( u < -myConstraints.u_box );
                if any(violatingIndices_below)
                    u(violatingIndices_below) = -myConstraints.u_box(violatingIndices_below);
                end
            end

            if myConstraints.flag_inc_u_rect
                violatingIndices_above = ( u > myConstraints.u_rect_upper );
                if any(violatingIndices_above)
                    u(violatingIndices_above) = myConstraints.u_rect_upper(violatingIndices_above);
                end
                violatingIndices_below = ( u < myConstraints.u_rect_lower );
                if any(violatingIndices_below)
                    u(violatingIndices_below) = -myConstraints.u_rect_lower(violatingIndices_below);
                end
            end

            % Second check with of the polytopic constraints are violated post
            % clipping
            if myConstraints.flag_inc_u_poly
                violatingIndices_poly = ( myConstraints.u_poly_A * u > myConstraints.u_poly_b );
                if any(violatingIndices_poly)
                    % Map "u" back to be inside the violated constraints
                    violatingIndex = find(violatingIndices_poly);
                    % Step through the violating indicies
                    for iIndex = 1:length(violatingIndex)
                        thisIndex = violatingIndex(iIndex);
                        thisa = myConstraints.u_poly_A(thisIndex,:);
                        thisb = myConstraints.u_poly_b(thisIndex,1);
                        % Compute the "amount" of violation (should be > 0)
                        thisViolationAmount = myConstraints.u_poly_A(thisIndex,:) * u - thisb;
                        % Get a logical index flag to the non-zero components of
                        % "A"
                        thisa_nonZero = ( thisa ~= 0 )';
                        % Noramlise the row of "A"
                        % Map the elements of "u" proportional to their factor in 
                        % "A"
                        thisa_sum = sum( thisa(thisa_nonZero') ) * 0.99;
                        u(thisa_nonZero) = u(thisa_nonZero) - thisa(thisa_nonZero')' .* thisViolationAmount ./ thisa_sum;
                    end
                    % Check that this mapping didn't violate any other constraints
                    violatingIndices_all_03 = (myConstraints.u_all_A * u > myConstraints.u_all_b);
                    if any(violatingIndices_all_03)
                        disp( ' ... ERROR: it was attempted to map the input "u" back into the feasible input set' );
                        disp( '            BUT, it did NOT work and an infeasible "u" is being requested' );
                        disp( '            The violated constraints are:' );
                        diplay( myConstraints.u_all_label(violatingIndices_all_03,1) );
                    end
                 end
            end
        end
    end % END OF: "if any(violatingIndices_all_01)"
    
end
% END OF FUNCTION