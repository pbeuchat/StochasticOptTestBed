function flag_successfullyInitialised = initialise_localControl_withDisturbanceInfo( obj , inputDistCoord , vararginLocal)
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

    % This function is called in response to the "initialise_localControl"
    % function returning the "flag_requestDisturbanceData" flag as true
    % Access to the disturbance data should only be used for computational
    % speed up purposes
    
    %% LET THE USER KNOW THAT THIS COULD TAKE A WHILE
    disp( ' ... NOTE: Now computing all Value Functions for the Full Cycle of the Disturbance Model' );
    disp( '           This could take quite some time... depending on problem size' );
    
    
    %% SPECIFY A FEW DEFAULTS TO USE
    % ...
    
    %% EXTRACT THE OPTIONS FROM THE "vararginLocal" INPUT VARIABLE
    if isstruct( vararginLocal )
        
        % --------------------------------------------------------------- %
        % GET THE ...
%         if isfield( vararginLocal , '...' )
%             
%         else
%             disp( ' ... ERROR: The "vararginLocal" did not contain a field "..."');
%             disp( ' ... NOTE: Using ... as a default');
%         end
        
    else
        disp( ' ... ERROR: the "vararginLocal" variable was not a struct and hence cannot be processed');
    end
    
    
    %% NOW PERFORM THE INITIALISATION
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % All the Value Function approximations will be computed at once so
    % that multiple scenarios can be played at maximum computational
    % speed
    
    % It is preferable that the regularilty of re-computing the Approxiate
    % Value Function fits exactly into the total time horizon of the
    % disturbance
    
    % Get the duration of the disturbance definition
    thisFileName = mfilename;
    distFullTimeCycleSteps = getDisturbanceModelFullTimeCycle_forLocalController( inputDistCoord , thisFileName );
    
    % Check that the remainder is zero when divided by the regularity with
    % which controllers should be recomputed
    if ~rem( distFullTimeCycleSteps , obj.computeVEveryNumSteps ) == 0
        disp( ' ... ERROR: The Full Time Cycle of the disturbance model is NOT divisible (remainder zero) ');
        disp( '            by the regularity which which the Approx. Value Functions are to be ');
        disp( '            recomputed. ');
        disp( '            This method has not been setup to handle such a case. Switching back to' );
        disp( '            computing the Value Functions "on-the-fly"' );
        
        % Set the flag to reflect this error
        obj.computeAllVsAtInitialisation = false;
        
        % And also initialise the empty cell array for the value functions
        obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
    else
        
        %% Adjust the iteration counter
        obj.iterationCounter = distFullTimeCycleSteps;
        obj.numVsInitialised = distFullTimeCycleSteps;
        
        %% A \hat{V} is required every time step for the "Full Cycle Time"
        % of the Disturbance Model, hence initialise the cell arrays as
        % such
        obj.P = cell( distFullTimeCycleSteps , 1 );
        obj.p = cell( distFullTimeCycleSteps , 1 );
        obj.s = cell( distFullTimeCycleSteps , 1 );
        
        
        %% Initilise a temporary \hat{V} for computing for each horizon
        P_temp = cell( obj.statsPredictionHorizon+1 , 1 );
        p_temp = cell( obj.statsPredictionHorizon+1 , 1 );
        s_temp = cell( obj.statsPredictionHorizon+1 , 1 );
        
        
        
        %% GET A VARIETY OF OBJECTS REQUIRED
        % Extract the system matrices from the model
        myBuilding      = obj.model.building;
        myCosts         = obj.model.costDef;
        myConstraints   = obj.model.constraintDef;

        A       = sparse( myBuilding.building_model.discrete_time_model.A   );
        Bu      = sparse( myBuilding.building_model.discrete_time_model.Bu  );
        Bxi     = sparse( myBuilding.building_model.discrete_time_model.Bv  );
        %Bxu     = myBuilding.building_model.discrete_time_model.Bxu;
        %Bxiu    = myBuilding.building_model.discrete_time_model.Bvu;

        % Get the coefficients for a quadratic cost
        currentTime = [];
        [costCoeff , flag_allCostComponentsIncluded] = getCostCoefficients_uptoQuadratic( myCosts , currentTime );

        Q       = costCoeff.Q;
        R       = costCoeff.R;
        S       = costCoeff.S;
        q       = costCoeff.q;
        r       = costCoeff.r;
        c       = costCoeff.c;

        r = 0*r;
        
        % Display an error message if all Cost Components are not included
        if not(flag_allCostComponentsIncluded)
            disp( ' ... ERROR: not all of the cost components could be retireived');
            disp( '            This likely because at least one of the components is NOT a quadratic or linear function');
            disp( '            and this ADP implementation can only handle linear or quadratic cost terms');
        end
        
        % Get the size of the disturbance vector per interval
        n_xi = obj.stateDef.n_xi;
        
        % Get the stats required mask
        statsRequired_mask = bbConstants.stats_createMaskFromCellArray( obj.statsRequired );
        
        
        %% ------------------------------------------------------------- %%
        %% PARALLELISATION HINT:
        % This loop is easily paralisable because the key function is a
        % "Static" function.
        % Therefore we should collect all the data here into local
        % variables (instead to accessing "obj." properties within the for
        % loop.
        % This will make it obvious to Matlab that the loop is
        % parallisation and which variable to "copy" or "share" between
        % "workers"
        % This approach comes at the cost to memory to create local copied
        % of all the required variables
        
        
        
        %% ------------------------------------------------------------- %%
        %% Now we step through the \hat{V} computations from the start up to
        % the "Full Cycle Time" of the Disturbance Model
        % Stepping in blocks of the "computeVEveryNumSteps" interval
        for iStep = 1 : obj.computeVEveryNumSteps : distFullTimeCycleSteps
            
            % Get the predicition information at this step for the
            % prediciton horizon
            this_prediction = getPredictions( inputDistCoord , statsRequired_mask , iStep , double(obj.statsPredictionHorizon) );
            
            % SPECIFY THE FITTIG RANGE
            internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
            x_lower = obj.VFitting_xInternal_lower * internalStates  +  obj.VFitting_xExternal_lower * ~internalStates;
            x_upper = obj.VFitting_xInternal_upper * internalStates  +  obj.VFitting_xExternal_upper * ~internalStates;
            u_lower = myConstraints.u_rect_lower;
            u_upper = myConstraints.u_rect_upper;


            % Initialise TERMINAL VALUE FUNCITON for the first iteration:
            % > To be purely the comfort cost
            P_temp{obj.statsPredictionHorizon+1} = Q;
            p_temp{obj.statsPredictionHorizon+1} = q;  % <<---- NOTE THE "0.5" HERE, OR THE LACK OF IT!!!!
            s_temp{obj.statsPredictionHorizon+1} = c;



            % Print out a few things for where we are at:
            %mainfprintf('T=');

            %% Now iterate backwards through the time steps
            for iTime = obj.statsPredictionHorizon : -1 : 1

                % Get the first and second moment from the input prediciton struct
                thisRange = ((iTime-1)*n_xi+1) : (iTime*n_xi);
                thisExi     = this_prediction.mean(thisRange,1);
                thisExixi   = this_prediction.cov(thisRange,thisRange);

                % Get the value function for the future time step
                thisP = P_temp{iTime+1};
                thisp = p_temp{iTime+1};
                thiss = s_temp{iTime+1};

                % Pass everything to a ADP Sampling method
                if obj.useMethod_samplingWithLSFit
                    [Pnew , pnew, snew] = performADP_singleIteration_bySampling_LSFit(  obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper , obj.PMatrixStructure );
                elseif obj.useMethod_bellmanIneq
                    [Pnew , pnew, snew] = performADP_singleIteration_byBellmanIneq(     obj , thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper , obj.PMatrixStructure);
                else
                    disp( ' ... ERROR: the selected ADP method was NOT recognised');
                    Pnew = 0 * thisP; pnew = 0 * pnew; snew = 0 * thiss;
                end

                P_temp{iTime,1} = Pnew;
                p_temp{iTime,1} = pnew;
                s_temp{iTime,1} = snew;
            end

            %% Store the first "computeVEveryNumSteps" Value Functions
            for iStore = 1 : obj.computeVEveryNumSteps
                obj.P{iStep+iStore-1} = P_temp{iStore,1};
                obj.p{iStep+iStore-1} = p_temp{iStore,1};
                obj.s{iStep+iStore-1} = s_temp{iStore,1};
            end

            temp = 1;
            
        end   % END OF: "for iStep = 1 : obj.computeVEveryNumSteps : distFullTimeCycleSteps"
        
        
        
    end   % END OF: "else rem( distFullTimeCycleSteps , obj.computeVEveryNumSteps ) == 0"
    
    
            
end
% END OF FUNCTION