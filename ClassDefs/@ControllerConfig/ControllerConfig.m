classdef ControllerConfig
% This class stores the configuration of a controller
% All classes that are not subclasses of the handle class are value classes
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > It is a value class because it can be changed at every
%                   time step
% ----------------------------------------------------------------------- %
% The "< value" syntax means that "ControllerConfig" is a subclass of
% the "value" superclass. Where the "value" class is a default MATLAB
% class


    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(1);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'ControllerConfig';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % Struct containing the configuration
        configData@struct;
    end
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = ControllerConfig(inputConfig)
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

                % Check if the input config (i.e. the variable "inputConfig"):
                % > is empty
                if isempty(inputConfig)
                    disp( ' ... ERROR: The "inputConfig" variable was empty' );
                    error(bbConstants.errorMsg);
                end

                % > is a struct
                if ~isstruct(inputConfig)
                    disp( ' ... ERROR: The "inputConfig" must be a struct. The config that was input is:' );
                    disp(class(inputConfig));
                    disp inputModelType;
                    error(bbConstants.errorMsg);
                end

                % Set the handles to the appropriate properties
                obj.configData  = inputConfig;
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function obj = ProgressModelEngine(inputModel,inputModelType)"
        
        % GET and SET Access methods
        function obj = set.configData(obj,value)
            obj.configData = value;
        end
            
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    %methods (Static = false , Access = public)
    %end
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

