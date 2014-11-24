classdef Control_Null_Global < Control_GlobalController
% This class runs the local control algorithms
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    properties(Hidden,Constant)
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Control_Null_Gocal';
        
        % Inheritted from the Abstract "Control_GlobalController" class
        % Number of properties required for object instantation
        %n_properties@uint64 = uint64(2);
    end
   
    properties (Access = public)
        % A cell array of strings with the statistics required
        statsRequired@cell = {};
        statsPredictionHorizon@uint32 = uint32(10);
        
        % The Identifiaction Number that specifies which sub-system 
        % this local controller is
        idnum@uint32;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        
        % The type of model that is being controller
        modelType@string = '';
        
        % The State Definiton Object
        stateDef@StateDef;
        
        % The Constraints Definiton object
        constraintDef@ConstraintDef;
        
    end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_Null_Global( inputStateDef , inputConstraintDef )
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                % Check if number of input arguments is correct
                if nargin ~= obj.n_properties
                    %disp( ' ... ERROR: The Constructor for the %s class requires %d argument/s for object creation.' , obj.thisClassName , obj.n_properties );
                    disp([' ... ERROR: The Constructor for the "',obj.thisClassName,'" class requires ',num2str(obj.n_properties),' argument/s for object creation.']);
                    error(bbConstants.errorMsg);
                end
                
                % Check that the State Definition  (i.e. "inputStateDef")
                % is of the correct type
                if ~isa( inputStateDef , 'StateDef' )
                    disp( ' ... ERROR: the input Identifiaction Number for this local controller is not of the expected "StateDef" type');
                    disp(['            It was input as type(inputStateDef) = ',type(inputStateDef) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Check that the Constraint Definition
                % (i.e. "inputConstraintDef") is of the correct type
                if ~isa( inputConstraintDef , 'ConstraintDef' )
                    disp( ' ... ERROR: the input Identifiaction Number for this local controller is not of the expected "ConstraintDef" type');
                    disp(['            It was input as type(inputConstraintDef) = ',type(inputConstraintDef) ]);
                    error(bbConstants.errorMsg);
                end
                
                % Perform all the initialisation here
                obj.stateDef            = inputStateDef;
                obj.constraintDef       = inputConstraintDef;
                
                
            end
            % END OF: "if nargin > 0"
            
        end
        % END OF: "function obj = Control_LocalInterface(inputHandleMain , inputModelType)"
        
%         % GET and SET Access methods
%         function obj = set.controllerConfig_Static(obj,value)
%             obj.controllerConfig_Static = value;
%         end
%         
%         function obj = set.controllerConfig_Mutable(obj,value)
%             obj.controllerConfig_Mutable = value;
%         end
            
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    methods (Static = false , Access = public)
        
        % This function will be called once before the simulation is
        % started
        % This function is to initialise the controller at a global level
        % This function should be used to specify a different number of
        % sub-systems and their corresponding masks
        [flag_ControlStructureChanged , new_n_ss , new_mask_x_ss , new_mask_u_ss , new_mask_xi_ss] = initialise_globalControl( obj , inputModelType , inputModel , vararginGlobal);
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    %methods (Static = true , Access = public)
    %end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

