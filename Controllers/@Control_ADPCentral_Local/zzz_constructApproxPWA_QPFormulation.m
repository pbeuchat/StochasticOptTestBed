%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     constructApproxPWA_QPFormulation.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [H, f, A, b, Aeq, beq, costConst] = constructApproxPWA_QPFormulation(Q,R,S,q,r,c,Mx,n,m,inSys,flagLifted)

%  AUTHOR:      Paul N. Beuchat
%  DATE:        01-Jun-2014
%  GOAL:        Generate distribution information
%
%  DESC:        > Function conainting a System Definition
%               
%% --------------------------------------------------------------------- %%
%% USER DEFINED INPUTS (aka. "pre-compile" switches)


%% --------------------------------------------------------------------- %%
%% BUILD THE COST MATRICES FOR THE "ROBUST QP" TO BE SOLVED
% -> See notes for how these equations are derived

H = kron( Mx , R );
f = 2 * kron( Mx , speye(m) )' * reshape( [r';S] , (n+1)*m , 1 );

costConst = trace( [ c , q' ; q , Q ] * Mx );


%% --------------------------------------------------------------------- %%
%% BUILD THE CONSTRAINT MATRICES FOR THE "ROBUST QP" TO BE SOLVED
% -> See notes for how these equations are derived

% First get the polytopic matrices dscribing the sets "X" and "U"
intersectLiftedWithProjection = 0;
[Ax, bx, qx, Au, bu, qu] = constructPolytopeMatrices( inSys , flagLifted , intersectLiftedWithProjection );


% For the INEQUALITY Constraint:
%    Au u0 + Z^T bx <= bu
% Where     u0 \in R^(m)
%           U' \in R^(m  x mn)
%           Z  \in R^(qx x qu)
% Hence this constraint is given by:
%     [Au  0_{qu x (mn)}  I_qu \otimes bx^T ]
A1 = [ Au  sparse([],[],[],qu,m*n,0)  kron(speye(qu) , bx') ];
b1 = bu;

% For the INEQUALITY Constraint:
%       Z >= 0 , element-wise
A2 = [ sparse([],[],[],qx*qu,m*(n+1),0)  -speye(qx*qu) ];
b2 = sparse([],[],[],qx*qu,1,0);


% For the EQUALITY Constraint:
%       -Au U' + Z^T Ax = 0
% vec(-Au U')  = -( I_n \otimes Au ) vec(U')
% vec(Z^T Ax) = vec(Z^T [ax1,...,axn]) =  [ (I_qu \otimes ax1^T) ; ... ; (I_qu \otimes axn^T] vec(Z)

tempAeqCell = cell(n,1);
for iDim=1:n
    tempAeqCell{iDim,1} = kron( speye(qu) , Ax(:,iDim)' );
end

Aeq1 = [ sparse([],[],[],qu*n,1,0)  -kron(speye(n),Au)  vertcat( tempAeqCell{:,1} ) ];
clear tempAeqCell;
beq1 = sparse([],[],[],qu*n,1,0);


% Combine things
A = [A1 ; A2];
b = [b1 ; b2];
Aeq = Aeq1;
beq = beq1;


%% --------------------------------------------------------------------- %%
%% SANITY CHECK THE MATRICES THAT WERE BUILT

% Check that "H" is sparse
check1 = issparse(H);
if not(check1)
    disp(' ... ERROR: the quadratic coefficient "H" is not a sparse matrix');
    disp('            This is not such a bad thing, but "gurobi" is a sparse solver so...');
    disp('            it is potentially much more efficient if "H" is sparse');
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

check2 = issparse(f);
if not(check2)
    disp(' ... NOTE: the linear coefficient "f" is not a sparse vector');
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

% Check the size of "H" and "f"
check3 = ( (size(H,1)==(n+1)*m) && (size(H,2)==(n+1)*m) );
if not(check3)
    disp(' ... ERROR: The size of the "H" matrix was not as expected');
    disp(['            size(H) = ',num2str(size(H,1)),'-by-',num2str(size(H,2)),' when it was expected to be size = ',num2str((n+1)*m),'-by-',num2str((n+1)*m)]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end
check4 = ( (size(f,1)==(n+1)*m) && (size(f,2)==1) );
if not(check4)
    disp(' ... ERROR: The size of the "f" matrix was not as expected');
    disp(['            size(f) = ',num2str(size(f,1)),'-by-',num2str(size(f,2)),' when it was expected to be size = ',num2str((n+1)*m),'-by-1']);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end


% CHECK THE INEQUALITY CONSTRAINT MATRICES
check1 = ( size(A,1) == size(b,1) );
if not(check1)
    disp(' ... ERROR: The height of the "A" matrix and "b" vector is not the same');
    disp(['            size(A,1) = ',num2str(size(A,1)),', while size(b,1) = ',num2str(size(b,1))]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end
check2 = ( size(A,2) == m*(n+1) + qx*qu );
if not(check2)
    disp(' ... ERROR: The width of the "A" matrix is not conistent with the state vector size "n" specified for the system');
    disp(['            size(A,2) = ',num2str(size(A,2)),', while n = ',num2str(m*(n+1) + qx*qu)]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end
check3 = ( size(b,2) == 1 );
if not(check3)
    disp(' ... ERROR: The width of the "b" matrix is not "1" as it should be for a vector');
    disp(['            size(b,2) = ',num2str(size(b,2))]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end


% CHECK THE EQUALITY CONSTRAINT MATRICES
check1 = ( size(Aeq,1) == size(beq,1) );
if not(check1)
    disp(' ... ERROR: The height of the "Aeq" matrix and "beq" vector is not the same');
    disp(['            size(Aeq,1) = ',num2str(size(Aeq,1)),', while size(beq,1) = ',num2str(size(beq,1))]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end
check2 = ( size(Aeq,2) == m*(n+1) + qx*qu );
if not(check2)
    disp(' ... ERROR: The width of the "Aeq" matrix is not conistent with the state vector size "n" specified for the system');
    disp(['            size(Aeq,2) = ',num2str(size(Aeq,2)),', while n = ',num2str(m*(n+1) + qx*qu)]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end
check3 = ( size(beq,2) == 1 );
if not(check3)
    disp(' ... ERROR: The width of the "beq" matrix is not "1" as it should be for a vector');
    disp(['            size(beq,2) = ',num2str(size(beq,2))]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

%% --------------------------------------------------------------------- %%
%% EXPAND THE OBJECTIVE TO INCLUDE THE SLACK VARIABLES IN THE CONSTRAINTS
H = blkdiag( H , sparse([],[],[],qx*qu,qx*qu,0) );
f = [ f ; sparse([],[],[],qx*qu,1,0) ];


%% --------------------------------------------------------------------- %%
%% ALL THE RETURN VARIABLES SOHULD NOW CONSTRUCTED



%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
%  HOW TO USE:  1) Specify the specificaion of the distribution
%
% INPUTS:
%       > xxx
%
% OUTPUTS:
%       > yyy





