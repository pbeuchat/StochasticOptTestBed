function passLocalInputToGlobalCoordinator( obj , local_ss_id , u , timeIndex )
 %timeStepIndex , timeStepAbsolute
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    % Get the mask for this sub-system
    obj.current_u( obj.stateDef.mask_u_ss(:,local_ss_id) , 1 ) = u;
    
    % Keep track of how many local controllers have communicated their
    % input plan here
    obj.numReceived = obj.numReceived + 1;

    % If we have heard from all sub-systems then check the polytopic
    % constraints on the input
    if (obj.numReceived == obj.stateDef.n_ss)
        % Reset the "numReceived" counter for the next round
        obj.numReceived = uint32(0);
        
        % Check that all input constraint are satisfied
        constraintCheck_u = ( obj.constraintDef.u_all_A * obj.current_u <= obj.constraintDef.u_all_b);
        if sum(~constraintCheck_u) > 0
            % Display some info about what the constraint violation was
            %disp([' ... CONSTRAINT VIOLATION: at time ',num2str(timeIndex),' the Global Coordinator determined that the combination of' ]);
            %disp( '               all inputs specified violates the following input constraints:' );
            %disp( obj.constraintDef.u_all_label(~constraintCheck_u,1) );
            %disp( ' ');
            %disp( ' ... An adjustment will be made to map the specified inputs to a set of feasible inputs');
        end

    end
            
end
% END OF FUNCTION