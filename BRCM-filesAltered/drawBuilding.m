function figure_handle = drawBuilding(obj,varargin)
   %DRAWBUILDING This method draws the Building according to its data.
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
   
   
   % THIS FILE HAS BEEN ADJUSTED BY PAUL BEUCHAT FOR TWO PURPOSES
   % 1) To make it compatible with the new figure handle object of Matlab
   %    2014b
   % 2) To adjust the input syntax sligtly to be the following:
   %    varargin = { {zone group and/or zone identifiers} , {Draw Specs} , figure_handle }
   %    ie. "varargin" is a cell array with the following 3 elements:
   %        varargin{1} = a cell array of strings of the zone group and/or
   %                      zone identifiers to plot
   %        varargin{2} = a cell array of strings of the plotting options
   %        varargin{3} = a figure handle, indcating (if not empty) that 
   %                      the figure should not be produce by this function
   %                      and not stored as a propeties of the object
   
   
   
   if isempty(obj.thermal_model_data.building_elements)
      error('Building:drawBuilding','Cannot draw %s. %s data requires to have %ss and/or %ss and/or %ss for drawing.\n',Constants.building_name_str,...
         Constants.thermalmodel_name_str,lower(Constants.buildingelement_name_str),lower(Constants.window_name_str),lower(Constants.construction_name_str));
   end
   
   view_option = Constants.view3d;
   noBELabels = false;
   noZoneLabels = false;
   
   % set figure name
   figure_type = sprintf('''%s''',Constants.view3d_str);
   
   % flag for labelling building elements
   buildingelement_tag = true;
   
   % retrieve all zones from BE
   zones_identifiers = setdiff(union({obj.thermal_model_data.building_elements.adjacent_A},{obj.thermal_model_data.building_elements.adjacent_B}),Constants.exterior);
   zones_identifiers(cellfun(@isempty,regexp(zones_identifiers,'^Z\d\d\d\d'))) = [];
      
   procVarargin = varargin;
   
   if nargin >= 1           % ADDED BY PAUL BEUCHAT
       if ~isempty(procVarargin) && iscellstr(procVarargin{1})

          identifiers_cell_str = procVarargin{1};
          identifiers = {};
          for i = 1:length(identifiers_cell_str)
             if~isempty(ThermalModelData.check_identifier(identifiers_cell_str{i},Zone.key))
                % entry is zone identifier
                identifiers = [identifiers;identifiers_cell_str{i}]; %#ok<AGROW>
             elseif ~isempty(ThermalModelData.check_special_identifier(identifiers_cell_str{i}))
                % entry is group identifier
                % check if zones are available and group is known
                try
                   identifiers = [identifiers; obj.thermal_model_data.getZoneIdentifiersFromGroupIdentifier(identifiers_cell_str{i})]; %#ok<AGROW>
                catch %#ok<*CTCH>
                   error('drawbuilding:ZoneGroupId','Cannot retrieve %ss from %s group identifier ''%s''. Either no %s data available or unknown group identifier.\n',...
                      lower(Constants.zone_name_str),lower(Constants.zone_name_str),identifiers_cell_str{i},lower(Constants.zone_name_str));
                end
             else
                error('drawbuilding:Identifier','Unknown identifier or %s group ''%s''.\n',lower(Constants.zone_name_str),identifiers_cell_str{i});
             end
          end
          identifiers_cell_str = identifiers;
          %procVarargin(1) = [];
       else
          identifiers_cell_str = zones_identifiers;
       end
   end

   
   
   if nargin >= 2       % ADDED BY PAUL BEUCHAT
       if ~isempty(procVarargin) && iscellstr(procVarargin{2})
           for i=1:length(procVarargin{2})
              s = procVarargin{2}{i};       % ADJUSTED SLIGHTLY BY PAUL BEUCHAT
              if ~ischar(s), error('drawbuilding:Input','Unrecognized input argument %s\n.',s); end;
              if strcmpi(s,Constants.view2d_str)
                 view_option = Constants.view2d;
                 buildingelement_tag = false;
                 figure_type = sprintf('''%s''',Constants.view2d_str);
              elseif strcmpi(s,Constants.noLabels)
                 noBELabels = true;
                 noZoneLabels = true;
              elseif strcmpi(s,Constants.noBELabels)
                 noBELabels = true;
              elseif strcmpi(s,Constants.noZoneLabels)
                 noZoneLabels = true;
              else
                 error('drawbuilding:Input','Unrecognized input argument %s\n.',s);
              end
           end
       end
   end
   
   
   if nargin >= 3       % ADDED BY PAUL BEUCHAT
       % ADDED BY PAUL BEUCHAT: to plot on a figure handle passed in
       if verLessThan('matlab','8.4.0')
           % Process an input figure handle
           if ~isempty(procVarargin) && ishandle(procVarargin{3})
                figure_handle = procVarargin{3};
                flag_figureHandleGiven = true;
           else
               flag_figureHandleGiven = false;
           end
       else
           % Process an input figure handle
           if ~isempty(procVarargin) && ishandle(procVarargin{3})
                figure_handle = procVarargin{3};
                flag_figureHandleGiven = true;
           else
               flag_figureHandleGiven = false;
           end
       end
   end
   
   
   % catch if argument identifiers coincide with the ones contained
   % in the data
   unknown_ids = setdiff(identifiers_cell_str,zones_identifiers);
   
   if ~isempty(unknown_ids)
      if length(unknown_ids) > 1
         error('Building:drawBuilding','Unknown identifiers ''%s''%s.\n',unknown_ids{1},sprintf(',''%s''',unknown_ids{2:end}));
      else
         error('Building:drawBuilding','Unknown identifier ''%s''.\n',unknown_ids{1});
      end
   end
   
   % consider only unique identifiers
   identifiers = unique(identifiers_cell_str);
   
   % remove 'NULL' entries
   identifiers = setdiff(identifiers,Constants.NULL_str);
   
   % number of unique identifiers
   n_ids = length(identifiers);
   
   current_drawn_elements = {};
   
   % ADAPTED BY PAUL BEUCHAT (next 9 lines)
   if verLessThan('matlab','8.4.0')
       % execute code for R2014a or earlier
       all_figure_handles = get(0,'Children');
       n_figs = length(intersect(obj.figure_handles,all_figure_handles));
   else
       % execute code for R2014b or later
       all_figure_handles = get(groot,'Children');
       n_figs = length(intersect(obj.figure_handles_objects,all_figure_handles));
   end
   
   
   %n_figs = length(intersect(obj.figure_handles,get(0,'Children')));   %REMOVED BY PAUL BEUCHAT
   if n_figs == 0
      n_figs = 1;
   end
   
   if ~flag_figureHandleGiven
        figure_handle = figure('Name',sprintf('''%s'' %s figure %d: %s',inputname(1),Constants.building_name_str,n_figs,figure_type),'Numbertitle','off','Position',obj.figure_position);
   else
        set(figure_handle,'Name',sprintf('''%s'' %s figure %d: %s',inputname(1),Constants.building_name_str,n_figs,figure_type),'Numbertitle','off','Position',obj.figure_position);
   end
   
   % update current handles
   % ADAPTED BY PAUL BEUCHAT (next 7 lines)
   if ~flag_figureHandleGiven
       if verLessThan('matlab','8.4.0')
           % execute code for R2014a or earlier
           obj.figure_handles = [obj.figure_handles  figure_handle];
       else
           % execute code for R2014b or later
           obj.figure_handles_objects = [obj.figure_handles_objects  figure_handle];
       end
   end
   %obj.figure_handles = [obj.figure_handles  figure_handle];       % REMOVED BY PAUL BEUCHAT
   
   hold on;
   grid on;
   
   daspect(Constants.aspect_ratio);
   
   % set view
   view(view_option);
   
   % title(regexprep(obj.identifier,'_','\\_'));
   zlabel(Constants.z_label);
   ylabel(Constants.y_label);
   xlabel(Constants.x_label);
   
   % figure handles for legend
   %f_WIN = 0;          % REMOVED BY PAUL BEUCHAT
   %f_NOMASS = 0;
   %f_BE = 0;
   %f_VERT = 0;
   
   % figure handles for legend
   f_WIN = [];          % ADDED BY PAUL BEUCHAT
   f_NOMASS = [];
   f_BE = [];
   f_VERT = [];
   
   for i = 1:n_ids
      
      try % adjacent entry defined?
         % get building elements
         be_idx_A = ismember({obj.thermal_model_data.building_elements.adjacent_A},identifiers(i));
         be_idx_B = ismember({obj.thermal_model_data.building_elements.adjacent_B},identifiers(i));
         be_identifiers_A = {obj.thermal_model_data.building_elements(be_idx_A).identifier};
         be_identifiers_B = {obj.thermal_model_data.building_elements(be_idx_B).identifier};
         be_identifiers2draw = union(be_identifiers_A,be_identifiers_B);
         
         % get number of all BEs belonging to the current zone
         n_be_zone = length(be_identifiers2draw);
         
         % compute zone center for labelling
         z_center = zeros(3,1);
         heightSet = false;
         
         for n = 1:n_be_zone
            try % vertices defined?
               be_idx = obj.thermal_model_data.getBuildingElementIdxFromIdentifier(be_identifiers2draw{n});
               
               if obj.thermal_model_data.building_elements(be_idx).isHorizontal
                  z = obj.thermal_model_data.building_elements(be_idx).computeCenterOfMaxRectangleInHorizontalPolygon;
                  % set only x and y coordinate
                  z_center(1:2) = z(1:2);
               elseif ~heightSet
                  % in order to heighten label for 3D plot
                  v = obj.thermal_model_data.building_elements(be_idx).vertices2Matrix;
                  z_center(3) = min(v(3,:)) + 1/2*abs(obj.thermal_model_data.building_elements(be_idx).computeProjectionZ);
                  heightSet = true;
               end
               
            catch
            end
            
         end
         
         % get only those building elements that are not drawn yet
         be_identifiers2draw = setdiff(be_identifiers2draw,current_drawn_elements);
      catch
         continue;
      end

      for j = 1:length(be_identifiers2draw)
         % get index of current element
         be_idx = obj.thermal_model_data.getBuildingElementIdxFromIdentifier(be_identifiers2draw{j});
         BE_color = Constants.building_element_color;
         total_thickness = 0;
         % get total thickness of building element
         if ~isempty(ThermalModelData.check_identifier(obj.thermal_model_data.building_elements(be_idx).construction_identifier,Construction.key))
            
            try % constructions available?
               c_idx = obj.thermal_model_data.getConstructionIdxFromIdentifier(obj.thermal_model_data.building_elements(be_idx).construction_identifier);
               
               n_layers = length(obj.thermal_model_data.constructions(c_idx).thickness);
               total_thickness = 0;
               for k=1:n_layers
                  total_thickness = total_thickness+obj.thermal_model_data.evalStr(obj.thermal_model_data.constructions(c_idx).thickness{k});
               end
               
               total_thickness = computeTotalThickness;
            catch
            end
         elseif ~isempty(ThermalModelData.check_identifier(obj.thermal_model_data.building_elements(be_idx).construction_identifier,NoMassConstruction.key))
            BE_color = Constants.building_element_nomass_color;
         end
         
         % get normal vector of building elment
         try % vertices defined?
            be_normal = obj.thermal_model_data.building_elements(be_idx).computeNormal;
         catch
            be_normal = zeros(3,1);
         end
         
         % building element vertex is always located in the center point of all layers in direction
         % of the normal vector, there for we halve the total thickness
         total_thickness = 0.5*total_thickness;
         
         % draw
         try % vertices defined?
            vertices = obj.thermal_model_data.building_elements(be_idx).vertices2Matrix;
            
            n_vertices = size(vertices,2);
            
            % plot vertice points
            f_VERT = scatter3(vertices(1,:),vertices(2,:),vertices(3,:),repmat(Constants.vertex_size,1,n_vertices),Constants.vertex_color,'fill');
            
            % front/top surface
            vertices_1 = vertices+total_thickness*repmat(be_normal,1,n_vertices);
            
            % back/bottom surface
            vertices_2 = vertices-total_thickness*repmat(be_normal,1,n_vertices);
            
            % draw front/top and back/bottom surface
            % building element
            
            f1_BE = fill3(vertices_1(1,:),vertices_1(2,:),vertices_1(3,:),BE_color);
            f2_BE = fill3(vertices_2(1,:),vertices_2(2,:),vertices_2(3,:),BE_color);
            set([f1_BE f2_BE],'EdgeColor',Constants.building_element_edge_color);
            
            if BE_color == Constants.building_element_nomass_color
               f_NOMASS = f1_BE;
            else
               f_BE = f1_BE;
            end
         catch
            continue;
         end
         
         % window
         try % does BE have windows and are they defined?
            
            if ~isempty(obj.thermal_model_data.building_elements(be_idx).window_identifier)
               
               % builiding elment has windows
               w_idx = obj.thermal_model_data.getWindowIdxFromIdentifier(obj.thermal_model_data.building_elements(be_idx).window_identifier);
               win_area = str2double(obj.thermal_model_data.windows(w_idx).glass_area)+str2double(obj.thermal_model_data.windows(w_idx).frame_area);
               
               scale_factor = sqrt(win_area/obj.thermal_model_data.building_elements(be_idx).computeArea);
               
               w_center = mean(vertices_1,2);
               w_center = repmat(w_center,1,n_vertices);
               win_vertices_1 = scale_factor*(vertices_1-w_center)+w_center;
               f1_WIN = fill3(win_vertices_1(1,:),win_vertices_1(2,:),win_vertices_1(3,:),Constants.window_color);
               
               w_center = mean(vertices_2,2);
               w_center = repmat(w_center,1,n_vertices);
               win_vertices_2 = scale_factor*(vertices_2-w_center)+w_center;
               f2_WIN = fill3(win_vertices_2(1,:),win_vertices_2(2,:),win_vertices_2(3,:),Constants.window_color);
               set([f1_WIN f2_WIN],'EdgeColor',Constants.window_edge_color);
               
               % draw other surfaces by collecting the appropriate vertices
               % through cycling
               % append first vertice at the end
               win_vertices_1 = [win_vertices_1 win_vertices_1(:,1)]; %#ok<AGROW>
               win_vertices_2 = [win_vertices_2 win_vertices_2(:,1)]; %#ok<AGROW>
               
            end
         catch
         end
         
         % draw other surfaces by collecting the appropriate vertices
         % through cycling
         % append first vertice at the end
         try % vertices defined?
            vertices_1 = [vertices_1 vertices_1(:,1)]; %#ok<AGROW>
            vertices_2 = [vertices_2 vertices_2(:,1)]; %#ok<AGROW>
            
            col_idx = 1:2;
            for s = 0:n_vertices-1
               v_idx = col_idx+s;
               vertices_3 = [vertices_1(:,v_idx(1)) vertices_2(:,v_idx) vertices_1(:,v_idx(2))];
               f = fill3(vertices_3(1,:),vertices_3(2,:),vertices_3(3,:),Constants.building_element_color);
               set(f,'EdgeColor',Constants.building_element_edge_color);
               
               % draw window
               try % were windows defined?
                  
                  if ~isempty(obj.thermal_model_data.building_elements(be_idx).window_identifier)
                     win_vertices_3 = [win_vertices_1(:,v_idx(1)) win_vertices_2(:,v_idx) win_vertices_1(:,v_idx(2))];
                     f_WIN = fill3(win_vertices_3(1,:),win_vertices_3(2,:),win_vertices_3(3,:),Constants.window_color);
                     set(f_WIN,'EdgeColor',Constants.window_edge_color);
                  end
               catch
               end
               
            end
         catch
         end
         
         % print building element identifier
         if buildingelement_tag && ~noBELabels
            try % vertices defined?
               be_center = obj.thermal_model_data.building_elements(be_idx).computeCenter;
               text(be_center(1),be_center(2),be_center(3),obj.thermal_model_data.building_elements(be_idx).identifier,'HorizontalAlignment','center');
            catch
            end
         end
      end
      
      % print zone identifier
      try % vertices defined
         if ~noZoneLabels
            text(z_center(1),z_center(2),z_center(3),identifiers{i},...
               'FontSize',Constants.zone_label_FontSize,'FontWeight','bold','HorizontalAlignment','center');
         end
      catch
      end
      
      % set current drawn ones
      try % elements to draw defined?
         current_drawn_elements = be_identifiers2draw;
      catch
      end
      
   end
   
   % set transparency
   alpha(Constants.alpha_transparency);
   fig_handles = [];
   legend_data = {};
   
   %if f_VERT                   % REMOVED BY PAUL BEUCHAT
   if ~isempty(f_VERT)          % ADDED BY PAUL BEUCHAT
      fig_handles = [fig_handles,f_VERT];
      legend_data = [legend_data;Constants.vertex_name_str];
   end
   
   %if f_BE                     % REMOVED BY PAUL BEUCHAT
   if ~isempty(f_BE)            % ADDED BY PAUL BEUCHAT
      fig_handles = [fig_handles,f_BE];
      legend_data = [legend_data;Constants.buildingelement_name_str];
   end
   
   % add windows and no mass constructions to legend if the have been drawn
   %if f_WIN                    % REMOVED BY PAUL BEUCHAT
   if ~isempty(f_WIN)           % ADDED BY PAUL BEUCHAT
      fig_handles = [fig_handles,f_WIN];
      legend_data = [legend_data;Constants.window_name_str];
   end
   
   %if f_NOMASS && view_option == Constants.view3d               % REMOVED BY PAUL BEUCHAT
   if ~isempty(f_NOMASS) && view_option == Constants.view3d      % ADDED BY PAUL BEUCHAT
      fig_handles = [fig_handles,f_NOMASS];
      legend_data = [legend_data; Constants.nomass_construction_name_str];
   end
   
   try % legend entries non-empty?
      legend(fig_handles,legend_data,'Location','BestOutside','LineWidth',Constants.legend_edge_width);
   catch
   end
   
   % Disable rotation in 'Floorplan' mode
   if view_option == Constants.view2d
      h = rotate3d;
      setAllowAxesRotate(h,gca,false);
   end
   hold off;
   set(gcf,'color',[1,1,1])
   
end % drawBuilding
