function [flag_successfullyInitialised , flag_requestDisturbanceData] = initialise_localControl( obj , inputModelType , inputModel , vararginLocal)
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

    % You can except the "inputModel" parameter to be empty when the
    % control is specified to be "Model-Free" and non-empty otherwise
    
    % In general this "flag_requestDisturbanceData" flag should be left as
    % "false" and only set to true if access to the disturbance data is
    % required for computational speed up purposes
    flag_requestDisturbanceData = false;
    
    % When using the "Null" controller as a template, insert your code here
    % to pre-compute off-line parts of your controllers so the the "on-line
    % computation time is minimised when the "copmuteControlAction"
    % function is called at each time step
    
    %% ----------------------------------------------------------------- %%
    %% SPECIFY A FEW DEFAULTS TO USE IN CASE A FIELDS IS MISSING FROM "vararginLocal"
    
    % FOR THE ADP METHOD TO USE:
    useMethod_samplingWithLSFit = false;
    useMethod_bellmanIneq       = true;
    
    % FOR THE PREDICITON HORIZON
    statsPredictionHorizon = uint32(12);
    
    % FOR THE REGULARILTY OF RECOMPUTING THE VALUE FUNCTIONS
    computeVEveryNumSteps = uint32(6);
    
    % FOR THE "P" MATRIX STRUCTURE TO ENFORCE
    PMatrixStructure = 'diag';
    
    % FOR THE FLAG ABOUT FITTING A PWA POLICY TO THE BELLMAN OPERATOR
    % (and the number of pieces to split each "x" dimension when doing it)
    usePWAPolicyApprox = false;
    liftingNumSidesPerDim = uint32(1);
    
    
    
    % THE STATE RANGE FOR WHERE TO FIT THE APPROXIMATE VALUE FUNCTION
    VFitting_xInternal_lower = 0;
    VFitting_xInternal_upper = 50;
    VFitting_xExternal_lower = 0;
    VFitting_xExternal_upper = 50;
    
    % THE "FIT ALL V's AT INITIALISATION" FLAG
    computeAllVsAtInitialisation = false;
    
    %% EXTRACT THE OPTIONS FROM THE "vararginLocal" INPUT VARIABLE
    if isstruct( vararginLocal )
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED ADP METHOD TO USE
        if isfield( vararginLocal , 'ADPMethod' )
            if strcmp( vararginLocal.ADPMethod , 'samplingWithLeastSquaresFit' )
                useMethod_samplingWithLSFit = true;
                useMethod_bellmanIneq       = false;
            elseif strcmp( vararginLocal.ADPMethod , 'bellmanInequality' )
                useMethod_samplingWithLSFit = false;
                useMethod_bellmanIneq       = true;
            else
                disp( ' ... ERROR: The specified ADP Method was not recognised');
                disp( '            The method specified was:');
                disp(vararginLocal.ADPMethod);
                disp( ' ... NOTE: Using the Bellman Inequality Method as a default');
            end
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "ADPMethod"');
            disp( ' ... NOTE: Using the Bellman Inequality Method as a default');
        end
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED TIME HORIZON TO USE
        if isfield( vararginLocal , 'predHorizon' )
            statsPredictionHorizon = uint32(vararginLocal.predHorizon);
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "predHorizon"');
            disp([' ... NOTE: Using the default of ',num2str(statsPredictionHorizon),' time steps']);
        end
            
        % --------------------------------------------------------------- %
        % GET THE REGULARILTY WITH WHICH THE VALUE FUNCTIONS SHOULD BE
        % RE-COMPUTED
        if isfield( vararginLocal , 'computeVEveryNumSteps' )
            computeVEveryNumSteps = uint32(vararginLocal.computeVEveryNumSteps);
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "computeVEveryNumSteps"');
            disp([' ... NOTE: Using the default of ',num2str(computeVEveryNumSteps),' time steps']);
        end
        
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED "P" MATRIX STRUCTURE TO ENFORCE
        if isfield( vararginLocal , 'PMatrixStructure' )
            PMatrixStructure = vararginLocal.PMatrixStructure;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "PMatrixStructure"');
            disp([' ... NOTE: Using the default of "',PMatrixStructure,'" instead']);
        end
        
        % --------------------------------------------------------------- %
        % GET THE FLAG FOR WHETHER TO "use a PWA Policy Approx" OR NOT
        if isfield( vararginLocal , 'usePWAPolicyApprox' )
            usePWAPolicyApprox = vararginLocal.usePWAPolicyApprox;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "usePWAPolicyApprox"');
            disp([' ... NOTE: Using the default of "',num2str(usePWAPolicyApprox),'" instead']);
        end
        
        % --------------------------------------------------------------- %
        % GET THE NUMBER OF SIDES IN WHICH TO SPLIT EACH DIMENSION
        if isfield( vararginLocal , 'liftingNumSidesPerDim' )
            liftingNumSidesPerDim = uint32( vararginLocal.usePWAPolicyApprox );
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain a field "liftingNumSidesPerDim"');
            disp([' ... NOTE: Using the default of "',liftingNumSidesPerDim,'" instead']);
        end
        
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED STATE FITTING RANGE FOR THE INTERNAL STATES
        if ( isfield( vararginLocal , 'VFitting_xInternal_lower' ) && isfield( vararginLocal , 'VFitting_xInternal_upper' ) )
            VFitting_xInternal_lower = vararginLocal.VFitting_xInternal_lower;
            VFitting_xInternal_upper = vararginLocal.VFitting_xInternal_upper;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the fields "VFitting_xInternal_lower" and "VFitting_xInternal_upper"');
            disp([' ... NOTE: Using the default of ',num2str(VFitting_xInternal_lower),' and ',num2str(VFitting_xInternal_upper),' respectively']);
        end
        
        % --------------------------------------------------------------- %
        % GET THE SPECIFIED STATE FITTING RANGE FOR THE EXTERNAL STATES
        if ( isfield( vararginLocal , 'VFitting_xExternal_lower' ) && isfield( vararginLocal , 'VFitting_xExternal_upper' ) )
            VFitting_xExternal_lower = vararginLocal.VFitting_xExternal_lower;
            VFitting_xExternal_upper = vararginLocal.VFitting_xExternal_upper;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the fields "VFitting_xExternal_lower" and "VFitting_xExternal_upper"');
            disp([' ... NOTE: Using the default of ',num2str(VFitting_xExternal_lower),' and ',num2str(VFitting_xExternal_upper),' respectively']);
        end
        
        % --------------------------------------------------------------- %
        % GET THE "FIT ALL V's AT INITIALISATION" FLAG
        if isfield( vararginLocal , 'computeAllVsAtInitialisation' ) 
            computeAllVsAtInitialisation = vararginLocal.computeAllVsAtInitialisation;
        else
            disp( ' ... ERROR: The "vararginLocal" did not contain the field "computeAllVsAtInitialisation"');
            disp([' ... NOTE: Using the default of "false"']);
        end
        
        
    else
        disp( ' ... ERROR: the "vararginLocal" variable was not a struct and hence cannot be processed');
    end
    
    
    %% PUT THE EXTRACTED OPTIONS INTO THE APPROPRIATE PROPERTIES OF THE OBJECT
    % Initialise the return flag
    flag_successfullyInitialised = true;
    
    % Store the model type in the appropriate property
    obj.modelType = inputModelType;
    
    % Store the model
    obj.model = inputModel;
    
    % Store the prediction horizon to be used
    obj.statsPredictionHorizon = statsPredictionHorizon;
    
    % Store the recomputation regularilty
    obj.computeVEveryNumSteps = computeVEveryNumSteps;
    
    % Initialise the counter so that V is computed during the first step
    obj.iterationCounter = obj.computeVEveryNumSteps;
    
    % Store which ADP Method to use
    obj.useMethod_samplingWithLSFit     = useMethod_samplingWithLSFit;
    obj.useMethod_bellmanIneq           = useMethod_bellmanIneq;
    
    % Store which "P" matrix structure to enforce
    obj.PMatrixStructure                = PMatrixStructure;
    
    % Store whether to "usa a PWA Policy Approximation" or not
    % (and the "number of sides per dimension" to use for it)
    obj.usePWAPolicyApprox      = usePWAPolicyApprox;
    obj.liftingNumSidesPerDim   = liftingNumSidesPerDim;
    
    
    % Store the state fitting range
    obj.VFitting_xInternal_lower        = VFitting_xInternal_lower;
    obj.VFitting_xInternal_upper        = VFitting_xInternal_upper;
    obj.VFitting_xExternal_lower        = VFitting_xExternal_lower;
    obj.VFitting_xExternal_upper        = VFitting_xExternal_upper;
    
    % Store "fit all V's at initialisation" flag
    obj.computeAllVsAtInitialisation    = computeAllVsAtInitialisation;
    
    
    
    %% ----------------------------------------------------------------- %%
    %% INITIALISE A CELL ARRAY FOR THE "P" AND "K" MATRICES
    % Create a cell array for storing the Value function at each time step
    % (and the "State Feedback" if it will be used)
    if ~computeAllVsAtInitialisation
        obj.P = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.p = cell( obj.statsPredictionHorizon+1 , 1 );
        obj.s = cell( obj.statsPredictionHorizon+1 , 1 );
        
        if usePWAPolicyApprox
            obj.K = cell( obj.statsPredictionHorizon+1 , 1 );
        end
        
    else

    %% OR SPECIFY THAT THE INITIALISATION SHOULD BE CALLED AGAIN WITH "DisturbanceData"
        % All the Value Function approximations will be computed at once so
        % that multiple scenarios can be played at maximum computational
        % speed
        
        % Access to the necessary disturbance data is not provided through
        % this initialisation function
        % Instead, it is required to request that an additional
        % initialisation be run providing access to the disturbance data
        flag_requestDisturbanceData = true;
    end
    
    
    
    
            
end
% END OF FUNCTION