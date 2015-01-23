function figure_handle = plot(obj,input_cell)
   %PLOT Engine for plotting the simulation data associated with the provided identifiers.
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
   
   
   
   
   if ~obj.plot_enabled
      error('SimulationExperiment:plot','No simulation data available for plot.\n');
   end
   
   if iscellstr(input_cell)
      input_cell = {input_cell};
   elseif ~iscell(input_cell)
      error('SimulationExperiment:plot','Argument is required to be a cell of identifiers (string) or a cell of cells containing identifiers (string).\n');
   end
   
   n_plots = length(input_cell);
   
   % translate all possible inputs to identifiers
   identifiers_cell = getIdentifiersCell(input_cell,obj.building);
   
   % ADDED BY PAUL BEUCHAT (next 9 lines)
   if verLessThan('matlab','8.4.0')
       % execute code for R2014a or earlier
       all_figure_handles = get(0,'Children');
       n_figs = length(intersect(obj.figure_handles,all_figure_handles));
   else
       % execute code for R2014b or later
       all_figure_handles = get(groot,'Children');
       n_figs = length(intersect(obj.figure_handles_objects,all_figure_handles));
   end
   
   %n_figs = length(intersect(obj.figure_handles,get(0,'Children')));    % REMOVED BY PAUL BEUCHAT
   if n_figs == 0
      n_figs = 1;
   end
   
   figure_handle = figure('Name',sprintf('''%s'' %s figure %d: %s ''%s''',inputname(1),Constants.simulation_name_str,n_figs,Constants.figure_name_simulation,obj.building_variable_name),'Numbertitle','off','Position',obj.figure_position);
   
   % update current handles
   % ADAPTED BY PAUL BEUCHAT (next 7 lines)
   if verLessThan('matlab','8.4.0')
       % execute code for R2014a or earlier
       obj.figure_handles = [obj.figure_handles  figure_handle];
   else
       % execute code for R2014b or later
       obj.figure_handles_objects = [obj.figure_handles_objects  figure_handle];
   end
   
   %obj.figure_handles = [obj.figure_handles figure_handle];    % REMOVED BY PAUL BEUCHAT
   
   for i = 1:n_plots
      
      % get the data corresponding to the identifiers
      Data = [[obj.x0(ismember(obj.building.building_model.identifiers.x,identifiers_cell{i})) obj.X(ismember(obj.building.building_model.identifiers.x,identifiers_cell{i}),1:end-1)]' ...
         obj.Q(ismember(obj.building.building_model.identifiers.q,identifiers_cell{i}),:)'...
         obj.U(ismember(obj.building.building_model.identifiers.u,identifiers_cell{i}),:)'...
         obj.V(ismember(obj.building.building_model.identifiers.v,identifiers_cell{i}),:)' ...
         obj.Y(ismember(obj.building.building_model.identifiers.y,identifiers_cell{i}),:)'];
      
      if isempty(Data)
         close(figure_handle);
         error('SimulationExperiment:plot','Cell of input argument has unknown identifiers at index %d. Consider only available identifiers for plot.\n',i);
      else
         subplot(n_plots,1,i)
         grid on;
         hold on;
         plot(obj.t_hrs,Data);
         
         %         % compare first letter in order to know if it is a heat flux or
         %         % state
         %         % TODO: ouput, input, disturbance variable label units
         %         if strcmp(identifiers_cell{i}{1}(1),Constants.state_variable)
         %             ylabel(Constants.temperature);
         %         elseif strcmp(identifiers_cell{i}{1}(1),Constants.heat_flux_variable)
         %             ylabel(Constants.heatflux);
         %         elseif strcmp(identifiers_cell{i}{1}(1),Constants.input_variable)
         %             ylabel(Constants.input_u);
         %         elseif strcmp(identifiers_cell{i}{1}(1),Constants.disturbance_variable)
         %             ylabel(Constants.input_v);
         %         elseif strcmp(identifiers_cell{i}{1}(1),Constants.output_variable)
         %             ylabel(Constants.output_y);
         %         end
         
         xlabel(Constants.time);
         
         
         legend_entry = {};
         % replace underscore '_' by '\_' in order to prevent subscripting
         for k = 1:length(identifiers_cell{i})
            entry = regexp(identifiers_cell{i}{k},strcat('^',Constants.state_variable,'_',Zone.key,Constants.expr_identifier_key),'match');
            if ~isempty(entry)
               entry = obj.building.thermal_model_data.zones(ismember({obj.building.thermal_model_data.zones.identifier},identifiers_cell{i}{k}(3:end))).description;
               legend_entry = [legend_entry; regexprep(entry,'_','\\_')]; %#ok<*AGROW>
            else
               legend_entry = [legend_entry; regexprep(identifiers_cell{i}{k},'_','\\_')];
            end
         end
         
         yLim = ylim;
         dYLim = yLim(2)-yLim(1);
         if dYLim <1
            yLim(1) = yLim(1)-(1-dYLim)/2; % minimum difference: 1
            yLim(2) = yLim(2)+(1-dYLim)/2; % minimum difference: 1
         end
         ylim(yLim);
         
         legend(legend_entry,'Location','Best');
      end
   end
   
end


function identifiers_cell = getIdentifiersCell(input_cell,building)
   
   n_plots = length(input_cell);
   
   % translate all possible inputs to identifiers
   for k = 1:n_plots
      
      % catch when cell content is another cell.
      if ~iscellstr(input_cell{k})
         error('SimulationExperiment:plot','Index %d of cell is not a cell of identifiers (string).\n',k);
      end
      
      % get dimensions and make a column cellstr out of it
      n = numel(input_cell{k});
      
      % make a cell of cellstr of only one dimension
      input_cell{k} = reshape(input_cell{k},n,1);
      
      variable_str_isSet = false;
      
      identifiers = {};
      
      for j = 1:n
         
         % case entry is zone-id
         if ~isempty(ThermalModelData.check_identifier(input_cell{k}{j},Zone.key))
            
            % get associated zone state
            try
               identifiers = [identifiers; building.building_model.identifiers.x(ismember(building.building_model.identifiers.x,strcat(Constants.state_variable,'_',input_cell{k}{j})))];
            catch %#ok<*CTCH>
               error('SimulationExperiment:plot','Unknown identifier ''%s''.\n',input_cell{k}{j});
            end
            % case entry is zone group, a state identifier passes the check_special_identifier test, so we have to consider all available identifiers of states, inputs and outputs
         elseif ~isempty(ThermalModelData.check_special_identifier(input_cell{k}{j})) && ~(sum(ismember(building.building_model.identifiers.x,input_cell{k}{j})) || ...
               sum(ismember(building.building_model.identifiers.q,input_cell{k}{j})) || sum(ismember(building.building_model.identifiers.u,input_cell{k}{j})) || ...
               sum(ismember(building.building_model.identifiers.v,input_cell{k}{j})) || sum(ismember(building.building_model.identifiers.y,input_cell{k}{j})))
            
            % get all zone states associated with group
            try
               zone_identifiers = building.thermal_model_data.getZoneIdentifiersFromGroupIdentifier(input_cell{k}{j});
               n_z = length(zone_identifiers);
               for l=1:n_z
                  identifiers = [identifiers; building.building_model.identifiers.x(ismember(building.building_model.identifiers.x,strcat(Constants.state_variable,'_',zone_identifiers{l})))];
               end
            catch
               error('SimulationExperiment:plot','Unknown group identifier ''%s''.\n',input_cell{k}{j});
            end
         elseif (strcmp(input_cell{k}{j}(1),Constants.state_variable) || strcmp(input_cell{k}{j}(1),Constants.heat_flux_variable) || ...
               strcmp(input_cell{k}{j}(1),Constants.input_variable) || strcmp(input_cell{k}{j}(1),Constants.disturbance_variable) || ...
               strcmp(input_cell{k}{j}(1),Constants.output_variable)) && ~variable_str_isSet
            variable_str_isSet = true;
            identifiers = [identifiers;input_cell{k}{j}];
         else
            identifiers = [identifiers;input_cell{k}{j}];
         end
      end
      
      identifiers_cell{k} = identifiers;
      
   end
   
end
