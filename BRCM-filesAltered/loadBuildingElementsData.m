function loadBuildingElementsData(obj,varargin)
   % LOADBUILDINGELEMENTSDATA Reads building element data from .xls file.
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
   
      
   if(isempty(varargin))
      [filename,pathname] = uigetfile(Constants.supported_file_extensions,sprintf('Select %s Data File',Constants.building_name_str),obj.data_directory_source);
      
      % Catch push 'Cancel': filename = pathname = 0;
      if(filename == 0)
         return;
      end
      
      buildingElementFile = strcat(pathname,filename);
      [path,~,~] = fileparts(buildingElementFile);
      obj.data_directory_source = path;
   elseif (nargin == 2) % arguments: obj, file
      buildingElementFile = varargin{1}; % returns characters
      [path,~,~] = fileparts(buildingElementFile);
      obj.data_directory_source = path;
   else
      error('loadBuildingElementsData:InputArguments','Too many input arguments.');
   end
   
   
   % THE FOLLOWING IS SIGNIFICANTLY EDITED BY PAUL BEUCHAT TO ALLOW FOR THE
   % VERTICIES TO BE INPUT AS A TABLE OF NUMBERS
   
   
   % FIRST: check that the first set of strings in the header are as
   % expected
   % Get the set of headers without the 'vertices' header at the end
   header_withoutVertices = Constants.building_element_file_header_withoutVertices;
   % Call the new function to check they are all there
   [ flag_checked , additionalHeaders ] = checkHeadersForFile(buildingElementFile,header_withoutVertices);
   
   % Throw an error if the flag indicates a problem
   if ~flag_checked
       disp(' ... ERROR: The headers of the Building Elements Data, not including the vertices, did not match the expected');
       error('See previous messages and ammend');
   end
   
   % Get the two type of header strings that are acceptable for the
   % vertices
   header_stringOfVertices = Constants.building_element_file_header_stringOfVertices;
   header_tableOfVertices  = Constants.building_element_file_header_tableOfVertices;
   
   
   % First check if the "string of verticies" matches
   [r,c] = find( ismember( additionalHeaders , header_stringOfVertices ));
   
   if numel(r)==1 || numel(c)==1
       flag_stringOfVertices_mathces = true;
       header_forVertices = header_stringOfVertices;
   else
       flag_stringOfVertices_mathces = false;
   end
   
   % Sedond check if the "table of verticies" matches
   [r,c] = find( ismember( additionalHeaders , header_tableOfVertices ));
   
   if ( ~mod(length(r),length(header_tableOfVertices)) && ~mod(length(c),length(header_tableOfVertices)) && ~isempty(c) )
       % Get the number of vertices
       numVertices = numel(r) / length(header_tableOfVertices);
       % Now check that the "table of vertices" headers are consecutive and
       % start from the start
       % (We are implicitly assuming here that "additionalHeaders" is row
       % vector, a fair assumption for data taken from a ".csv" input)
       % Start by computing the index difference between each column
       cdiff = diff(c);
       if ( (c(1) == 1)  &&  all( cdiff(1:numVertices*length(header_tableOfVertices)-1) == 1 ) )
           flag_tableOfVertices_mathces = true;
           header_forVertices = repmat( header_tableOfVertices , 1 , numVertices );
       else
           flag_tableOfVertices_mathces = false;
       end
   else
       flag_tableOfVertices_mathces = false;
   end
   
   % Check that exactly one of the formats was identified
   if ~xor( flag_stringOfVertices_mathces , flag_tableOfVertices_mathces )
      error('The Building Elements file was found to contain both possible definition of vertices')
   end
   
   % Now form the headers to be used for reading the data from the file
   header_fromTheFile = [  header_withoutVertices , header_forVertices ];
   
   % Get the table of data from the file (passing the eaders that we know
   % will work for this file
   replaceNaNs = true;
   [table, ~] = getDataTablesFromFile(buildingElementFile,header_fromTheFile,replaceNaNs);
   table = table{1};
   
   
   building_elements = BuildingElement.empty(0,size(table,1)-1);

   % check uniqueness of identifiers
   identifiers = table(2:end,1);
   u_identifiers = unique(identifiers);
   if numel(identifiers) ~= numel(u_identifiers)
      error('loadBuildingElementsData:General','Not all identifiers are unique.\n')
   end
   
   fns = properties(BuildingElement);
   valid_rows = 2:size(table,1);
   
   header = [  header_withoutVertices , header_forVertices{1} ];
   
   for row = valid_rows
      
      r = table(row,:);
      be = BuildingElement;
      
      for i = 1:length(header)
         
         h = header{i};
         
         if strcmp(h,'identifier')
            if isempty(regexp(r{i},strcat('^',BuildingElement.key,Constants.expr_identifier_key),'match'))
               error('loadBuildingElementsData:General','Bad identifier %s',r{i});
            end
         end
         
         % if its a group, make it a cell array
         if strcmp(h,'vertices')
            val = obj.check_vertices( r(i) );
            
         % If it is a table of vertices then grab all the data to the end
         % -> Given that we determined "numVertices" earlier
         elseif strcmp(h,'v_x')
             verticesCellForThisRow = r(i:i+numVertices*length(header_tableOfVertices)-1);
             val = obj.check_vertices( verticesCellForThisRow );
             h = 'vertices';
         else
            val = r{i};
         end
         
         ind = find(strcmpi(h,fns));
         if numel(ind) ~= 1
            error('loadBuildingElementsData:General','Did not find property %s in the BuildingElement object.\n',h);
         end
         
         be.(fns{ind}) = val;
         
      end
      building_elements(row-1) = be;         

   end
   
   obj.building_elements = building_elements;
   obj.source_files.(Constants.buildingelement_filename) = buildingElementFile;
   obj.is_dirty = true;

   
end % loadBuildingElementsData
