classdef (Abstract) CostComponent < matlab.mixin.Heterogeneous
% This class keeps track of the state, input and disturbance defintions for
% a pariticular porblem instance
% The "matlab.mixin.Heterogeneous" inherritence class allow of an array to
% be created from a variety of sub-classes
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               
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
        % Name of this class for displaying relevant messages
        thisAbstractClassName@string = 'CostComponent';
    end
   
    properties (Access = public , Abstract = true)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        % The function type of cost function
        functionType@string;
        
    end
    
    %properties (Access = private , Abstract = true)
        % In general, properties should be set as PRIVATE, but...
        % Private properties make no sense for an Abstract class because
        % they are not visible to sub-classes.
        % So it is the prerogative of the sub-class to have any properties
        % it needs, and this Abstract class is mainly specifying the
        % functions that MUST be implement for a sub-class to be CONCRETE
    %end
    
    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = CostComponent()
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
        % END OF: "function [..] = CostComponent(...)"
      
        % Augment the deconstructor method
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    
    methods (Static = false , Access = public)
        
        % FUNCTION: to compute the cost component
        [returnCost , returnCostPerSubSystem] = computeCostComponent( obj , x , u , xi , currentTime );
        
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

