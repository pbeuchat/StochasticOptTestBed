function returnCompletedSuccessfully = runSimulation( obj )
% Defined for the "Simulation_Coordinator" class, this function runs a
% simulation
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    % Set the return flag to "false", and if we make it to the end of this
    % function it will be set to "true"
    returnCompletedSuccessfully = false;

    %% First check that is is ready to run
    if ~( obj.flag_readyToSimulate )
        disp(' ... ERROR: this simulation instance is not ready to simulate');
        disp('            It is surprising that it made it this far without being check for readiness ... oh well');
        error(bbConstants.errorMsg);
    end
    
    
    
    % Get the initial condition
    this_x         = obj.stateDef.x0;
    % Set the stage cost for the first time step iteration to be zero
    this_stageCost = 0;
    % Set the disturbance for the first time step to be its initial value
    prev_xi = zeros( obj.stateDef.n_xi , 1 );
    
    % Flag for whether the current or previous disturbance is available to
    % the controller
    flag_current_xi_isAvailable = false;
    
    % Get the timing
    timeStart      = obj.simTimeIndex_start;
    timeEnd        = obj.simTimeIndex_end;
    timeDuration   = timeEnd - timeStart + 1;

    % Initiliase variables for storing the State, Input and Disturbance
    % results
    result_x  = zeros( obj.stateDef.n_x  , timeDuration + 1 );
    result_u  = zeros( obj.stateDef.n_u  , timeDuration );
    result_xi = zeros( obj.stateDef.n_xi , timeDuration );
    % Initiliase a variable for storing the per-Stage-Cost
    result_cost = zeros( 1 , timeDuration + 1);
    
    % Get the list of stats required, and convert it to the "masked"
    % format
    statsRequired = obj.controlCoord.distStatsRequired;
    statsRequired_mask = bbConstants.stats_createMaskFromCellArray( statsRequired );
    
    flag_getPredictions = ( sum(statsRequired_mask) > 0 );
    
    timeHorizon = 5;
    
    % Step through each of the "Local" controllers
    for iTime = 1 : timeDuration
        
        % ------------------------ %
        % Some debugging code
        %fprintf(' %03d ',iTime);
        % ------------------------ %
        
        % Get the time step for this itertion
        this_time = timeStart + (iTime - 1);
        
        % Get the disturbance sample for this time
        this_xi = getDisturbanceSampleForOneTimeStep( obj.distCoord , this_time );
        
        % Get the disturbance statisitcs for this time
        if flag_getPredictions
            this_prediction = getPredictions( obj.distCoord , statsRequired_mask , this_time , timeHorizon);
        else
            this_prediction = [];
        end
        
        % Pass either "this" or the "prev" "xi" based on the flag
        if flag_current_xi_isAvailable
            prev_xi = this_xi;
        end
        
        % Get the control action to apply
        this_u = computeControlAction( obj.controlCoord , this_x , prev_xi , this_stageCost , this_prediction , statsRequired_mask , timeHorizon );
        
        % Progress the Plant
        delta_t = [];
        [new_x , this_stageCost , constraintSatisfaction] = performStateUpdate( obj.progModelEng , this_x , this_u , this_xi , delta_t);
        
        % Save the results
        result_x(  : , iTime ) = this_x;
        result_u(  : , iTime ) = this_u;
        result_xi( : , iTime ) = this_xi;
        % Save the stage cost
        result_cost( 1 , iTime ) = this_stageCost;
        
        % Put the updated the state in to the running state variable
        this_x = new_x;
        
        % Pass either "this" or the "prev" "xi" based on the flag
        if ~flag_current_xi_isAvailable
            prev_xi = this_xi;
        end
        
        
    end
    % END OF: "for iTime = 1 : timeDuration"
    
    % ------------------------ %
    % Some debugging code
    fprintf('\n');
    % ------------------------ %
    
    % Save the final state
    result_x( : , timeDuration+1 ) = this_x;
    
    % Save the terminal cost
    result_cost( 1 , timeDuration ) = 0;
    
    
    % Put the error flag in to the return variable
    %diagnostics.error       = errorOccurred;
    %diagnostics.errorMsg    = errorMsg;
    
    returnCompletedSuccessfully = true;
            
end
% END OF FUNCTION