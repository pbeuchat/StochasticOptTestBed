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
        
        %% FIRST CHECK IF THERE IS A MATCHING SET OF MATRICES THAT WAS SAVED PREVIOUSLY
        
        flag_matchFound = false;
        
        mySaveDataPath = constants_MachineSpecific.saveDataPath;
        adpFolderName = 'ADP_SavedControllers';
        adpFolderPath_full = [ mySaveDataPath , adpFolderName , filesep ];
        % Check that there is already a folder of the ADP matrices
        if (exist(adpFolderPath_full,'dir') == 7)
        
            % Now check if there is already a index file for what controllers
            % are saved
            adpIndexFileName = 'adp_SavedControllersIndex';
            adpIndexFileName_full = [ adpFolderPath_full , adpIndexFileName , '.mat' ];
        
            % If it exists then load it 
            if (exist(adpIndexFileName_full,'file') == 2)
                tempload = load( adpIndexFileName_full );
                adpIndex = tempload.adpIndex;
                apdIndexLength = size(adpIndex,1);
                
                % Now look for a match
                for iTemp = 1:apdIndexLength
                    thisEntry = adpIndex{iTemp,1}.vararginLocal;
                    thisEntry_fields = fields(thisEntry);
                    varargin_fields  = fields(vararginLocal );
                    thisEntry_numfields = length( thisEntry_fields );
                    varargin_numfields  = length( varargin_fields );
                    % Check they have the same number of fields
                    if thisEntry_numfields == varargin_numfields
                        flag_mathcingFieldNames = true;
                        % Check the fields have the same name
                        for iField = 1:thisEntry_numfields
                            if ~ismember( thisEntry_fields{iField} , varargin_fields)
                                flag_mathcingFieldNames = false;
                            end
                        end
                        if flag_mathcingFieldNames
                            flag_mathcingFieldData = true;
                            % Now check that the data in each field is the
                            % same
                            for iField = 1:thisEntry_numfields
                                thisFieldData = thisEntry.(thisEntry_fields{iField});
                                if isa( thisFieldData , 'double' ) || isa( thisFieldData , 'logical' )
                                    if thisFieldData ~= vararginLocal.(thisEntry_fields{iField})
                                        flag_mathcingFieldData = false;
                                    end
                                elseif isa( thisFieldData , 'char' )
                                    if ~strcmp( thisFieldData , vararginLocal.(thisEntry_fields{iField}) )
                                        flag_mathcingFieldData = false;
                                    end
                                else
                                    flag_mathcingFieldData = false;
                                end
                            end
                            if flag_mathcingFieldData
                                flag_matchFound = true;
                                index_ofMatchFound = iTemp;
                            end
                        end
                    end
                end
            end
        end
        
        if flag_matchFound
            matricesFolderName = 'Matrices';
            matricesFolderPath_full = [ adpFolderPath_full , matricesFolderName , filesep ];
            if ~(exist(matricesFolderPath_full,'dir') == 7)
                flag_matchFound = false;
            end
        end
        
        % If a match was found then load the matrices rather than computing
        % them
        if flag_matchFound
            
            % Adjust the iteration counter
            obj.iterationCounter = distFullTimeCycleSteps;
            obj.numVsInitialised = distFullTimeCycleSteps;
            
            % Load the matrices for the previously computed value functions
            tempload = load( [matricesFolderPath_full, filesep, adpIndex{index_ofMatchFound,1}.P_fileName, '.mat'] );
            P = tempload.P;
            tempload = load( [matricesFolderPath_full, filesep, adpIndex{index_ofMatchFound,1}.p_fileName, '.mat'] );
            p = tempload.p;
            tempload = load( [matricesFolderPath_full, filesep, adpIndex{index_ofMatchFound,1}.s_fileName, '.mat'] );
            s = tempload.s;
        
            
        else
        
        
            %% Adjust the iteration counter
            obj.iterationCounter = distFullTimeCycleSteps;
            obj.numVsInitialised = distFullTimeCycleSteps;

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

                temp = 1;

            end   % END OF: "for iStep = 1 : obj.computeVEveryNumSteps : distFullTimeCycleSteps"


            % SAVE THE COMPUTED V's SO THEY CAN BE USED AGAIN TO SAVE TIME
            mySaveDataPath = constants_MachineSpecific.saveDataPath;

            adpFolderName = 'ADP_SavedControllers';

            adpFolderPath_full = [ mySaveDataPath , adpFolderName , filesep ];

            % Check that there is already a folder of the ADP matrices
            % ... creating one if required
            if ~(exist(adpFolderPath_full,'dir') == 7)
                mkdir(adpFolderPath_full);
            end

            % Now check if there is already a folder of the actual matrices
            matricesFolderName = 'Matrices';

            matricesFolderPath_full = [ adpFolderPath_full , matricesFolderName , filesep ];

            if ~(exist(matricesFolderPath_full,'dir') == 7)
                mkdir(matricesFolderPath_full);
            end

            % Now check if there is already a index file for what controllers
            % are saved
            adpIndexFileName = 'adp_SavedControllersIndex';

            adpIndexFileName_full = [ adpFolderPath_full , adpIndexFileName , '.mat' ];

            % If it exists then load it, otherwise 
            if (exist(adpIndexFileName_full,'file') == 2)
                tempload = load( adpIndexFileName_full );
                adpIndex = tempload.adpIndex;
                apdIndexLength = size(adpIndex,1);
            else
                adpIndex = cell(0,1);
                apdIndexLength = 0;
            end

            % Generate a file name for this controller using the clock
            [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();
            temp_fileNamePrefix = [currDateStr, '_', currTimeStr];

            % Now add the details to the index
            adpIndex{apdIndexLength+1,1}.vararginLocal = vararginLocal;
            adpIndex{apdIndexLength+1,1}.P_fileName = [temp_fileNamePrefix , '_P_quad'];
            adpIndex{apdIndexLength+1,1}.p_fileName = [temp_fileNamePrefix , '_p_lin'];
            adpIndex{apdIndexLength+1,1}.s_fileName = [temp_fileNamePrefix , '_s_const'];

            % Now save the matrices
            save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_P_quad', '.mat'], 'P', '-v7.3');
            save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_p_lin', '.mat'], 'p', '-v7.3');
            save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_s_const', '.mat'], 's', '-v7.3');
            
            % And save the index back
            save(adpIndexFileName_full, 'adpIndex', '-v7.3');
            
        
        end   % END OF: flag_matchFound
        
        
        % Now put the matrices into the object
        obj.P = P;
        obj.p = p;
        obj.s = s;
        
        
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