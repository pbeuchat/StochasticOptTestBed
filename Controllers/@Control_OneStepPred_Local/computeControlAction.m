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
    
    Exixi=Exi*Exi';
    
    if isempty(obj.optYalmip)
    
        % For the comfort score
        num_x_to_control = 42;
        comfortRef = 22.5*[ones(num_x_to_control,1) ; zeros(n_x-num_x_to_control,1) ];
        xref = comfortRef;
        %scalingOfComfortRelativeToEnergy = 100000;
        %thisI = blkdiag(speye(num_x_to_control),speye(n_x-num_x_to_control));


        % Now formulate the optimisation problem to solve for u
        %toControl = ~[1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
        toControl = [ ones(7,1) ; zeros(35,1) ];
        %num_x_to_cotnrol = length(toControl);
        %thisI = diag(toControl);

        %x_masked = toControl .* x;
        xref = toControl .* xref;

        % Define the yalmip variable
        u_opt = sdpvar( double(n_u) , 1 , 'full' );
        
        % Define the yalmip variable for the optimizer
        x_opt = sdpvar( double(n_x) , 1 , 'full' );
        
        % Compute the state update equation
        xplus_opt = A*x_opt + Bu * u_opt + Bxi * Exi;

        % Compute the objective function
        thisObj_opt = (xplus_opt.*toControl - xref)' * (xplus_opt.*toControl - xref);
        
        % Copmute the Constraints
        thisCons_opt = ( myConstraints.u_all_A * u_opt <= myConstraints.u_all_b );
        
        % Define the options
        thisOptions = sdpsettings;
        thisOptions.debug    = false;
        thisOptions.verbose  = false;
        
        % Create the "optimised" Yalmip function
        obj.optYalmip = optimizer(thisCons_opt,thisObj_opt,thisOptions,x_opt,u_opt);

        
    end
    
    
    % Inform the user that we are about to call the solver
    %disp([' ... calling solver now (calling "',thisSolverStr,'" via Yalmip)'])
    % Call the solver via Yalmip
    
    % Using the "optimised" Yalmip object to speed up the code
    u = obj.optYalmip{x};

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