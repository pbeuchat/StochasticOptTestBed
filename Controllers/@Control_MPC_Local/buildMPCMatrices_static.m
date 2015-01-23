%function [A,B,C] = constructMPCmatrices(Ak,Bk,Ck,T)
function [A_new, Bu_new, Bxi_new, Q_new, R_new, S_new, q_new, r_new, c_new ] = buildMPCMatrices_static( T, A_k, Bu_k, Bxi_k, Q_k, R_k, S_k, q_k, r_k, c_k)

% Defined for the "Control_LocalControl" class, this function will be
% called once before the simulation is started
% This function should be used to perform off-line possible
% computations so that the controller computation speed during
% simulation run-time is faster
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %    
%

%% CONVERT THE TIME HORIZON VARIABLE "T" TO A "double"
T = double(T);

%% GET SIZES
n_x = size(A_k,1);
n_u = size(Bu_k,2);
n_xi = size(Bxi_k,2);
%p = size(Ck,1);    % Not Required

%% A MATRIX
if ~issparse(A_k)
    A_k = sparse(A_k);
end
% Matrix "A" in general could be full
% Hence contstruct by storing each power in a cell array, and then
% concatentating vertically
Acell = cell(T,1);
for iTemp=1:T
    Acell{iTemp} = A_k^iTemp;
end
% Combine into the overall "A" matrix (should be in sparse format by
% construction)
A_new = vertcat(Acell{:});


%% Bu MATRIX
if ~issparse(Bu_k)
    Bu_k = sparse(Bu_k);
end
nzmax = (n_x*n_u)*T*(T+1)/2;
Bu_new = sparse([],[],[],n_x*T,n_u*T,nzmax);
for iTemp=1:T
    % The "Bu" matrix is constructed to be sparse
    tempABk = A_k^(iTemp-1)*Bu_k;
    tempAB = kron( [sparse([],[],[],iTemp-1,T-iTemp+1,0)   sparse([],[],[],iTemp-1,iTemp-1,0); speye(T-iTemp+1)  sparse([],[],[],T-iTemp+1,iTemp-1,0)], tempABk);
    Bu_new = Bu_new + tempAB;
end


%% Bxi MATRIX
if ~issparse(Bxi_k)
    Bxi_k = sparse(Bxi_k);
end
nzmax = (n_x*n_xi)*T*(T+1)/2;
Bxi_new = sparse([],[],[],n_x*T,n_xi*T,nzmax);
for iTemp=1:T
    % The "Bxi" matrix is constructed to be sparse
    tempABk = A_k^(iTemp-1)*Bxi_k;
    tempAB = kron( [sparse([],[],[],iTemp-1,T-iTemp+1,0)   sparse([],[],[],iTemp-1,iTemp-1,0); speye(T-iTemp+1)  sparse([],[],[],T-iTemp+1,iTemp-1,0)], tempABk);
    Bxi_new = Bxi_new + tempAB;
end


%% --------------------------------------------------------------------- %%
%% NOW FOR THE COST TERMS
% Assuming that the stage costs are not time coupled

% First convert the per stage cost to a 
Q_new = kron(speye(T),Q_k);
R_new = kron(speye(T),R_k);
S_new = kron(speye(T),S_k);

q_new = repmat(q_k,T,1);
r_new = repmat(r_k,T,1);
c_new = c_k * T;


%% EQUATIONS FOR BUILDING THE COST FUNCTION IN TERMS OF "u" ONLY
% R_new   =     R ...
%             + Bu_new' * Q * Bu_new ...
%             + Bu_new' * S';

% r_new   =     r' ...
%             + 2 * x0' * A_new' * Q * Bu_new ...
%             + 2 * thisExi' * Bxi_new' * Q * Bu_new ...
%             + x0' * A_new' * S' ...
%             + q' * Bu_new;

% c_new   =     x0' * A_new' * Q * A_new * x0 ...
%             +  thisExi' * Bxi_new' * Q * Bxi_new * thisExi ...
%             + 2 * x0' * A_new' * Q * Bxi_new * thisExi ...
%             + q' * A_new * x0 ...
%             + q' * Bxi_new * thisExi ...
%             + c;


end  %<-- END OF FUNCTION

