function returnCost = computeCostComponent( obj , x , u , xi , currentTime )
% Defined for the "CostComponent" class, this function computes the cost
% for its type without performing any checks on the input
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function is specific to linear cost functions,
%                 assumptions are made and checks left out in order to
%                 speed up the computations
%               > Computational speed is important for this function
%                 because it is called at every iteration
% ----------------------------------------------------------------------- %


    returnCost = obj.q' * x + obj.r' * u + obj.c;
    

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
