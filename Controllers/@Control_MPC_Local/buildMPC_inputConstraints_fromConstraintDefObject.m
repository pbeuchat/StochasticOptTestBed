function [return_A_ineq, return_b_ineq] = buildMPC_inputConstraints_fromConstraintDefObject( T, constraintDef )
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



%% GET THE POLYTOPE OF THE INPUT CONSTRAINT PER TIME STEP

% Could either construct the polytope
% if constraintDef.flag_inc_u_box
%     u_box = constraintDef.u_box;
% end
% if constraintDef.flag_inc_u_rect
%     u_rect_lower = constraintDefu_rect_lower;
%     u_rect_upper = constraintDefu_rect_upper;
% end
% if constraintDef.flag_inc_u_poly
%     u_poly_A = constraintDef.u_poly_A;
%     u_poly_b = constraintDef.u_poly_b;
% end

% OR
% Just pull the polytope from the "constraintDef" directly
u_all_A = constraintDef.u_all_A;
u_all_b = constraintDef.u_all_b;


%% GET SIZES
%n_u = size(u_all_A,2);


%% CONSTRUCT THE CONSTRAINT POLYTOPE FOR THE FULL TIME HORIZON

return_A_ineq = kron( speye(T) , u_all_A );
return_b_ineq = repmat( u_all_b , T , 1 );



end  %<-- END OF FUNCTION

