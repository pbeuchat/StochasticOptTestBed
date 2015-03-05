function flag_successfullyInitialised = initialise_localControl_withDisturbanceInfo( obj , inputModelID , inputDisturbanceID , inputDistCoord , vararginLocal)
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
        
        % Also initialise the empty cell array for the value functions
        obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
        % And for the linear feedback matrix
        obj.K = cell( obj.statsPredictionHorizon+1 , 1 );
    else
        
        %% STRUCTURE FOR THE FOLLOWING CODE
        
        %   If in need of "K"
        %       Check for "K"
        %       If found "K"
        %           Load "K"
        %       else
        %           Set flag that "K" needs to be computed
        %           Therefore, also set flag that "P" is needed
        %       end
        %   else
        %       Set flag that "K" does not need to be computed
        %   end
        %
        %   If in need of "P"
        %       Check for "P"
        %       If found "P"
        %           Load "P"
        %       else
        %           Set flag that "P" needs to be computed
        %       end
        %   else
        %       Set flag that "P" does not need to be computed
        %   end
        %   
        %
        %   If flag that "P" needs to be computed == true
        %       compute "P"
        %       save "P"
        %   end
        %   If flag that "K" needs to be computed == true
        %       compute "K"
        %       save "K"
        %   end
        %
        %   "P" and/or "K" now exist in the workspace as required
        
        
        %% ------------------------------------------------------------- %%
        %% SET THE FLAGS FOR WHETHER "P" OR "K" IS REQUIRED
        if obj.computeAllVsAtInitialisation
            if obj.usePWAPolicyApprox
                flag_need_P = false;
                flag_need_K = true;
            else
                flag_need_P = true;
                flag_need_K = false;
            end
        else
            % THIS SHOULD NOT HAPPEN BECAUSE WHEN SHOULD ONLY HAVE ENTERED
            % THIS FUNCITON IF IT WAS REQUESTED TO
            % "computeAllVsAtInitialisation"
            % But initialise the empty cell array for the value functions
            obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
            obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
            obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
            % And for the linear feedback matrix
            obj.K = cell( obj.statsPredictionHorizon+1 , 1 );
        end
        
        
        %% ------------------------------------------------------------- %%
        %% FIRST CHECK IF THERE IS A MATCHING SET OF MATRICES THAT WAS SAVED PREVIOUSLY

        % Set any flags here that need to be initilaised
        flag_available_P = false;
        flag_available_K = false;
        
        %% If in need of "K"
        if flag_need_K
            % Check for "K"
            clear specsForCheck;
            specsForCheck = vararginLocal;
            specsForCheck.modelID = inputModelID;
            specsForCheck.disturbanceID = inputDisturbanceID;

            % Check if we already have a saved version of "K"
            [flag_matchFound_K , index_of_K] = Control_ADPCentral_Local.saveLoadCheckFor( 'check_K_PWA' , specsForCheck );
            
            % If found "K"
            if flag_matchFound_K
                % Then load "K"
                
                % Adjust the iteration counter
                obj.iterationCounter = distFullTimeCycleSteps;
                obj.numVsInitialised = distFullTimeCycleSteps;

                % Load the matrices for the previously computed value functions
                clear specsForLoad;
                specsForLoad.type = 'K';
                specsForLoad.index = index_of_K;
                [flag_loaded_K , tempLoad] = Control_ADPCentral_Local.saveLoadCheckFor( 'load' , specsForLoad );

                % Extract the matrices from the result is loaded successfully
                if flag_loaded_K
                    K = tempLoad.K;
                    % And set the flag that we don't need to compute it
                    flag_compute_K = false;
                    % Also a flag that "K" is avilable
                    flag_available_K = true;
                else
                    % If the load failed then set a flag that "K" needs to
                    % be computed
                    flag_compute_K = true;
                    % Therefore, also set flag that "P" is needed
                    flag_need_P = true;
                end
            else
                % Else, "K" was NOT found, so set a flag that "K" needs to
                % be computed
                flag_compute_K = true;
                % Therefore, also set flag that "P" is needed
                flag_need_P = true;
            end
        else
            % Else, "K" is NOT needed, so set a flag that "K" does NOT
            % need to be computed
            flag_compute_K = false;
        end
        
        
        %% If in need of "P"
        if flag_need_P
            % Check for "P"
            clear specsForCheck;
            specsForCheck = vararginLocal;
            specsForCheck.modelID = inputModelID;
            specsForCheck.disturbanceID = inputDisturbanceID;

            % Check if we already have a saved version of "P"
            [flag_matchFound , index_of_P] = Control_ADPCentral_Local.saveLoadCheckFor( 'check_P' , specsForCheck );
            
            % If found "P"
            if flag_matchFound
                % Then load "P"
                
                % Adjust the iteration counter
                obj.iterationCounter = distFullTimeCycleSteps;
                obj.numVsInitialised = distFullTimeCycleSteps;

                % Load the matrices for the previously computed value functions
                clear specsForLoad;
                specsForLoad.type = 'P';
                specsForLoad.index = index_of_P;
                [flag_loaded_P , tempLoad] = Control_ADPCentral_Local.saveLoadCheckFor( 'load' , specsForLoad );

                % Extract the matrices from the result is loaded successfully
                if flag_loaded_P
                    P = tempLoad.P;
                    p = tempLoad.p;
                    s = tempLoad.s;
                    % And set the flag that we don't need to compute it
                    flag_compute_P = false;
                    % Also a flag that "P" is avilable
                    flag_available_P = true;
                else
                    % If the load failed then set a flag that "P" needs to
                    % be computed
                    flag_compute_P = true;
                end
            else
                % Else, "P" was NOT found, so set a flag that "P" needs to
                % be computed
                flag_compute_P = true;
            end
        else
            % Else, "P" is NOT needed, so set a flag that "P" does NOT
            % need to be computed
            flag_compute_P = false;
        end
        
            
        %% ------------------------------------------------------------- %%
        %% NOW COMPUTE "P" AND "K" AS REQUIRED
        
        
        %% Adjust the iteration counter
        obj.iterationCounter = distFullTimeCycleSteps;
        obj.numVsInitialised = distFullTimeCycleSteps;
        
        %% ------------------------------------------------------------- %%
        %% COMPUTE "P"
        %% flag that "P" needs to be computed == true
        if flag_compute_P
            % Then compute "P"

            %% A \hat{V} is required every time step for the "Full Cycle Time"
            % of the Disturbance Model, hence initialise the cell arrays as
            % such
            P = cell( distFullTimeCycleSteps , 1 );
            p = cell( distFullTimeCycleSteps , 1 );
            s = cell( distFullTimeCycleSteps , 1 );


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

            % @TODO - this is a hard code setting the energy cost to zero
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

                fprintf('%-3d',iStep);

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
                    P{iStep+iStore-1} = P_temp{iStore,1};
                    p{iStep+iStore-1} = p_temp{iStore,1};
                    s{iStep+iStore-1} = s_temp{iStore,1};
                end


            end   % END OF: "for iStep = 1 : obj.computeVEveryNumSteps : distFullTimeCycleSteps"

            % SAVE THE COMPUTED V's SO THEY CAN BE USED AGAIN TO SAVE TIME
            clear specsForSave;
            specsForSave.type = 'P';
            
            varargin_forSave = vararginLocal;
            varargin_forSave.modelID = inputModelID;
            varargin_forSave.disturbanceID = inputDisturbanceID;
            specsForSave.vararginLocal = varargin_forSave;
            
            specsForSave.P = P;
            specsForSave.p = p;
            specsForSave.s = s;
            
            [flag_saved_P , ~] = Control_ADPCentral_Local.saveLoadCheckFor( 'save' , specsForSave );

            
            % SET THE FLAG THAT "P" IS NOW AVAILABLE
            if flag_saved_P
                flag_available_P = true;
            else
                flag_available_P = false;
            end
            
            
        
        end   % END OF: if "flag_compute_P"
        
        %% ------------------------------------------------------------- %%
        %% COMPUTE "K"
        %% flag that "K" needs to be computed == true
        if flag_compute_K
            % Then compute "K"

            %% A \hat{V} is required every time step for the "Full Cycle Time"
            % of the Disturbance Model, hence initialise the cell arrays as
            % such
            K = cell( distFullTimeCycleSteps , 1 );

            %% Initilise a temporary \hat{V} for computing for each horizon
            %K_temp = cell( obj.statsPredictionHorizon+1 , 1 );


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

            % @TODO - this is a hard code setting the energy cost to zero
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
            %% Now we step through the \hat{V} already computed and compute a "K" for each on
            % the "Full Cycle Time" of the Disturbance Model
            % Stepping in blocks of the "computeVEveryNumSteps" interval
            for iStep = 1 : distFullTimeCycleSteps

                fprintf('%-3d',iStep);

                % Get the predicition information at this step for the
                % prediciton horizon
                this_prediction = getPredictions( inputDistCoord , statsRequired_mask , iStep , double(1) );

                % Extrace the Disturbance moments from the predicition
                thisRange   = 1:n_xi;
                thisExi     = this_prediction.mean(thisRange,1);
                thisExixi   = this_prediction.cov(thisRange,thisRange);
                
                % SPECIFY THE FITTIG RANGE
                internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
                x_lower = obj.VFitting_xInternal_lower * internalStates  +  obj.VFitting_xExternal_lower * ~internalStates;
                x_upper = obj.VFitting_xInternal_upper * internalStates  +  obj.VFitting_xExternal_upper * ~internalStates;
                u_lower = myConstraints.u_rect_lower;
                u_upper = myConstraints.u_rect_upper;

                % Get the value function for the future time step
                thisP = P{iStep};
                thisp = p{iStep};
                thiss = s{iStep};
                
                % SPECIFY THE MOMENTS OF "x" TO USE IN THE FITTING
                thisEx = [];
                thisExx = [];

                % Pass everything to a ADP Sampling method
                [Knew] = performADP_fitPWA_toP(obj , thisP, thisp, thiss, thisExi, thisExixi, thisEx , thisExx, A, Bu, Bxi, Q, R, S, q, r, c, x_lower, x_upper, u_lower, u_upper , obj.PMatrixStructure);

                K{iStep,1} = Knew;

            end   % END OF: "iStep = 1 : distFullTimeCycleSteps"

            % SAVE THE COMPUTED V's SO THEY CAN BE USED AGAIN TO SAVE TIME
            clear specsForSave;
            specsForSave.type = 'K';
            
            varargin_forSave = vararginLocal;
            varargin_forSave.modelID = inputModelID;
            varargin_forSave.disturbanceID = inputDisturbanceID;
            specsForSave.vararginLocal = varargin_forSave;
            
            specsForSave.K = K;
            
            [flag_saved_K , ~] = Control_ADPCentral_Local.saveLoadCheckFor( 'save' , specsForSave );
            
            % SET THE FLAG THAT "P" IS AVAILABLE
            if flag_saved_K
                flag_available_K = true;
            else
                flag_available_K = false;
            end
        end
        
        
        
        % Now put the "P" matrices into the object
        if flag_available_P
            obj.P = P;
            obj.p = p;
            obj.s = s;
        end
        % Also put the "K" matrices into the object
        if flag_available_K
            obj.K = K;
        end
        
        
        %% ------------------------------------------------------------- %%
        %% PLOT THE LOWER BOUND FOR INTEREST
        if false
            % PLOT THE LOWER BOUND FOR INTEREST
            % Uniform DIstribution on x
            internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
            x_lower = obj.VFitting_xInternal_lower * internalStates  +  obj.VFitting_xExternal_lower * ~internalStates;
            x_upper = obj.VFitting_xInternal_upper * internalStates  +  obj.VFitting_xExternal_upper * ~internalStates;
            Ex  = 0.5 * (x_lower + x_upper);
            Exx = 1/3 * diag( (x_lower.^2 + x_lower.*x_upper + x_upper.^2) );

            thisObj = zeros(distFullTimeCycleSteps,1);
            for iStep = 1 : distFullTimeCycleSteps

                thisP = obj.P{iStep};
                thisp = obj.p{iStep};
                thiss = obj.s{iStep};


                thisObj(iStep,1) = ( trace( thisP * Exx ) + 2 * Ex' * thisp + thiss );

            end

            figure;
            plot( 1:distFullTimeCycleSteps , thisObj );
        end        
        
        
        
    end   % END OF: "else rem( distFullTimeCycleSteps , obj.computeVEveryNumSteps ) == 0"
    
    
            
end
% END OF FUNCTION