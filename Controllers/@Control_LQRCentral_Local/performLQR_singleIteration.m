function [Pnew , pnew, snew, u0new, Fnew] = performLQR_singleIteration( discountFactor, P_tp1, p_tp1, s_tp1, Exi, Exixi, A, Bu, Bxi, Q, R, S, q, r, c )
% Defined for the "Control_ADPCentral_Local" class, this function fits a
% Piece-wise Affine policy to a given value function
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %
% This file is part of the Stochastic Optimisation Test Bed.
%
% The Stochastic Optimisation Test Bed - Copyright (C) 2015 Paul Beuchat
%
% The Stochastic Optimisation Test Bed is free software: you can
% redistribute it and/or modify it under the terms of the GNU General
% Public License as published by the Free Software Foundation, either
% version 3 of the License, or (at your option) any later version.
% 
% The Stochastic Optimisation Test Bed is distributed in the hope that it
% will be useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with the Stochastic Optimisation Test Bed.  If not, see
% <http://www.gnu.org/licenses/>.
%  ---------------------------------------------------------------------  %



%% Convert the input "Discount Factor" to a shorter variable name
g = discountFactor;


%% Extract some sizes
% State and Input sizes
%n_x         = size(A ,2);
%n_u         = size(Bu,2);

%% --------------------------------------------------------------------- %%
%% MAKE SURE THAT EVERYTHING IS SPARSE
if ~issparse(P_tp1);    P_tp1 = sparse(P_tp1);  end
if ~issparse(p_tp1);    p_tp1 = sparse(p_tp1);  end
%if ~issparse(s_tp1);    s_tp1 = sparse(s_tp1);  end

%if ~issparse(Exi);      Exi = sparse(Exi);  end
%if ~issparse(Exixi);    Exi = sparse(Exixi);  end

if ~issparse(A);        A   = sparse(A);  end
if ~issparse(Bu);       Bu  = sparse(Bu);  end
if ~issparse(Bxi);      Bxi = sparse(Bxi);  end

if ~issparse(Q);        Q   = sparse(Q);  end
if ~issparse(R);        R   = sparse(R);  end
if ~issparse(S);        S   = sparse(S);  end
if ~issparse(q);        q   = sparse(q);  end
if ~issparse(r);        r   = sparse(r);  end
%if ~issparse(c);        c   = sparse(c);  end







%% --------------------------------------------------------------------- %%
%% COMPUTE THE "NEW" VALUE FUNCTION COEFFICIENTS

% Compute the inverse term once to save a bit fo computational
% repetitiveness
RBuPBu_inv = inv( R + g * Bu' * P_tp1 * Bu );

Pnew  = Q + A' * (P_tp1 - P_tp1 * Bu * RBuPBu_inv * Bu' * P_tp1 ) * A;

pnew  =  - ( r' + 2 * Exi' * Bxi' * P_tp1 * Bu + p_tp1' * Bu ) * RBuPBu_inv * Bu' * P_tp1 * A ...
         + 2 * Exi' * Bxi' * P_tp1 * A + q' + p_tp1' * A;
pnew  = pnew';

snew  =  - ( 0.5 * r' + Exi' * Bxi' * P_tp1 * Bu + 0.5 * p_tp1' * Bu ) * RBuPBu_inv * ( 0.5 * r + Bu' * P_tp1 * Bxi * Exi + 0.5 * Bu' * p_tp1 ) ...
         + c + trace( Bxi' * P_tp1 * Bxi * Exixi ) + s_tp1;
    
Fnew  =  - RBuPBu_inv * Bu' *P_tp1 * A;
    
u0new =  - RBuPBu_inv * ( 0.5 * r + Bu' * P_tp1 * Bxi * Exi + 0.5 * Bu' * p_tp1 );

    
end
% END OF FUNCTION