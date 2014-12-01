function [Pnew , pnew, snew] = performADP_singleIteration_bySampling_LSFit( obj , P_tp1, p_tp1, s_tp1, Exi, Exixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper )
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

    %% INFER FROM SIZES FROM THE INPUTS
    n_x = length( x_lower );
    n_u = length( u_lower );

    %% COMPUTE THE NUMBER OF SAMPLES REQUIRED
    N_samples = ( n_x + n_u )^2;
    %N_samples = 3*n_x;
    
    % Decalare the Yalmip Variables
    P = sdpvar( n_x , 1 , 'full' );
    p = sdpvar( n_x , 1 , 'full' );
    s = sdpvar( 1   , 1 , 'full' );
    
    
    % Initialise the objective variable
    %thisObj = 0;
    
    % Initialise some variables
%     sum_x = 0;
%     sum_x2 = 0;
%     sum_xx = 0;
%     sum_xx2 = 0;
%     sum_x2x2 = 0;
%     sum_d = 0;
%     sum_dx = 0;
%     sum_dx2 = 0;
%     sum_d2 = 0;
    
    sum_all = 0;
    
    
    
    % Step through the number of samples, building the cost function
    for iSamp = 1 : N_samples
        % Get a sample
        x_samp = x_lower + (x_upper - x_lower) .* rand(n_x,1);
        u_samp = u_lower + (u_upper - u_lower) .* rand(n_u,1);
        
%         thisObj = thisObj + (   (x_samp.^2)'*P + p'*x_samp  +  s    ...
%                             - (   x_samp'*Q*x_samp + u_samp'*R*u_samp + 2*u_samp'*S*x_samp + q'*x_samp + r'*u_samp + c ...
%                                 + (A*x_samp + Bu*u_samp)' *diag(P_tp1)* (A*x_samp + Bu*u_samp + 2*Bxi*Exi) ...
%                                 + trace( Bxi'*diag(P_tp1)*Bxi*Exixi ) ...
%                                 + p_tp1'*A*x_samp + p_tp1'*Bu*u_samp + p_tp1'*Bxi*Exi + s_tp1 ...
%                               ) ...
%                             )^2;

        this_d =   x_samp'*Q*x_samp + u_samp'*R*u_samp + 2*u_samp'*S*x_samp + q'*x_samp + r'*u_samp + c ...
            + (A*x_samp + Bu*u_samp)' *diag(P_tp1)* (A*x_samp + Bu*u_samp + 2*Bxi*Exi) ...
            + trace( Bxi'*diag(P_tp1)*Bxi*Exixi ) ...
            + p_tp1'*A*x_samp + p_tp1'*Bu*u_samp + p_tp1'*Bxi*Exi + s_tp1;
                            

        x2 = x_samp.^2;
        
%         sum_x       = sum_x + x_samp';
%         sum_x2      = sum_x2 + x2';
%         sum_x2x2    = sum_x2x2 + x2 * x2';
%         sum_xx      = sum_xx + x_samp * x_samp';
%         sum_xx2     = sum_xx2 + x_samp * x2';
%         
%         sum_d       = sum_d + this_d;
%         sum_dx      = sum_dx + this_d * x_samp';
%         sum_dx2     = sum_dx2 + this_d * x2';
%         sum_d2      = sum_d2 + this_d * this_d;
        
        sum_all = sum_all + [x2 ; x_samp ; 1 ; -this_d] * [x2' , x_samp' , 1 , -this_d];

    end
    
    
%     thisObj =   P' * sum_x2x2 * P ...
%               + p' * sum_xx * p ...
%               + s * s ...
%               + 2 * p' * sum_xx2 * P ...
%               + 2 * s * sum_x2 * P ...
%               + 2 * s * sum_x * p ...
%               - 2 * sum_dx2 * P ...
%               - 2 * sum_dx * p ...
%               - 2 * sum_d * s ...
%               + sum_d2;
              

    thisObj = [P' , p' , s , 1] * sum_all * [P ; p ; s ; 1];

    
    % Initialise the constraint object
    thisCons = (P >= 0);
    % Add in the convex constraint that the P must be positve
    % (semi-definite)
    %for iElement = 1:n_x
    %end
    
%     % Specify the options
%     thisSolverStr = 'SeDuMi';
%     %thisSolverStr = 'Mosek';
%     %thisSolverStr = 'sdpt3';
%     if strcmp('SeDuMi',thisSolverStr)
%         thisOptions = sdpsettings('solver','sedumi','verbose',verboseOptDisplay);
%     elseif strcmp('Mosek',thisSolverStr)
%         thisOptions = sdpsettings('solver','mosek-sdp','verbose',verboseOptDisplay);
%     elseif strcmp('sdpt3',thisSolverStr)
%         thisOptions = sdpsettings('solver','sdpt3','verbose',verboseOptDisplay);
%     else
%         disp([' ... the specified solver "',thisSolverStr,'" was not recognised']);
%         error(' Terminating :-( See previous messages and ammend');
%     end

    
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

    % Double check that P is positive semi-definite
    %minEigP = min( eig( double(Pnew) ) );
    %if minEigP < 0
    %    disp(' ... ERROR: The coefficient matrix P is not Positive Semi-Definite');
    %    error(' Terminating :-( See previous messages and ammend');
    %end
    if sum( double(P) < 0 ) > 0
        disp(' ... ERROR: The coefficient matrix P is not Positive Semi-Definite');
        error(' Terminating :-( See previous messages and ammend');
    end
    
    Pnew = double( P );
    pnew = double( p );
    snew = double( s );
    
    
end
% END OF FUNCTION