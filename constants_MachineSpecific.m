classdef constants_MachineSpecific
% CONSTANTS MACHINE SPECIFIC
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > Some user specific paths, environment variable, etc.
%               required. Including
%                   - path for where to save data
%                   - path to the installed BRCM toolbox
%                   - path to any optimisers required
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



    properties(Constant)
        %% --------------------------------------------------------------------- %%
        %% PLEASE INPUT THE FOLLOWING PATHS ON YOUR MACHINE
        
        %% Path where the saved data should be stored
        saveDataPath = '/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/Data/';
        
        %% Path where the PRIVATE controller class defs are stored
        privateControllerClasseDefsPath = '/Users/pbeuchat/BitBucketRep/StochOptTestBed_ADPControllers';
        
        
    end %properties(Constant)
   
    % We do not allow an instantion of this object
    methods
        % constructor
        function obj = constants_MachineSpecific()
            % Nothing to do here
        end % Constants
    end %methods(Access=private)
    
    
    methods( Static = true , Access = public )
        %% --------------------------------------------------------------------- %%
        %% PLEASE INPUT THE FOLLOWING PATHS ON YOUR MACHINE
        
        function addUserSpecifiedPaths()
            %% VERSION 1.01 OF THE BRCM TOOLBOX
            % See www.brcm.ethz.ch for installation instructions
            % Example: addpath(genpath('/Users/pbeuchat/Documents/MATLAB/tbxmanager/toolboxes/brcm/v1.01'));
            addpath( genpath( '/Users/pbeuchat/Documents/MATLAB/tbxmanager/toolboxes/brcm/v1.01' ) );

            %% THE PATH TO THE PRIVATE CONTROLLER CLASS DEFS
            addpath( genpath( constants_MachineSpecific.privateControllerClasseDefsPath ) );

            %% ANY OPTIMISERS REQUIRED FOR CONTROLLER COMPUTATIONS
            % Example: addpath(genpath('/Users/pbeuchat/Documents/MATLAB/tbxmanager/toolboxes/brcm/v1.01'));

            % ----------------------------------------------------------- %
            % FOR PAUL BEUCHAT'S iMac Retina 5K
            %addpath('/Users/pbeuchat/Documents/MATLAB/tbxmanager/');
            %tbxmanager restorepath;

            addpath('/Library/gurobi600/mac64/matlab');
            setenv GRB_LICENSE_FILE '/Users/pbeuchat/opt/gurobi/gurobi.lic'

            addpath(genpath('/Users/pbeuchat/opt/mosek/7/'));
            setenv MOSEKLM_LICENSE_FILE '/Users/pbeuchat/opt/mosek/mosek.lic'
            
            addpath(genpath('/Users/pbeuchat/opt/sedumi-master/'));
            
            
            % ----------------------------------------------------------- %
            % FOR PAUL BEUCHAT'S Mac Book Pro
            %addpath('/Library/gurobi562/mac64/matlab');
            %setenv GRB_LICENSE_FILE '/Users/pbeuchat/Documents/MATLAB/Gurobi/gurobi.lic'
            
            %addpath(genpath('/Library/mosek/7/'));
            %setenv MOSEKLM_LICENSE_FILE '/Users/pbeuchat/Documents/MATLAB/mosek/mosek.lic'

            %addpath(genpath('/Users/pbeuchat/Documents/MATLAB/sdpt3'));
        end
        % END OF: "function addPaths()"
        
    end
    % END OF: "methods(Static)"
    
    
end
% END OF: "classdef constants_MachineSpecific"
