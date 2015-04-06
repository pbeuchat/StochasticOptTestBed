function [xnew , l , l_per_ss , constraintSatisfaction] = performStateUpdate( obj , x , u , xi , currentTime)
% Defined for the "ModelCostConstraints_Building" class, this function
% progresses the state given that the "obj" is already know to be of type
% "building"
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > As this function is specific to buildings, assumptions
%                 are made and checks left out in order to speed up the
%                 computations
%               > Computational speed is important for this function
%                 because it is called at every iteration
%               > Additionally, as the funtion is pecific to buildings it
%                 is "ok" to put in a few hacks
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



%% DEFAULT THE CONSTRAINT VIOLATION FLAG TO BE "true"
    constraintSatisfaction = true;

%% GET THE SIZES FOR THINGS
    % Get the size of the stuff, state, input, disturbance and sub-systems
    n_x   = obj.n_x;
    n_u   = obj.n_u;
    n_xi  = obj.n_xi;
    %n_ss  = obj.stateDef.n_ss;


%% COMPUTE THE STAGE COST, BOTH GLOBAL AND PER-SUB-SYSTE<
    
    % OLD CODE TO GIVE AN IDEA OF WHERE THE PARAMETERS COME FROM:
    %numCostValues  = obj.costDef.subCosts_num + 1;
    %l              = zeros(numCostValues , 1);
    %l_per_ss       = zeros(numCostValues , n_ss);
    
    % Call the "computeCost" function
    [l , l_per_ss] = computeCost( obj.costDef , x , u , xi , currentTime );
    
    
    
    
    
%% CHECK THAT THE INPUT CONSTRAINTS ARE SATISFIED    
    
    % First check that all input constraint are satisfied
    constraintCheck_u = ( obj.constraintDef.u_all_A * u <= obj.constraintDef.u_all_b);
    if sum(~constraintCheck_u) > 0
        % Set the flag the the constraint were not satisfied
        constraintSatisfaction = false;
        % Display some info about what the constraint violation was
        %disp([' ... CONSTRAINT VIOLATION: at time ',num2str(0),' the input specified violates the following input constraints:' ]);
        %disp( obj.constraintDef.u_all_label(~constraintCheck_u,1) );
        %disp( ' ');
        %disp( ' ... An adjustment will be made to map the specified inputs to a set of feasible inputs');
    end
    
    
%% AND ALSO CHECK THAT ANY STATE-by-INPUT CONSTRAINTS ARE SATISFIED    

    
%% PERFORM THE STATE VECTOR UPDATE TO PROGRESS TO THE NEXT TIME STEP
    % This follows the same structure as the "simulateBM.m" function which
    % is included in the "@SimulationExperiment" class
    
    
    % Add the linear parts
    xnew = obj.A * x + obj.Bu * u + obj.Bxi * xi;
    
    % Now add the bilinear parts
    % By first computing "kron(u,x)" and "kron(u,xi)" in a faster way
    %u   = reshape( u  , [1    n_u  1  1 ] );
    %x   = reshape( x  , [n_x  1    1  1 ] );
    %xi  = reshape( xi , [n_xi 1    1  1 ] );
    x_stacked   = bsxfun(@times,u',x);
    x_stacked   = reshape(x_stacked,[n_u*n_x 1]);
    xi_stacked  = bsxfun(@times,u',xi);
    xi_stacked  = reshape(xi_stacked,[n_u*n_xi 1]);
    % Now actually add the bilinear parts
    xnew = xnew + obj.Bxiu_stacked * xi_stacked + obj.Bxu_stacked * x_stacked;

    
%% CHECK IF THE UPDATED STATE VIOLATES ANY OF THE STATE-ONLY CONSTRIANTS
    % First check that all state constraints are satisfied
    constraintCheck_xnew = ( obj.constraintDef.x_all_A * xnew <= obj.constraintDef.x_all_b);
    if sum(~constraintCheck_xnew) > 0
        % Set the flag the the constraint were not satisfied
        constraintSatisfaction = false;
        % Display some info about what the constraint violation was
        %disp([' ... CONSTRAINT VIOLATION: after progressing the state from time ',num2str(0),' to time ',num2str(0),',' ]);
        %disp( '            the updated state violates the following state constraints:');
        %disp( obj.constraintDef.x_all_label(~constraintCheck_xnew,1) );
        %disp( ' ');
        %disp( ' ... An adjustment will be made to map the specified states back to a set of feasible states');
    end
    
    
%% COMPUTE THE NEXT OUTPUT AT THIS "PROGRESSED TO" TIME STEP
    
%     % compute output y
%     %y = sys.C*x0 + sys.Du*u + sys.Dv*v;
%     y = mD.C*x0 + mD.Du*u + mD.Dv*v;
% 
%     for i = 1:n_u
%      y = y + (mD.Dvu(:,:,i)*v+mD.Dxu(:,:,i)*x0)*u(i);
%     end
    
    

end
% END OF FUNCTION


%% --------------------------------------------------------------------- %%
%% SOME CODE FOR MAKING THESE COMPUTATIONS BUT OTHER METHODS
%  These were generally not used because the computation times were longer


% For the per-sub-system stage cost
% Compute the per-sub-system Stage Cost
%l_per_ss = zeros(obj.stateDef.n_ss , 1);
%for i_ss = 1 : obj.stateDef.n_ss
%    l_per_ss(i_ss,1) = 2 * obj.costDef.r(obj.stateDef.mask_u_ss(:,i_ss),1)' * u(obj.stateDef.mask_u_ss(:,i_ss),1);
%end


% For the state update
% This is a more readable method to perform the state update
% But it was about 25% slower when tested
% The system matrices are directly properties of "obj"
%xnew = obj.A * x + obj.Bu * u + obj.Bxi * xi;
%for iCtrlElement = 1:n_u
%    xnew = xnew + (obj.Bxiu(:,:,iCtrlElement) * xi + obj.Bxu(:,:,iCtrlElement) * x) * u(iCtrlElement);
%end
