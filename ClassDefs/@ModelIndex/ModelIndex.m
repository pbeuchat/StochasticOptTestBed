classdef ModelIndex < handle
% A class for combining a Building model, its cost and constraint
% parameters into one class
% Note: that "ModelCostsConstraints" is a subclass of:
%    "< matlab.mixin.Copyable"
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This class is the heart of the simulator
%               > It has the high-level function to take in the:
%                   - current state
%                   - current input
%                   - current disturbance
%               > The model is porgressed
%               > And the following are returned:
%                   - updated state
%                   - stage cost
%                   - infomation about constraint satisfaction
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
        thisClassName@string = 'ModelIndex';
        
        % The index of the Models
        index = { ...
            '001_001'   ,   'building'   ;...
            '001_002'   ,   'building'   ;...
            '001_003'   ,   'building'   ;...
            '002_001'   ,   'building'   ;...
            '002_002'   ,   'building'   ;...
            '002_003'   ,   'building'   ;...
            };
    end

    
    
    methods
        
        % Define functions directly implemented here:
        % -----------------------------------------------
        % FUNCTION: the CONSTRUCTOR method for this class
        function obj = ModelIndex()
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function [...] = BuildingModelCostConstraints(...)"
      
        % Augment the deconstructor method
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    
    %% methods (Static = true , Access = public)
    methods (Static = true , Access = public)
        
    end % END OF: "methods (Static = true , Access = public)"
    
    
    %% methods (Static = true , Access = public)
   
    
end

