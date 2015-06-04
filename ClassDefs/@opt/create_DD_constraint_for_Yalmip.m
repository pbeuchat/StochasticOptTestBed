function [constraints] = create_DD_constraint_for_Yalmip(P)
% Defined for the "opt" class, this function takes a symmetric Yalmip
% expression and returns to constraint required to enforce positve
% semi-definiteness via the Diagonally Dominant method
% ----------------------------------------------------------------------- %
%  AUTHOR:      Angelos Georghiou
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


% GET THE SIZE OF THE INPUT VARIABLE, AND CHECK THAT IT IS SQUARE
[m,n] = size(P);
if (m ~= n)
    disp( ' ... ERROR: input matrix is not square');
    error(bbConstants.errorMsg);
end

% CREATE A MATRIX OF ONES ON THE OFF_DIAGONALS
I = ones(m,m);
I = I - eye(m);

% DEFINE TWO MATRIX VARIABLES (with the diagonal set to zero)
P2 = sdpvar(m,m,'symmetric');
P2 = I.*P;

P3 = sdpvar(m,m,'symmetric');
P3 = I.*P3;

% CONSTRUCT THE DIAGONALLY DOMINANT CONSTRAINTS
constraints = [];
constraints = constraints + (P3(:) >= P2(:));
constraints = constraints + (P3(:) >= -P2(:));
constraints = constraints + (diag(P) >= sum(P3')');

end  % <-- END OF FUNCTION
