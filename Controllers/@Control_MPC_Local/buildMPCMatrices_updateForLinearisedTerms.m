function [ ] = buildMPCMatrices_updateForLinearisedTerms( obj, T, Bxu_linearised , Bxiu_linearised)
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



%% CONVERT THE TIME HORIZON VARIABLE "T" TO A "double"
T = double(T);

%% GET DETAILS
% GET THE "A_k" AND "Bu_k" MATRICES
A_k = obj.A;
Bu_k = obj.Bu;

% GET SIZES REQUIRED
n_x = size(A_k,1);
n_u = size(Bu_k,2);
%n_xi = size(Bxi_k,2);  % Not Required
%p = size(Ck,1);    % Not Required


% GET THE FLAGS FOR WHAT BI-LINEAR TERMS TO INCLUDE
flag_has_Bxu = obj.flag_hasBilinearTerm_Bxu;
flag_has_Bxiu = obj.flag_hasBilinearTerm_Bxiu;

%% Bu MATRIX

%nzmax_Bu = (n_x*n_u)*T*(T+1)/2;
%Bu_new = sparse([],[],[],n_x*T,n_u*T,nzmax_Bu);
Bu_new_cell = cell(T,T);


tempA_pwr_t = speye(n_x);
for iTemp=1:T
    
    % Compute the next power of A^(t)
    if iTemp>1
        tempA_pwr_t = tempA_pwr_t * A_k;
    end
    
    % The "Bu" matrix is constructed to be sparse
    %tempABk = A_k^(iTemp-1)*Bu_k;
    %tempABk = tempA_pwr_t * (Bu_k + Bxu_linearised + Bxiu_linearised{iTemp,1});
    %tempAB = kron( [sparse([],[],[],iTemp-1,T-iTemp+1,0)   sparse([],[],[],iTemp-1,iTemp-1,0); speye(T-iTemp+1)  sparse([],[],[],T-iTemp+1,iTemp-1,0)], tempABk);
    %Bu_new = Bu_new + tempAB;
    
    for jTemp = 1:iTemp-1
        Bu_new_cell{jTemp,iTemp} = sparse([],[],[],n_x,n_u,0);
    end
    
    for jTemp = 1:T-iTemp+1
        this_location = sparse( iTemp-1+jTemp , jTemp , 1 , T, T, 1);
        
        if flag_has_Bxu && flag_has_Bxiu
            this_Bu = (Bu_k + Bxu_linearised + Bxiu_linearised{jTemp,1});
        elseif flag_has_Bxu
            this_Bu = (Bu_k + Bxu_linearised);
        elseif flag_has_Bxiu
            this_Bu = (Bu_k + Bxiu_linearised{jTemp,1});
        else
            this_Bu = Bu_k;
        end
        
        Bu_new_cell{ iTemp-1+jTemp , jTemp} = tempA_pwr_t * this_Bu;
        
        % THIS METHOD WAS TOO SLOW
        %tempAB = kron( this_location , tempA_pwr_t * this_Bu );
        %Bu_new = Bu_new + tempAB;
    end
    
end

Bu_new_cell_columns = cell(1,T);
for iTemp = 1:T
    Bu_new_cell_columns{1,iTemp} = vertcat( Bu_new_cell{:,iTemp} );
end

Bu_new = horzcat( Bu_new_cell_columns{1,:} );



%% --------------------------------------------------------------------- %%
%% THE FOLLOWING TERMS SHOULD BE UPDATED
% For the term "R_new", we need to update:
%   -> obj.Bu_Q_Bu
        
% For the term "r_new", we need to update:
%   -> obj.A_Q_Bu
%   -> obj.Bxi_Q_Bu
%   -> obj.q_Bu


%% --------------------------------------------------------------------- %%
%% BUILD THE REQUIRED COST TERMS
% Assuming that the stage costs are not time coupled

obj.Bu_Q_Bu     = Bu_new'       *  obj.Q_mpc  *  Bu_new;
obj.A_Q_Bu      = obj.A_mpc'    *  obj.Q_mpc  *  Bu_new;
obj.Bxi_Q_Bu    = obj.Bxi_mpc'  *  obj.Q_mpc  *  Bu_new;
obj.q_Bu        = obj.q_mpc'    *  Bu_new;



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

