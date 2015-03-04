function [returnCompletedSuccessfully , returnResults , returnSavedDataNames] = runSimulation( obj , savePath )
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
    
    %% ----------------------------------------------------------------- %%
    %% UPDATE THE STATE DEFITION - only the sub-system config part is updated
    % Set the "stateDef" object for the model to have the same masks as for
    % this "Control_Coordinator"
    updateStateDefMasks( obj.progModelEng , obj.controlCoord.stateDef.n_ss , obj.controlCoord.stateDef.mask_x_ss , obj.controlCoord.stateDef.mask_u_ss , obj.controlCoord.stateDef.mask_xi_ss );
    
    
    %% ----------------------------------------------------------------- %%
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
    % @TODO - this is a hardcode
    flag_current_xi_isAvailable = false;
    
    %% ----------------------------------------------------------------- %%
    %% GET THE TIMING SPECIFICATIONS FOR THIS SIMULATION RUN
    % Get the timing
    timeStartIndex  = obj.simTimeIndex_start;
    timeEndIndex    = obj.simTimeIndex_end;
    timeDuration    = timeEndIndex - timeStartIndex;
    timeHoursPerInc = obj.progModelEng.t_perInc_hrs;

    % Pre-allocate a "thisTime" struct
    this_time = struct( 'index' , 0 , 'abs_hours' , 0 , 'abs_increment_hrs' , timeHoursPerInc );

    
    
    %% ----------------------------------------------------------------- %%
    %% PRE-ALLOCATE VARIABLES FOR STORING TIME-INDEPENDENT RESULTS
    % This is the exception that doesn't need time as the second last
    % dimension because it is the same at every time
    result_realisationNumber_all        = zeros( 2 , obj.evalMulti_numRealisations );
    result_realisationNumber_label      = {'workerNumber' , 'realisationNumber'};

    % This is another exception that doesn't need time as the second
    % last dimension because it is a sum over time
    result_costCumulative_all           = zeros( numCostValues , obj.evalMulti_numRealisations );
    result_costCumulative_per_ss_all    = zeros( numCostValues , obj.stateDef.n_ss_original , obj.evalMulti_numRealisations );
    
    
    %% ----------------------------------------------------------------- %%
    %% INITIALISE THE RANDOM NUMBER GENERATOR FOR EACH WORKER
    this_parallelInitialised = initialise_MultipleDistCoordRandStream_ForParallelSimulations( obj );
    if ~(this_parallelInitialised)
        disp(' ... ERROR: the Simulation Coordinator Object could not successfully make a deep copy of the disturbance Coordinator object for parallel simulations');
    end

    %% ----------------------------------------------------------------- %%
    %% THIS IS THE PARALLELISATION POINT - Hints from some website
    %
    %   https://computing.ee.ethz.ch/Services/SGE
    %   http://www.robinince.net/blog/2013/03/13/sharedmatrix-with-parallel-computing-toolbox/
    %   http://uk.mathworks.com/matlabcentral/fileexchange/28572-sharedmatrix
    %   http://ch.mathworks.com/matlabcentral/newsreader/view_thread/297723
    %   http://www.mathworks.com/matlabcentral/newsreader/view_thread/288746#769470
    %
    
    
    
    %% ----------------------------------------------------------------- %%
    %% NOW SPLIT UP THE REALISATION EVALUATION WORKLOAD AMONGST THE WORKERS
    for iWorker = 1 : obj.evalMulti_numWorkers

        % Get the number of realisation to compute for this worker
        thisNumRealisations = obj.evalMulti_numRealisationsPerWorkerVector(iWorker,1);
        
        % Get the indexing in the context of the overall realisations
        thisRealisationIndexStart   = obj.evalMulti_realisationIndexStart(iWorker,1);
        thisRealisationIndexEnd     = obj.evalMulti_realisationIndexEnd(iWorker,1);
        
        % Get the Disturbance Coordinator object for this worker
        thisDistCoord = obj.distCoordArray(iWorker,1);
        
        
        %% LEGACY CODE
        % LEGACY CODE: from when the Simulation Coordinator provided the
        % Stream of Random numbers
        % The The "RandStream" object that will be used by this worker for
        % generating random samples
        %thisRandStream = obj.randStream_perWorkerCellArray{iWorker,1};
        % @TODO - this is a HACK, should retreive the number from the
        % diturbance
        %thisLengthRandSamplePerXi = obj.stateDef.n_xi;
        
        
        %% PRE-ALLOCATE VARIABLES FOR STORING THE RESULTS
        
        % The convention we use is that the last dimension is the number of
        % realisations, and the second last dimension is the time
        
        % Initiliase variables for storing the State, Input and Disturbance
        % results
        result_x  = zeros( obj.stateDef.n_x  , timeDuration + 1 , thisNumRealisations );
        result_u  = zeros( obj.stateDef.n_u  , timeDuration     , thisNumRealisations );
        result_xi = zeros( obj.stateDef.n_xi , timeDuration     , thisNumRealisations );
        % Initiliase a variable for storing the per-Stage-Cost
        result_cost = zeros( numCostValues , timeDuration + 1 , thisNumRealisations);
        result_cost_per_ss = zeros( numCostValues , obj.stateDef.n_ss_original , timeDuration + 1 , thisNumRealisations);

        result_controlComputationTime = zeros( 1 , timeDuration , thisNumRealisations );
        result_controlComputationTime_per_ss = zeros( obj.stateDef.n_ss , timeDuration , thisNumRealisations );

        result_time = zeros( 2 , timeDuration+1 , thisNumRealisations );
        result_time_label = {'index','abs_hours'};

        % This is the exception that doesn't need time as the second last
        % dimension because it is the same at every time
        result_realisationNumber        = zeros( 2 , thisNumRealisations );
        result_realisationNumber(1,:)   = iWorker;
        
        % This is another exception that doesn't need time as the second
        % last dimension because it is a sum over time
        result_costCumulative           = zeros( numCostValues , thisNumRealisations);
        result_costCumulative_per_ss    = zeros( numCostValues , obj.stateDef.n_ss_original , thisNumRealisations);
        
        %% CONVERT THE LIST OF STATISTICS REQUIRED TO A "masked" LIST
        % Get the list of stats required, and convert it to the "masked"
        % format
        statsRequired = obj.controlCoord.distStatsRequired;
        statsRequired_mask = bbConstants.stats_createMaskFromCellArray( statsRequired );

        % Combine this into one flag for the case that NO predicitons are
        % needed
        flag_getPredictions = ( sum(statsRequired_mask) > 0 );


        % For the deterministic simulation we want to pull the mean
        if obj.flag_deterministic
            statsRequiredDeterministic = {'mean'};
            statsRequiredDeterministic_mask = bbConstants.stats_createMaskFromCellArray( statsRequiredDeterministic );
        end


        %% GET THE PREDICITON HORIZON FROM THE CONTROL METHOD
        if flag_getPredictions
            timeHorizon = obj.controlCoord.distStatsHorizon;
        else
            timeHorizon = 0;
        end


        %% ------------------------------------------------------------- %%
        %% STEP THROUGH THE REALISATIONS
        
        for iRealisation = 1 : thisNumRealisations
        
            %% SET THE STREAM NUMBER FOR THE RANDOM STREAM NUMBER GENERATOR
            thisStream = iRealisation;
            setSubStreamNumberForDisturbanceRandStream( thisDistCoord , thisStream );
            
            %% LEGACY CODE: 
            % SET THE STREAM NUMBER FOR THE RANDOM STREAM NUMBER GENERATOR
            % LEGACY CODE: from when the Simulation Coordinator provided
            % the Stream of Random numbers
            % For Generator Types that handle sub-streams
            %if strcmp(thisRandStream.Type,'mrg32k3a') || strcmp(thisRandStream.Type,'mlfg6331_64')
            %    thisRandStream.Substream = iRealisation;
            %end
            % For other generator type we just sample continously
            
            
            %% Store the realisation number in the results
            result_realisationNumber(2,iRealisation) = iRealisation;
    
        
            %% --------------------------------------------------------- %%
            %% PREPARE A PROGRESS BAR
            % This is the "inner" most loop other than the controller, and likely
            % the slowest, so we expect the control to display nothing at each
            % iteration and show the user some useful progress bar.
            progBarWidthPer10Percent = 5;
            progBarWidth = 10 * progBarWidthPer10Percent;
            progBarPercentPerMark = 100/progBarWidth;
            disp([' Progress bar of the time horizon for: Worker# ',num2str(iWorker,'%5d'),', and Realisation #',num2str(iRealisation,'%5d'),' -out of- ',num2str(thisNumRealisations)]);
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


            %% --------------------------------------------------------- %%
            %% RUN THE SIMULATION

            % Step through each of the "Local" controllers
            for iTime = 1 : timeDuration

                % ------------------------ %
                % Some debugging code to label the start of a step
                %fprintf(' %03d ',iTime);
                %disp(iTime);
                % ------------------------ %

                % Get the time step for this itertion
                this_time.index      = timeStartIndex + (iTime - 1);
                this_time.abs_hours  = (double(this_time.index) - 1) * timeHoursPerInc;

                result_time(1,iTime,iRealisation) = this_time.index;
                result_time(2,iTime,iRealisation) = this_time.abs_hours;

                % Get the disturbance sample for this time
                if ~obj.flag_deterministic
                    if obj.flag_precomputedDisturbancesAvailable
                        this_xi = obj.precomputedDisturbances(:,this_time.index);
                    else
                        % Draw a sample from the Disturbance Coordinator
                        this_xi = getDisturbanceSampleForOneTimeStep( obj.distCoord , this_time.index );
                        
                        % Draw a sample from the RandStream for this worker
                        %tempSample = randn( thisRandStream , thisLengthRandSamplePerXi , 1 );
                        %this_xi = getDisturbanceSampleForOneTimeStep_withRandInput( obj.distCoord , this_time.index , tempSample );
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
                result_controlComputationTime( 1 , iTime , iRealisation ) = etime(clock,thisStartTime_Control);
                result_controlComputationTime_per_ss( : , iTime , iRealisation ) = this_compTime_per_ss;


                % Progress the Plant
                [new_x , this_stageCost , this_stageCost_per_ss , constraintSatisfaction] = performStateUpdate( obj.progModelEng , this_x , this_u , this_xi , this_time);

                % Save the results
                result_x(  : , iTime , iRealisation ) = this_x;
                result_u(  : , iTime , iRealisation ) = this_u;
                result_xi( : , iTime , iRealisation ) = this_xi;


                % Save the stage cost
                result_cost( : , iTime , iRealisation )             = this_stageCost;
                result_cost_per_ss( : , : , iTime , iRealisation )  =  this_stageCost_per_ss;

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
            result_x( : , timeDuration+1 , iRealisation ) = this_x;

            % Store the terminal cost
            % @TODO: this is a partial HACK at the moment
            this_u  =  zeros( obj.stateDef.n_u  , 1 );
            this_xi =  zeros( obj.stateDef.n_xi , 1 );
            [~ , this_stageCost , this_stageCost_per_ss , ~] = performStateUpdate( obj.progModelEng , this_x , this_u , this_xi , this_time);

            result_cost( : , timeDuration+1 , iRealisation ) = this_stageCost;
            result_cost_per_ss( : , : , timeDuration+1 , iRealisation ) =  this_stageCost_per_ss;
            
            % Store the terminal time
            result_time(1 , timeDuration+1 , iRealisation ) = (timeStartIndex + timeDuration);
            result_time(2 , timeDuration+1 , iRealisation ) = (timeStartIndex + timeDuration) * timeHoursPerInc;
            
            % Store the CUULATIVE COST
            result_costCumulative( : , iRealisation )               = sum(        result_cost(:,:,iRealisation) , 2 );
            result_costCumulative_per_ss( : , : , iRealisation )    = sum( result_cost_per_ss(:,:,:,iRealisation) , 3 );

        end
        
        %% ------------------------------------------------------------- %%
        %% SAVE THE DATA - FOR THIS SET OF REALISATIONS - FOR THE TIME-DEPENDENT QUANTITIES
        
        % To save a particular data set, we should store the data plus the
        % following attributes so that things can be easily plotted
        % Specifically
        % .data         - this is the actual data
        % .dataRepresents - this catagorised what the data is, eg. 'state'
        %                   OPTIONS: 'time', 'state', 'input', 'disturbance',
        %                   'cost', 'cost_per_ss'
        % .dimPerTime   - this is the number of dimension of data stored per time step
        % .labelPerDim  - this is a label of the variable for each non-time dimension
        % .timePropertyName - this is the name of the property under which the time data is saved
        %                     This makes the plotting more generic
        % .toPlotMask  - this is a logical mask that specifies which states
        %               are important for visualisation
        
        % We then put all these together into a struct, where the property
        % names for the struct are saved in a cell array of strings
    
        % Initialise the data counter and container
        iDataName = 0;
        clear savedDataNames_thisWorker;
        savedDataNames_thisWorker = cell(7,1);
        
        % Clear the results struct just in case
        clear results_thisWorker;
        
        % --------------------------- %
        % For 'time' - Always save this
        iDataName                   = iDataName + 1;
        if obj.evalMulti_numWorkers == 1
            savedDataNames_thisWorker{iDataName,1}  = 'time';
        else
            savedDataNames_thisWorker{iDataName,1}  = ['time_worker_',num2str(iWorker,'%04d')];
        end
        tempResult.data             = result_time;
        tempResult.dataRepresents   = 'time';
        tempResult.dimPerTime       = 1;
        tempLabels                  = cell(tempResult.dimPerTime,1);
        tempLabels{1,1}             = result_time_label;
        tempResult.labelPerDim      = tempLabels;
        tempResult.timePropertyName = savedDataNames_thisWorker{1,1};
        tempResult.toPlotMask       = true( size(result_time,1) , 1 );

        results_thisWorker.(savedDataNames_thisWorker{iDataName}) = tempResult;
        clear tempLabels;
        clear tempResult;

        % --------------------------- %
        % For 'x'
        if obj.evalMultiReal_details.flag_save_x
            iDataName                   = iDataName + 1;
            if obj.evalMulti_numWorkers == 1
                savedDataNames_thisWorker{iDataName,1}  = 'x';
            else
                savedDataNames_thisWorker{iDataName,1}  = ['x_worker_',num2str(iWorker,'%04d')];
            end
            tempResult.data             = result_x;
            tempResult.dataRepresents   = 'state';
            tempResult.dimPerTime       = 1;
            tempLabels                  = cell(tempResult.dimPerTime,1);
            tempLabels{1,1}             = obj.stateDef.label_x;
            tempResult.labelPerDim      = tempLabels;
            tempResult.timePropertyName = savedDataNames_thisWorker{1,1};
            tempResult.toPlotMask       = obj.stateDef.mask_toPlot_x;
            
            results_thisWorker.(savedDataNames_thisWorker{iDataName}) = tempResult;
            clear tempLabels;
            clear tempResult;
        end

        % --------------------------- %
        % For 'u'
        if obj.evalMultiReal_details.flag_save_u
            iDataName                   = iDataName + 1;
            if obj.evalMulti_numWorkers == 1
                savedDataNames_thisWorker{iDataName,1}  = 'u';
            else
                savedDataNames_thisWorker{iDataName,1}  = ['u_worker_',num2str(iWorker,'%04d')];
            end
            tempResult.data             = result_u;
            tempResult.dataRepresents   = 'input';
            tempResult.dimPerTime       = 1;
            tempLabels                  = cell(tempResult.dimPerTime,1);
            tempLabels{1,1}             = obj.stateDef.label_u;
            tempResult.labelPerDim      = tempLabels;
            tempResult.timePropertyName = savedDataNames_thisWorker{1,1};
            tempResult.toPlotMask       = obj.stateDef.mask_toPlot_u;

            results_thisWorker.(savedDataNames_thisWorker{iDataName}) = tempResult;
            clear tempLabels;
            clear tempResult;
        end


        % --------------------------- %
        % For 'xi'
        if obj.evalMultiReal_details.flag_save_xi
            iDataName                   = iDataName + 1;
            if obj.evalMulti_numWorkers == 1
                savedDataNames_thisWorker{iDataName,1}  = 'xi';
            else
                savedDataNames_thisWorker{iDataName,1}  = ['xi_worker_',num2str(iWorker,'%04d')];
            end
            tempResult.data             = result_xi;
            tempResult.dataRepresents   = 'disturbance';
            tempResult.dimPerTime       = 1;
            tempLabels                  = cell(tempResult.dimPerTime,1);
            tempLabels{1,1}             = obj.stateDef.label_xi;
            tempResult.labelPerDim      = tempLabels;
            tempResult.timePropertyName = savedDataNames_thisWorker{1,1};
            tempResult.toPlotMask       = obj.stateDef.mask_toPlot_xi;

            results_thisWorker.(savedDataNames_thisWorker{iDataName}) = tempResult;
            clear tempLabels;
            clear tempResult;
        end
        

        % --------------------------- %
        % For 'cost'
        if obj.evalMultiReal_details.flag_save_cost
            iDataName                   = iDataName + 1;
            if obj.evalMulti_numWorkers == 1
                savedDataNames_thisWorker{iDataName,1}  = 'cost';
            else
                savedDataNames_thisWorker{iDataName,1}  = ['cost_worker_',num2str(iWorker,'%04d')];
            end
            tempResult.data             = result_cost;
            tempResult.dataRepresents   = 'cost';
            tempResult.dimPerTime       = 1;
            tempLabels                  = cell(tempResult.dimPerTime,1);
            tempLabels{1,1}             = costLabels;
            tempResult.labelPerDim      = tempLabels;
            tempResult.timePropertyName = savedDataNames_thisWorker{1,1};
            tempResult.toPlotMask       = true( size(result_cost,1) , 1 );

            results_thisWorker.(savedDataNames_thisWorker{iDataName}) = tempResult;
            clear tempLabels;
            clear tempResult;
        end

        % --------------------------- %
        % For 'cost_per_ss'
        if obj.evalMultiReal_details.flag_save_cost_perSubSystem
            iDataName                   = iDataName + 1;
            if obj.evalMulti_numWorkers == 1
                savedDataNames_thisWorker{iDataName,1}  = 'cost_per_ss';
            else
                savedDataNames_thisWorker{iDataName,1}  = ['cost_per_ss_worker_',num2str(iWorker,'%04d')];
            end
            tempResult.data             = result_cost_per_ss;
            tempResult.dataRepresents   = 'cost_per_ss';
            tempResult.dimPerTime       = 2;
            % Labes for dimension 1
            tempLabels                  = cell(tempResult.dimPerTime,1);
            tempLabels{1,1}             = costLabels;
            % Labes for dimension 2
            tempCell = cell(obj.stateDef.n_ss,1);
            for itemp=1:obj.stateDef.n_ss
                tempCell{itemp,1} = num2str(itemp);
            end
            tempLabels{2,1}             = tempCell;
            tempResult.labelPerDim      = tempLabels;
            tempResult.timePropertyName = savedDataNames_thisWorker{1,1};
            tempResult.toPlotMask       = false( size(result_cost_per_ss,1) , size(result_cost_per_ss,2) , 1 );
            
            results_thisWorker.(savedDataNames_thisWorker{iDataName}) = tempResult;
            clear tempLabels;
            clear tempResult;
        end

        % ------------------------------ %
        % For 'realisationNumber', put the results for this worker into the
        % overal container
        result_realisationNumber_all(:,thisRealisationIndexStart:thisRealisationIndexEnd) = result_realisationNumber;
        
        
        % ------------------------------ %
        % For 'result_costCumulative'
        result_costCumulative_all(:,thisRealisationIndexStart:thisRealisationIndexEnd) = result_costCumulative;
        
        
        % ------------------------------ %
        % For 'result_costCumulative_per_ss'
        result_costCumulative_per_ss_all(:,:,thisRealisationIndexStart:thisRealisationIndexEnd) = result_costCumulative_per_ss;
        
        
        % Get the number of data files to be stored
        numDataNames = iDataName;


        % Step through the data and save it (if the save path is not emtpty
        if ~isempty(savePath)
            for iDataName = 1:numDataNames
                save( [savePath , savedDataNames_thisWorker{iDataName} , '.mat'] , '-struct' ,  'results_thisWorker' , savedDataNames_thisWorker{iDataName} , '-v7.3' )
            end
        end    
        
        % @TODO - a hack to only pass worker #1 results back
        if iWorker == 1
            returnResults = results_thisWorker;
        end
        
        % @TODO - a hack to only pass worker #1 "data names" back
        % Didn't matter at the time because the plotting function didn't
        % use the info
        if iWorker == 1
            returnSavedDataNames = savedDataNames_thisWorker(1:numDataNames,1);
        end
        
        % CLEAR THE SAVE VARIABLES TO ENUSRE THERE IS NO MISTAKE IN THE
        % CASE THAT MULTIPLE WORKERS ARE PERFORMED SERIALLY ON THE SAME
        % MACHINE
        clear savedDataNames_thisWorker;
        clear results_thisWorker;
        % CLEAR ALL THE OTHER WORKER SPECIFIC VARIABLES (Technically this
        % would be done by the "parallel" pool
        clear thisNumRealisations;
        clear thisRandStream;
        clear thisLengthRandSamplePerXi;
        clear thisRealisationIndexStart;
        clear thisRealisationIndexEnd;
        clear result_x;
        clear result_u;
        clear result_xi;
        clear result_cost;
        clear result_cost_per_ss;
        clear result_controlComputationTime;
        clear result_controlComputationTime_per_ss;
        clear result_time;
        clear result_time_label;
        clear result_realisationNumber;
        clear result_realisationNumber;
        clear result_costCumulative;
        clear result_costCumulative_per_ss;
        
    
    end   % END OF: "iWorker = 1 : evalMulti_numWorkers"
    
    
    %% ----------------------------------------------------------------- %%
    %% SAVE THE DATA - FOR THE TIME_INDEPENDENT QUANTITIES
    % To save a particular data set, we should store the data plus the
    % following attributes so that things can be easily plotted
    % Specifically
    % .data                - this is the actual data
    % .dataRepresents      - this catagorised what the data is, eg. 'state'
    %                       OPTIONS: 'realisationNumber', '', 'costCumulative',
    %                                'costCumulative_per_ss'
    % .dimPerRealisation   - this is the number of dimension of data stored per realisation
    % .labelPerDim         - this is a label of the variable for each non-time dimension
    % .toPlotMask   - this is a logical mask that specifies which states
    %                 are important for visualisation
    
    % We then put all these together into a struct, where the property
    % names for the struct are saved in a cell array of strings
    
    % Initialise the data counter and container
    iDataName = 0;
    savedDataNames_all = cell(5,1);
    
    % Clear the results struct just in case
    clear results_all;
    
    
    
    % --------------------------- %
    % For 'worker and realisation number'
    iDataName                   = iDataName + 1;
    savedDataNames_all{iDataName,1} = 'realisationNumber';
    tempResult.data                 = result_realisationNumber_all;
    tempResult.dataRepresents       = 'realisationNumber';
    tempResult.dataRepresents       = '';
    tempResult.dimPerRealisation    = 1;
    tempLabels                      = cell(tempResult.dimPerRealisation,1);
    tempLabels{1,1}                 = result_realisationNumber_label;
    tempResult.labelPerDim          = tempLabels;
    tempResult.toPlotMask           = false( size(result_realisationNumber_all,1) , 1 );

    results_all.(savedDataNames_all{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    
    % --------------------------- %
    % For 'costCumulative'
    iDataName                       = iDataName + 1;
    savedDataNames_all{iDataName,1} = 'costCumulative';
    tempResult.dataRepresents       = 'costCumulative';
    tempResult.data                 = result_costCumulative_all;
    tempResult.dimPerRealisation    = 1;
    tempLabels                      = cell(tempResult.dimPerRealisation,1);
    tempLabels{1,1}                 = costLabels;
    tempResult.labelPerDim          = tempLabels;
    tempResult.toPlotMask           = true( size(result_costCumulative_all,1) , 1 );

    results_all.(savedDataNames_all{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;

    % --------------------------- %
    % For 'costCumulative_per_ss'
    iDataName                       = iDataName + 1;
    savedDataNames_all{iDataName,1} = 'costCumulative_per_ss';
    tempResult.dataRepresents       = '';
    tempResult.data                 = result_costCumulative_per_ss_all;
    tempResult.dimPerRealisation    = 2;
    % Labes for dimension 1
    tempLabels                      = cell(tempResult.dimPerRealisation,1);
    tempLabels{1,1}                 = costLabels;
    % Labes for dimension 2
    tempCell = cell(obj.stateDef.n_ss,1);
    for itemp=1:obj.stateDef.n_ss
        tempCell{itemp,1} = num2str(itemp);
    end
    tempLabels{2,1}                 = tempCell;
    tempResult.labelPerDim          = tempLabels;
    tempResult.dataRepresents       = 'costCumulative_per_ss';
    tempResult.toPlotMask           = false( size(result_costCumulative_per_ss_all,1) , size(result_costCumulative_per_ss_all,2) , 1 );

    results_all.(savedDataNames_all{iDataName}) = tempResult;
    clear tempLabels;
    clear tempResult;
    
    
    % ------------------------------------------------------------------- %
    % To save the details of the Random Stream object used for each worker
    % so that any result can be exactly reproduced
    % .data                - this is the actual data
    % .dataRepresents      - this catagorised what the data is, eg. 'randStreamPerWorker'
    % .propertiesPerCell   - this is the number of dimension of data stored per realisation
    
    % --------------------------- %
    % For 'RandStreamPerWorker'
    iDataName                       = iDataName + 1;
    savedDataNames_all{iDataName,1} = 'randStreamPerWorker';
    tempResult.data                 = obj.detailsOf_randStreamPerWorker;
    tempResult.dataRepresents       = 'randStreamPerWorker';
    tempWorker = 1;
    tempResult.propertiesPerCell    = fieldnames( obj.detailsOf_randStreamPerWorker{tempWorker,1} );

    results_all.(savedDataNames_all{iDataName}) = tempResult;
    clear tempResult;
    
    
    % Get the number of data files to be stored
    numDataNames = iDataName;

    % Step through the data and save it (if the save path is not emtpty)
    if ~isempty(savePath)
        for iDataName = 1:numDataNames
            save( [savePath , savedDataNames_all{iDataName} , '.mat'] , '-struct' ,  'results_all' , savedDataNames_all{iDataName} , '-v7.3' )
        end
    end
    
    % Augment these result with the return ones
    for iDataName = 1:numDataNames
        returnResults.(savedDataNames_all{iDataName}) = results_all.(savedDataNames_all{iDataName});
    end
    % ... and "datanames" also
    for iDataName = 1:numDataNames
        returnSavedDataNames = [ returnSavedDataNames(:,1) ; savedDataNames_all(iDataName,1) ];
    end
    
    
    % CLEAR THE SAVE VARIABLES 
    clear savedDataNames_all;
    clear results_all;
    
    
    %% SET THAT THE SIMULATION WAS SUCCESSFUL IF WE MADE IT HERE
    % Put the error flag in to the return variable
    %diagnostics.error       = errorOccurred;
    %diagnostics.errorMsg    = errorMsg;
    
    returnCompletedSuccessfully = true;
            
end
% END OF FUNCTION



%%
%% A FEW DETAILS ABOUT THE RANDOM STREAMS
%
% See these websites:
%       http://ch.mathworks.com/help/matlab/math/multiple-streams.html?refresh=true
%       http://ch.mathworks.com/help/matlab/math/creating-and-controlling-a-random-number-stream.html
%       http://ch.mathworks.com/help/matlab/ref/randstream.html
%
%