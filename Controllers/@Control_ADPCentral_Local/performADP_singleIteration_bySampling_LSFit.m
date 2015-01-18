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

    %% FLAGS FOR WHICH LEAST SQUARE FITTING METHOD TO USE
    flag_full_01 = false;
    flag_full_02 = false;
    flag_diag_01 = true;

    %% INFER FROM SIZES FROM THE INPUTS
    n_x = length( x_lower );
    n_u = length( u_lower );

    %% COMPUTE THE NUMBER OF SAMPLES REQUIRED
    % ---------------------------------------- %
    % METHOD "FULL" 01
    if flag_full_01 || flag_full_02
        N_samples = 2 * ( n_x+1 )^2;
        %N_samples = 2*n_x;
        %N_samples = 1;
    elseif flag_diag_01
        N_samples = 2 * ( 2*n_x + 1 );
    end
    
    %% INITIALISE THE VARIABLES FOR SUMMING STUFF   
    
    % ---------------------------------------- %
    % METHOD "FULL" 01
    if flag_full_01
        sum_xxxx    = zeros(n_x,n_x);
        sum_xxx     = zeros(n_x^2,n_x);
        sum_xx      = zeros(n_x,n_x);
        sum_x       = zeros(n_x,1);
        sum_z       = zeros(1,1);
        sum_zz      = zeros(1,1);
        sum_xxz     = zeros(n_x,n_x);
        sum_xz      = zeros(n_x,1);
    
        
    % ---------------------------------------- %
    % METHOD "FULL" 02
    elseif flag_full_02
        sum_x1x1    = zeros(n_x+1,n_x+1);
        sum_x1x1x1x1= zeros(n_x+1,n_x+1);
        sum_x1x1z   = zeros(n_x+1,n_x+1);
        sum_zz      = zeros(1,1);
        
        
    % ---------------------------------------- %
    % METHOD "FULL" 02
    elseif flag_diag_01
        sum_all     = zeros( 1+1+n_x+n_x , 1+1+n_x+n_x );
    end
    
    
%% --------------------------------------------------------------------- %%
    %% BUILD AN "OPTIMIZED" YALMIP FUNCTION
    % Formulate an optimised Yalmip function for minimising the Bellman
    % operator given the coefficients of the quadratic value function, the
    % mean and covariance of the uncertainty, and the state x
    
    % Define a Yalmip variable for the "parameter" in the porblem
    x = sdpvar( double(n_x) , 1 , 'full' );
    
    % Define a Yalmip variable for the "optimisation variable" in the
    % problem
    u = sdpvar( double(n_u) , 1 , 'full' );
    
    % If "P_tp1", is input as a vector, then assume that it is the elemet
    % of a diagonal P-matrix
    if isvector(P_tp1)
        P_tp1 = sparse( 1:length(P_tp1) , 1:length(P_tp1) , P_tp1 , length(P_tp1) , length(P_tp1) , length(P_tp1) );
    end
    
    % Compute the objective function
    thisObj_optYal =   r' * u ...
                     + x' * A'  * P_tp1 * A  * x ...
                     + u' * Bu' * P_tp1 * Bu * u ...
                     + trace( Bxi' * P_tp1 * Bxi * Exixi ) ...
                     + 2 * x'   * A'   * P_tp1 * Bu  * u ...
                     + 2 * x'   * A'   * P_tp1 * Bxi * Exi ...
                     + 2 * Exi' * Bxi' * P_tp1 * Bu  * u ...
                     + p_tp1' * A   * x ...
                     + p_tp1' * Bu  * u ...
                     + p_tp1' * Bxi * Exi ...
                     + s_tp1;
        
    % Copmute the Constraints
    thisCons_optYal = ( obj.constraintDef.u_all_A * u <= obj.constraintDef.u_all_b );
    
    
    % Define the options
    thisOptions          = sdpsettings;
    thisOptions.debug    = false;
    thisOptions.verbose  = false;

    % Create the "optimised" Yalmip function
    % SYNTAX: optimisedSolver = optimizer(Constraints,Objective,options,parametricVariables,decisionVariables)
    optYalmip = optimizer(thisCons_optYal,thisObj_optYal,thisOptions,x,u);
    
    % Clear the "sdpvar"s so that we don't accidentallly refer to them
    % later
    clear x; clear u;
    
    
%% --------------------------------------------------------------------- %%    
    %% NOW STEP THROUGH THE SAMPLES
    % Print out a few things for where we are at:
    %fprintf(',  Sample=');
    
    
    % Step through the number of samples, building the cost function
    for iSamp = 1 : N_samples
    %parfor iSamp = 1 : N_samples
        
        % Print this Sample Number
        %fprintf('%8d',iSamp);
        
        % Get a sample
        x_samp = x_lower + (x_upper - x_lower) .* rand(n_x,1);

        % Solve the Bellman Operator for this sample
        % SYNTAX: [u,obj,c,d] = optYalmip{x_samp};
        [u_samp,~,~,~] = optYalmip{x_samp};
        
        % Compute the cost
        z =            r' * u_samp ...
                     + x_samp' * Q   * x_samp + q' * x_samp + c ...
                     + x_samp' * A'  * P_tp1 * A  * x_samp ...
                     + u_samp' * Bu' * P_tp1 * Bu * u_samp ...
                     + trace( Bxi' * P_tp1 * Bxi * Exixi ) ...
                     + 2 * x_samp'   * A'   * P_tp1 * Bu  * u_samp ...
                     + 2 * x_samp'   * A'   * P_tp1 * Bxi * Exi ...
                     + 2 * Exi' * Bxi' * P_tp1 * Bu  * u_samp ...
                     + p_tp1' * A   * x_samp ...
                     + p_tp1' * Bu  * u_samp ...
                     + p_tp1' * Bxi * Exi ...
                     + s_tp1;

                 
        % ---------------------------------------- %
        % METHOD "FULL" 01
        if flag_full_01
            xx = x_samp * x_samp';

            xx_reshaped_1 = reshape(xx,[ 1  n_x  1  n_x]);

            sum_xxxx    = sum_xxxx + xx * xx;
            sum_xxx     = sum_xxx  + reshape(bsxfun(@times,xx_reshaped_1,x_samp),[n_x*n_x n_x]);
            sum_xx      = sum_xx   + xx;
            sum_x       = sum_x    + x_samp;
            sum_z       = sum_z    + z;
            sum_zz      = sum_zz   + z^2;
            sum_xxz     = sum_xxz  + xx.*z;
            sum_xz      = sum_xz   + x_samp.*z;
            
            %sum_all = sum_all + [x2 ; x_samp ; 1 ; -this_d] * [x2' , x_samp' , 1 , -this_d];
        
        
        % ---------------------------------------- %
        % METHOD "FULL" 02
        elseif flag_full_02
            x1x1 = [1 ; x_samp] * [1 , x_samp'];

            sum_x1x1     = sum_x1x1     +  x1x1;
            sum_x1x1x1x1 = sum_x1x1x1x1 + (x1x1 * x1x1);
            sum_x1x1z    = sum_x1x1z    + (x1x1 * z);
            sum_zz       = sum_zz       + z^2;
            
            
        % ---------------------------------------- %
        % METHOD "DIAG" 01
        elseif flag_diag_01
            x2 = x_samp.^2;

            sum_all = sum_all +  [         z^2         ,   (-1) * z   ,   (-1) * (x_samp*z)'   ,   (-1) * ( x2 * z )'    ; ...
                                    (-1) * z           ,          1   ,           x_samp'      ,            x2'          ; ...
                                    (-1) * (x_samp*z)  ,      x_samp  ,   x_samp * x_samp'     ,        x_samp * x2'     ; ...
                                    (-1) * ( x2 * z )  ,        x2    ,       x2 * x_samp'     ,     x2 * x2'              ...
                                  ];
        end
        
        
        % Delete this Sample Number with backspaces
        %fprintf('\b\b\b\b\b\b\b\b');
        
    end
    
    % Delete ",  Sample=" with backspaces
    %fprintf('\b\b\b\b\b\b\b\b\b\b');
    
    
    
%% --------------------------------------------------------------------- %%
    %% NOW FORMULATE THE PROBLEM TO FIT A VALUE FUNCTION TO THE CLOUD OF POINTS
    
    
    %% Declare the "sdpvar"s for the new value function
    % ---------------------------------------- %
    % METHOD "FULL" 01 and 02
    if ( flag_full_01 || flag_full_02 )
        P = sdpvar( n_x , n_x ,'symmetric');
        p = sdpvar( n_x ,  1  ,'full');
        s = sdpvar(  1  ,  1  ,'full');
        
    
    % ---------------------------------------- %
    % METHOD "DIAG" 01
    elseif flag_diag_01
        P = sdpvar( n_x ,  1  ,'full');
        p = sdpvar( n_x ,  1  ,'full');
        s = sdpvar(  1  ,  1  ,'full');
    end
    
    
    
    %% Specify the "objective" and "constraint" functions
    % ---------------------------------------- %
    % METHOD "FULL" 01
    if flag_full_01
    % The objective function to minimise is a Least Squares fitting
%         thisObj =   vec(P')' * kron( speye(n_x) , sum_xxxx )  * vec(P) ...
%                   + p' * sum_xx * p ...
%                   + N_samples * s^2 ...
%                   + sum_zz ...
%                   + vec(P')' * 2    * sum_xxx * p ...
%                   + vec(P')' * 2    * vec( sum_xx ) * s ...
%                   + vec(P')' * (-2) * vec( sum_xxz ) ...
%                   + p' * 2 * sum_x * s ...
%                   + p' * (-2) * sum_xz ...
%                   + (-2) * sum_z * s;

        % This was MUCH faster     
        thisObj = [ vec(P)' , p' , s , 1 ] * ...
                  [  kron( speye(n_x) , sum_xxxx )   ,  sum_xxx          ,  vec( sum_xx )  ,  (-1) * vec( sum_xxz )  ; ...
                     sum_xxx'                        ,  sum_xx           ,  sum_x          ,  (-1) * sum_xz          ; ...
                     vec( sum_xx )'                  ,  sum_x'           ,  N_samples      ,  (-1) * sum_z           ; ...
                     (-1) * vec( sum_xxz )'          ,  (-1) * sum_xz'   ,  (-1) * sum_z   ,  sum_zz                   ...
                  ] * ...
                  [ vec(P) ; p ; s ; 1 ] .* 10^-8;
              
        % The constraint is for the P matrix to be positive semi-definite (PSD)
        % Note: this work for both dense and diagonal only P matrices
        thisCons = (P >= 0);
    
    
    
    % ---------------------------------------- %
    % METHOD "FULL" 02
    elseif flag_full_02
        % If we instead construct a combine "\hat{P}" matrix:
        P_hat = [ s , p' ; p , P ];

        thisObj = [ 1 , vec(P_hat)' ] * ...
                  [ sum_zz                   ,   (-1) * vec(sum_x1x1z)'                ;...
                    (-1) * vec(sum_x1x1z)    ,   kron( speye(n_x+1) , sum_x1x1x1x1 )    ...
                  ] * ...
                  [ 1 ; vec(P_hat) ] .* 10^-8;
        
              
        % The constraint is for the P matrix to be positive semi-definite (PSD)
        % Note: this work for both dense and diagonal only P matrices
        thisCons = (P >= 0);
              
              
        
    % ---------------------------------------- %
    % METHOD "DIAG" 01
    elseif flag_diag_01
        
        % Check what the biggest value in the sum_all matrix is
        sum_all_max = max(max(sum_all));
        orderOfMagnitude = floor( log10(sum_all_max) );
        
        
        
        % If the "P" matrix is restricted to be diagonal only, then the
        % objective function can be simplified slightly:
        thisObj = [1 , s , p' , P'] * sum_all * [1 ; s ; p ; P] .* 10^-(orderOfMagnitude-3);

        % The constraint is for the P matrix to be positive semi-definite (PSD)
        % Note: this work for both dense and diagonal only P matrices
        thisCons = (P >= 0);
    
    end
    
    
    %% Call Yalmip to solve for the next value function
    
    % Define the options
    thisOptions          = sdpsettings;
    thisOptions.debug    = true;
    thisOptions.verbose  = true;
    
    
    % Specify the solver
    %thisSolverStr = 'SeDuMi';
    thisSolverStr = 'Mosek';
    %thisSolverStr = 'sdpt3';
    if strcmp('SeDuMi',thisSolverStr)
        thisOptions.solver = 'sedumi';
    elseif strcmp('Mosek',thisSolverStr)
        thisOptions.solver = 'mosek-sdp';
    elseif strcmp('sdpt3',thisSolverStr)
        thisOptions.solver = 'sdpt3';
    else
        disp([' ... the specified solver "',thisSolverStr,'" was not recognised']);
        error(' Terminating :-( See previous messages and ammend');
    end

    
    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    diagnostics = solvesdp(thisCons,thisObj,thisOptions);

    
    % Interpret the results
    if diagnostics.problem == 0
        % Don't display anything if things work
        %disp(' ... the optimisation formulation was Feasible and has been solved')
    elseif diagnostics.problem == 1
        disp(' ... the optimisation formulation was Infeasible');
        error(' Terminating :-( See previous messages and ammend');
    else
        disp(' ... the optimisation formulation was strange, it was neither "Feasible" nor "Infeasible", something else happened...');
        error(' Terminating :-( See previous messages and ammend');
    end

    
    
    
    % ---------------------------------------- %
    % METHOD "FULL" 01 and 02
    if ( flag_full_01 || flag_full_02 )
        % Double check that P is positive semi-definite
        %minEigP = min( eig( double(Pnew) ) );
        %if minEigP < 0
        %    disp(' ... ERROR: The coefficient matrix P is not Positive Semi-Definite');
        %    error(' Terminating :-( See previous messages and ammend');
        %end
    
    % ---------------------------------------- %
    % METHOD "DIAG" 01
    elseif flag_diag_01
        if sum( double(P) < 0 ) > 0
            disp(' ... ERROR: The coefficient matrix P is not Positive Semi-Definite');
            error(' Terminating :-( See previous messages and ammend');
        end
        
    end
    
    
    
    %% STORE THE RESULTANT VALUE FUNCTION INTO THE RETURN VARIABLES
    
    
    % ---------------------------------------- %
    % METHOD "FULL" 01 and 02
    if ( flag_full_01 || flag_full_02 )
        Pnew = double( P );
        pnew = double( p );
        snew = double( s );
        
    
    % ---------------------------------------- %
    % METHOD "DIAG" 01
    elseif flag_diag_01
        Pnew = diag( double( P ) );
        pnew = double( p );
        snew = double( s );
        
    end
    
    
    temp = 1;
    
end
% END OF FUNCTION