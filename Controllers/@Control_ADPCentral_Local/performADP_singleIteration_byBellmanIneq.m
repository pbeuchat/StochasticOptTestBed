function [Pnew , pnew, snew] = performADP_singleIteration_byBellmanIneq( obj , P_tp1, p_tp1, s_tp1, Exi, Exixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper )
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

    %% DIVIDE "p_tp1" BY 2 (and multiply the result by 2 at the end)
    p_tp1 = 0.5 * p_tp1;

    %% FLAGS FOR WHICH LEAST SQUARE FITTING METHOD TO USE
    flag_full_01 = true;
    flag_full_02 = false;
    flag_diag_01 = false;

    %% INFER FROM SIZES FROM THE INPUT VARIABLES
    n_x = size(A,1);
    n_u = size(Bu,2);
    %n_xi = size(Bxi,2);
    
    
    %% NOW FORMULATE THE PROBLEM FOR THE VALUE FUNCTION
    
    % Implement the ADP computation using
    % > Bellman's Inequality
    % > Finite Horizon
    % > Quadratic Value Function
    % > Linear system dynamics
    % > Adjustable polynomial order for the multiplier is the S-procedure

    
%% --------------------------------------------------------------------- %%
%% SPECIFY SOME SETTINGS
    
    % > Specify the polynomial order for the multiplier is the S-procedure
    polyOrderOfMultipliers = 0;

    
    
    
%% --------------------------------------------------------------------- %%
%% EXTRACT THE DETAILS FROM THE INPUTS AND PROPERTIES OF THIS OBJECT
    %myBuilding      = obj.model.building;
    %myCosts         = obj.model.costDef;
    myConstraints   = obj.model.constraintDef;
    
%     A       = sparse( myBuilding.building_model.discrete_time_model.A   );
%     Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
%     Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
    
%     n_x = size(A,1);
%     n_u = size(Bu,2);
%     n_xi = size(Bxi,2);
    
%     Exi     = predictions.mean(1:n_xi);
%     Exixi   = predictions.cov(1:n_xi,1:n_xi);
    
    
%% --------------------------------------------------------------------- %%
%% COMPUTE THE SIZE OF THE PROBLEM

    % To be used to dimensioning things
    %n_z = 1 + n_x + n_u;

    
%% --------------------------------------------------------------------- %%
%% DEFINE THE DISCOUNT FACTOR
    
    % Only required if doing infinte horizon ...
    disFactor = 1.0;


%% --------------------------------------------------------------------- %%
%% BUILD THE MATRIX FOR "V(f(x,u,xi))"
   
    Vhatf = [ A' * P_tp1 * A ,...
                    A' * P_tp1 * Bu ,...
                    A' * p_tp1 + A' * P_tp1 * Bxi * Exi ;...
              Bu' * P_tp1 * A ,...
                    Bu' * P_tp1 * Bu ,...
                    Bu' * p_tp1 + Bu' * P_tp1 * Bxi * Exi ;...
              p_tp1' * A + Exi' * Bxi' * P_tp1 * A ,...
                    p_tp1' * Bu + Exi' * Bxi' * P_tp1 * Bu ,...
                    s_tp1 + p_tp1' * Bxi * Exi + trace(Bxi' * P_tp1 * Bxi * Exixi) ...
            ];
       

%% --------------------------------------------------------------------- %%
%% BUILD THE COST MATRIX

%     Lhat =  [  costCoeff.c   ,   costCoeff.q'   ,   costCoeff.r'   ;...
%                     costCoeff.q   ,   costCoeff.Q    ,   costCoeff.S'   ;...
%                     costCoeff.r   ,   costCoeff.S    ,   costCoeff.R     ...
%                  ];
    
    Lhat = ...
             [            Q    ,   0.5 * S'   ,   0.5 * q   ;...
                    0.5 * S    ,         R    ,   0.5 * r   ;...
                    0.5 * q'   ,   0.5 * r'   ,         c    ...
                 ];
    
    
%% --------------------------------------------------------------------- %%
%% GET THE NUMBER OF CONSTRAINTS

    numCons = 0;

    % Compute the number of constraints
    if myConstraints.flag_inc_x_rect
        numCons = numCons + n_x;
    end
    
    if myConstraints.flag_inc_u_rect
        numCons = numCons + n_u;
    end
    
    if myConstraints.flag_inc_u_poly
        numCons = numCons + size(myConstraints.u_poly_b,1);
    end

    % Initiliase a cell array to store the matrix co-efficient for each
    % constrait
    constraintCoefficient = cell(numCons,1);
    thisCon = 0;

    if myConstraints.flag_inc_x_rect
        % THE QUADRATIC CONSTRAINT PER COMPONENT IS:
        %   0 <= -x_i^2 + x_i (x_i,upper + x_i,lower) - (x_i,upper * x_i,lower)
        for iCons = 1:n_x
            thisMask = sparse( iCons , 1 , true , n_x , 1 , 1 );
            %this_lower = myConstraints.x_rect_lower(iCons,1);
            %this_upper = myConstraints.x_rect_upper(iCons,1);
            this_lower = x_lower(iCons,1);
            this_upper = x_upper(iCons,1);
            thisCon = thisCon + 1;
            constraintCoefficient{thisCon,1} = ...
                    [   -1 * diag(thisMask)                 ,  sparse([],[],[],n_x,n_u,0)   ,    (this_lower+this_upper)*thisMask    ;...
                         sparse([],[],[],n_u,n_x,0)         ,  sparse([],[],[],n_u,n_u,0)   ,    sparse([],[],[],n_u,1,0)            ;...
                         (this_lower+this_upper)*thisMask'  ,  sparse([],[],[],1  ,n_u,0)   ,   -(this_lower*this_upper)             ...
                    ];
        end
    end
    
    if myConstraints.flag_inc_u_rect
        for iCons = 1:n_u
            thisMask = sparse( iCons , 1 , true , n_u , 1 , 1 );
            %this_lower = myConstraints.u_rect_lower(iCons,1);
            %this_upper = myConstraints.u_rect_upper(iCons,1);
            this_lower = u_lower(iCons,1);
            this_upper = u_upper(iCons,1);
            thisCon = thisCon + 1;
            constraintCoefficient{thisCon,1} = ...
                    [    sparse([],[],[],n_x,n_x,0)     ,   sparse([],[],[],n_x,n_u,0)          ,    sparse([],[],[],n_x,1,0)            ;...
                         sparse([],[],[],n_u,n_x,0)     ,  -1 * diag(thisMask)                  ,    (this_lower+this_upper)*thisMask    ;...
                         sparse([],[],[],1  ,n_x,0)     ,   (this_lower+this_upper)*thisMask'   ,   -(this_lower*this_upper)              ...
                    ];
        end
    end
    
    if myConstraints.flag_inc_u_poly
        % Each row of the polytope is used as
        % 0 <= -[A]_i u + bi
        for iCons = 1:size(myConstraints.u_poly_b,1)
            this_Ai = myConstraints.u_poly_A(iCons,:);
            this_bi = myConstraints.u_poly_b(iCons,1);
            thisCon = thisCon + 1;
            constraintCoefficient{thisCon,1} = ...
                    [    sparse([],[],[],n_x,n_x,0)     ,   sparse([],[],[],n_x,n_u,0)          ,    sparse([],[],[],n_x,1,0)   ;...
                         sparse([],[],[],n_u,n_x,0)     ,   sparse([],[],[],n_u,n_u,0)          ,   -0.5*this_Ai'               ;...
                         sparse([],[],[],1  ,n_x,0)     ,  -0.5*this_Ai                         ,    this_bi                     ...
                    ];
        end
    end
    




%% --------------------------------------------------------------------- %%
%% DECLARE THE OPTIMISATION VARIABLES FOR THE VALUE FUNCTION
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

    % ---------------------------------------- %
    % METHOD "FULL" 01 and 02
    if ( flag_full_01 || flag_full_02 )
    Vhat = ...
            [    P                              ,   sparse([],[],[],n_x,n_u,0)          ,   p                           ;...
                 sparse([],[],[],n_u,n_x,0)     ,   sparse([],[],[],n_u,n_u,0)          ,   sparse([],[],[],n_u,1,0)    ;...
                 p'                             ,   sparse([],[],[],1  ,n_u,0)          ,   s                            ...
            ];

    % ---------------------------------------- %
    % METHOD "DIAG" 01
    elseif flag_diag_01
        Vhat = ...
            [    diag(P)                        ,   sparse([],[],[],n_x,n_u,0)          ,   p                           ;...
                 sparse([],[],[],n_u,n_x,0)     ,   sparse([],[],[],n_u,n_u,0)          ,   sparse([],[],[],n_u,1,0)    ;...
                 p'                             ,   sparse([],[],[],1  ,n_u,0)          ,   s                            ...
            ];
    end
    
%% --------------------------------------------------------------------- %%
%% DECLARE THE OPTIMISATION VARIABLES FOR THE CONSTRAINT S-PROCEDURE

    if polyOrderOfMultipliers == 0
        % Declare the "lambda" multiplier variables
        lmul = sdpvar(numCons,1,'full');
        
        % Step through the "numCons" building up the SDP constraint
        % P_t+1 - P_t + L - \lambda_i * \sum_i G_i
        fullMatrix = disFactor * Vhatf - Vhat + Lhat;
        for iCons = 1:numCons
            fullMatrix = fullMatrix - lmul(iCons,1) * constraintCoefficient{iCons,1};
        end
    end

   

%% --------------------------------------------------------------------- %%
%% SPECIFY THE CONSTRAINT FUNCTIONS FOR THE SDP

    % The constraint is for the P matrix to be positive semi-definite
    % (PSD), and for the "Vhatf - Vhat + Lhat - sum lmul*Ghat" matrix to be
    % PSD
    % Note: this work for both dense and diagonal only P matrices
    thisCons = [ P >= 0 , fullMatrix >= 0 , lmul >= 0];
    
    
%% --------------------------------------------------------------------- %%
%% SPECIFY THE OBJECTIVE FUNCTION FOR THE SDP
        
        
    % If the "P" matrix is restricted to be diagonal only, then the
    % objective function can be simplified slightly:
    %thisObj = [1 , s , p' , P'] * sum_all * [1 ; s ; p ; P] .* 10^-(orderOfMagnitude-3);


    % ---------------------------------------- %
    % METHOD "FULL" 01 and 02
    if ( flag_full_01 || flag_full_02 )
        % Take a uniform distribution over the x-space
        Ex  = 0.5 * (x_lower + x_upper);
        Exx = 1/3 * diag( (x_lower.^2 + x_lower.*x_upper + x_upper.^2) );
        % Compute the objective based on this
        thisObj = - ( trace( P * Exx ) + 2 * Ex' * p + s );

    % ---------------------------------------- %
    % METHOD "DIAG" 01
    elseif flag_diag_01
        % Take a uniform distribution over the x-space
        Ex  = 0.5 * (x_lower + x_upper);
        Exx = 1/3 * diag( (x_lower.^2 + x_lower.*x_upper + x_upper.^2) );
        % Compute the objective based on this
        thisObj = - ( trace( diag(P) * Exx ) + 2 * Ex' * p + s );
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
        if sum( double(P+10^-10) < 0 ) > 0
            disp(' ... ERROR: The diagonal entries of the matrix P are NOT all non-negative');
            %error(' Terminating :-( See previous messages and ammend');
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
    
    optimalObjVal = ( trace( Pnew * Exx ) + 2 * Ex' * pnew + snew );
    
    %% MULTIPLY "pnew" BY 2
    pnew = 2.0 * pnew;
    
end
% END OF FUNCTION