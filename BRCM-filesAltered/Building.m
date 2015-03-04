classdef Building < matlab.mixin.Copyable
   %BUILDING This class contains all the relevant properties of a building one aims to control with MPC
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
   
   
   
   
   properties(SetAccess=private)
      identifier@string;                              % Identifier of the building
   end
   
   properties(SetObservable,Hidden)
      thermal_model_data_consistent@logical = false;  % flag indicating if the property thermal_model_data is consistent
      building_model_consistent@logical = false;      % flag indicating if the property building_model is consistent
   end
   
   properties(Hidden,SetAccess=private)
      figure_position@double;     % specifies the position of figures, e.g. when executing drawBuilding
      
      % collect figure handles
      figure_handles@double;      % collection of all object specific figure handles
      figure_handles_objects@matlab.graphics.Graphics;  % ADDED BY PAUL BEUCHAT
      
   end % properties(Hidden)
   
   %    properties(SetAccess = {?Building,?SimulationExperiment})% IF_WITH_METACLASS_SUPPORT
   properties % IF_NO_METACLASS_SUPPORT
      building_model@BuildingModel;            % stores the building model
      thermal_model_data@ThermalModelData;     % stores all the relevant thermal model data
      
      % Struct that holds information for generation of an EHF Model
      % classfile:    Matlab m-file of the EHF-submodel class
      % file:         path to the source file (.xls,.xlsx)
      EHF_model_declarations@struct = struct('class_file',{},'source_file',{},'EHF_identifier',{});
   end % properties(SetAccess = {?Building,?SimulationExperiment})
   
   methods
      % constructor
      function obj = Building(identifier)
         
         if nargin == 0
            obj.identifier = 'TheBuilding';
         elseif nargin == 1
            obj.identifier = identifier;
         end
         
         % Add listener to is_dirty flag in order to update Building consistency
         % flag (obj.thermal_model_data_Consistent)
         
         obj.thermal_model_data  = ThermalModelData; % This is very crucial if properties are handle classes...
         obj.building_model = BuildingModel;
         addlistener(obj.thermal_model_data,'is_dirty','PostSet',@obj.handleThermalModelDataIsDirty);
         addlistener(obj,'thermal_model_data_consistent','PostSet',@obj.handleThermalModelDataConsistent);
         
         % Add listener for the case when a full Building Model already
         % exists and the user declares a new EHF Model afterwards
         addlistener(obj.building_model,'is_dirty','PostSet',@obj.handleBuildingModelIsDirty);
         addlistener(obj,'building_model_consistent','PostSet',@obj.handleBuildingModelConsistent);
         
         % Plot properties
         screen_size = get(0,'ScreenSize');
         
         % screen_size = [left bottom width height]
         obj.figure_position = [Constants.fig_scale_left*screen_size(3) Constants.fig_scale_bottom*screen_size(4) ...
            Constants.fig_scale_width*screen_size(3) Constants.fig_scale_height*screen_size(4)];
         
      end % constructor
      
      function delete(obj)
         
         fprintfDbg(2,'%s object of ''%s'' and its associated data and model deleted.\n',Constants.building_name_str,obj.identifier);
         
         % close figures if any
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
      
      function clearEHFModelDeclarations(obj)
         
         obj.EHF_model_declarations = struct('class_file',{},'source_file',{},'EHF_identifier',{});
         
      end % clearEHFModelDeclarations
      
      function printThermalModelData(obj)
         
         if isempty(obj.thermal_model_data.zones) && isempty(obj.thermal_model_data.building_elements) && isempty(obj.thermal_model_data.constructions) && ...
               isempty(obj.thermal_model_data.materials)
            
            fprintfDbg(1,'\nNo %s data available. Nothing to be printed.\n',Constants.thermalmodel_name_str);
            return;
         end
         
         % Header
         print_header = sprintf('%s DATA of %s',upper(Constants.thermalmodel_name_str),Constants.building_name_str);
         fprintfDbg(0,'\n %s ''%s''\n',print_header,obj.identifier);
         fprintfDbg(0,'%s\n',repmat('=',1,2*(length(obj.identifier)+length(print_header))));
         
         % Zones
         obj.thermal_model_data.printZoneData;
         % Building elements
         obj.thermal_model_data.printBuildingElementData;
         % Constructions
         obj.thermal_model_data.printConstructionData;
         
         % No mass constructions
         if ~isempty(obj.thermal_model_data.nomass_constructions)
            obj.thermal_model_data.printNoMassConstructionData;
         end
         
         % Materials
         obj.thermal_model_data.printMaterialData;
         
         % Windows
         if ~isempty(obj.thermal_model_data.windows)
            obj.thermal_model_data.printWindowData;
         end
         
         % Parameters
         if ~isempty(obj.thermal_model_data.parameters)
            obj.thermal_model_data.printParameterData;
         end
         
      end %printThermalModelData
      
      function handleThermalModelDataIsDirty(obj,Source,Event) %#ok<*INUSL>
         
         if Event.AffectedObject.is_dirty && obj.thermal_model_data_consistent
            obj.thermal_model_data_consistent = false;
         end
         
      end % handleThermalModelDataIsDirty
      
      function handleBuildingModelIsDirty(obj,Source,Event)
         
         if Event.AffectedObject.is_dirty && obj.building_model.model_exists && obj.building_model_consistent
            obj.building_model_consistent = false;
         end
         
      end % handleBuildingModelIsDirty
      
      function handleThermalModelDataConsistent(obj,Source,Event) %#ok<*INUSD>
         
         
         if ~obj.thermal_model_data_consistent
            fprintfDbg(2,'\n%s data consistency flag set to ''0''.\n\n',Constants.thermalmodel_name_str);
         else
            fprintfDbg(2,'\n%s data consistency flag set to ''1''.\n\n',Constants.thermalmodel_name_str);
         end
         
      end % handleThermalModelDataConsistent
      
      function handleBuildingModelConsistent(obj,Source,Event)
         
         if ~obj.building_model_consistent
            fprintfDbg(2,'\n%s model consistency flag set to ''0''.\n\n',Constants.building_name_str);
         else
            fprintfDbg(2,'\n%s model consistency flag set to ''1''.\n\n',Constants.building_name_str);
         end
      end % handleBuildingModelConsistent
   end % methods
   
   methods(Access=private)
      
      loadEHFModel(obj,EHF_generator_handle,varargin)
      
   end %(Access=private)
   
   methods(Access=private,Static)
      
      checkAllThermalModelDataFilesAvailable(file_list)
      
   end % methods(Access=private,Static)
end % classdef

