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
    
    
    %% COMPUTE THE MPC CONTROL ACTIONS (when it is time)
    % We now compute the MPC Controller based on the expected value of the
    % uncertainty
    if obj.iterationCounter > obj.computeMPCEveryNumSteps
        
        % TEMPORATY TIMING USED FOR IMPROVING SPEED
        %temptime = clock;
        
        % Reset the iteration counter to one
        obj.iterationCounter = uint32(1);

        % THE FOLLOWING STEPS WERE DONE IN THE INITIALISATION
        % > Specify the time horizon
        % > Extract the system matrices from the model
        % > Extract the cost matrices from the model
        % > Build the matrices for the MPC formulation        
        % > Get the constraints
        % Although it is not generic enough to handle time-varying costs
        % and constraints
        
        
        %% LINEARISE THE BI-LINEAR TERMS
        
        if obj.flag_hasBilinearTerms
            % Choose a state about which to linearise
            x_to_linearise = sparse( 22.5 * obj.stateDef.internalStates + 16 * ~obj.stateDef.internalStates );

            % Creat a block diagonal version of the "x_to_linearise"
            x_to_linearise_cell = repmat({x_to_linearise}, 1, obj.n_u);
            x_to_linearise_blkdiag = blkdiag(x_to_linearise_cell{:});

            Bxu_linearised = obj.Bxu_stacked * x_to_linearise_blkdiag;


            % Choose a disturbance about which to linearise
            xi_to_linearise = predictions.mean;
            
            % Pre-allocate a cell for linearising "Bxiu" at each time step
            Bxiu_linearised = cell(obj.statsPredictionHorizon,1);
            
            % Iterate through the Time Horizon
            for iTime = 1:obj.statsPredictionHorizon
                this_xi_to_linearise = xi_to_linearise( (iTime-1)*obj.stateDef.n_xi+1 : iTime*obj.stateDef.n_xi , 1 );
                this_xi_to_linearise_cell = repmat({this_xi_to_linearise}, 1, obj.n_u);
                this_xi_to_linearise_blkdiag = blkdiag(this_xi_to_linearise_cell{:});

                Bxiu_linearised{iTime,1} = obj.Bxiu_stacked * this_xi_to_linearise_blkdiag;
            end
            
            % Call the function to build the updated MPC matrices
            buildMPCMatrices_updateForLinearisedTerms( obj, obj.statsPredictionHorizon, Bxu_linearised , Bxiu_linearised);
        
        end
            
        %% EQUATIONS FOR BUILDING THE COST FUNCTION IN TERMS OF "u" ONLY
        % R_new   =     R ...
        %             + Bu_new' * Q * Bu_new ...
        %             + Bu_new' * S';

        % r_new   =     r' ...
        %             + 2 * x0' * A_new' * Q * Bu_new ...
        %             + 2 * thisExi' * Bxi_new' * Q * Bu_new ...
        %             + x0' * A_new' * S' ...
        %             + q' * Bu_new;

        % c_new   =     x0' * A_new' * Q * A_new * x0 ...
        %             +  thisExi' * Bxi_new' * Q * Bxi_new * thisExi ...
        %             + 2 * x0' * A_new' * Q * Bxi_new * thisExi ...
        %             + q' * A_new * x0 ...
        %             + q' * Bxi_new * thisExi ...
        %             + c;
        
                
        % BUILD THE OBJECTIVE FROM THE PRE-COMPUTED OBJECTS
        %R_new = obj.R_mpc + obj.Bu_Q_Bu + obj.Bu_S;
        R_new = obj.Bu_Q_Bu;
        
        %r_new'  =        obj.r_mpc' ...
        %           + 2 * x' * obj.A_Q_Bu ...
        %           + 2 * predictions.mean' obj.Bxi_Q_Bu ...
        %           +     x' * obj.A_S ...
        %           +     obj.q_Bu;
        % NOTE: this equation above is already transposed!!
        r_new =  obj.r_mpc + 2 * obj.A_Q_Bu' * x  +  2 * obj.Bxi_Q_Bu' * predictions.mean  +  obj.q_Bu';
        
        % c_new   =         x' * obj.A_Q_A * x ...
        %             +     trace( obj.Bxi*Q*Bxi * predictions.cov ) ...
        %             + 2 * x' * obj.A_Q_Bxi * predictions.mean ...
        %             +     obj.q_A * x ...
        %             +     obj.q_Bxi * predictions.mean ...
        %             +     obj.c_mpc;
        c_new = 0;
        
        
        % TEMPORATY TIMING USED FOR IMPROVING SPEED
        %disp(['Building took: ',num2str( etime(clock,temptime) ) ]);
        
        % TEMPORATY TIMING USED FOR IMPROVING SPEED
        %temptime = clock;
        
        
        % Some things that need to be passed to the solver
        n_u_mpc = double(obj.n_u) * double(obj.statsPredictionHorizon);
        A_eq_input = sparse([],[],[],0,n_u_mpc,0);
        b_eq_input = sparse([],[],[],0,1,0);
        tempModelSense = 'min';
        tempVerboseOptDisplay = false;
                
        % Pass the problem to a solver
        % RETURN SYNTAX: [x , objVal, lambda, flag_solvedSuccessfully] = = solveQP_viaGurobi( H, f, c, A_ineq, b_ineq, A_eq, b_eq, lb, ub, inputModelSense, verboseOptDisplay )
        [temp_u , ~, ~, flag_solvedSuccessfully ] = opt.solveQP_viaGurobi( R_new, r_new, c_new, obj.A_ineq_input, obj.b_ineq_input, A_eq_input, b_eq_input, [], [], tempModelSense, tempVerboseOptDisplay );
        
        
        % TEMPORATY TIMING USED FOR IMPROVING SPEED
        %disp(['Computing took: ',num2str( etime(clock,temptime) ) ]);
        
        
        % Handle the case that the problem was not successfully solved
        if flag_solvedSuccessfully
            obj.u_MPC_fullHorizon = temp_u;
        else
            disp([' ... ERROR: The optimisation for MPC failed at time step: ',num2str(currentTime.index) ]);
            error(bbConstants.errorMsg);
        end
        
    end
    
    % Select the u for this step within the MPC solution
    thisRange = ( (obj.iterationCounter - 1) * obj.n_u + 1 ) : (obj.iterationCounter * obj.n_u);
    u = obj.u_MPC_fullHorizon(thisRange,1);
    
end
% END OF FUNCTION