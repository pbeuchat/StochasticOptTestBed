classdef Disturbance_ology < handle
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
        n_properties@uint32 = uint32(1);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Disturbance_ology';
        % List of statistics that can be computed by this class
        statsComputationsAvailable = {'mean','cov','bounds_boxtype'}
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        % An object from the "Disturbance_Model" class, this will be the
        % true underlying disturbance model
        myDisturbanceModel@Disturbance_Model;
        
        % The size of the uncertainty per time step
        n_xi@uint32 = uint32(0);
        
        % The cycle time of the model
        N_max@uint32 = uint32(0);
        
        % Paths for the data
        path_mean@string;
        path_cov@string;
        path_bounds_boxtype_lower@string;
        path_bounds_boxtype_upper@string;
        
        % Data 
        data_mean@double;
        data_cov@double;
        data_bounds_boxtype_lower@double;
        data_bounds_boxtype_upper@double;
        
        % Indexing "cheating" for non-time correlated disturbances
        % This is just the (i,j) indexing for build a sparse, block
        % diagonal matrix where each block is of size "n_xi" -by- "n_xi"
        i_blkDiag_nxi_by_nxi;
        j_blkDiag_nxi_by_nxi;
        
        
    end
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Disturbance_ology(inputDistModel)
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

                % Check the the "inputModel" is a subclass of
                % "DisturbanceModel"
                bbConstants.checkObjIsSubclassOf(inputDistModel,'Disturbance_Model',1);
                
                % Set the size of the uncertainty per time step and the
                % time cycle from the disturance model
                obj.n_xi    = getDisturbanceVectorSizePerTimeStep( inputDistModel );
                obj.N_max   = getDisturbanceModelFullTimeCycle( inputDistModel );

                % Set the handles to the appropriate properties
                obj.myDisturbanceModel  = inputDistModel;
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
        % FUNCTION: to take many samples from the Disturbance Model and
        % compute the required statistics from the data
        returnSuccess = sampleComputeAndSaveStatistics( obj , statsRequired , distCycleTimeSteps , n_xi , isTimeCorrelated , timeHorizon );
        
        % FUNCTION: to load the statistics that were saved by the sampling
        % function
        returnPred = getPredictions( obj , statsRequired , isTimeCorrelated , startTime , duration , trace , flag_checkValid);
        
        
        % FUNCTION: to check for what statistics were saved by the sampling
        % function
        [returnFlagPerStat , returnFlagOverall] = checkForStatsAlreadyComputed( obj , statsRequired , isTimeCorrelated );
        
        % FUNCTION: to set the paths to the data so that it is faster to
        % load when the predicitons are called for
        returnSuccess = setPathsToData( obj );
        
        
    end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    methods (Static = true , Access = public)
        % FUNCTION: to apply a mask to the load statistics
        returnPred = applyMaskToPrediciton( obj , inputStatsIncluded , inputPred , inputMask , duration );
    end
    % END OF: "methods (Static = true , Access = public)"
        
    methods (Static = true , Access = private)
        % FUNCTION
        returnData = getStatistic_fromData_withFormat_XiByTime( inputData , startTime , duration );
        % FUNCTION:
        returnData = getStatistic_fromData_withFormat_XiByXiByTime( inputData , startTime , duration , i_fullInput , j_fullInput );
        
        
        % FUNCTION: same as the two functions above but loaded directly
        % from matfile ... this turned out to be quiet slow
        %returnData = loadDataFromMatFile_withFormat_XiByTime( loadFileFullPath , startTime , duration );
        %returnData = loadDataFromMatFile_withFormat_XiByXiByTime( loadFileFullPath , startTime , duration );
        
        
    end
    % END OF: "methods (Static = true , Access = private)"
    
end

