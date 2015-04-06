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



 
    %% Extract the system matrices from the model
    %myBuilding      = obj.model.building;
    myCosts         = obj.model.costDef;
    myConstraints   = obj.model.constraintDef;
    
    A       = obj.A;
    Bu      = obj.Bu;
    Bxi     = obj.Bxi;
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
    
    r = 0 * r;
    
    n_x  = obj.stateDef.n_x;
    n_u  = obj.stateDef.n_u;
    n_xi = obj.stateDef.n_xi;
    
    x_lower = myConstraints.x_rect_lower;
    x_upper = myConstraints.x_rect_upper;
    u_lower = myConstraints.u_rect_lower;
    u_upper = myConstraints.u_rect_upper;
    
    
    
    %% COMPUTE THE CONTROL
    
    
    % The the predictions for the next time step
    thisRange = 1 : n_xi;
    Exi     = predictions.mean(thisRange,1);
    Exixi   = predictions.cov(thisRange,thisRange);
    
    %Exixi=Exi*Exi';
    
    if isempty(obj.optYalmip)
    
%         % For the comfort score
%         num_x_to_control = 42;
%         comfortRef = 22.5*[ones(num_x_to_control,1) ; zeros(n_x-num_x_to_control,1) ];
%         xref = comfortRef;
%         
%         %scalingOfComfortRelativeToEnergy = 100000;
%         %thisI = blkdiag(speye(num_x_to_control),speye(n_x-num_x_to_control));
% 
% 
%         % Now formulate the optimisation problem to solve for u
%         %toControl = ~[1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
%         toControl = [ ones(7,1) ; zeros(35,1) ];
%         %num_x_to_cotnrol = length(toControl);
%         %thisI = diag(toControl);
% 
%         %x_masked = toControl .* x;
%         xref = toControl .* xref;

        % Define the yalmip variable
        u_opt = sdpvar( double(n_u) , 1 , 'full' );
        
        % Define the yalmip variable for the optimizer
        x_opt = sdpvar( double(n_x) , 1 , 'full' );
        
        % Define the yalmip variable for the optimizer
        Exi_opt = sdpvar( double(n_xi) , 1 , 'full' );
        
        % Compute the state update equation
        xplus_opt = A*x_opt + Bu * u_opt + Bxi * Exi_opt;

        % Compute the objective function
        %thisObj_opt = (xplus_opt.*toControl - xref)' * (xplus_opt.*toControl - xref);
        thisObj_opt = xplus_opt' * Q * xplus_opt + q' * xplus_opt + c + r' * u_opt;
        
        
        % THIS IS FUNDAMENTALLY WRONG!!! BECAUSE IT IS NOT USING THE NEW
        % Exi information at each time step!!!!!!!!!!!!
        
        
        
        % Copmute the Constraints
        thisCons_opt = ( myConstraints.u_all_A * u_opt <= myConstraints.u_all_b );
        
        % Define the options
        thisOptions = sdpsettings;
        thisOptions.debug    = false;
        thisOptions.verbose  = false;
        
        % Create the "optimised" Yalmip function
        obj.optYalmip = optimizer(thisCons_opt,thisObj_opt,thisOptions,[x_opt;Exi_opt],u_opt);

        
    end
    
    
    % Inform the user that we are about to call the solver
    %disp([' ... calling solver now (calling "',thisSolverStr,'" via Yalmip)'])
    % Call the solver via Yalmip
    
    % Using the "optimised" Yalmip object to speed up the code
    u = obj.optYalmip{[x;Exi]};

    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    %diagnostics = solvesdp(thisCons,thisObj,thisOptions);
    
    % Interpret the results
%     if diagnostics.problem == 0
%         % Display nothing if it works
%         %disp(' ... the optimisation formulation was Feasible and has been solved')
%     elseif diagnostics.problem == 1
%         disp(' ... the optimisation formulation was Infeasible');
%         error(' Terminating :-( See previous messages and ammend');
%     else
%         disp(' ... the optimisation formulation was strange, it was neither "Feasible" nor "Infeasible", something else happened...');
%         disp('     The following info was provided from Yalmip about the problem:');
%         disp( diagnostics.info );
%         error(' Terminating :-( See previous messages and ammend');
%     end

    %u = double( u );
    temp = 1;
    
end
% END OF FUNCTION