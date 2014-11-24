function initialiseControllers( obj , inputSettings , inputModel)
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

%% --------------------------------------------------------------------- %%
%% CHECK IF ALREADY INITIALISED (before doing anything else)
    % Check if already initialised
    checkInit = obj.initialised;
    if checkInit
        disp(' ... ERROR: This Global Coordinator was already initialised');
        disp('            It is not allowed to initialise it twice');
        error(bbConstants.errorMsg);
    end

%% --------------------------------------------------------------------- %%
%% GET THE VARIOUS FLAGS AND SETTINGS
    % Get the "Model Free" flag
    myModelFree = inputSettings.modelFree;
    if ( myModelFree )
        inputModel = [];
    end
    
    % Get the "Global Initialisation" flag
    myGlobalInit = inputSettings.globalInit;

    % Get the "SUGGESTED" number of controllers
    myNumControllers = obj.stateDef.n_ss;
    
%% --------------------------------------------------------------------- %%
%% CHECK THAT THE MODEL IS PRESENT AND VALID (if Model-Based control)
    % If "Model-Based" then check...
    if ~myModelFree
        %  that the inputModel variable is not empty
        if isempty(myModelFree)
            disp(' ... ERROR: The controller is specified as MODEL-BASED but');
            disp('            the model passed in for initialisation is an empty object');
            error(bbConstants.errorMsg);
        end
        % and that it is of the appropriate class
        bbConstants.checkObjIsSubclassOf(inputModel,'ModelCostConstraints',1);
        % and that it is concrete
        bbConstants.checkObjConcrete(inputModel,1);
    end    
    
    
    
%% --------------------------------------------------------------------- %%
%% INITIALISE THE GLOBAL CONTROLLERS - if requested to
% As we have set of "inputModel" to be empty when the "Model-Free" flag is
% true, we can call the initialise functions in the same manner
    if myGlobalInit
        % Make a function handle of the Global Controller class name
        myClassFuncGlobal = str2func( obj.classNameGlobal );
        % Create a Global Control object of type "myClassNameGlobal"
        tempGlobalControllerObject = myClassFuncGlobal( obj.stateDef , obj.constraintDef );
        
        % Check that this Global Controller Class is a subclass of
        % "Control_GlobalController" and that it is a concrete class:
        flag_throwError = true;
        bbConstants.checkObjIsSubclassOf(   tempGlobalControllerObject , 'Control_GlobalController' , flag_throwError );
        bbConstants.checkObjConcrete(       tempGlobalControllerObject , flag_throwError );
        
        % Now save the Global Controller to the appropriate property
        obj.globalController = tempGlobalControllerObject;

        % Initialisation function required of all Global Controllers that
        % are a subclass of "Control_GlobalController"
        [flag_ControlStructureChanged , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss] = initialise_globalControl( obj.globalController , obj.modelType , inputModel , obj.vararginGlobal);
        
        % If the Control Structure was Changed by this Global
        % Initialisation function then we need to update the State
        % Definition object
        if flag_ControlStructureChanged
            disp(' ... NOTE: The Global Initialisation of the controllers returned a different control structure to that specified by the model');
            disp(['           Updating to have ',num2str(new_n_ss),' local controllers, versus the model specified number of ',num2str(myNumControllers) ]);
            
            % First check that the new set of masks is compatible with the
            % state, input, and disturbance sizes in the state def.
            % Additionally this checks that the all inputs are specified
            % uniquely
            returnIsValid = checkMasksAreValid( obj.stateDef , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss );
            
            % Reject if not valid
            if ~returnIsValid
                disp(' ... ERROR: the new control strucutre specified was NOT valid');
                error(bbConstants.errorMsg);
            else
                % Update the number of controllers
                myNumControllers = new_n_ss;
                obj.numControllers = myNumControllers;
                % Update the State Definiton object
                updateMasks( obj.stateDef , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss )
            end
        end
        
    else
        %disp(' ... INFO: A global controller object was not requested and hence has not been created for this control technique.');
        obj.numControllers = myNumControllers;
        
        % Set the global controller to be empty
        %obj.globalController = [];
    end

    
%% --------------------------------------------------------------------- %%
%% INITIALISE THE LOCAL CONTROLLERS - if requested to

    % NOTE: An important thing is that by this point the property
    % "numControllers" should be set
    
    % Make a function handle of the Global Controller class name
    myClassFuncLocal = str2func( obj.classNameLocal );
    % Create a Global Control object of type "myClassNameGlobal"
    tempLocalControllerObjectArray(obj.numControllers,1) = myClassFuncLocal();

    % Check that this Local Controller Class is a subclass of
    % "Control_GlobalController" and that it is a concrete class:
    flag_throwError = true;
    bbConstants.checkObjIsSubclassOf(   tempLocalControllerObjectArray(1,1) , 'Control_LocalController' , flag_throwError );
    bbConstants.checkObjConcrete(       tempLocalControllerObjectArray(1,1) , flag_throwError );

    % Iterate through the controllers
    for iController = 1:myNumControllers
        % Create a partial "State Definition" object for this sub-system
        thisStateDef = requestPartialStateDefForGivenSubSystem( obj.stateDef , iController );
        
        % Create a partial "Constraint Definition" object for this sub-system
        thisConstraintDef = requestPartialConstraintDefForGivenSubSystem( obj.constraintDef , thisStateDef , obj.stateDef , iController );
        
        % Now create the constroller for this sub-system
        tempLocalControllerObjectArray(iController,1) = myClassFuncLocal( uint32(iController) , thisStateDef , thisConstraintDef , obj.globalController);
        
        % And initilise it
        flag_successfullyInitialised = initialise_localControl( tempLocalControllerObjectArray(iController,1) , obj.modelType , inputModel , obj.vararginLocal);
        
        % Check that the initialisation was successful
        if ~flag_successfullyInitialised
            disp(' ERROR: ...')
            error(bbConstants.errorMsg);
        end
    end

    % Finally store the array of Local Controller objects into the
    % approproate property
    obj.localControllerArray = tempLocalControllerObjectArray;
    clear tempLocalControllerObjectArray;
    
    
    
%% --------------------------------------------------------------------- %%
%% COLLECT A LIST OF THE STATASTICS REQUIRED
% Get the list of stats that need to be computed we should iterate
% through each local controller and get the list of all stats required
    
    % Initialise a blank cell array for the list of stats
    numStatsRequired = 0;
    statsRequired = cell( numStatsRequired , 1);
    
    % Iterate through the controllers
    for iController = 1:myNumControllers
        % Get the stats cell array of string for this Controller
        thisStatsRequired = obj.localControllerArray(1).statsRequired;
        % Get the number of stats in the list
        thisNumStats = length( thisStatsRequired );
        % Iterate through the stats
        for iStat = 1:thisNumStats
            % Get this stat
            thisStat = thisStatsRequired{iStat};
            % Check if it is a member
            thisCheck = ismember( thisStat , statsRequired );
            % Create the check that confirms if it was a member or not
            thisIsMemberCheck = ( sum(thisCheck) == 0 );
            % If "thisStat" is not a member of "statsRequired" then add it,
            % only if it is a valid stat to ask for
            if thisIsMemberCheck
                % Check that "thisStat" is a member of the recognised stat
                % string stored in "bbConstants.stats_numPossibleStats"
                thisCheck = ismember( thisStat , bbConstants.stats_numPossibleStats );
                thisIsMemberCheck = ( sum(thisCheck) == 0 );
                if thisIsMemberCheck
                    numStatsRequired = numStatsRequired + 1;
                    statsRequired{numStatsRequired,1} = thisStat;
                else
                    disp([' ... ERROR: an unrecognised statistic string was requested by Local Controller number ',num2str(iController) ]);
                    disp(['            The statistic string requested was: ',thisStat ]);
                end
            end
        end
    end

    % Finally put the list into the appropriate property
    obj.distStatsRequired = statsRequired;
    clear statsRequired;

end
% END OF FUNCTION

% The "inputSettings" variable should be a struct with the following
% properties:
%    .modelFree
%    .trueModelBased     = thisController.trueModelBased;
%    .globalInit