function [Knew] = performADP_fitPWA_toP( obj , P_tp1, p_tp1, s_tp1, Exi, Exixi, Ex, Exx, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper , PMatrixStructure )
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
    %flag_full_01 = false;
    flag_full_02 = false;
    flag_diag_01 = false;
    
%     if strcmp( PMatrixStructure , 'dense' )
%         flag_full_01 = true;
%     elseif strcmp( PMatrixStructure , 'distributable' )
%         flag_full_02 = true;
%     elseif strcmp( PMatrixStructure , 'diag' )
%         flag_diag_01 = true;
%     else
%         disp( ' ... NOTE: The specified "P" matrix structure was not recognised');
%         disp( '           Setting it to be diagonal');
%         flag_diag_01 = true;
%     end
    
    flag_full_01 = true;

    %% INFER FROM SIZES FROM THE INPUT VARIABLES
    n_x = size(A,1);
    n_u = size(Bu,2);
    %n_xi = size(Bxi,2);
    
    
    %% NOW FORMULATE THE PROBLEM FOR THE VALUE FUNCTION
    
    % Implement the PieceWise Affine fitting using:
    % > 

    
%% --------------------------------------------------------------------- %%
%% SPECIFY SOME SETTINGS
    

    
    
    
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
    
    if flag_full_02
        % Add constraints to make P distributable
        thisCons = [thisCons , P(1,2:7) == 0];
        thisCons = [thisCons , P(2,3:7) == 0];
        thisCons = [thisCons , P(3,4:7) == 0];
        thisCons = [thisCons , P(4,5:7) == 0];
        thisCons = [thisCons , P(5,6:7) == 0];
        thisCons = [thisCons , P(6,7)   == 0];
    end
    
    
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
    thisOptions.debug    = false;
    thisOptions.verbose  = false;
    
    
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

    
    tempTime = clock;
    
    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    diagnostics = solvesdp(thisCons,thisObj,thisOptions);

    time_forSDP = etime(clock,tempTime);
    
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
        if sum( double(P+10^-8) < 0 ) > 0
            disp(' ... ERROR: The diagonal entries of the matrix P are NOT all non-negative');
            %error(' Terminating :-( See previous messages and ammend');
        end
        
    end
    
    
    %% ----------------------------------------------------------------- %%
    %% DIAGONALLY DOMINANT
    
flag_runDiagonallyDominant = false;
if flag_runDiagonallyDominant
    
    % Now try solve it again faster!!!
    P_dd = sdpvar( n_x , n_x ,'symmetric');
    p_dd = sdpvar( n_x ,  1  ,'full');
    s_dd = sdpvar(  1  ,  1  ,'full');
    
    Vhat_dd = ...
            [    P_dd                           ,   sparse([],[],[],n_x,n_u,0)          ,   p_dd                        ;...
                 sparse([],[],[],n_u,n_x,0)     ,   sparse([],[],[],n_u,n_u,0)          ,   sparse([],[],[],n_u,1,0)    ;...
                 p_dd'                          ,   sparse([],[],[],1  ,n_u,0)          ,   s_dd                         ...
            ];
    
    % Declare the "lambda" multiplier variables
    lmul_dd = sdpvar(numCons,1,'full');

    % Step through the "numCons" building up the SDP constraint
    % P_t+1 - P_t + L - \lambda_i * \sum_i G_i
    fullMatrix_dd = disFactor * Vhatf - Vhat_dd + Lhat;
    for iCons = 1:numCons
        fullMatrix_dd = fullMatrix_dd - lmul_dd(iCons,1) * constraintCoefficient{iCons,1};
    end
        
    % The objective shuoldn't have changed, so we just need to adjust the
    % constraint to reformulate the SDP constraints as Scaled Diagonally
    % Dominant constrints
    % Take a uniform distribution over the x-space
    Ex  = 0.5 * (x_lower + x_upper);
    Exx = 1/3 * diag( (x_lower.^2 + x_lower.*x_upper + x_upper.^2) );
    % Compute the objective based on this
    thisObj_dd = - ( trace( P_dd * Exx ) + 2 * Ex' * p_dd + s_dd );
    
    
    
    %% SPECIFY THE CONSTRAINT FUNCTIONS FOR THE SDP

    % The constraints were for the P matrix to be positive semi-definite
    % (PSD), and for the "Vhatf - Vhat + Lhat - sum lmul*Ghat" matrix to be
    % PSD
    % ie. thisCons = [ P >= 0 , fullMatrix >= 0 , lmul >= 0];
    
    thisCons_dd = (lmul >= 0);
    
    % For P >= 0
    for i_nx=1:n_x
        thisTrue = true(n_x,1);
        thisTrue(i_nx,1) = false;
        thisCons_dd = [thisCons_dd , P_dd(i_nx,i_nx) >= sum( abs( P_dd(i_nx,thisTrue) ) ) ];
    end
    
    % For fullMatrix >= 0
    n_temp = size(fullMatrix_dd,1);
    for i_ntemp=1:n_temp
        thisTrue = true(n_temp,1);
        thisTrue(i_ntemp,1) = false;
        thisCons_dd = [thisCons_dd , fullMatrix_dd(i_ntemp,i_ntemp) >= sum( abs( fullMatrix_dd(i_ntemp,thisTrue) ) ) ];
    end
    
    
    
    
    %% Call Yalmip to solve for the next value function - SHOULD BE AN LP
    
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
        thisOptions.solver = 'mosek';
    elseif strcmp('sdpt3',thisSolverStr)
        thisOptions.solver = 'sdpt3';
    else
        disp([' ... the specified solver "',thisSolverStr,'" was not recognised']);
        error(' Terminating :-( See previous messages and ammend');
    end

    
    tempTime = clock;
    
    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    diagnostics = solvesdp(thisCons_dd,thisObj_dd,thisOptions);

    time_forDD = etime(clock,tempTime);
    
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
    
    
    % Check how similar the solution is...
    
end % END OF: "if flag_runDiagonallyDominant"
    



    %% ----------------------------------------------------------------- %%
    %% SCALED DIAGONALLY DOMINANT

flag_runScaledDiagonallyDominant = false;
if flag_runScaledDiagonallyDominant
    
    % Now try solve it again faster!!!
    P_sdd = sdpvar( n_x , n_x ,'symmetric');
    p_sdd = sdpvar( n_x ,  1  ,'full');
    s_sdd = sdpvar(  1  ,  1  ,'full');
    
    Vhat_sdd = ...
            [    P_sdd                           ,   sparse([],[],[],n_x,n_u,0)          ,   p_sdd                        ;...
                 sparse([],[],[],n_u,n_x,0)     ,   sparse([],[],[],n_u,n_u,0)          ,   sparse([],[],[],n_u,1,0)    ;...
                 p_sdd'                          ,   sparse([],[],[],1  ,n_u,0)          ,   s_sdd                         ...
            ];
    
    % Declare the "lambda" multiplier variables
    lmul_sdd = sdpvar(numCons,1,'full');

    % Step through the "numCons" building up the SDP constraint
    % P_t+1 - P_t + L - \lambda_i * \sum_i G_i
    fullMatrix_sdd = disFactor * Vhatf - Vhat_sdd + Lhat;
    for iCons = 1:numCons
        fullMatrix_sdd = fullMatrix_sdd - lmul_sdd(iCons,1) * constraintCoefficient{iCons,1};
    end
        
    % The objective shuoldn't have changed, so we just need to adjust the
    % constraint to reformulate the SDP constraints as Scaled Diagonally
    % Dominant constrints
    % Take a uniform distribution over the x-space
    Ex  = 0.5 * (x_lower + x_upper);
    Exx = 1/3 * diag( (x_lower.^2 + x_lower.*x_upper + x_upper.^2) );
    % Compute the objective based on this
    thisObj_sdd = - ( trace( P_sdd * Exx ) + 2 * Ex' * p_sdd + s_sdd );
    
    
    
    %% SPECIFY THE CONSTRAINT FUNCTIONS FOR THE SDP

    % The constraints were for the P matrix to be positive semi-definite
    % (PSD), and for the "Vhatf - Vhat + Lhat - sum lmul*Ghat" matrix to be
    % PSD
    % ie. thisCons = [ P >= 0 , fullMatrix >= 0 , lmul >= 0];
    
    thisCons_sdd = (lmul >= 0);
    
    
    % For P >= 0
    
    % Create the "sub-matrix" variables
    numSubMat = double((n_x-1)*(n_x-2))/2;
    %M_for_P_sdd = cell(numSubMat,1);
    %for i=1:numSubMat
    %    M_for_P_sdd = sdpvar(  3  ,  1  ,'full');
    %end
    M_for_P_sdd = sdpvar(  numSubMat  , 3  ,'full');
    
    % Enforce the positivity constraints
    thisCons_sdd = [ thisCons_sdd , M_for_P_sdd(:,1) >= 0, M_for_P_sdd(:,2) >= 0, M_for_P_sdd(:,1) .* M_for_P_sdd(:,2) - M_for_P_sdd(:,3).^2 >= 0 ];
    
    % Now build the full "M" matrix
    M_sum_for_P_sdd = zeros(n_x,n_x);
    iM = 1;
    jM = 1;
    for kSubMat = 1:numSubMat
        jM = jM + 1;
        if jM > n_x
            iM = iM + 1;
            jM = iM + 1;
            if iM > n_x
                error(' ... THIS SHOULD NOT HAVE OCCURRED :-(');
            end
            M_sum_for_P_sdd(iM,iM) = M_sum_for_P_sdd(iM,iM) + M_for_P_sdd(kSubMat,1);
            M_sum_for_P_sdd(jM,jM) = M_sum_for_P_sdd(jM,jM) + M_for_P_sdd(kSubMat,2);
            M_sum_for_P_sdd(iM,jM) = M_sum_for_P_sdd(iM,jM) + M_for_P_sdd(kSubMat,3);
            M_sum_for_P_sdd(jM,iM) = M_sum_for_P_sdd(jM,iM) + M_for_P_sdd(kSubMat,3);
        end
    end
    
    % Lastly put the constraint that P == M
    thisCons_sdd = [ thisCons_sdd , P_sdd == M_sum_for_P_sdd ];
    
    
    
    % For fullMatrix >= 0
    
    % Create the "sub-matrix" variables
    n_temp = size(fullMatrix_sdd,1);
    numSubMat = double((n_temp-1)*(n_temp-2))/2;
    M_for_fullMatrix_sdd = sdpvar(  numSubMat  , 3  ,'full');
    
    % Enforce the positivity constraints
    thisCons_sdd = [ thisCons_sdd , M_for_fullMatrix_sdd(:,1) >= 0, M_for_fullMatrix_sdd(:,2) >= 0, M_for_fullMatrix_sdd(:,1) .* M_for_fullMatrix_sdd(:,2) - M_for_fullMatrix_sdd(:,3).^2 >= 0 ];
    
    
    % Now build the full "M" matrix
    M_sum_for_fullMatrix_sdd = zeros(n_temp,n_temp);
    iM = 1;
    jM = 1;
    for kSubMat = 1:numSubMat
        jM = jM + 1;
        if jM > n_temp
            iM = iM + 1;
            jM = iM + 1;
            if iM > n_temp
                error(' ... THIS SHOULD NOT HAVE OCCURRED :-(');
            end
            M_sum_for_fullMatrix_sdd(iM,iM) = M_sum_for_fullMatrix_sdd(iM,iM) + M_for_fullMatrix_sdd(kSubMat,1);
            M_sum_for_fullMatrix_sdd(jM,jM) = M_sum_for_fullMatrix_sdd(jM,jM) + M_for_fullMatrix_sdd(kSubMat,2);
            M_sum_for_fullMatrix_sdd(iM,jM) = M_sum_for_fullMatrix_sdd(iM,jM) + M_for_fullMatrix_sdd(kSubMat,3);
            M_sum_for_fullMatrix_sdd(jM,iM) = M_sum_for_fullMatrix_sdd(jM,iM) + M_for_fullMatrix_sdd(kSubMat,3);
        end
    end
    
    
    % Lastly put the constraint that P == M
    thisCons_sdd = [ thisCons_sdd , fullMatrix_sdd == M_sum_for_fullMatrix_sdd ];
    
    
    
    
    %% Call Yalmip to solve for the next value function - SHOULD BE AN SOCP
    
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
        thisOptions.solver = 'mosek';
    elseif strcmp('sdpt3',thisSolverStr)
        thisOptions.solver = 'sdpt3';
    else
        disp([' ... the specified solver "',thisSolverStr,'" was not recognised']);
        error(' Terminating :-( See previous messages and ammend');
    end

    
    tempTime = clock;
    
    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    diagnostics = solvesdp(thisCons_sdd,thisObj_sdd,thisOptions);

    time_forDD = etime(clock,tempTime);
    
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
    
    
    % Check how similar the solution is...
    
end % END OF: "if flag_runScaledDiagonallyDominant"




    %% ----------------------------------------------------------------- %%
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