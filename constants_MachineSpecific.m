classdef constants_MachineSpecific
% 
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
   
    properties(Constant)
        %% --------------------------------------------------------------------- %%
        %% PLEASE INPUT THE FOLLOWING PATHS ON YOUR MACHINE
        
        %% Path where the saved data should be stored
        saveDataPath = '/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/Data/';
        
        
    end %properties(Constant)
   
    % We do not allow an instantion of this object
    methods
        % constructor
        function obj = constants_MachineSpecific()
            % Nothing to do here
        end % Constants
    end %methods(Access=private)
    
    
    methods(Static , Access = public )
        %% --------------------------------------------------------------------- %%
        %% PLEASE INPUT THE FOLLOWING PATHS ON YOUR MACHINE
        
        function addUserSpecifiedPaths()
            %% VERSION 1.01 OF THE BRCM TOOLBOX
            % See www.brcm.ethz.ch for installation instructions
            % Example: addpath(genpath('/Users/pbeuchat/Documents/MATLAB/tbxmanager/toolboxes/brcm/v1.01'));
            addpath( genpath( '/Users/pbeuchat/Documents/MATLAB/tbxmanager/toolboxes/brcm/v1.01' ) );


            %% ANY OPTIMISERS REQUIRED FOR CONTROLLER COMPUTATIONS
            % Example: addpath(genpath('/Users/pbeuchat/Documents/MATLAB/tbxmanager/toolboxes/brcm/v1.01'));

            % ----------------------------------------------------------- %
            % FOR PAUL BEUCHAT'S iMac Retina 5K
            %addpath('/Users/pbeuchat/Documents/MATLAB/tbxmanager/');
            %tbxmanager restorepath;

            %addpath('/Library/gurobi600/mac64/matlab');
            %setenv GRB_LICENSE_FILE '/Users/pbeuchat/opt/gurobi/gurobi.lic'

            addpath(genpath('/Users/pbeuchat/opt/mosek/7/'));
            setenv MOSEKLM_LICENSE_FILE '/Users/pbeuchat/opt/mosek/mosek.lic'
            
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
