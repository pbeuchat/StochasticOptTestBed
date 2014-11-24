function u = computeControlAction( obj , x , xi_prev , stageCost_prev , predictions )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    % Null controller for now
    u = zeros( obj.n_u , 1 );
            
end
% END OF FUNCTION