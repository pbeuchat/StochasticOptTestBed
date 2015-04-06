classdef Disturbance_Model_002_001 < Disturbance_Model
% This is a specific implementation of the "isturbance_Model" superclass
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




    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(1);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Disturbance_Model_001';
    end
   
    properties (Access = public)
        % A flag showing if the model is valid or not
        isValid@uint8;
        
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % The size of the uncertainty per time step
        n_xi@uint32 = uint32(1);
        
        % The cycle time of the model
        N_max@uint32 = uint32(24*4);
        
        % The time increment per time step (in hours)
        Tinc@double = 0.25;
        
        % A flag for whether or not the samples are time-correlated
        isTimeCorrelated@logical = false;
        
        % A cell array of the statistic that are available and can be told
        % to the "disturbance-ology department" (to save the need for
        % sampling)
        %stats_directlyAvailable = {'mean'};
        stats_directlyAvailable = {'mean'};
        
    end
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Disturbance_Model_002_001(inputAnything)
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

                % There is actually nothing to do, everything should be
                % defined inside the model
                
                % Set the handles to the appropriate properties
                obj.isValid  = uint8(1);
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function obj = ProgressModelEngine(inputModel,inputModelType)"
        
            
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    methods (Static = false , Access = public)
        % FUNCTION: to get a trace for the full length of the cycle
        returnSample = requestSampleForFullCylce( obj );
        
        % FUNCTION: to call for a trae for a given duration
        returnSample = requestSampleFromTimeForDuration( obj , startTime , duration , startXi );
        
        % FUNCTION: to check if a statistics is available directly
        returnCheck = isStatAvailableDirectly( obj , statDesired );
        
        % FUNCTION: to return a statistics directly
        [returnStat , returnSuccess] = requestStatDirectly( obj , statDesired , startTime , duration , startXi );
        
        % FUNCTION: to return the mean directly
        [returnMean , returnSuccess] = get_mean_directly( obj , startTime , duration , startXi );
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    
    methods (Static = false , Access = {?Disturbance_Model,?Disturbance_ology,?Disturbance_Coordinator})
        % FUNCTION: to get a trace for the full length of the cycle
        % This violates the "all properties should be private" structure
        % But is required for interfacing with other components
        function returnSize = getDisturbanceVectorSizePerTimeStep( obj )
            returnSize = obj.n_xi;
        end
        
        % FUNCTION: to get a trace for the full length of the cycle
        % This violates the "all properties should be private" structure
        % But is required for interfacing with other components
        function returnTinc = getTimeIncrement( obj )
            returnTinc = obj.Tinc;
        end
    end
    % END OF: "methods (Static = false , Access = {?Disturbance_ology,?Disturbance_Coordinator})"
    
    
    methods (Static = false , Access = {?Disturbance_Model,?Disturbance_ology,?Disturbance_Coordinator})
        % FUNCTION: to check if the Disturbance Model is TIME correlated
        % This violates the "all properties should be private" structure
        % See more notes at end for reasoning
        function returnCorrelated = isDisturbanceModelTimeCorrelated( obj )
            returnCorrelated = obj.isTimeCorrelated;
        end
        
        % FUNCTION: get the Full Time Cycle of the Disturbance Model
        % This violates the "all properties should be private" structure
        % See more notes at end for reasoning
        function returnFullTimeCycleSteps = getDisturbanceModelFullTimeCycle( obj )
            returnFullTimeCycleSteps = obj.N_max;
        end
        
    end
    % END OF: "methods (Static = false , Access = {?Disturbance_ology})"
    
    
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



%% EXTRA NOTES ABOUT THE FUNCTIONS THAT VIOLATE THE PRIVATE PROPERTIES IDEAL
%
% > In relation to the function: "isDisturbanceModelTimeCorrelated"
%   This violates the "all properties should be private" structure
%   because it is essentially a "getter" method. It makes sense that
%   this violate the structure because NO-ONE else deserves to know
%   if the Disturbance Model is TIME correlated or not.
%   BUT... it saves the Disturbance-ology Department a lot of trouble
%   in terms of having to sample over a time horizon at every time
%   step
%   Hence the method is set to only be accessible by the
%   "disturbance-ologists"
%
%
% > In relation to the function: "getDisturbanceModelFullTimeCycle"
%   This violates the "all properties should be private" structure
%   because it is essentially a "getter" method. It makes sense that
%   this violate the structure because NO-ONE else deserves to know
%   the time cycle on which the Disturbance Model repeats itself.
%   BUT... it saves the Disturbance-ology Department a lot of trouble
%   in terms of having to sample over a long time horizon and instead
%   allows then to provide arbitarily long predicitons
%   Hence the method is set to only be accessible by the
%   "disturbance-ologists"
%
%



