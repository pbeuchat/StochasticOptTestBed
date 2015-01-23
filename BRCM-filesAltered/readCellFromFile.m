function c = readCellFromFile(filename)
   %READCELLFROMFILE Reads a cell array or strings from a Excel or ';' delimited csv-file. Empty values in the file become 'NaN' strings.
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
   
   
   [~,~,ext] = fileparts(filename);
      
   if strcmpi(ext,'.xls') || strcmp(ext,'.xlsx')
      
      % Empty values become 'NaN' in xlsread
      try
         
            if isempty(xlsfinfo(filename))
               fprintf('Did not find Microsoft Excel. Trying to read %s in ''basic'' mode (see xlsread documentation). \nFile must be saved in Excel 97-2003 compatible format. \n', filename);
               warning off %#ok<WNOFF>
               [~,~,c] = xlsread(filename,'','','basic');
               warning on %#ok<WNON>
            else
               [~,~,c] = xlsread(filename);
            end
            
      catch e
         
         fprintf('Error when trying xlsread(%s).\n If no Excel is installed make sure that the file is saved in Excel 97-2003 compatible format (see xlsread documentation).\n\n',filename);
         throw(e)
         
      end
      
   elseif strcmpi(ext,Constants.fileextension_CSV)
            
      L = getLines(filename);
      c = {};
      
      for i=1:length(L)
         %r = regexp(L{i},'([^;]+|);','match');     % REMOVED BY PAUL BEUCHAT
         
         % SEE THE WIKIPEDIA PAGE:
         % http://en.wikipedia.org/wiki/Comma-separated_values
         % Under the heading: "Towards Standardisation" for how this parse
         % was chosen
         
         % Find is the index of any " (double quote) that is not two "
         % (double quotes)
         % Note: this fails if a field starts with 2 "
         doubleQuoteIndices = regexp([' ',L{i},','],'([^"]"[^"])','start');     % ADDED BY PAUL BEUCHAT
         
         if isempty(doubleQuoteIndices)
            r = regexp([L{i},','],'([^,]*),','match');       % ADDED BY PAUL BEUCHAT
         else
            % Add one to account for the character before and minus 1 to
            % account for the space added before the string
            %doubleQuoteIndices = doubleQuoteIndices + 1 - 1;
            
            % Check if there is a comma before the first " or after the
            % last "
            %flag_commaBeforeDblQuote = ~isempty( strfind( L{i}( 1:doubleQuoteIndices(1)   ) , ',' ) );
            %flag_commaAfterDblQuote  = ~isempty( strfind( L{i}( 1:doubleQuoteIndices(end) ) , ',' ) );
            
            % Initialise a counter for moving through the string
            currIndex = 1;
            r_temp = [];
            
            % Check that the length of "Double Quote Indices" found it
            % modulo 2
            if mod( length(doubleQuoteIndices) , 2)
                disp(' ... ERROR: The syntax with respect to double quotes (") is not as expected');
                disp('            Specifically, the number of indicator double quotes was not even');
                error(' See previous messages and ammend.');
            end
            
            % Step through the locations of the Double Quotes
            for iDoubleQuote = 1:2:length(doubleQuoteIndices)
                
                % Find the last comma before this quote
                index_commaBefore = strfind( L{i}(currIndex:doubleQuoteIndices(iDoubleQuote)) , ',' );
                
                % And find the first comma after the next quote
                index_commaAfter  = strfind( L{i}(doubleQuoteIndices(iDoubleQuote+1):end) , ',' );
                
                % Process the string up to the Double Quote
                if ~isempty(index_commaBefore)
                    r_temp = [r_temp , regexp( L{i}(currIndex:index_commaBefore(end)) ,'([^,]*),','match') ];
                end
                
                % Process the Double Quote wrapped part (ignoring any text
                % between the comma before and the first double quote, and
                % also any text between the second double quote and the
                % comma after, and also not including the double quotes)
                
                
                r_temp = [ r_temp , [L{i}(doubleQuoteIndices(iDoubleQuote)+1:doubleQuoteIndices(iDoubleQuote+1)-1),','] ];
                
                % Process the string after the double quote
                if ~isempty(index_commaAfter)
                    % Check that the comma is not before another 
                    %r_temp = [r_temp , regexp( L{i}(currIndex:index_commaBefore(end)) ,'([^,]*),','match') ];
                    
                    currIndex = doubleQuoteIndices(iDoubleQuote+1)+index_commaAfter(1);
                    
                end
                
            end
            
            % If there is anything left to process after the last double
            % quote, then process it now:
            if ~isempty(index_commaAfter)
                currIndex = doubleQuoteIndices(end)+index_commaAfter(1);
                % It is possible that the comma after is the last character
                % in the string
                if ( currIndex > length(L{i}) )
                    r = [ r_temp , [] ];
                else
                    r = [ r_temp , regexp( [L{i}(currIndex:end),','] ,'([^,]*),','match') ];
                end
            else
                r = r_temp;
            end
            
         end
         
         
         %r = regexp([L{i},','],'([^,]*),','match');       % ADDED BY PAUL BEUCHAT
         r = cellfun(@removeTrailingComma,r,'uniformoutput',0);     % ADDED BY PAUL BEUCHAT
         r = strtrim(r);                            % ADDED BY PAUL BEUCHAT
         
         
         r = cellfun(@processElement,r,'uniformoutput',0);
         c = [c;r];
      end
      
   else
      error('readDataTablesFromFile:General','Did not recognize file extension "%s"\n',ext);
   end
   
end

function out = removeTrailingComma(in)
   out = in;
   %out(out == ';') = '';
   
   
   %out(out == ',') = '';
   
   commaIndices = strfind(out,',');
   out(commaIndices(end)) = '';
   
end


function out = processElement(in)
   
   out = in;
   %out(out == ';') = '';
   %out(out == ',') = '';
   if isempty(out)
      out = 'NaN';
   elseif ~isnan(str2double(out)) && isempty(strfind(out,',')) % need to search for commas otherwise false == isnan('0.1016,0') 
      out = str2double(out);
   end
   
end
