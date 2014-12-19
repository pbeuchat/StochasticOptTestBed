function returnIsCompatible = checkSimulationCompatability( obj , flag_throwError )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    % Initialise an compatability tracking variable
    % Default to true, and if anything is incompatibile then set to "false"
    returnIsCompatible = true;
    
    % NOTE: that alot of these checks should go through without problem
    % because the "StateDef" object is passed around when initialising most
    % object. The most likely discrepancy is like to occur for the size of
    % the Disturbance variable (\xi) because the the Disturbance Model is
    % specified separately of the System (aka Plant) model, and the
    % controller is expected to adapt to the sizes
    
    %% Check that Disturbance Statistics Required by the Controller are
    % avilable from the Disturbance Coordinator
    % Get the disturbances required by the controller
    distStat_RequiredByController = obj.controlCoord.distStatsRequired;
        % We will assume this is a cell array of strings based on the
        % assumption that the Control Coordination implements such a check
    % Check that these stats are available from the disturbance Coordinator
    flag_recomputeStats = false;
    distStat_isCompatable_withControl = checkStatsAreAvailable_ComputingAsRequired( obj.distCoord , distStat_RequiredByController , flag_recomputeStats);
    if ~distStat_isCompatable_withControl
        disp(' ... ERROR: the Disturbance Coordinator does not have the statistics required by the controller');
        disp('            Specifically, the statistics requested by the controller are:');
        disp(distStat_RequiredByController);
        % Throw an error if requested
        if flag_throwError
            error(bbConstants.errorMsg);
        end
        % Set the return flag to be not compatible
        returnIsCompatible = false;
    end

    
    %% Check that the Controller is expecting the same size state variable
    % dimension that the Plant will output
    % Should be true by construction
    
    
    %% Check that the Plant is expecting the same size input variable
    % dimension that the Controller will output
    % Should be true by construction
    
    
    %% Check that the Plant is expecting the same size disturbance variable
    % dimension that the Disturbance Variable will output
    % Get a 1-time-step disturbance sample, and take "n_xi" as the length
    tempTime = 1;
    distSample = getDisturbanceSampleForOneTimeStep( obj.distCoord , tempTime );
    n_xi_accordingToDist = length(distSample);
    % Get the "n_xi" expected by the plant directly from the State Def.
    n_xi_accordingToPlant = obj.stateDef.n_xi;
    clear distSample;
    % Check the compatability
    if ( n_xi_accordingToDist  ~=  n_xi_accordingToPlant )
        % Display some info about the error
        disp(' ... ERROR: The simulation components are not compatibile');
        disp('            Specifically the "Disturbance" module and "Plant" module did not agree on "n_xi"');
        disp(['            According to the "Disturbance" module,   "n_xi" = ',num2str(n_xi_accordingToDist) ]);
        disp(['            According to the "Plant" module,         "n_xi" = ',num2str(n_xi_accordingToPlant) ]);
        % Throw an error if requested
        if flag_throwError
            error(bbConstants.errorMsg);
        end
        % Set the return flag to be not compatible
        returnIsCompatible = false;
    end
    
    
    %% IF PRE-COMPUTED DISTURBANCE DATA WAS SUPLIED, THEN CHECK THAT IT IS COMPATIBLE
    if obj.flag_precomputedDisturbancesAvailable
        % Check that it is not empty
        if ~isempty( obj.precomputedDisturbances )
            % Get the size of the data
            [ tempHeight , tempWidth ] = size( obj.precomputedDisturbances );
            % Check that the height agrees with "n_xi" and that the width
            % agrees with the time duration
            tempDuration = obj.simTimeIndex_end - obj.simTimeIndex_start;
            if (tempHeight ~= n_xi_accordingToPlant) || (tempWidth ~= tempDuration)
                disp( ' ... ERROR: the size of the "precomputedDisturbances" was not as expected' );
                disp(['            size(obj.precomputedDisturbances) = ',num2str(tempHeight),' -by- ',num2str(tempWidth) ]);
                disp(['            size( expected )                  = ',num2str(n_xi_accordingToPlant),' -by- ',num2str(tempDuration) ]);
            end
        else
            disp( ' ... ERROR: the flag specifies to use Precopmuted Disturbance Data' );
            disp( '            BUT the "precomputedDisturbances" property is empty' );
            disp( '            HENCE changing the flag to "false"' );
            obj.flag_precomputedDisturbancesAvailable = false;
        end
        
    end
    
    
    %% Set the flag of the Simulation Coordinator Object
    obj.flag_componentsAreCompatible = returnIsCompatible;
    
            
end
% END OF FUNCTION