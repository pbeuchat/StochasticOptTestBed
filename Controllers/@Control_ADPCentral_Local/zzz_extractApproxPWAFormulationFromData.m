%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     extractApproxPWAFormulationFromData.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [Q,R,S,q,r,c,Mx,n_lift,m] = extractApproxPWAFormulationFromData(inV, inSys, inDist, inGamma, flagLifted)

%  AUTHOR:      Paul N. Beuchat
%  DATE:        01-Jun-2014
%  GOAL:        Generate distribution information
%
%  DESC:        > Function conainting a System Definition
%               
%% --------------------------------------------------------------------- %%
%% USER DEFINED INPUTS (aka. "pre-compile" switches)


%% --------------------------------------------------------------------- %%
%% EXTRACT DATA FROM THE INPUTS
inP = inV.P;
inp = inV.p * 0.5;
ins = inV.s;

n = inSys.sys.n;
m = inSys.sys.m;

inA = inSys.sys.A;
inB = inSys.sys.B;
inC = inSys.sys.C;

inQ = inSys.cost.Q;
inR = inSys.cost.R;
inS = inSys.cost.S;
inq = inSys.cost.q;
inr = inSys.cost.r;
inc = inSys.cost.s;

inmuw = inDist.mean;
inMw = inDist.cov;

if flagLifted
    Mx = [ 1 , inSys.lift.x.mean' ; inSys.lift.x.mean , inSys.lift.x.cov ];
    inRx = inSys.lift.x.retractOp;
    n_lift = sum(inSys.lift.x.numSidesPerDim,1);
else
    Mx = [ 1 , inSys.meanx'   ; inSys.sys.meanx   , inSys.sys.covx   ];
    inRx = speye(n);
    n_lift = n;
end

ing = inGamma;

%% BUILD THE FORMAULTION MATRICES TO BE RETURNED

Q = inRx' * inQ * inRx  +  ing * inRx' * inA' * inP * inA * inRx;
R = inR  +  ing * inB' * inP * inB;
S = inRx' * inS  +  ing * inRx' * inA' * inP * inB;
q = inRx' * inq  +  ing * inRx' * ( inA' * inP * inC * inmuw + inA' * inp);
r = inr  +  ing * ( inB' * inP * inC * inmuw + inB' * inp );
c = inc  +  ing * ( trace(inC' * inP * inC * inMw) + 2*inp' * inC * inmuw + ins );

%% SANITY CHECK THE SIZE OF EVERYTHING
check1 = ( (size(Q,1)==n_lift) && (size(Q,2)==n_lift) );
if not(check1)
    disp(' ... ERROR: The size of the "Q" matrix was not as expected');
    disp(['            size(Q) = ',num2str(size(Q,1)),'-by-',num2str(size(Q,2)),' when it was expected to be size = ',num2str(n_lift),'-by-',num2str(n_lift)]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

check2 = ( (size(R,1)==m) && (size(R,2)==m) );
if not(check2)
    disp(' ... ERROR: The size of the "R" matrix was not as expected');
    disp(['            size(R) = ',num2str(size(R,1)),'-by-',num2str(size(R,2)),' when it was expected to be size = ',num2str(m),'-by-',num2str(m)]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

check3 = ( (size(S,1)==n_lift) && (size(S,2)==m) );
if not(check3)
    disp(' ... ERROR: The size of the "S" matrix was not as expected');
    disp(['            size(S) = ',num2str(size(S,1)),'-by-',num2str(size(S,2)),' when it was expected to be size = ',num2str(n_lift),'-by-',num2str(m)]);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

check4 = ( (size(q,1)==n_lift) && (size(q,2)==1) );
if not(check4)
    disp(' ... ERROR: The size of the "q" matrix was not as expected');
    disp(['            size(q) = ',num2str(size(q,1)),'-by-',num2str(size(q,2)),' when it was expected to be size = ',num2str(n_lift),'-by-1']);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

check5 = ( (size(r,1)==m) && (size(q,2)==1) );
if not(check5)
    disp(' ... ERROR: The size of the "r" matrix was not as expected');
    disp(['            size(r) = ',num2str(size(r,1)),'-by-',num2str(size(r,2)),' when it was expected to be size = ',num2str(m),'-by-1']);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end

check5 = ( (size(c,1)==1) && (size(c,2)==1) );
if not(check5)
    disp(' ... ERROR: The size of the "c" matrix was not as expected');
    disp(['            size(c) = ',num2str(size(c,1)),'-by-',num2str(size(c,2)),' when it was expected to be size = 1-by-1']);
    error(' TERMINATING NOW :-( See previous messages and ammend');
end



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

