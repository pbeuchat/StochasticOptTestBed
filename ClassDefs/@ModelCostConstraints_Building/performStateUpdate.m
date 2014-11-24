function [xnew , l , constraintSatisfaction] = performStateUpdate( obj , x , u , xi , delta_t)
% Defined for the "ProgressModelEngineClass", this function progresses the
% state given that the "obj" is already know to be of type "building"
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %


    l = sum(x)+sum(u);
    constraintSatisfaction = 1;


    % This follows the same structure as the "simulateBM.m" function which
    % is included in the "@SimulationExperiment" class
    
    % Get the size of the state and input vectors
    n_x   = obj.n_x;
    n_u   = obj.n_u;
    n_xi  = obj.n_xi;
    
    
    % Add the linear parts
    xnew = obj.A * x + obj.Bu * u + obj.Bxi * xi;
    
    % Now add the bilinear parts
    % By first computing "kron(u,x)" and "kron(u,xi)" in a faster now
    u   = reshape( u  , [1    n_u  1  1 ] );
    x   = reshape( x  , [n_x  1    1  1 ] );
    xi  = reshape( xi , [n_xi 1    1  1 ] );
    x_stacked   = bsxfun(@times,u,x);
    x_stacked   = reshape(x_stacked,[n_u*n_x 1]);
    xi_stacked  = bsxfun(@times,u,xi);
    xi_stacked  = reshape(xi_stacked,[n_u*n_xi 1]);
    % Now actually add the bilinear parts
    xnew = xnew + obj.Bxiu_stacked * xi_stacked + obj.Bxu_stacked * x_stacked;

    
    % This is a more readable method to perform the state update
    % But it was about 25% slower when tested
    % The system matrices are directly properties of "obj"
    %xnew = obj.A * x + obj.Bu * u + obj.Bxi * xi;
    %for iCtrlElement = 1:n_u
    %    xnew = xnew + (obj.Bxiu(:,:,iCtrlElement) * xi + obj.Bxu(:,:,iCtrlElement) * x) * u(iCtrlElement);
    %end
    
    
%     % compute output y
%     %y = sys.C*x0 + sys.Du*u + sys.Dv*v;
%     y = mD.C*x0 + mD.Du*u + mD.Dv*v;
% 
%     for i = 1:n_u
%      y = y + (mD.Dvu(:,:,i)*v+mD.Dxu(:,:,i)*x0)*u(i);
%     end
    
    

end
% END OF FUNCTION