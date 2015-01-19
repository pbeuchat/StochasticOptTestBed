function [returnCompletedSuccessfully , returnResults , savedDataNames] = runSimulation( obj , savePath )
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
    %returnCompletedSuccessfully = false;

    %% First check that is is ready to run
    if ~( obj.flag_readyToSimulate )
        disp(' ... ERROR: this simulation instance is not ready to simulate');
        disp('            It is surprising that it made it this far without being check for readiness ... oh well');
        error(bbConstants.errorMsg);
    end
    
    %% UPDATE THE STATE DEFITION - only the sub-system config part is updated
    % Set the "stateDef" object for the model to have the same masks as for
    % this "Control_Coordinator"
    updateStateDefMasks( obj.progModelEng , obj.controlCoord.stateDef.n_ss , obj.controlCoord.stateDef.mask_x_ss , obj.controlCoord.stateDef.mask_u_ss , obj.controlCoord.stateDef.mask_xi_ss );
    
    
    %% SET THE INITIAL CONDITION FOR: 'x', 'xi', 'cost'
    % Get the initial condition
    this_x = obj.stateDef.x0;
    
    % Set the disturbance for the first time step to be its initial value
    % Chosen to be zero for now
    prev_xi = zeros( obj.stateDef.n_xi , 1 );
    
    % Set the stage cost for the first time step iteration to be zero
    numSubCostValues        = obj.costDef.subCosts_num;
    numCostValues           = numSubCostValues + 1;
    this_stageCost          = zeros( numCostValues , 1 );
    this_stageCost_per_ss   = zeros( numCostValues , obj.stateDef.n_ss );
    costLabels              = [ {'full'} ; obj.costDef.subCosts_label ];
    
    
    % Flag for whether the current or previous disturbance is available to
    % the controller
    flag_current_xi_isAvailable = false;
    
    %% GET THE TIMING SPECIFICATIONS FOR THIS SIMULATION RUN
    % Get the timing
    timeStartIndex  = obj.simTimeIndex_start;
    timeEndIndex    = obj.simTimeIndex_end;
    timeDuration    = timeEndIndex - timeStartIndex;
    timeHoursPerInc = obj.progModelEng.t_perInc_hrs;

    % Pre-allocate a "thisTime" struct
    this_time = struct( 'index' , 0 , 'abs_hours' , 0 , 'abs_increment_hrs' , timeHoursPerInc );

    %% PRE-ALLOCATE VARIABLE FOR STORING THE RESULTS
    % Initiliase variables for storing the State, Input and Disturbance
    % results
    result_x  = zeros( obj.stateDef.n_x  , timeDuration + 1 );
    result_u  = zeros( obj.stateDef.n_u  , timeDuration );
    result_xi = zeros( obj.stateDef.n_xi , timeDuration );
    % Initiliase a variable for storing the per-Stage-Cost
    result_cost = zeros( numCostValues , timeDuration + 1);
    result_cost_per_ss = zeros( numCostValues , obj.stateDef.n_ss_original , timeDuration + 1);
    
    result_controlComputationTime = zeros( 1 , timeDuration );
    result_controlComputationTime_per_ss = zeros( obj.stateDef.n_ss , timeDuration );
    
    result_time = zeros( 2 , timeDuration+1 );
    result_time_label = {'index','abs_hours'};
    
    %% CONVERT THE LIST OF STATISTICS REQUIRED TO A "masked" LIST
    % Get the list of stats required, and convert it to the "masked"
    % format
    statsRequired = obj.controlCoord.distStatsRequired;
    statsRequired_mask = bbConstants.stats_createMaskFromCellArray( statsRequired );
    
    % Combine this into one flag for the case that NO predicitons are
    % needed
    flag_getPredictions = ( sum(statsRequired_mask) > 0 );
    
    
    % For the deterministic simulation we want to pull the mean
    statsRequiredDeterministic = {'mean'};
    statsRequiredDeterministic_mask = bbConstants.stats_createMaskFromCellArray( statsRequiredDeterministic );
    
    
    %% GET THE PREDICITON HORIZON
    % @TODO - this is a HORRIBLE hack because it should be specified by the
    % control method
    if flag_getPredictions
        timeHorizon = obj.controlCoord.distStatsHorizon;
    else
        timeHorizon = 0;
    end
    
    
    %% ----------------------------------------------------------------- %%
    %% RUN THE SIMULATION
    
    % This is the "inner" most loop other than the controller, and likely
    % the slowest, so we expect the control to display nothing at each
    % iteration and show the user some useful progress bar.
    progBarWidthPer10Percent = 5;
    progBarWidth = 10 * progBarWidthPer10Percent;
    progBarPercentPerMark = 100/progBarWidth;
    disp(' ... Progress bar of the time horizon:');
    fprintf('0');
    for iTemp = 1:10
        for iTemp = 1:progBarWidthPer10Percent-1
            fprintf('-');
        end
        if iTemp ~= 10
            fprintf('|');
        end
    end
    fprintf('100\n');
    
    % Put the first marker to say that we are 0% complete
    fprintf('|');
    nextProgPrint = progBarPercentPerMark;
    
    
    % Step through each of the "Local" controllers
    for iTime = 1 : timeDuration
        
        % ------------------------ %
        % Some debugging code to label the start of a step
        %fprintf(' %03d ',iTime);
        %disp(iTime);
        % ------------------------ %
        
        % Get the time step for this itertion
        this_time.index      = timeStartIndex + (iTime - 1);
        this_time.abs_hours  = double(this_time.index) * timeHoursPerInc;
        
        result_time(1,iTime) = this_time.index;
        result_time(2,iTime) = this_time.abs_hours;
        
        % Get the disturbance sample for this time
        if ~obj.flag_deterministic
            if obj.flag_precomputedDisturbancesAvailable
                this_xi = obj.precomputedDisturbances(:,this_time.index);
            else
                this_xi = getDisturbanceSampleForOneTimeStep( obj.distCoord , this_time.index );
            end
        else
            this_prediction_forDeterminisitic = getPredictions( obj.distCoord , statsRequiredDeterministic_mask , this_time.index , 1 );
            this_xi = this_prediction_forDeterminisitic.mean;
        end
        
        % Get the disturbance statisitcs for this time
        if flag_getPredictions
            this_prediction = getPredictions( obj.distCoord , statsRequired_mask , this_time.index , double(timeHorizon) );
        else
            this_prediction = [];
        end
        
        
        % Pass either "this" or the "prev" "xi" based on the flag
        if flag_current_xi_isAvailable
            prev_xi = this_xi;
        end
        
        % Get the control action to apply
        thisStartTime_Control = clock;
        [this_u , this_compTime_per_ss ] = computeControlAction( obj.controlCoord , this_time , this_x , prev_xi , this_stageCost , this_stageCost_per_ss , this_prediction , statsRequired_mask , timeHorizon );
        result_controlComputationTime( 1 , iTime ) = etime(clock,thisStartTime_Control);
        result_controlComputationTime_per_ss( : , iTime ) = this_compTime_per_ss;
        
        
        % Progress the Plant
        [new_x , this_stageCost , this_stageCost_per_ss , constraintSatisfaction] = performStateUpdate( obj.progModelEng , this_x , this_u , this_xi , this_time);
        
        % Save the results
        result_x(  : , iTime ) = this_x;
        result_u(  : , iTime ) = this_u;
        result_xi( : , iTime ) = this_xi;
        
        
        % Save the stage cost
        result_cost( : , iTime ) = this_stageCost;
        result_cost_per_ss( : , : , iTime ) =  this_stageCost_per_ss;
        
        % Put the updated the state in to the running state variable
        this_x = new_x;
        
        % Pass either "this" or the "prev" "xi" based on the flag
        if ~flag_current_xi_isAvailable
            prev_xi = this_xi;
        end
        
        
        % ------------------------ %
        % Updating the current percentage complete
        thisProg = double(iTime) / double(timeDuration) * 100;
        while thisProg >= nextProgPrint
            fprintf('|');
            nextProgPrint = nextProgPrint + progBarPercentPerMark;
        end
        % ------------------------ %
        
    end
    % END OF: "for iTime = 1 : timeDuration"
    
    % ------------------------ %
    % Part of printing out the current percentage
    fprintf('\n');
    % ------------------------ %
    
    % Store the final state
    result_x( : , timeDuration+1 ) = this_x;
    
    % Store the terminal cost
    result_cost( : , timeDuration+1 ) = 0;
    result_cost_per_ss( : , : , timeDuration+1 ) =  0;
    
    % Store the terminal time
    result_time(1,timeDuration+1) = timeStartIndex + timeDuration;
    result_time(2,timeDuration+1) = (timeStartIndex + timeDuration) * timeHoursPerInc;
    
    
    %% ----------------------------------------------------------------- %%
    %% SAVE THE DATA
    % To save a particular data set, we should store the data plus the
    % following attributes so that things can be easily plotted
    % Specifically
    % .data         - this is the actual data
    % .dimPerTime   - this is the number of dimension of data stored per time step
    % .labelPerDim  - this is a label of the variable for each non-time dimension
    
    
    
    % When then put all these together into a struct, where the properties
    % names for the struct are saved in a cell array of strings
    % 
    
    % Initialise the data counter
    iDataName = 0;
    
    % --------------------------- %
    % For 'time'
    iDataName                   = iDataName + 1;
    savedDataNames{iDataName,1}  = 'time';
    tempResult.data             = result_time;
    tempResult.dimPerTime       = 1;
    tempLabels                  = cell(tempResult.dimPerTime,1);
    tempLabels{1,1}             = result_time_label;
    tempResult.labelPerDim      = tempLabels;
    
    returnResults.(savedDataNames{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    % --------------------------- %
    % For 'x'
    iDataName                   = iDataName + 1;
    savedDataNames{iDataName,1}  = 'x';
    tempResult.data             = result_x;
    tempResult.dimPerTime       = 1;
    tempLabels                  = cell(tempResult.dimPerTime,1);
    tempLabels{1,1}             = obj.stateDef.label_x;
    tempResult.labelPerDim      = tempLabels;
    
    returnResults.(savedDataNames{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    
    % --------------------------- %
    % For 'u'
    iDataName                   = iDataName + 1;
    savedDataNames{iDataName,1}  = 'u';
    tempResult.data             = result_u;
    tempResult.dimPerTime       = 1;
    tempLabels                  = cell(tempResult.dimPerTime,1);
    tempLabels{1,1}             = obj.stateDef.label_u;
    tempResult.labelPerDim      = tempLabels;
    
    returnResults.(savedDataNames{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    
    
    % --------------------------- %
    % For 'xi'
    iDataName                   = iDataName + 1;
    savedDataNames{iDataName,1}  = 'xi';
    tempResult.data             = result_xi;
    tempResult.dimPerTime       = 1;
    tempLabels                  = cell(tempResult.dimPerTime,1);
    tempLabels{1,1}             = obj.stateDef.label_xi;
    tempResult.labelPerDim      = tempLabels;
    
    returnResults.(savedDataNames{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    
    % --------------------------- %
    % For 'cost'
    iDataName                   = iDataName + 1;
    savedDataNames{iDataName,1}  = 'cost';
    tempResult.data             = result_cost;
    tempResult.dimPerTime       = 1;
    tempLabels                  = cell(tempResult.dimPerTime,1);
    tempLabels{1,1}             = costLabels;
    tempResult.labelPerDim      = tempLabels;
    
    returnResults.(savedDataNames{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    
    % --------------------------- %
    % For 'cost_per_ss'
    iDataName                   = iDataName + 1;
    savedDataNames{iDataName,1}  = 'cost_per_ss';
    tempResult.data             = result_cost_per_ss;
    tempResult.dimPerTime       = 2;
    tempLabels                  = cell(tempResult.dimPerTime,1);
    tempLabels{1,1}             = costLabels;
    
    tempCell = cell(obj.stateDef.n_ss,1);
    for itemp=1:obj.stateDef.n_ss
        tempCell{itemp,1} = num2str(itemp);
    end
    
    tempLabels{2,1}             = tempCell;
    tempResult.labelPerDim      = tempLabels;
    
    returnResults.(savedDataNames{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    numDataNames = iDataName;
    
    
    % Step through the data and save it (if the save path is not emtpty
    if ~isempty(savePath)
        for iDataName = 1:numDataNames
            save( [savePath , savedDataNames{iDataName} , '.mat'] , '-struct' ,  'returnResults' , savedDataNames{iDataName} , '-v7.3' )
        end
    end    
    
    
    %% SET THAT THE SIMULATION WAS SUCCESSFUL IF WE MADE IT HERE
    % Put the error flag in to the return variable
    %diagnostics.error       = errorOccurred;
    %diagnostics.errorMsg    = errorMsg;
    
    returnCompletedSuccessfully = true;
            
end
% END OF FUNCTION