classdef (Abstract) Control_LocalController < handle
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
        thisAbstractClassName@string = 'Control_LocalController';
    end
   
    properties (Access = public , Abstract = true)
        % A cell array of strings with the statistics required
        statsRequired@cell;
        statsPredictionHorizon@uint32;
        
        % The Identifiaction Number that specifies which sub-system 
        % this local controller is
        idnum@uint32;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    %properties (Access = private , Abstract = true)
        % In general, properties should be set as PRIVATE, but...
        %
        % Private properties make no sense for an Abstract class because
        % they are not visible to sub-classes.
        %
        % So it is the prerogative of the sub-class to have any properties
        % it needs, and this Abstract class is mainly specifying the
        % functions that MUST be implement for a sub-class to be CONCRETE
    %end

    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Control_LocalController()
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                % A CONSTRUCTOR for "nargin > 0" is not really required
                % because an ABSTRACT class cannot be instantiated
                %obj.isValid     = uint8(0);
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
        % This function will be called at every time step and must return
        % the input vector to be applied
        u = computeControlAction( obj , x , xi_prev , stageCost_prev , predictions );
        
        % This function will be called once before the simulation is
        % started
        % This function should be used to perform off-line possible
        % computations so that the controller computation speed during
        % simulation run-time is faster
        flag_successfullyInitialised = initialise_localControl( obj , inputModelType , inputModel , vararginLocal);
        
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

