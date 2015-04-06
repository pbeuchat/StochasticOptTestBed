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



    % This function is called in response to the "initialise_localControl"
    % function returning the "flag_requestDisturbanceData" flag as true
    % Access to the disturbance data should only be used for computational
    % speed up purposes
    
    %% LET THE USER KNOW THAT THIS COULD TAKE A WHILE
    disp( ' ... NOTE: Now computing all LQR Controllers for the Full Cycle of the Disturbance Model' );
    disp( '           This could take quite some time... depending on problem size' );
    
    
    
    %% EXTRACT THE OPTIONS FROM THE "vararginLocal" INPUT VARIABLE
    if isstruct( vararginLocal )
        % Actually this should have been done in the
        % "initialise_localControl" function and all the options should
        % have been stored in the respective properties of "obj"
    else
        disp( ' ... ERROR: the "vararginLocal" variable was not a struct and hence cannot be processed' );
        disp( '            But really is should have been processed in the "initialise_localControl" function,' );
        disp( '            so if there really is a problem with "vararginLocal", then there should also be previous' );
        disp( '            errors displayed describing the problem.' );
    end
    
    
    %% NOW PERFORM THE INITIALISATION
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % All the LQR Controllers will be computed at once so that multiple
    % scenarios can be played at maximum computational speed
    
    % It is preferable that the regularilty of re-computing the LQR
    % Controllers fits exactly into the total time horizon of the
    % disturbance
    
    % Get the duration of the disturbance definition
    thisFileName = mfilename;
    distFullTimeCycleSteps = getDisturbanceModelFullTimeCycle_forLocalController( inputDistCoord , thisFileName );
    
    
    % Check that the remainder is zero when divided by the regularity with
    % which controllers should be recomputed
    if ~rem( distFullTimeCycleSteps , obj.computeKEveryNumSteps ) == 0
        disp( ' ... ERROR: The Full Time Cycle of the disturbance model is NOT divisible (remainder zero) ');
        disp( '            by the regularity which which the Approx. Value Functions are to be ');
        disp( '            recomputed. ');
        disp( '            This method has not been setup to handle such a case. Switching back to' );
        disp( '            computing the LQR Controllers "on-the-fly"' );
        
        % Set the flag to reflect this error
        obj.computeAllKsAtInitialisation = false;
        
        % Also initialise the empty cell array for the value functions
        obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
        % And for the linear feedback matrix
        obj.K = cell( obj.statsPredictionHorizon+1 , 1 );
    else
        
        %% ------------------------------------------------------------- %%
        %% SET THE FLAGS FOR WHETHER "P" OR "K" IS REQUIRED
        if obj.computeAllKsAtInitialisation
            flag_need_K = true;
        else
            % THIS SHOULD NOT HAPPEN BECAUSE WHEN SHOULD ONLY HAVE ENTERED
            % THIS FUNCITON IF IT WAS REQUESTED TO
            % "computeAllKsAtInitialisation"
            % But initialise the empty cell array for the LQR Controllers
            obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
            obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
            obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
            obj.K = cell( obj.statsPredictionHorizon+1 , 1 );
            flag_need_K = false;
        end
        
        
        %% ------------------------------------------------------------- %%
        %% FIRST CHECK IF THERE IS A MATCHING SET OF MATRICES THAT WAS SAVED PREVIOUSLY

        % Set any flags here that need to be initilaised
        flag_available_K = false;
        
        %% If in need of "K"
        if flag_need_K
            % Check for "K"
            clear specsForCheck;
            specsForCheck = vararginLocal;
            specsForCheck.modelID = inputModelID;
            specsForCheck.disturbanceID = inputDisturbanceID;

            % Check if we already have a saved version of "K"
            [flag_matchFound_K , index_of_K] = Control_LQRCentral_Local.saveLoadCheckFor( 'check' , specsForCheck );
            
            % If found "K"
            if flag_matchFound_K
                % Then load "K"
                
                % Adjust the iteration counter
                obj.iterationCounter = distFullTimeCycleSteps;
                obj.numKsInitialised = distFullTimeCycleSteps;

                % Load the matrices for the previously computed value functions
                clear specsForLoad;
                specsForLoad.type = 'K';
                specsForLoad.index = index_of_K;
                [flag_loaded_K , tempLoad] = Control_LQRCentral_Local.saveLoadCheckFor( 'load' , specsForLoad );

                % Extract the matrices from the result is loaded successfully
                if flag_loaded_K
                    K = tempLoad.K;
                    P = tempLoad.P;
                    p = tempLoad.p;
                    s = tempLoad.s;
                    % And set the flag that we don't need to compute it
                    flag_compute_K = false;
                    % Also a flag that "K" is available
                    flag_available_K = true;
                else
                    % If the load failed then set a flag that "K" needs to
                    % be computed
                    flag_compute_K = true;
                end
            else
                % Else, "K" was NOT found, so set a flag that "K" needs to
                % be computed
                flag_compute_K = true;
            end
        else
            % Else, "K" is NOT needed, so set a flag that "K" does NOT
            % need to be computed
            flag_compute_K = false;
        end
        
        
        % FOR DEBUGGING PURPOSES
        %flag_compute_K = true;
        %flag_need_P = true;
        
            
        %% ------------------------------------------------------------- %%
        %% NOW COMPUTE THE LQR CONTROLLERS (the "K"'s)
        
        
        %% First, adjust the iteration counter
        obj.iterationCounter = distFullTimeCycleSteps;
        obj.numKsInitialised = distFullTimeCycleSteps;
        
        %% ------------------------------------------------------------- %%
        %% COMPUTE "K"
        %% If flag that "K" needs to be computed == true
        if flag_compute_K
            % Then compute "K"

            %% A Value Function "P" is required every time step for the "Full Cycle Time"
            % of the Disturbance Model, hence initialise the cell arrays as
            % such
            P = cell( distFullTimeCycleSteps , 1 );
            p = cell( distFullTimeCycleSteps , 1 );
            s = cell( distFullTimeCycleSteps , 1 );
            
            K = cell( distFullTimeCycleSteps , 1 );


            %% Initilise a temporary "P" for computing for each horizon
            P_temp = cell( obj.statsPredictionHorizon+1 , 1 );
            p_temp = cell( obj.statsPredictionHorizon+1 , 1 );
            s_temp = cell( obj.statsPredictionHorizon+1 , 1 );
            
            K_temp = cell( obj.statsPredictionHorizon   , 1 );



            %% GET A VARIETY OF OBJECTS REQUIRED
            % Extract the system matrices from the model
            myBuilding      = obj.model.building;
            myCosts         = obj.model.costDef;
            %myConstraints   = obj.model.constraintDef;

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

            % APPLY THE ENERGY TO COMFORT SCALING
            % If the "S" term is non-zero then this scaling doesn't make as
            % much sense
            r = obj.energyToComfortScaling*r;
            R = obj.energyToComfortScaling*R;

            % Display an error message if all Cost Components are not included
            if not(flag_allCostComponentsIncluded)
                disp( ' ... ERROR: not all of the cost components could be retireived');
                disp( '            This likely because at least one of the components is NOT a quadratic or linear function');
                disp( '            and this LQR implementation can only handle linear or quadratic cost terms');
            end

            % Get the size of the disturbance vector per interval
            n_xi = obj.stateDef.n_xi;

            % Get the stats required mask
            statsRequired_mask = bbConstants.stats_createMaskFromCellArray( obj.statsRequired );


            %% *** PARALLELISATION HINT ***
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



            %% Now we step through the "P-lqr" and "K-lqr" computations from the start up to ...
            % the "Full Cycle Time" of the Disturbance Model
            % Stepping in blocks of the "computeVEveryNumSteps" interval
            for iStep = 1 : obj.computeKEveryNumSteps : distFullTimeCycleSteps

                fprintf('%-3d',iStep);

                % Get the predicition information at this step for the
                % prediciton horizon
                this_prediction = getPredictions( inputDistCoord , statsRequired_mask , iStep , double(obj.statsPredictionHorizon) );

                % SPECIFY THE FITTIG RANGE
                %internalStates = [1 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 0  1 1 1 ]';
                %x_lower = obj.VFitting_xInternal_lower * internalStates  +  obj.VFitting_xExternal_lower * ~internalStates;
                %x_upper = obj.VFitting_xInternal_upper * internalStates  +  obj.VFitting_xExternal_upper * ~internalStates;
                %u_lower = myConstraints.u_rect_lower;
                %u_upper = myConstraints.u_rect_upper;


                % Initialise TERMINAL VALUE FUNCITON for the first iteration:
                % > To be purely the comfort cost (ie. the state portion of
                % the stage cost)
                P_temp{obj.statsPredictionHorizon+1} = Q;
                p_temp{obj.statsPredictionHorizon+1} = q;  % <<---- NOTE THE "0.5" HERE, OR THE LACK OF IT!!!!
                s_temp{obj.statsPredictionHorizon+1} = c;
                
                % > To be the solution of the Lyapunov Equation for this
                % system (ie. the infinte horizon autonomous cost to go)
                % Note: this only work if the system is stable
                %P_lyapunov = dlyap(A,Q);                
                % BUT DOES THIS MAKE SENSE?? Because we want to penalise
                % stable autonomous decay to the set-point, not to zero??
                
                

                % Print out a few things for where we are at:
                %mainfprintf('T=');

                %% RECURSIVE APPROACH: Now iterate backwards through the time steps
                for iTime = obj.statsPredictionHorizon : -1 : 1

                    % Get the first and second moment from the input prediciton struct
                    thisRange = ((iTime-1)*n_xi+1) : (iTime*n_xi);
                    thisExi     = this_prediction.mean(thisRange,1);
                    thisExixi   = this_prediction.cov(thisRange,thisRange);

                    % Get the value function for the future time step
                    thisP = P_temp{iTime+1};
                    thisp = p_temp{iTime+1};
                    thiss = s_temp{iTime+1};

                    % Pass everything to a LQR Recursion Method
                    discountFactor = 1;
                    [Pnew , pnew, snew, u0new, Knew] = Control_LQRCentral_Local.performLQR_singleIteration( discountFactor, thisP, thisp, thiss, thisExi, thisExixi, A, Bu, Bxi, Q, R, S, q, r, c );

                    P_temp{iTime,1} = Pnew;
                    p_temp{iTime,1} = pnew;
                    s_temp{iTime,1} = snew;
                    
                    K_temp{iTime,1} = [u0new , Knew];
                    
                    
                end

                %% Store the first "computeVEveryNumSteps" Value Functions
                for iStore = 1 : obj.computeKEveryNumSteps
                    P{iStep+iStore-1} = P_temp{iStore,1};
                    p{iStep+iStore-1} = p_temp{iStore,1};
                    s{iStep+iStore-1} = s_temp{iStore,1};
                    
                    K{iStep+iStore-1} = K_temp{iStore,1};
                end


            end   % END OF: "for iStep = 1 : obj.computeVEveryNumSteps : distFullTimeCycleSteps"

            % SAVE THE COMPUTED V's SO THEY CAN BE USED AGAIN TO SAVE TIME
            clear specsForSave;
            specsForSave.type = 'K';
            
            varargin_forSave = vararginLocal;
            varargin_forSave.modelID = inputModelID;
            varargin_forSave.disturbanceID = inputDisturbanceID;
            specsForSave.vararginLocal = varargin_forSave;
            
            specsForSave.P = P;
            specsForSave.p = p;
            specsForSave.s = s;
            
            specsForSave.K = K;
            
            [flag_saved_K , ~] = Control_LQRCentral_Local.saveLoadCheckFor( 'save' , specsForSave );

            
            % SET THE FLAG THAT "P" IS NOW AVAILABLE
            if flag_saved_K
                flag_available_K = true;
            else
                flag_available_K = false;
            end
            
            
        
        end   % END OF: if "flag_compute_K"
        
        
        
        %% NOW PUT THE "P" and/or "K" MATRICES INTO THE OBJECT (if available)
        
        % Now put the "K" matrices into the object
        if flag_available_K
            obj.K = K;
        end
        % And also put the "P" matrices into the object (Not that they will
        % ever be used)
        if flag_available_K
            obj.P = P;
            obj.p = p;
            obj.s = s;
        end
        
        
       
        
        
        
    end   % END OF: "else rem( distFullTimeCycleSteps , obj.computeVEveryNumSteps ) == 0"
    
    
            
end
% END OF FUNCTION