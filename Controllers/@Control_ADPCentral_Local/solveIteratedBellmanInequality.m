%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     solveIteratedBellmanInequality.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnVhat, returnJhat] = solveIteratedBellmanInequality(M, isFH, inVhat, inGamma, inSys, inDist, inCouplingInfo, verboseOptDisplay)

%  AUTHOR:      Paul N. Beuchat
%  DATE:        01-Jun-2014
%  GOAL:        Runnig the Finate Horizon ADP solver
%
%  DESC:        > Function to run a Finite Horizon ADP solver
%               
%% --------------------------------------------------------------------- %%
%% USER DEFINED INPUTS (aka. "pre-compile" switches)
%%  Nothing to define for this function


%% --------------------------------------------------------------------- %%
%% EXTRACT DATA FROM THE INPUTS
% About the SYSTEM
n = inSys.sys.n;
m = inSys.sys.m;

A  = inSys.sys.A;
B  = inSys.sys.B;
C  = inSys.sys.C;

meanx = inSys.sys.meanx;
covx  = inSys.sys.covx;

% About the COSTS
costQ  = inSys.cost.Q;
costR  = inSys.cost.R;
costS  = inSys.cost.S;
costq  = inSys.cost.q;
costr  = inSys.cost.r;
costs  = inSys.cost.s;

% About the CONSTRAINTS
% -> This is all extracted and constructed in a separate function

% About the PREVIOUS Value Function IF IS FINITE HORIZON MODE
if isFH
    P  = inVhat.P;
    p  = inVhat.p;
    s  = inVhat.s;
end

% About the DISTURBANCE distribution
thisMu  = inDist.mean;
thisCov = inDist.cov;


%% INITILISE VARIABLES


%% CONSTRUCT THE OPTIMISATION MATRICES
% The matrices for introducing the constraints via the S-procedure
G_cons = constructConstraintMatricesForSProcedure(inSys);
numCons = length(G_cons);


% Construct the matrix relating to "E[V(f(x,u,w))]" based on "inVhat"
% Only needs to be done for the Finite Horizon ("isHF") case
if isFH
    G_from_inVhat = [ A'*P*A                     A'*P*B                      0.5*A'*p+A'*P*C*thisMu;...
                      B'*P*A                     B'*P*B                      0.5*B'*p+B'*P*C*thisMu;...
                      0.5*p'*A+thisMu'*C'*P*A    0.5*p'*B+thisMu'*C'*P*B     trace(C'*P*C*thisCov)+p'*C*thisMu+s;...
                    ];
end

% Construct the matrix relating to "l(x,u) = x^T Q x + u^T R u + "
G_cost = [ costQ    costS    costq;...
           costS'   costR    costr;...
           costq'   costr'   costs;...
         ];


%% PASS THE OPTIIMSATION PROBLEM TO THE SOLVER

% Declare the variables
Pnew  = cell(M,1);
% If the "coupling" flag is off then allow each "P{i}" to be a dense
% symmetric matrix
if not(inCouplingInfo.flag)
    for iM = 1:M
        Pnew{iM} = sdpvar(n,n,'symmetric');        % Symmetric nxn matrix
    end
else
    % else the "coupling" flag is on, so restrict the structure of each
    % "P{i}" based on the input coupling info

    % Convert the coupling matrix to a lower block triangular matrix
    % (becuase "P" is symmetric we only need as many variable elements as
    % the number of non-zeros on the lower block triangle)
    inCouplingMatrix = inCouplingInfo.matrix;
    couplingLowerTri = tril(inCouplingMatrix,-1);
    % Get the indices of the non-zero elements
    [iCoupled,jCoupled,~] = find(couplingLowerTri);
    numNonZero = length(iCoupled);
    PelDiag = cell(M,1);
    PelTril = cell(M,1);
    for iM = 1:M
        % Declare a variable of length equal to the number of non-zero elements
        PelDiag{iM} = sdpvar(n,1,'full');
        PelTril{iM} = sdpvar(numNonZero,1,'full');
        % Declare the parts for building the sparese matrix "P"
        PDiag = sparse(1:n,1:n,PelDiag{iM},n,n,n);
        PTril = sparse(iCoupled,jCoupled,PelTril{iM},n,n,numNonZero);
        % Build the sparse matrix "P"
        Pnew{iM} = PTril + PDiag + PTril';
        clear PDiag;
        clear PTril;
    end
end

% ... declare the other variables
pnew  = cell(M,1);
snew  = cell(M,1);
lmul  = cell(M,1);

for iM = 1:M
    pnew{iM}  = sdpvar(n,1,'full');
    snew{iM}  = sdpvar(1,1,'full');
    lmul{iM}  = sdpvar(numCons,1,'full');
end

% Specify the objective function
thisObj = -( trace(Pnew{1} * covx) + meanx' * pnew{1} + snew{1} );

% Specify the Constraints
G_new = [  Pnew{M}                   sparse([],[],[],n,m,0)     pnew{M};...
           sparse([],[],[],m,n,0)    sparse([],[],[],m,m,0)     sparse([],[],[],m,1,0);...
           pnew{M}'                  sparse([],[],[],1,m,0)     snew{M};...
        ];
          
          
% Construct the matrix relating to "E[V(f(x,u,w))]"
% -> Base on the "Pnew{1},pnew{1},snew{1}" if INFINTE Horizon
% Where the choice of "{1}" is because the Iterated Bellman Inequality
% method for infinite forizon defines Vhat_0 = Vhat_M = Vhat
if not(isFH)
	thisG = [ A'*Pnew{1}*A                             A'*Pnew{1}*B                              0.5*A'*pnew{1}+A'*Pnew{1}*C*thisMu;...
              B'*Pnew{1}*A                             B'*Pnew{1}*B                              0.5*B'*pnew{1}+B'*Pnew{1}*C*thisMu;...
              0.5*pnew{1}'*A+thisMu'*C'*Pnew{1}*A      0.5*pnew{1}'*B+thisMu'*C'*Pnew{1}*B       trace(C'*Pnew{1}*C*thisCov)+pnew{1}'*C*thisMu+snew{1};...
            ] * inGamma;
else
    % -> Or call the one based on "inVhat" is FINITE Horizon
    thisG = G_from_inVhat;
end

% Put these problems related matrices together
thisConsRHS = thisG - G_new + G_cost;
% Add the constraint related matrices per the S-procedure
for iCons = 1:numCons
    thisConsRHS = thisConsRHS - lmul{M}(iCons) * G_cons{iCons};
end
% Declare the constraint on the object that have been built and the
% variables in the problem
thisCons = [ thisConsRHS >=0 , Pnew{M} >= 0, lmul{M} >= 0 ];

% Now construct the iterated inequalities
for iM = M : -1 : 2
    % Construct the matrix relating to "V_{iM-1}(x)"
    G_new = [  Pnew{iM-1}                sparse([],[],[],n,m,0)     pnew{iM-1};...
               sparse([],[],[],m,n,0)    sparse([],[],[],m,m,0)     sparse([],[],[],m,1,0);...
               pnew{iM-1}'               sparse([],[],[],1,m,0)     snew{iM-1};...
            ];
    % Construct the matrix relating to "E[V_{iM}(f(x,u,w))]"
    % Only difference between FINITE and INFINITE horizon for "thisG"
    % matrix is the multiplication by a discount factor
    if isFH
        thisG = [ A'*Pnew{iM}*A                            A'*Pnew{iM}*B                             0.5*A'*pnew{iM}+A'*Pnew{iM}*C*thisMu;...
                  B'*Pnew{iM}*A                            B'*Pnew{iM}*B                             0.5*B'*pnew{iM}+B'*Pnew{iM}*C*thisMu;...
                  0.5*pnew{iM}'*A+thisMu'*C'*Pnew{iM}*A    0.5*pnew{iM}'*B+thisMu'*C'*Pnew{iM}*B     trace(C'*Pnew{iM}*C*thisCov)+pnew{iM}'*C*thisMu+snew{iM};...
                ];
    else
        thisG = [ A'*Pnew{iM}*A                            A'*Pnew{iM}*B                             0.5*A'*pnew{iM}+A'*Pnew{iM}*C*thisMu;...
                  B'*Pnew{iM}*A                            B'*Pnew{iM}*B                             0.5*B'*pnew{iM}+B'*Pnew{iM}*C*thisMu;...
                  0.5*pnew{iM}'*A+thisMu'*C'*Pnew{iM}*A    0.5*pnew{iM}'*B+thisMu'*C'*Pnew{iM}*B     trace(C'*Pnew{iM}*C*thisCov)+pnew{iM}'*C*thisMu+snew{iM};...
                ]  * inGamma;
    end
    
    % Put these problems related matrices together
    thisConsRHS = thisG - G_new + G_cost;
    % Add the constraint related matrices per the S-procedure
    for iCons = 1:numCons
        thisConsRHS = thisConsRHS - lmul{iM-1}(iCons) * G_cons{iCons};
    end
    % Declare the constraint on the object that have been built and the
    % variables in the problem
    thisCons = [ thisCons, thisConsRHS >=0 , Pnew{iM-1} >= 0, lmul{iM-1} >= 0];
    clear thisConsRHS;
    clear thisG;
end


% Specify the options
thisOptions = sdpsettings('solver','sedumi','verbose',verboseOptDisplay);

% Call the solver via Yalmip
disp(' ... calling solver now (calling SeDuMi via Yalmip)')
% SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
diagnostics = solvesdp(thisCons,thisObj,thisOptions);

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
minEigP = min( eig( double(Pnew{1}) ) );
if minEigP < 0
    disp(' ... ERROR: The coefficient matrix P is not Positive Semi-Definite');
    error(' Terminating :-( See previous messages and ammend');
end




%% PUT TOGETHER THE RETURN VARIABLES
returnVhat.P = sparse( double(Pnew{1}) );
returnVhat.p = sparse( double(pnew{1}) );
returnVhat.s = sparse( double(snew{1}) );

returnJhat   = trace( double(Pnew{1}) * covx) + meanx' * double(pnew{1}) + double(snew{1});

%% --------------------------------------------------------------------- %%
%% More details about this script/function
%
%  HOW TO USE:  1) No "User Options" (aka. "pre-compile" switches)
%                   to seelct for this function
%
% INPUTS:
%       > xxx
%
% OUTPUTS:
%       > yyy
%
