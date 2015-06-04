function [ ] = buildMPCMatrices_specific( obj )
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


%% EQUATIONS FOR BUILDING THE COST FUNCTION IN TERMS OF "u" ONLY
% R_new   =     R ...
%             + Bu_new' * Q * Bu_new ...
%             + Bu_new' * S';
obj.Bu_Q_Bu     = obj.Bu_mpc'  *  obj.Q_mpc  *  obj.Bu_mpc;
obj.Bu_S        = obj.Bu_mpc'  *  obj.S_mpc';

% r_new   =     r' ...
%             + 2 * x0' * A_new' * Q * Bu_new ...
%             + 2 * thisExi' * Bxi_new' * Q * Bu_new ...
%             + x0' * A_new' * S' ...
%             + q' * Bu_new;
obj.A_Q_Bu      = obj.A_mpc'    *  obj.Q_mpc  *  obj.Bu_mpc;
obj.Bxi_Q_Bu    = obj.Bxi_mpc'  *  obj.Q_mpc  *  obj.Bu_mpc;
obj.A_S         = obj.A_mpc'    *  obj.S_mpc';
obj.q_Bu        = obj.q_mpc'    *  obj.Bu_mpc;

% c_new   =     x0' * A_new' * Q * A_new * x0 ...
%             +  thisExi' * Bxi_new' * Q * Bxi_new * thisExi ...
%             + 2 * x0' * A_new' * Q * Bxi_new * thisExi ...
%             + q' * A_new * x0 ...
%             + q' * Bxi_new * thisExi ...
%             + c;
obj.A_Q_A       = obj.A_mpc'    *  obj.Q_mpc  *  obj.A_mpc;
obj.Bxi_Q_Bxi   = obj.Bxi_mpc'  *  obj.Q_mpc  *  obj.Bxi_mpc;
obj.A_Q_Bxi     = obj.A_mpc'    *  obj.Q_mpc  *  obj.Bxi_mpc;
obj.q_A         = obj.q_mpc'    *  obj.A_mpc;
obj.q_Bxi       = obj.q_mpc'    *  obj.Bxi_mpc;



end  %<-- END OF FUNCTION

