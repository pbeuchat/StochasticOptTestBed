function [vertices,tf_white_space,tf_in_plane] = check_vertices(vertices_str)
   %CHECK_VERTICES Checks whether the vertices fullfil convention.
   % A vertice is a comma separted list of numbers (x,y,z coordinates).
   % vertices_str: String of the form (x1,y1,z1),(x2,y2,z2),...,(xn,yn,zn).
   %               The order of the vertices should be either clockwise or counter clockwise.
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
   
   
   % SIGNIFICANTLY EDITED BY PAUL BEUCHAT TO HANLDLE THE INPUT AS EITHER A
   % SINGLE STRING OR A CELL ARRAY OF COORDINATES
   
   % If the length of the input "vertices_str" is 1 then it is a string,
   % otherwise it is a cell array of coordinates
   
   if length(vertices_str) == 1             % ADDED BY PAUL BEUCHAT
   
       vertices_str = vertices_str{1};      % ADDED BY PAUL BEUCHAT
       
       tf_in_plane = true;
       tf_white_space = true;

       % catch not yet specified
       if strcmpi(strtrim(vertices_str),Constants.NULL_str)
          vertices = Constants.NULL_str;
          return;
       end

       % catch if vertices are empty, in this case the area might be specified
       % we only require vertices if area is not specified and for drawing
       if strcmpi(strtrim(vertices_str),Constants.NaN_str)
          vertices = Constants.EMPTY_str;
          return;
       end

       vertices = Vertex.empty;

       % catch white spaces in string
       if ~isempty(regexp(vertices_str,'\s','once'))
          tf_white_space = false;
          return;
       end

       % Split along convention '(\(\d*.\d*,\d*.\d*,\d*.\d*\))'. If successful we
       % obtain a cell with string elements of the form (x,y,z)
       len_vert_str = length(vertices_str);
       vert_cell = regexp(vertices_str,Constants.expr_vertices,'match');

       if isempty(vert_cell)
          return;
       end

       n_vertices = length(vert_cell);

       % The number of vertices must be at least 3
       if (n_vertices<3)
          return;
       end

       % Concatenate cell of string in order to check if the data fulfills convention
       vert_cell_str = [vert_cell{1},sprintf(',%s',vert_cell{2:end})];
       len_vert = length(vert_cell_str);

       % Catch any vertices format error
       if ~(len_vert_str==len_vert)
          return;
       end

       % Required for checking if vertices are contained in one plane
       vertices_mat = zeros(3,n_vertices); %[v1 v2 v3 v4]

       % Retrieve coordinates and populate matrix
       for j = 1:n_vertices

          % split vertice elements by comma
          coordinates_cell = regexp(vert_cell{j},Constants.expr_coordinate,'match');

          n_elems = length(coordinates_cell);
          if n_elems ~= 3, return, end;

          for i = 1:n_elems
             vertices_mat(i,j) = str2double(coordinates_cell{i});
          end
       end
       
   % MOAJORITY OF EDITS BY PAUL BEUCHAT ARE THIS ELSE STATEMENT
   else
      
       % ELSE: "vertices_str" is a cell array of coordiantes, need to
       % process it and set the following:
       %    -> tf_white_space
       %    -> tf_in_plane
       %    -> n_vertices
       %    -> vertices_mat
       %    -> vertices
       
       % Set the simple ones first that are not dependent on the input data
       tf_in_plane = true;
       tf_white_space = true;
       vertices = Vertex.empty;
       
       % Get the num of elements input (noting that some may be empty
       n_elems = length(vertices_str);
       
       % Check that the number of elements is mod 3
       if mod(n_elems,3)
           disp(' ERROR: the length of the vertex cell aray was not a multiple of 3');
           error('See previous messages and ammend');
       end
       
       % Compute the total number of possible vertices
       n_vertices_possible = n_elems/3;
       
       % Now find out how many actual vertices there are by iterating
       % through until the first empty cell is found
       % (maybe processing then as we go)
       
       vertices_mat = zeros(3,0);
       
       for iVert = 1:n_vertices_possible
           % Check that the first element is not empty
           if ~isempty(vertices_str{ (iVert-1)*3+1} )
               % Now check that the other 2 cells for this vertex are not
               % empty
               if ( ~isempty(vertices_str{ (iVert-1)*3+2} ) && ~isempty(vertices_str{ (iVert-1)*3+3} ) )
                   thisVertex = [  str2double( vertices_str{ (iVert-1)*3+1} ) ; ...
                                   str2double( vertices_str{ (iVert-1)*3+2} ) ; ...
                                   str2double( vertices_str{ (iVert-1)*3+3} )   ...
                                ];
                   vertices_mat = [vertices_mat , thisVertex];
               end
           end
       end
       
       % Finally set the number of vertices
       n_vertices = size(vertices_mat,2);
   end

   % NOTHING BELOW THIS WAS EDITED BY PAUL BEUCHAT
   
   % For more than 3 vertices:
   if n_vertices > 3
      
      % check vertex geometry: are all vertices must be in the same plane
      % plane equation E: n1*x+n2*y+n3*z+d = 0
      % a = v2-v1
      a = vertices_mat(:,2)-vertices_mat(:,1);
      % b = v3-v1
      b = vertices_mat(:,3)-vertices_mat(:,1);
      % n = axb
      n = cross(a,b);
      % d = -dot(v1,n)
      d = -dot(vertices_mat(:,1),n);
      norm_n = norm(n,2);
      
      % check if vertices are ordered clockwise or counter-clockwise
      % compute angles between a and b for checking the
      % order of the vertices
      %norm_a = norm(a);
      %theta_1_rad = acos(dot(a,b)/(norm_a*norm(b)));
      
      for i = 4:n_vertices
         
         % Check if v4,...,vn are on the plane E within tolerance
         if abs((dot(vertices_mat(:,i),n)+d)/norm_n) > Constants.tol_planarity
            tf_in_plane = false;
            return;
         end
         
         % Compute angle between a and v_i = vertices_mat(:,i)-v1
         %{
        vi = vertices_mat(:,i)-vertices_mat(:,1);
        theta_ai_rad = acos(dot(a,vi)/(norm_a*norm(vi)));
        
        % Current angle must always be greater or equal the precedent angle
        if theta_ai_rad < theta_1_rad
           tf_order = false;
            return;
        end
        
        % Set precedent angle to be the current angle
        theta_1_rad = theta_ai_rad;
         %}
      end
   end
   
   %normal = n/norm_n;
   % Case: BE is not horizontal
   % Check if the z-coordinates of top and bottom vertices are aligned
   % For the horizontal case we don't check since we allow any planar shape (floor,ceiling elements)
   %{
if abs(normal(3)) < Constants.tol_norm_vec

    % get indexes of top vertices
    top_idx = find(abs(vertices_mat(3,:)-max(vertices_mat(3,:))) < Constants.tol_height);
    
    % catch top vertices are not aligned within tolerance
    if ~(length(top_idx)==2)
        bad_align = true;
        disp('Top vertices are not aligned within tolerance.'); % TODO: remove
        return;
    end
    
    % get indexes of bottom vertices
    bottom_idx = find(abs(vertices_mat(3,:)-min(vertices_mat(3,:))) < Constants.tol_height);
    
    % catch top vertices are not aligned within tolerance
    if ~(length(bottom_idx)==2)
        bad_align = true;
        disp('Bottom vertices are not aligned within tolerance.'); % TODO: remove
        return;
    end
    
end
   %}
   
   
   for j = 1:n_vertices
      vertices = [vertices,Vertex(vertices_mat(1,j),vertices_mat(2,j),vertices_mat(3,j))]; %#ok<AGROW>
   end
   
end
