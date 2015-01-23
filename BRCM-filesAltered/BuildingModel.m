classdef BuildingModel < matlab.mixin.Copyable
   %BUILDINGMODEL This class contains the model of the building one aims to control
   %   This class stores the building's model. The model has the following
   %   representiation:
   %
   %   Thermal sub model:
   %   x' = A_t*x+Bq*q
   %
   %   External heat flux submodel
   %   q' = Aq*x + Bq_u*u + Bq_v*v + sum_i{(Bq_vu(:,:,i)*v+Bq_xu(:,:,i)*x)*u_i}
   %   y  = C*x + Du*u + Dv*v + sum_i{(D_vu(:,:,i)*v+D_xu(:,:,i)*x)*u_i}
   %
   %   Building Model
   %   x' = A*x+Bu*u+Bv*v+sum_i{(Bvu(:,:,i)*v+Bxu(:,:,i)*x)*u_i}
   %   y  = C*x + Du*u+Dv*v+sum_i{(D_vu(:,:,i)*v+D_xu(:,:,i)*x)*u_i}
   %--------------------------------------------------------------------------
   % ------------------------------------------------------------------------
   % This file is part of the BRCM Toolbox v1.01.
   %
   % The BRCM Toolbox - Building Resistance-Capacitance Modeling for Model Predictive Control.
   % Copyright (C) 2013  Automatic Control Laboratory, ETH Zurich.
   % 
   % The BRCM Toolbox is free software; you can redistribute it and/or modify
   % it under the terms of the GNU General Public License as published by
   % the Free Software Foundation, either version 3 of the License, or
   % (at your option) any later version.
   % 
   % The BRCM Toolbox is distributed in the hope that it will be useful,
   % but WITHOUT ANY WARRANTY; without even the implied warranty of
   % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   % GNU General Public License for more details.
   % 
   % You should have received a copy of the GNU General Public License
   % along with the BRCM Toolbox.  If not, see <http://www.gnu.org/licenses/>.
   %
   % For support check www.brcm.ethz.ch.
   % ------------------------------------------------------------------------
   
   
   
   %    properties (SetAccess = {?Building}) % IF_WITH_METACLASS_SUPPORT
   properties % IF_NO_METACLASS_SUPPORT
      
      identifiers@Identifier;     % stores the state,input,output and constraint identifiers
      
      % Thermal RC-Model and Exteral Heat Flux Model
      thermal_submodel@ThermalModel = ThermalModel.empty;
      EHF_submodels@cell = {};               % cell array for different type of EHF class objects
      
      % system matrices of complete building model
      % State Space matrices
      % continuous time
      continuous_time_model = [];
      % discrete time
      discrete_time_model = [];
      
   end % properties(SetAccess = {?Building})
   
   %    properties (SetAccess = {?Building},Hidden) % IF_WITH_METACLASS_SUPPORT
   properties (Hidden) % IF_NO_METACLASS_SUPPORT   
       % Boundary conditions for thermal model generation
      % Stores the states x that are connected with
      % 'ADB','AMB','GND' and user-specified disturbances
      boundary_conditions@struct = struct(Constants.ambient_name_str,BoundaryCondition.empty,Constants.adiabatic_name_str,BoundaryCondition.empty,...
         Constants.ground_name_str,BoundaryCondition.empty,Constants.user_defined_name_str,BoundaryCondition.empty);
      model_exists@logical = false;       % Flag indicating that the complete building model according to the current state of its data has been generated
   end  
   properties(SetObservable)
      is_dirty@logical = false;           % flag indicating data the building model does not match the current state (new declarations and data)
   end
   
   properties(SetAccess = private)
      Ts_hrs@double;                     % Discretization time step
   end
   
   %    methods(Access = {?Building}) % IF_WITH_METACLASS_SUPPORT
   methods % IF_NO_METACLASS_SUPPORT
      % constructor
      function obj = BuildingModel()
         
      end % constructor
      
      function delete(obj) %#ok<MANU>
         fprintfDbg(2,'%s deleted.\n',Constants.buildingmodel_name_str);
      end % delete
      
   end % methods(Access = {?Building})
   
   methods
      function makeEmpty(obj)
         
         obj.identifiers = Identifier.empty;
         obj.boundary_conditions = struct(Constants.ambient_name_str,BoundaryCondition.empty,Constants.adiabatic_name_str,BoundaryCondition.empty,...
            Constants.ground_name_str,BoundaryCondition.empty,Constants.user_defined_name_str,BoundaryCondition.empty);
         obj.thermal_submodel = ThermalModel.empty;
         obj.EHF_submodels = {};
         
         obj.continuous_time_model = [];
         obj.discrete_time_model = [];
         
         obj.Ts_hrs = [];
         obj.model_exists = false;
         
      end % makeEmpty
      
      function setDiscretizationStep(obj,Ts_hrs)
         
         if ~isnumeric(Ts_hrs)
            error('BuildingModel:Ts_hrs','Discretization requires to be a numeric value > 0');
         end
         
         if ~(Ts_hrs>0)
            error('BuildingModel:Ts_hrs','Discretization requires to be a numeric value > 0');
         end
         
         obj.Ts_hrs = Ts_hrs;
      end % setTimeStep
      
      
      % FUNCTION: to discretised by FORWARD EULER instead of matrix
      % exonential
      discretise_viaForwardEuler(obj);  % ADDED BY PAUL BEUCHAT
      
      
      function printIdentifiers(obj)
         
         ids = {};
         headers = {};
         len_max_str = 0;
         
         % states
         if ~isempty(obj.identifiers.x)
            headers = [headers; sprintf('STATES ''%s''',Constants.state_variable)];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),headers))));
            ids = [ids {obj.identifiers.x}];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),obj.identifiers.x))));
         end
         
         % input_q
         if ~isempty(obj.identifiers.q)
            headers = [headers; sprintf('INPUTS ''%s''',Constants.heat_flux_variable)];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),headers))));
            ids = [ids {obj.identifiers.q}];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),obj.identifiers.q))));
         end
         
         % input_u
         if ~isempty(obj.identifiers.u)
            headers = [headers; sprintf('INPUTS ''%s''',Constants.input_variable)];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),headers))));
            ids = [ids {obj.identifiers.u}];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),obj.identifiers.u))));
         end
         
         % input_v
         if ~isempty(obj.identifiers.v)
            headers = [headers; sprintf('INPUTS ''%s''',Constants.disturbance_variable)];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),headers))));
            ids = [ids {obj.identifiers.v}];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),obj.identifiers.v))));
         end
         
         % output_y
         if ~isempty(obj.identifiers.y)
            headers = [headers; sprintf('INPUTS ''%s''',Constants.output_variable)];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),headers))));
            ids = [ids {obj.identifiers.y}];
            len_max_str = max(len_max_str,max(max(cellfun(@(x) length(num2str(x)),obj.identifiers.y))));
         end
         
         fprintfDbg(0,'\nAvailable identifiers for plot:\t')
         if isempty(ids)
            fprintfDbg(0,'NONE.\n');
            return;
         end
         fprintfDbg(0,'\n\n');
         
         len_header = length(headers);
         underline = repmat('-',1,len_max_str+2);
         format = strcat('  %',num2str(len_max_str),'s\n');
         
         for i = 1:len_header
            fprintfDbg(0,'%s\n',headers{i});
            fprintfDbg(0,'%s\n',underline);
            n_ids = length(ids{i});
            
            for  j = 1:n_ids
               fprintfDbg(0,format,ids{i}{j});
            end
            fprintfDbg(0,'\n');
         end
      end % printIdentifiers
   end % methods
end % classdef
