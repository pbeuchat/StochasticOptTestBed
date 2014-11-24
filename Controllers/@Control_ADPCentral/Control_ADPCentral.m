classdef Control_ADPCentral < Control_LocalController
% This class runs the local control algorithms
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %

    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(2);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Control_Null';
    end
   
    properties (Access = public)
        % A cell array of strings with the statistics required
        statsRequired@cell = {'mean','cov'};
        statsPredictionHorizon@uint32 = uint32(10);
        
        numControllers@uint32 = uint32(1);
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        
        % Size of the input vector that must be returned
        % (Default set to "0" so that an error occurs if not changed)
        n_u@uint32 = uint32(0);
        
        model@ModelCostConstraints;
        
    end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_ADPCentral( inputStateDef , inputModel)
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
                % Perform all the initialisation here
                obj.n_u = inputStateDef.n_u;
                
                obj.model = inputModel;
                
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
        
        u = computeControlAction( obj , x , xi_prev , stageCost_prev , predictions );
        
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

