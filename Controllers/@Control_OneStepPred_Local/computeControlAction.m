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

 
    %% Extract the system matrices from the model
    myBuilding      = obj.model.building;
    myCosts         = obj.model.costDef;
    myConstraints   = obj.model.constraintDef;
    
    A       = sparse( myBuilding.building_model.discrete_time_model.A   );
    Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
    Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
    %Bxu     = myBuilding.building_model.discrete_time_model.Bxu;
    %Bxiu    = myBuilding.building_model.discrete_time_model.Bvu;
    
    Q       = myCosts.Q;
    R       = myCosts.R;
    S       = myCosts.S;
    q       = myCosts.q;
    r       = myCosts.r;
    c       = myCosts.c;
    
    
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
    
    % For the comfort score
    comfortRef = 22.5*[ones(7,1) ; zeros(n_x-7,1) ];
    xref = comfortRef;
    scalingOfComfortRelativeToEnergy = 1000;
    
    thisI = blkdiag(speye(7),speye(n_x-7));
    
    
    % Now formulate the optimisation problem to solve for u
    u = sdpvar( double(n_u) , 1 , 'full' );
    
    thisObj =   myCosts.r' * u ...
              + scalingOfComfortRelativeToEnergy * ( ...
                  x' * A'*thisI*A * x ...
                + u' * Bu'*thisI*Bu * u ...
                + trace( Bxi'*thisI*Bxi*Exixi ) ...
                + 2*x'*A'*thisI*Bu * u ...
                + 2*x'*A'*thisI*Bxi*Exi ...
                + 2*Exi'*Bxi'*thisI*Bu * u ...
                - 2 * xref' *A*x ...
                - 2 * xref' *Bu*u ...
                -2 * xref' *Bxi*Exi ...
                + xref'*xref ...
              );
    
	thisCons = ( myConstraints.u_all_A * u <= myConstraints.u_all_b );
          
    
        % Inform the user that we are about to call the solver
    %disp([' ... calling solver now (calling "',thisSolverStr,'" via Yalmip)'])
    
    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    diagnostics = solvesdp(thisCons,thisObj);

    % Interpret the results
    if diagnostics.problem == 0
        disp(' ... the optimisation formulation was Feasible and has been solved')
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