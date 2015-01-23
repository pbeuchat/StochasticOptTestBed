classdef SimulationExperiment < handle
   %SIMULATIONEXPERIMENT This class provides all necessary properties for the simulation of a Building.
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
   
   
   properties(Hidden,Constant)
      n_properties@uint64 = uint64(1);     % number of properties required for object instantation
   end % properties(Constant,Hidden)
   
   properties(Hidden,SetAccess=private)
      figure_position@double;              % screen size and postion for plot
      figure_handles@double;               % collect figure handles
      figure_handles_objects@matlab.graphics.Graphics;  % ADDED BY PAUL BEUCHAT
      data_directory_target@string = '';   % remember directory when writing simulation data
   end % properties(Hidden)
   
   properties(Access=private)
      
      building@Building;                   % building for which the simulation will be done
      building_variable_name@string;       % variable name of the associated building
      
      Ts_hrs@double;                       % Simulation time step is [hrs]
      n_simulation_time_steps@double;      % number of simulation steps
      
      t_hrs@double;                        % Time vector
      
      x0@double;                           % Initial state
      X@double;                            % State sequence matrix
      Q@double;                            % Input Q sequence matrix
      U@double;                            % Input U sequence matrix
      V@double;                            % Input V sequence matrix
      Y@double;                            % Output sequence matrix
      
      default_input_q_handle = @SimulationExperiment.default_input_q_generator;
      input_q_trajectory_handle = @SimulationExperiment.input_q_trajectory_generator;
      custom_input_q_handle;
      
      default_input_uv_handle = @SimulationExperiment.default_input_uv_generator;
      input_uv_trajectory_handle = @SimulationExperiment.input_uv_trajectory_generator;
      custom_input_uv_handle;
      
      % flag indicating if data is available for plot and write, will be set to
      % true when at least one simulation is run successfully
      plot_enabled@logical = false;
      write_enabled@logical = false;
      
   end
   
   methods
      
      function obj = SimulationExperiment(building)
         
         % Check if number of input arguments is correct
         if nargin ~= obj.n_properties
            error('SimulationExperiment:Constructor','%s requires %d argument/s for object creation.\n',Constants.simulation_name_str,obj.n_properties);
         end
         
         % Check if input is a Building object
         if ~isa(building,Constants.building_classname_str)
            error('SimulationExperiment:Constructor','%s requires argument of type %s.\n',Constants.simulation_name_str,Constants.building_name_str);
         end
         
         % Check if the continuous-time thermal model exists
         if isempty(building.building_model.thermal_submodel)
            error('SimulationExperiment:Constructor','The building model of %s ''%s'' must contain at least a thermal model.\n',Constants.building_name_str,building.identifier);
         end
         
         % Check if sampling time was set in the building model
         if isempty(building.building_model.Ts_hrs)
            error('SimulationExperiment:Constructor','The building model of %s ''%s'' must have a set sampling time.\n',Constants.building_name_str,building.identifier);
         end
         
         % check if at the continuous-time building model exists
         if isempty(building.building_model.continuous_time_model) && isempty(building.building_model.discrete_time_model)
            fprintfDbg(1,'%s  ''%s'' does not contain a building model. Only simulation of the thermal model will be possible\n',Constants.building_name_str,building.identifier);
         elseif building.building_model.is_dirty % If it exists, check if BuildingModel object is not dirty
            error('SimulationExperiment:Constructor','%s ''%s'' must not be ''dirty''. Please re-generate the building model and try again.\n',Constants.building_name_str,building.identifier);
         end
         
         % Make deep copy of the Building object in order to prevent changes of data in object from outside of SimulationExperiment
         obj.building = copy(building);
         obj.building.thermal_model_data = copy(building.thermal_model_data);
         obj.building_variable_name = inputname(1);
         obj.building.building_model = copy(building.building_model);
         
         % Set figure_position
         screen_size = get(0,'ScreenSize');
         obj.figure_position = [Constants.fig_scale_left*screen_size(3) Constants.fig_scale_bottom*screen_size(4) ...
            Constants.fig_scale_width*screen_size(3) Constants.fig_scale_height*screen_size(4)]; % screen_size = [left bottom width height]
         
      end % SimulationExperiment
      
      function delete(obj)
         
         if ~isempty(obj.building)
            fprintfDbg(2,'%s of %s ''%s'' deleted.\n',Constants.simulation_name_str,Constants.building_name_str,obj.building.identifier);
         else
            fprintfDbg(2,'%s deleted.\n',Constants.simulation_name_str);
         end
         
         % ADAPTED BY PAUL BEUCHAT (next 15 lines)
         if verLessThan('matlab','8.4.0')
            % execute code for R2014a or earlier
            if ~isempty(obj.figure_handles)
                obj.figure_handles = unique(obj.figure_handles);
                all_figure_handles = get(0,'Children');
                close(intersect(obj.figure_handles,all_figure_handles));
            end
         else
            if ~isempty(obj.figure_handles_objects)
                % execute code for R2014b or later
                obj.figure_handles_objects = unique(obj.figure_handles_objects);
                all_figure_handles = get(groot,'Children');
                close(intersect(obj.figure_handles_objects,all_figure_handles));
            end
         end
         
      end % delete
      
      function setNumberOfSimulationTimeSteps(obj,n_simulation_time_steps)
         
         if ~isnumeric(n_simulation_time_steps) || floor(n_simulation_time_steps) ~= ceil(n_simulation_time_steps)
            error('setNumberOfSimulationTimeSteps:NSteps','Number of steps must be an integer.\n');
         end
         
         obj.n_simulation_time_steps = n_simulation_time_steps;
         
      end % setNumberOfSimulationTimeSteps
      
      function setInitialState(obj,x0)
         
         [in_row,in_col] = size(x0);
         
         dim_x = length(obj.building.building_model.thermal_submodel.A);
         
         if ~(in_row == dim_x && in_col == 1)
            error('SimulationExperiment:Dimension','Dimension error. Input must be a column vector of dimension %d.\n',dim_x);
         end
         
         obj.x0 = x0;
      end % setInitialState
      
      function printIdentifiers(obj)
         
         obj.building.building_model.printIdentifiers();
         
      end  % printIdentifiers
      
      function r = getIdentifiers(obj)
         
         r = obj.building.building_model.identifiers;
         
      end % getIdentifiers
      
      function Ts_hrs = getSamplingTime(obj)
         
         Ts_hrs = obj.building.building_model.Ts_hrs;
         
      end % getSamplingTime
      
      figure_handle = plot(obj,input_cell);
      
      [X,U,V,t_hrs] = simulateBuildingModel(obj,simMode,varargin);
      
      [X,Q,t_hrs] = simulateThermalModelModel(obj,simMode,varargin);
      
   end % methods
   
   methods(Access=private)
      
      simulateTM(obj,simMode)
      
      simulateBM(obj,simMode)
      
      function t = generateTimeVector(obj)
         
         t = 0:obj.building.building_model.Ts_hrs:(obj.building.building_model.Ts_hrs*(obj.n_simulation_time_steps-1));
         
      end % generateTimeVector
      
      write(obj,identifiers_cell,varargin) % disabled writing for the same arguments as with the BuildingModel
      
   end %(Access=private)
   
   methods(Static, Access=private)
      
      function q = default_input_q_generator(x,t,identifiers) %#ok<*INUSD>
         
         n_q = identifiers.q;
         q = Constants.default_amplitude*ones(p_dim_q,1)*sin(2*pi/Constants.default_period_hrs*t)+Constants.default_temperature_C+rand(n_q,1);
         
      end % default_input_q_generator
      
      function [u,v] = default_input_uv_generator(x,t,identifiers)
         
         n_u = length(identifiers.u);
         n_v = length(identifiers.v);
         
         u = Constants.default_amplitude*ones(n_u,1)*sin(2*pi/Constants.default_period_hrs*t)+Constants.default_temperature_C+rand(n_u,1);
         v = Constants.default_amplitude*ones(n_v,1)*sin(2*pi/Constants.default_period_hrs*t)+Constants.default_temperature_C+rand(n_v,1);
         
      end % default_input_uv_generator
      
      function q = input_q_trajectory_generator(x,t,identifiers,t_hrs,Q) %#ok<*INUSL>
         
         persistent p_Q p_t_hrs;
         
         if nargin == 5
            p_Q = Q;
            p_t_hrs = t_hrs;
            return;
         elseif nargin == 3
            
            if isempty(p_t_hrs) || isempty(p_Q)
               error('input_q_trajectory_generator:EmptyMatrix','Empty matrix. Cannot set trajectory ''%s''.\n',Constants.heat_flux_variable);
            end
            
            q = p_Q(:,ismember(p_t_hrs,t));
         else
            error('input_q_trajectory_generator:Arguments','Argument error.\n');
         end
         
      end % input_q_trajectory_generator
      
      function [u,v] = input_uv_trajectory_generator(x,t,identifiers,t_hrs,U,V)
         
         persistent p_U p_V p_t_hrs;
         
         if nargin == 6
            p_U = U;
            p_V = V;
            p_t_hrs = t_hrs;
            return;
         elseif nargin == 3
            
            if isempty(p_t_hrs)
               error('input_uv_trajectory_generator:EmptyMatrix','Empty matrix. Cannot set trajectories for ''%s'' and ''%s''.\n',Constants.input_variable,Constants.disturbance_variable);
            end
            
            u = p_U(:,ismember(p_t_hrs,t));
            v = p_V(:,ismember(p_t_hrs,t));
         else
            error('input_uv_trajectory_generator:Arguments','Argument error.\n');
         end
         
      end % input_uv_trajectory_generator
      
   end % methods(Static)
   
end % classdef
