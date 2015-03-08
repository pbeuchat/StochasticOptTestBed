function [u0 , K] = performADP_fitPWA_toP( P, p, s, Exi, Exixi, Ex, Exx, Rx, A, Bu, Bxi, Q, R, S, q, r, c, discountFactor, A_poly_x, b_poly_x, A_poly_u, b_poly_u )
% Defined for the "Control_ADPCentral_Local" class, this function fits a
% Piece-wise Affine policy to a given value function
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

%% Convert the input "Discount Factor" to a shorter variable name
g = discountFactor;

%% Extract some sizes
% State and Input sizes
%n_x         = size(A ,2);
n_x_lift    = length(Ex);
n_u         = size(Bu,2);

% NOTE: that "n_x_lift" does not include the extra dimension that put a "1"
% in the first position of the lifted vector

% The number of inequalities describing each polytope
n_poly_x = length( b_poly_x );
n_poly_u = length( b_poly_u );


%% --------------------------------------------------------------------- %%
%% Compute the condensed coefficients of:
%%   l( Rx x' , u ) + \gamma E[ \hat{V}(f(Rx',u,w)) ]
% where u is parameterised to be:
%   u = u0 + U * x = [u0 , U'] * [1 ; x] = U * [1 ; x]

Qu = Rx' * Q * Rx  +  g * Rx' * A' * P * A * Rx;
Ru = R  +  g * Bu' * P * Bu;
Su = Rx' * S  +  g * Rx' * A' * P * Bu;
qu = Rx' * q  +  g * Rx' * ( A' * P * Bxi * Exi + A' * p);
ru = r  +  g * ( Bu' * P * Bxi * Exi + Bu' * p );
cu = c  +  g * ( trace(Bxi' * P * Bxi * Exixi) + 2*p' * Bxi * Exi + s );


%% SANITY CHECK THE SIZE OF EVERYTHING
check1 = ( (size(Qu,1)==n_lift) && (size(Qu,2)==n_lift) );
if not(check1)
    disp(' ... ERROR: The size of the "Qu" matrix was not as expected');
    disp(['            size(Qu) = ',num2str(size(Qu,1)),'-by-',num2str(size(Qu,2)),' when it was expected to be size = ',num2str(n_lift),'-by-',num2str(n_lift)]);
    error(bbConstants.errorMsg);
end

check2 = ( (size(Ru,1)==m) && (size(Ru,2)==m) );
if not(check2)
    disp(' ... ERROR: The size of the "Ru" matrix was not as expected');
    disp(['            size(Ru) = ',num2str(size(Ru,1)),'-by-',num2str(size(Ru,2)),' when it was expected to be size = ',num2str(m),'-by-',num2str(m)]);
    error(bbConstants.errorMsg);
end

check3 = ( (size(Su,1)==n_lift) && (size(S,2)==m) );
if not(check3)
    disp(' ... ERROR: The size of the "Su" matrix was not as expected');
    disp(['            size(Su) = ',num2str(size(Su,1)),'-by-',num2str(size(Su,2)),' when it was expected to be size = ',num2str(n_lift),'-by-',num2str(m)]);
    error(bbConstants.errorMsg);
end

check4 = ( (size(qu,1)==n_lift) && (size(qu,2)==1) );
if not(check4)
    disp(' ... ERROR: The size of the "qu" matrix was not as expected');
    disp(['            size(qu) = ',num2str(size(qu,1)),'-by-',num2str(size(qu,2)),' when it was expected to be size = ',num2str(n_lift),'-by-1']);
    error(bbConstants.errorMsg);
end

check5 = ( (size(ru,1)==m) && (size(ru,2)==1) );
if not(check5)
    disp(' ... ERROR: The size of the "ru" matrix was not as expected');
    disp(['            size(ru) = ',num2str(size(ru,1)),'-by-',num2str(size(ru,2)),' when it was expected to be size = ',num2str(m),'-by-1']);
    error(bbConstants.errorMsg);
end

check5 = ( (size(cu,1)==1) && (size(cu,2)==1) );
if not(check5)
    disp(' ... ERROR: The size of the "cu" matrix was not as expected');
    disp(['            size(cu) = ',num2str(size(cu,1)),'-by-',num2str(size(cu,2)),' when it was expected to be size = 1-by-1']);
    error(bbConstants.errorMsg);
end


%% --------------------------------------------------------------------- %%
%% BUILD THE "QP" FORMULATION TO SOLVE OF THE PWA POLICY COEFFICIENT



%% --------------------------------------------------------------------- %%
%% BUILD THE COST MATRICES FOR THE "ROBUST QP" TO BE SOLVED
% -> See notes for how these equations are derived

Mx  = [ 1 , Ex' ; Ex , Exx ];

H   = kron( Mx , Ru );
f   = 2 * kron( Mx , speye(m) )' * reshape( [r';S] , (n+1)*m , 1 );

costConst = trace( [ c , q' ; q , Q ] * Mx );


%% --------------------------------------------------------------------- %%
%% BUILD THE CONSTRAINT MATRICES FOR THE "ROBUST QP" TO BE SOLVED
% -> See notes for how these equations are derived

% First get the polytopic matrices dscribing the sets "X" and "U"
%intersectLiftedWithProjection = 0;
%[Ax, bx, qx, Au, bu, qu] = constructPolytopeMatrices( inSys , flagLifted , intersectLiftedWithProjection );


% For the INEQUALITY Constraint:
%    Au u0 + Z^T bx <= bu
% Where     u0 \in R^(m)
%           U' \in R^(m  x mn)
%           Z  \in R^(qx x qu)
% Hence this constraint is given by:
%     [Au  0_{qu x (mn)}  I_qu \otimes bx^T ]
A_ineq_1 = [ A_poly_u  sparse([],[],[],n_poly_u,n_u*n_x_lift,0)  kron(speye(n_poly_u) , b_poly_x') ];
b_ineq_1 = b_poly_u;

% For the INEQUALITY Constraint:
%       Z >= 0 , element-wise
A_ineq_2 = [ sparse([],[],[],n_poly_x*n_poly_u,n_u*(n_x_lift+1),0)  -speye(n_poly_x*n_poly_u) ];
b_ineq_2 = sparse([],[],[],n_poly_x*n_poly_u,1,0);


% For the EQUALITY Constraint:
%       -Au U' + Z^T Ax = 0
% vec(-Au U')  = -( I_n \otimes Au ) vec(U')
% vec(Z^T Ax) = vec(Z^T [ax1,...,axn]) =  [ (I_qu \otimes ax1^T) ; ... ; (I_qu \otimes axn^T] vec(Z)

tempAeqCell = cell(n_x_lift,1);
for iDim=1:n_x_lift
    tempAeqCell{iDim,1} = kron( speye(n_poly_u) , A_poly_x(:,iDim)' );
end

A_eq_1 = [ sparse([],[],[],n_poly_u*n_x_lift,n_u,0)  -kron(speye(n_x_lift),A_poly_u)  vertcat( tempAeqCell{:,1} ) ];
clear tempAeqCell;
b_eq_1 = sparse([],[],[],n_poly_u*n_x_lift,1,0);


% Combine things
A_ineq  = [A_ineq_1 ; A_ineq_2];
b_ineq  = [b_ineq_1 ; b_ineq_2];
A_eq    = A_eq_1;
b_eq    = b_eq_1;


%% --------------------------------------------------------------------- %%
%% SANITY CHECK THE MATRICES THAT WERE BUILT

% Check that "H" is sparse
check1 = issparse(H);
if not(check1)
    disp(' ... ERROR: the quadratic coefficient "H" is not a sparse matrix');
    disp('            This is not such a bad thing, but "gurobi" is a sparse solver so...');
    disp('            it is potentially much more efficient if "H" is sparse');
    error(bbConstants.errorMsg);
end

check2 = issparse(f);
if not(check2)
    disp(' ... NOTE: the linear coefficient "f" is not a sparse vector');
    error(bbConstants.errorMsg);
end

% Check the size of "H" and "f"
check3 = ( (size(H,1)==(n_x_lift+1)*n_u) && (size(H,2)==(n_x_lift+1)*n_u) );
if not(check3)
    disp(' ... ERROR: The size of the "H" matrix was not as expected');
    disp(['            size(H) = ',num2str(size(H,1)),'-by-',num2str(size(H,2)),' when it was expected to be size = ',num2str((n_x_lift+1)*n_u),'-by-',num2str((n_x_lift+1)*n_u)]);
    error(bbConstants.errorMsg);
end
check4 = ( (size(f,1)==(n_x_lift+1)*n_u) && (size(f,2)==1) );
if not(check4)
    disp(' ... ERROR: The size of the "f" matrix was not as expected');
    disp(['            size(f) = ',num2str(size(f,1)),'-by-',num2str(size(f,2)),' when it was expected to be size = ',num2str((n_x_lift+1)*n_u),'-by-1']);
    error(bbConstants.errorMsg);
end


% CHECK THE INEQUALITY CONSTRAINT MATRICES
check1 = ( size(A_ineq,1) == size(b_ineq,1) );
if not(check1)
    disp(' ... ERROR: The height of the "A_ineq" matrix and "b_ineq" vector is not the same');
    disp(['            size(A_ineq,1) = ',num2str(size(A_ineq,1)),', while size(b_ineq,1) = ',num2str(size(b_ineq,1))]);
    error(bbConstants.errorMsg);
end
check2 = ( size(A_ineq,2) == n_u*(n_x_lift+1) + n_poly_x*n_poly_u );
if not(check2)
    disp(' ... ERROR: The width of the "A_ineq" matrix is not conistent with the optimisation decision variable vector size expected');
    disp(['            size(A_ineq,2) = ',num2str(size(A_ineq,2)),', while it was expeted to be = ',num2str(n_u*(n_x_lift+1) + n_poly_x*n_poly_u)]);
    error(bbConstants.errorMsg);
end
check3 = ( size(b_ineq,2) == 1 );
if not(check3)
    disp(' ... ERROR: The width of the "b_ineq" matrix is not "1" as it should be for a vector');
    disp(['            size(b_ineq,2) = ',num2str(size(b_ineq,2))]);
    error(bbConstants.errorMsg);
end


% CHECK THE EQUALITY CONSTRAINT MATRICES
check1 = ( size(A_eq,1) == size(b_eq,1) );
if not(check1)
    disp(' ... ERROR: The height of the "A_eq" matrix and "b_eq" vector is not the same');
    disp(['            size(A_eq,1) = ',num2str(size(A_eq,1)),', while size(b_eq,1) = ',num2str(size(b_eq,1))]);
    error(bbConstants.errorMsg);
end
check2 = ( size(A_eq,2) == n_u*(n_x_lift+1) + n_poly_x*n_poly_u );
if not(check2)
    disp(' ... ERROR: The width of the "A_eq" matrix is not conistent with the state vector size "n" specified for the system');
    disp(['            size(A_eq,2) = ',num2str(size(A_eq,2)),', while n = ',num2str(n_u*(n_x_lift+1) + n_poly_x*n_poly_u)]);
    error(bbConstants.errorMsg);
end
check3 = ( size(b_eq,2) == 1 );
if not(check3)
    disp(' ... ERROR: The width of the "b_eq" matrix is not "1" as it should be for a vector');
    disp(['            size(b_eq,2) = ',num2str(size(b_eq,2))]);
    error(bbConstants.errorMsg);
end



%% --------------------------------------------------------------------- %%
%% EXPAND THE OBJECTIVE TO INCLUDE THE SLACK VARIABLES IN THE CONSTRAINTS
H = blkdiag( H , sparse([],[],[],n_poly_x*n_poly_u,n_poly_x*n_poly_u,0) );
f = [ f ; sparse([],[],[],n_poly_x*n_poly_u,1,0) ];



%% --------------------------------------------------------------------- %%
%% PASS THE FORMULATION TO A "QP" SOLVER

tempModelSense = 'min';
tempVerboseOptDisplay = false;

[ opt_decision , ~, ~, flag_solvedSuccessfully ] = opt.solveQP_viaGurobi( H, f, costConst, A_ineq, b_ineq, A_eq, b_eq, tempModelSense, tempVerboseOptDisplay );


if flag_solvedSuccessfully
    % Split out the policy part from the slack variables part
    opt_u0  = opt_decision(1:n_u,1);
    opt_K   = reshape( opt_decision( (n_u+1) : ((n_x_lift+1)*n_u) ) , n_u , n_x_lift );
    %opt_Z   = reshape( opt_decision( ((n_x_lift+1)*n_u+1) :  (n_u*(n_x_lift+1) + n_poly_x*n_poly_u) ) , n_poly_x , n_poly_u );
end



%% --------------------------------------------------------------------- %%
%% PUT IN THE RETURN VARIABLES
u0 = opt_u0;
K  = opt_K;



    
end
% END OF FUNCTION