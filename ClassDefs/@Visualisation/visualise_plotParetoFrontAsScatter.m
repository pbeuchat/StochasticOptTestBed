function [ ] = visualise_plotParetoFrontAsScatter( hAxes , data_x , data_y , varargin )
% Defined for the "ControllerInterface" class, this function builds a cell
% array of initialised controllers
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
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




    %% REFERENCES:
    % See this Matlab page for all the possible properties that can be set
    % for the "Axes Properties";
    % http://ch.mathworks.com/help/matlab/ref/axes-properties.html
    

    %% ----------------------------------------------------------------- %%
    %% PRELIMINARY CHECKS AND SETTINGS
    

    %% Set the default interpretter for text to be latex
    %   > This will apply to all figures created
    set(0, 'defaultTextInterpreter', 'latex');
    
    %% Check the x and y data are compatible with eachother
    %% Noting that we need to differentiate between cell-array input and direct data
    % If either "data_x" or "data_y" is a cell array, then we expect both
    % to be and to be the same length:
%     if ( iscell(data_x) || iscell(data_y) )
%         if iscell(data_x) && iscell(data_y)
%             % Check that they are both vectors of the same length
%             if ( isvector(data_x) && isvector(data_y) )
%                 % Now check they are the same length
%                 if ~( length(data_x) == length(data_x) )
%                     disp( ' ... ERROR: The input "x" and "y" data are not the same length');
%                     disp(['            length(data_x) = ',length(data_x,1) ]);
%                     disp(['            length(data_y) = ',length(data_y,1) ]);
%                     return;
%                 end
%             % Else they are not both vector hence we don't know what to do
%             else
%                 disp( ' ... ERROR: One or both of the input "x" and "y" data is NOT a vector cell array');
%                 disp(['            size(data_x) = ',size(data_x,1),' -by- ',size(data_x,2) ]);
%                 disp(['            size(data_y) = ',size(data_y,1),' -by- ',size(data_y,2) ]);
%                 return;
%             end
%             
%         % Else if they are not both cell array then we don't know how to
%         % handle them
%         else
%             disp( ' ... ERROR: One of the input "x" and "y" data is a cell array but not both');
%             disp(['            class(data_x) = ',class(data_x)]);
%             disp(['            class(data_x) = ',class(data_y)]);
%             return;
%         end
%             
%     % Otherwise, we expect the data to be a vector and matrix of a
%     % compatible size:
%     else
%         if ~( (size(data_x,1) == 1) || (size(data_x,2) == 1) )
%             disp( ' ... ERROR: the input "x" data was not a vector');
%             disp(['            size(data_x) = ',num2str(size(data_x,1)),' -by- ',num2str(size(data_x,2)) ]);
%             disp( ' ... Returning from function now without plotting anything');
%             return;
%         end
% 
%         if ~( length(data_x) == size(data_y,2) )
%             disp( ' ... ERROR: the input "y" data should have the same width as the length of the "x" data');
%             disp(['            size(data_y)    = ',num2str(size(data_y,1)),' -by- ',num2str(size(data_y,2)) ]);
%             disp(['            length(data_x)  = ',num2str(length(data_y)),' -by- ',num2str(size(data_y,2)) ]);
%             disp( ' ... Returning from function now without plotting anything');
%             return;
%         end
%     end
    
    
    %% GET THE NUMBER OF LINE TO PLOT - directly from the "y" data
    if ~iscell(data_y)
        numScatterToPlot = size(data_y,1);
    else
        numScatterToPlot = size(data_y,1);
    end
    
    
    %% ----------------------------------------------------------------- %%
    %% NOW PARSE THE "varargin" TO EXTRACT THE SETTINGS FROM IT
    % The following need to be set for the plotting to be performed
    % We declare them all as empty here, parse through the "varargin", and
    % then set those that are still empty to their default
    
    
    %% INITIALISE ALL THE VARIABLES
    % Line details
    lineColourIndex         = [];
    lineWidth               = [];
    markerIndex             = [];
    
    % Legend details
    legendOnOff             = [];
    legendStrings           = [];
    legendFontSize          = [];
    legendFontWeight        = [];
    legendLocation          = [];
    legendInterpreter       = [];
    
    % Title details
    titleOnOff              = [];
    titleString             = [];
    titleFontSize           = [];
	titleFontWeight         = [];
	titleColour             = [];

    % Axis label details
    xLabelOnOff             = [];
    yLabelOnOff             = [];
    xLabelString            = [];
	yLabelString            = [];
    xLabelInterpreter       = [];
    yLabelInterpreter       = [];
	xLabelColour            = [];
	yLabelColour            = [];
	labelFontSize           = [];
	labelFontWeight         = [];
    
    % Grid details
	xGridOnOff              = [];
	yGridOnOff              = [];
    gridColour              = [];
	gridStyle               = [];
	xGridMinorOnOff         = [];
	yGridMinorOnOff         = [];
    gridMinorColour         = [];
	gridMinorStyle          = [];
	
    %% Specify also in one place the defaults for each of the above
    % Line defaults
    default_lineColourIndex = ones( numScatterToPlot , 1 );
    default_lineWidth = Visualisation.lineWidthDefault * ones( numScatterToPlot , 1 );
    default_markerIndex = ones( numScatterToPlot , 1 );
    
    % Legend defaults
    default_legendOnOff             = 'off';
    default_legendStrings           = [];
    default_legendFontSize          = 10;
    default_legendFontWeight        = 'normal';
    default_legendLocation          = 'bestOutside';
    default_legendInterpreter       = 'none';
    
    % Title defaults
    default_titleOnOff              = 'off';
    default_titleString             = [];
    default_titleFontSize           = 16;
	default_titleFontWeight         = 'bold';
	default_titleColour             = 'k';

    % Axis label defaults
    default_xLabelOnOff             = 'off';
    default_yLabelOnOff             = 'off';
    default_xLabelString            = [];
	default_yLabelString            = [];
    default_xLabelInterpreter       = 'none';
    default_yLabelInterpreter       = 'none';
	default_xLabelColour            = 'k';
	default_yLabelColour            = 'k';
	default_labelFontSize           = 12;
	default_labelFontWeight         = 'normal';
    
    % Grid defaults
	default_xGridOnOff              = 'on';
	default_yGridOnOff              = 'on';
    default_gridColor               = 'black';
	default_gridStyle               = '--';
	default_xGridMinorOnOff         = 'off';
	default_yGridMinorOnOff         = 'off';
    default_gridMinorColor          = 'black';
	default_gridMinorStyle          = ':';
	
    %% Now parse through the "VARiable ARGuments IN" cell array (i.e.
    % "varargin")
    if (~isempty(varargin))
        % Check if the number of extra arguments is more than expected
        if length(varargin) > 1
            disp(' ... ERROR: inputs after the 4th are not used');
        end
        inputSettings = varargin{1};
        for iTemp = 1:size(inputSettings,1)
            switch lower(inputSettings{iTemp,1})
                % ------------------------------- %
                case 'linecolourindex'
                    lineColourIndex = inputSettings{iTemp,2};
                    % If entered as a singleton, increase it to a vector
                    if isscalar(lineColourIndex)
                        lineColourIndex = repmat(lineColourIndex,numScatterToPlot,1);
                    end
                    % Check it is the right size
                    if ~( length(lineColourIndex) == numScatterToPlot && isvector(lineColourIndex) )
                        disp(' ... ERROR: the "LineColourIndex" option input was not a compatible size, using the default instead');
                        lineColourIndex = [];
                    end
                    
                % ------------------------------- %
                case 'linewidth'
                    lineWidth = inputSettings{iTemp,2};
                    % If entered as a singleton, increase it to a vector
                    if ( isscalar(lineWidth) && ismatrix(lineWidth) )
                        lineWidth = repmat(lineWidth,numScatterToPlot,1);
                    end
                    % Check it is the right size
                    if ~( length(lineWidth) == numScatterToPlot && min(size(lineWidth)) == 1 && ismatrix(lineWidth) )
                        disp(' ... ERROR: the "lineWidth" option input was not a compatible size, using the default instead');
                        lineWidth = [];
                    end
                    
                % ------------------------------- %
                case 'markerindex'
                    markerIndex = inputSettings{iTemp,2};
                    % If entered as a singleton, increase it to a vector
                    if ( isscalar(markerIndex) && ismatrix(markerIndex) )
                        markerIndex = repmat(markerIndex,numScatterToPlot,1);
                    end
                    % Check it is the right size
                    if ~( length(markerIndex) == numScatterToPlot && min(size(markerIndex)) == 1 && ismatrix(markerIndex) )
                        disp(' ... ERROR: the "markerIndex" option input was not a compatible size, using the default instead');
                        markerIndex = [];
                    end
                 
                    
                % ------------------------------- %
                case 'legendonoff'
                    legendOnOff = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(legendOnOff) && ismember( lower(legendOnOff) , Visualisation.onOffOptions ) )
                        disp(' ... ERROR: the "legendOnOff" option input was not valid, using default instead');
                        legendOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendstrings'
                    legendStrings = inputSettings{iTemp,2};
                    % If it is empty then there is nothing to check and a
                    % legend will not be plotted anyway
                    if ~isempty(legendStrings)
                        % If is is not a cell array of strings then ignore
                        if ~iscellstr( legendStrings )
                            disp(' ... ERROR: the "legendStrings" option input was not a cell array of strings and can not be used');
                            disp('            No legend will be displayed');
                            legendStrings = [];
                        end
                        % Check it is the right size
                        if ~( length(legendStrings) == numScatterToPlot && isvector(legendStrings) )
                            disp(' ... ERROR: the "legendStrings" option input was not a compatible size');
                            disp('            No legend will be displayed');
                            legendStrings = [];
                        end
                    end
                    
                    
                % ------------------------------- %
                case 'legendfontsize'
                    legendFontSize = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~( isscalar(legendFontSize) && ismatrix(legendFontSize) && isfloat(legendFontSize) )
                        disp(' ... ERROR: the "legendFontSize" option input was not valid, using default instead');
                        legendFontSize = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendfontweight'
                    legendFontWeight = inputSettings{iTemp,2};
                    % If is is not a memeber then ignore it
                    if ~ismember( legendFontWeight , Visualisation.fontWeightOptions )
                        disp(' ... ERROR: the "legendFontWeight" option input was not valid, using default instead');
                        legendFontWeight = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendlocation'
                    legendLocation = inputSettings{iTemp,2};
                    % If is is not a memeber then ignore it
                    if ~ismember( lower(legendLocation) , Visualisation.legendLocationOptions )
                        disp(' ... ERROR: the "legendLocation" option input was not valid, using default instead');
                        legendLocation = [];
                    end
                    
                    
                % ------------------------------- %
                case 'legendinterpreter'
                    legendInterpreter = inputSettings{iTemp,2};
                    % If is is not a memeber then ignore it
                    if ~ismember( lower(legendInterpreter) , Visualisation.interpretterOptions )
                        disp(' ... ERROR: the "legendInterpreter" option input was not valid, using default instead');
                        legendInterpreter = [];
                    end
                    
                    
                % ------------------------------- %
                case 'titlestring'
                    titleString = inputSettings{iTemp,2};
                    % If it is empty then there is nothing to check, and it
                    % will not be plotted
                    if ~isempty(titleString)
                        % If is is not a string then ignore it
                        if ~ischar( titleString )
                            disp(' ... ERROR: the "titleString" option input was not valid, using default instead');
                            titleString = [];
                        else
                            titleOnOff = 'on';
                        end
                    else
                        titleOnOff = [];
                    end
                    
                % ------------------------------- %
                case 'titlefontsize'
                    titleFontSize = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~( isscalar(titleFontSize) && ismatrix(titleFontSize) && isfloat(titleFontSize) )
                        disp(' ... ERROR: the "titleFontSize" option input was not valid, using default instead');
                        titleFontSize = [];
                    end
                    
                    
                % ------------------------------- %
                case 'titlefontweight'
                    titleFontWeight = inputSettings{iTemp,2};
                    % If is is not a memeber then ignore it
                    if ~( ischar( titleFontWeight ) && ismember( titleFontWeight , Visualisation.fontWeightOptions ) )
                        disp(' ... ERROR: the "titleFontWeight" option input was not valid, using default instead');
                        titleFontWeight = [];
                    end
                    
                    
                    
                    
                % ------------------------------- %
                case 'titlecolour'
                    % If is is not a memeber or a 3-by-1 double, then
                    % ignore it
                    titleColour = inputSettings{iTemp,2};
                    if ischar(titleColour)
                        if ~ismember( lower(titleColour) , Visualisation.colourOptions )
                            disp(' ... ERROR: the "titleColour" option input was not valid, using default instead');
                            titleColour = [];
                        end
                    else
                        if ~( isvector(titleColour) && ismatrix(titleColour) && length(titleColour) == 3 && isfloat(titleColour) )
                            disp(' ... ERROR: the "titleColour" option input was not valid, using default instead');
                            titleColour = [];
                        end
                    end
                    
                    
                % ------------------------------- %
                case 'xlabelstring'
                    xLabelString = inputSettings{iTemp,2};
                    % If it is empty then there is nothing to check, and it
                    % will not be plotted
                    if ~isempty(xLabelString)
                        % If is is not a string then ignore it
                        if ~ischar( xLabelString )
                            disp(' ... ERROR: the "xLabel" option input was not valid, using default instead');
                            xLabelString = [];
                        else
                            xLabelOnOff = 'on';
                        end
                    else
                        xLabelOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'ylabelstring'
                    yLabelString = inputSettings{iTemp,2};
                    % If it is empty then there is nothing to check, and it
                    % will not be plotted
                    if ~isempty(yLabelString)
                        % If is is not a string then ignore it
                        if ~ischar( yLabelString )
                            disp(' ... ERROR: the "yLabel" option input was not valid, using default instead');
                            yLabelString = [];
                        else
                            yLabelOnOff = 'on';
                        end
                    else
                        yLabelOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'xlabelinterpreter'
                    xLabelInterpreter = inputSettings{iTemp,2};
                    % If is is not a memeber then ignore it
                    if ~ismember( lower(xLabelInterpreter) , Visualisation.interpretterOptions )
                        disp(' ... ERROR: the "xLabelInterpreter" option input was not valid, using default instead');
                        xLabelInterpreter = [];
                    end
                    
                    
                % ------------------------------- %
                case 'ylabelinterpreter'
                    yLabelInterpreter = inputSettings{iTemp,2};
                    % If is is not a memeber then ignore it
                    if ~ismember( lower(yLabelInterpreter) , Visualisation.interpretterOptions )
                        disp(' ... ERROR: the "yLabelInterpreter" option input was not valid, using default instead');
                        yLabelInterpreter = [];
                    end
                    
                    
                % ------------------------------- %
                case 'xlabelcolour'
                    % If is is not a memeber or a 3-by-1 double, then
                    % ignore it
                    xLabelColour = inputSettings{iTemp,2};
                    if ischar(xLabelColour)
                        if ~ismember( lower(xLabelColour) , Visualisation.colourOptions )
                            disp(' ... ERROR: the "xLabelColour" option input was not valid, using default instead');
                            xLabelColour = [];
                        end
                    else
                        if ~( isvector(xLabelColour) && ismatrix(xLabelColour) && length(xLabelColour) == 3 && isfloat(xLabelColour) )
                            disp(' ... ERROR: the "xLabelColour" option input was not valid, using default instead');
                            xLabelColour = [];
                        end
                    end
                    
                    
                % ------------------------------- %
                case 'ylabelcolour'
                    % If is is not a memeber or a 3-by-1 double, then
                    % ignore it
                    yLabelColour = inputSettings{iTemp,2};
                    if ischar(yLabelColour)
                        if ~ismember( lower(yLabelColour) , Visualisation.colourOptions )
                            disp(' ... ERROR: the "yLabelColour" option input was not valid, using default instead');
                            yLabelColour = [];
                        end
                    else
                        if ~( isvector(yLabelColour) && ismatrix(yLabelColour) && length(yLabelColour) == 3 && isfloat(yLabelColour) )
                            disp(' ... ERROR: the "yLabelColour" option input was not valid, using default instead');
                            yLabelColour = [];
                        end
                    end
                    
                    
                % ------------------------------- %
                case 'labelfontsize'
                    labelFontSize = inputSettings{iTemp,2};
                    % If is is not a 1-by-1 double then ignore it
                    if ~( isscalar(labelFontSize) && ismatrix(labelFontSize) && isfloat(labelFontSize) )
                        disp(' ... ERROR: the "labelFontSize" option input was not valid, using default instead');
                        labelFontSize = [];
                    end
                    
                    
                % ------------------------------- %
                case 'labelfontweight'
                    labelFontWeight = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(labelFontWeight) && ismember( lower(labelFontWeight) , Visualisation.fontWeightOptions ) )
                        disp(' ... ERROR: the "labelFontWeight" option input was not valid, using default instead');
                        labelFontWeight = [];
                    end
                    
                    
                % ------------------------------- %
                case 'xgridonoff'
                    xGridOnOff = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(xGridOnOff) && ismember( lower(xGridOnOff) , Visualisation.onOffOptions ) )
                        disp(' ... ERROR: the "xGridOnOff" option input was not valid, using default instead');
                        xGridOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'ygridonoff'
                    yGridOnOff = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(yGridOnOff) && ismember( lower(yGridOnOff) , Visualisation.onOffOptions ) )
                        disp(' ... ERROR: the "yGridOnOff" option input was not valid, using default instead');
                        yGridOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'gridcolour'
                    % If is is not a memeber or a 3-by-1 double, then
                    % ignore it
                    gridColour = inputSettings{iTemp,2};
                    if ischar(gridColour)
                        if ~ ismember( lower(gridColour) , Visualisation.colourOptions )
                            disp(' ... ERROR: the "gridColor" option input was not valid, using default instead');
                            gridColour = [];
                        end
                    else
                        if ~( isvector(gridColour) && ismatrix(gridColour) && length(gridColour) == 3 && isfloat(gridColour) )
                            disp(' ... ERROR: the "gridColour" option input was not valid, using default instead');
                            gridColour = [];
                        end
                    end
                    
                    
                % ------------------------------- %
                case 'gridstyle'
                    gridStyle = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(gridStyle) && ismember( gridStyle , Visualisation.gridStyleOptions ) )
                        disp(' ... ERROR: the "gridStyle" option input was not valid, using default instead');
                        gridStyle = [];
                    end
                    
                    
                % ------------------------------- %
                case 'xgridminoronoff'
                    xGridMinorOnOff = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(xGridMinorOnOff) && ismember( lower(xGridMinorOnOff) , Visualisation.onOffOptions ) )
                        disp(' ... ERROR: the "xGridMinorOnOff" option input was not valid, using default instead');
                        xGridMinorOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'ygridminoronoff'
                    yGridMinorOnOff = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(yGridMinorOnOff) && ismember( lower(yGridMinorOnOff) , Visualisation.onOffOptions ) )
                        disp(' ... ERROR: the "yGridMinorOnOff" option input was not valid, using default instead');
                        yGridMinorOnOff = [];
                    end
                    
                    
                % ------------------------------- %
                case 'gridminorcolour'
                    % If is is not a memeber or a 3-by-1 double, then
                    % ignore it
                    gridMinorColour = inputSettings{iTemp,2};
                    if ischar(gridMinorColour)
                        if ~ismember( lower(gridMinorColour) , Visualisation.colourOptions )
                            disp(' ... ERROR: the "gridColor" option input was not valid, using default instead');
                            gridMinorColour = [];
                        end
                    else
                        if ~( isvector(gridMinorColour) && ismatrix(gridMinorColour) && length(gridMinorColour) == 3 && isfloat(gridMinorColour) )
                            disp(' ... ERROR: the "gridColor" option input was not valid, using default instead');
                            gridMinorColour = [];
                        end
                    end

                    
                
                % ------------------------------- %
                case 'gridminorstyle'
                    gridMinorStyle = inputSettings{iTemp,2};
                    % If is is not a member then ignore it
                    if ~( ischar(gridMinorStyle) && ismember( gridMinorStyle , Visualisation.gridStyleOptions ) )
                        disp(' ... ERROR: the "gridMinorStyle" option input was not valid, using default instead');
                        gridMinorStyle = [];
                    end
                    
                    
            otherwise         
                disp([' ... ERROR: Invalid optional argument, "',inputSettings{iTemp},'"' ]);
                disp( '            This argument is skipped and the default used instead' );  
            end
            % END OF: switch varargin{c}
        end
        % END OF: for c=1:length(varargin)
    end
    % END OF: if (~isempty(varargin))
    
    
    %% PUT IN THE DEFAULTS FOR ANYTHING THAT WAS LEFT EMPTY
    if isempty(lineColourIndex)
        lineColourIndex = default_lineColourIndex;
    end
    if isempty(lineWidth)
        lineWidth = default_lineWidth;
    end
    if isempty(markerIndex)
        markerIndex = default_markerIndex;
    end
    if isempty(legendOnOff)
        legendOnOff = default_legendOnOff;
    end
    if isempty(legendStrings)
        legendStrings = default_legendStrings;
    end
    if isempty(legendFontSize)
        legendFontSize = default_legendFontSize;
    end
    if isempty(legendFontWeight)
        legendFontWeight = default_legendFontWeight;
    end
    if isempty(legendLocation)
        legendLocation = default_legendLocation;
    end
    if isempty(legendInterpreter)
        legendInterpreter = default_legendInterpreter;
    end
    if isempty(titleOnOff)
        titleOnOff = default_titleOnOff;
    end
    if isempty(titleString)
        titleString = default_titleString;
    end
    if isempty(titleFontSize)
        titleFontSize = default_titleFontSize;
    end
    if isempty(titleFontWeight)
        titleFontWeight = default_titleFontWeight;
    end
    if isempty(titleColour)
        titleColour = default_titleColour;
    end
    if isempty(xLabelOnOff)
        xLabelOnOff = default_xLabelOnOff;
    end
    if isempty(yLabelOnOff)
        yLabelOnOff = default_yLabelOnOff;
    end
    if isempty(xLabelString)
        xLabelString = default_xLabelString;
    end
    if isempty(yLabelString)
        yLabelString = default_yLabelString;
    end
    if isempty(xLabelInterpreter)
        xLabelInterpreter = default_xLabelInterpreter;
    end
    if isempty(yLabelInterpreter)
        yLabelInterpreter = default_yLabelInterpreter;
    end
    if isempty(xLabelColour)
        xLabelColour = default_xLabelColour;
    end
    if isempty(yLabelColour)
        yLabelColour = default_yLabelColour;
    end
    if isempty(labelFontSize)
        labelFontSize = default_labelFontSize;
    end
    if isempty(labelFontWeight)
        labelFontWeight = default_labelFontWeight;
    end
    if isempty(xGridOnOff)
        xGridOnOff = default_xGridOnOff;
    end
    if isempty(yGridOnOff)
        yGridOnOff = default_yGridOnOff;
    end
    if isempty(gridColour)
        gridColour = default_gridColor;
    end
    if isempty(gridStyle)
        gridStyle = default_gridStyle;
    end
    if isempty(xGridMinorOnOff)
        xGridMinorOnOff = default_xGridMinorOnOff;
    end
    if isempty(yGridMinorOnOff)
        yGridMinorOnOff = default_yGridMinorOnOff;
    end
    if isempty(gridMinorColour)
        gridMinorColour = default_gridMinorColor;
    end
    if isempty(gridMinorStyle)
        gridMinorStyle = default_gridMinorStyle;
    end
    
    
    
    %% ----------------------------------------------------------------- %%
    %% COMPUTE THE MEANS TO BE PLOTTED AS A BIGGER CROSS
    
    % Initialise a container for the numbers
    data_x_mean = zeros(numScatterToPlot,1);
    data_y_mean = zeros(numScatterToPlot,1);
    
    % Step through each of the "scatters"
    for iScatter = 1:numScatterToPlot
        
        if iscell(data_y)
            data_x_mean(iScatter,1) = mean(data_x{iScatter,1});
            data_y_mean(iScatter,1) = mean(data_y{iScatter,1});
        else
            data_x_mean(iScatter,1) = mean(data_x(iScatter,:));
            data_y_mean(iScatter,1) = mean(data_y(iScatter,:));
        end
    end
    
    
    
    
    %% ----------------------------------------------------------------- %%
    %% PLOT THE DATA
    % Pre-allocate a vector for the handle to each scatter
    hScatter = cell(numScatterToPlot,1);
    hScatter_mean = cell(numScatterToPlot,1);
    %hLine = zeros(numScatterToPlot,1);
    
    % Plot the scatter data
    hold on;
    for iLine = 1:numScatterToPlot
        % Get the colour for this line
        thisColour = Visualisation.getDefaultColourForIndex( lineColourIndex(iLine) );
        % Specify the line width
        thisLineWidth = lineWidth( iLine );
        % Specify the mark
        thisMarker = Visualisation.getDefaultMarkerForIndex( markerIndex(iLine) );
        
        % Plot the line
        if iscell(data_y)
            %hLine(iLine) = plot( hAxes, data_x{iLine}, data_y{iLine} , 'color' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , thisMarker);%
            hScatter{iLine,1} = scatter( hAxes, data_x{iLine,:}, data_y{iLine,1} , 'MarkerEdgeColor' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , thisMarker);
        else
            hScatter{iLine,1} = scatter( hAxes, data_x(iLine,:), data_y(iLine,:) , 'MarkerEdgeColor' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , thisMarker);
        end
        hScatter_mean{iLine,1} = scatter( hAxes, data_x_mean(iLine,1), data_y_mean(iLine,1) , 'MarkerEdgeColor' , thisColour , 'LineWidth' , 2*thisLineWidth , 'SizeData' , 72*4 , 'marker' , 'x');
        
    end
    hold off;
    
%     % Now plot the line data with the means
%     hold on;
%     for iLine = 1:numScatterToPlot
%         % Get the colour for this line
%         thisColour = Visualisation.getDefaultColourForIndex( lineColourIndex(iLine) );
%         % Specify the line width
%         thisLineWidth = lineWidth( iLine );
%         % Specify the mark
%         thisMarker = Visualisation.getDefaultMarkerForIndex( markerIndex(iLine) );
%         
%         % Plot the line
%         if iscell(data_y)
%             %hLine(iLine) = plot( hAxes, data_x{iLine}, data_y{iLine} , 'color' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , thisMarker);
%             hLine(iLine) = errorbar( hAxes, data_mean_x(iLine,:), data_mean_y(iLine,:) , data_mean_std(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , 'none');
%         else
%             %hLine(iLine) = plot( hAxes, data_mean_x(iLine,:), data_mean_y(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , thisMarker);
%             hLine(iLine) = errorbar( hAxes, data_mean_x(iLine,:), data_mean_y(iLine,:) , data_mean_std(iLine,:) , 'color' , thisColour , 'LineWidth' , thisLineWidth , 'marker' , 'none');
%         end
%     end
%     hold off;
    
    
    % Label a few things
    % Set some properties of the axes
    
    if strcmp( titleOnOff , 'on' )
        hTitle = title(hAxes,titleString);
        set(hTitle,'Color',titleColour);
        set(hTitle,'FontSize',titleFontSize);
        set(hTitle,'FontWeight',titleFontWeight);
    end
    
    % Set the x-axis limits and tick marks to be at the scatter locations
    %xlim( hAxes , [x_limit_min , x_limit_max] );
    %set(hAxes,'XTickMode','manual');
    %set(hAxes,'XTick',1:numScatterToPlot);
    
    
    if strcmp( xLabelOnOff , 'on' )
        hXLabel = xlabel(hAxes,xLabelString);
        set(hXLabel,'Interpreter',xLabelInterpreter);
        set(hXLabel,'Color',xLabelColour);
        set(hXLabel,'FontSize',labelFontSize);
        set(hXLabel,'FontWeight',labelFontWeight);
    end
    
    
    
    
    if strcmp( yLabelOnOff , 'on' )
        yLabelString = strrep( yLabelString , '_' , '\_' );
        hYLabel = ylabel(hAxes,yLabelString);
        set(hYLabel,'Interpreter',yLabelInterpreter);
        set(hYLabel,'Color',yLabelColour);
        set(hYLabel,'FontSize',labelFontSize);
        set(hYLabel,'FontWeight',labelFontWeight);
    end
    
    set(hAxes,'XGrid',xGridOnOff);
    set(hAxes,'YGrid',yGridOnOff);
    
    if isprop(hAxes,'GridColor')
        set(hAxes,'GridColor',gridColour);
    else
        set(hAxes,'XColor',gridColour);
        set(hAxes,'YColor',gridColour);
    end
    
    set(hAxes,'GridLineStyle',gridStyle);
    
    set(hAxes,'XMinorGrid',xGridMinorOnOff);
    set(hAxes,'YMinorGrid',yGridMinorOnOff);
    
    if isprop(hAxes,'MinorGridColor')
        set(hAxes,'MinorGridColor',gridMinorColour);
    else
        set(hAxes,'XColor',gridMinorColour);
        set(hAxes,'YColor',gridMinorColour);
    end
    
    set(hAxes,'MinorGridLineStyle',gridMinorStyle);
    
    
    
    % Make it only integer ticks
    %if (display_xTickLabel)     set(hAxFObj,'XTick',(1:numCases)');
    %else                        set(hAxFObj,'XTickLabel','');       end;
    
    % LEGEND
    if ~isempty(legendStrings) && strcmp(legendOnOff,'on')
        
        % Add the display name to each handle
        for iLine = 1:numScatterToPlot
            hScatter{iLine,1}.DisplayName = legendStrings{iLine,1};
        end
        for iLine = 1:numScatterToPlot
            hScatter_mean{iLine,1}.DisplayName = '';
            hScatter_mean{iLine,1}.Annotation.LegendInformation.IconDisplayStyle = 'off';        % OPTIONS: 'on' , 'off' , 'children'
        end
        
        % Create the legnend
        hLegend1 = legend(hAxes, 'Location', legendLocation);
        
        set(hLegend1,'Interpreter',legendInterpreter);
        set(hLegend1,'FontSize',legendFontSize);
        set(hLegend1,'FontWeight',legendFontWeight);
        
        
        %newPosition = [0.125 0.02 0.25 0.07];
        %newUnits = 'normalized';
        %set(hLegend1,'Position', newPosition,'Units', newUnits );
    end
    
    
    
    
    
    
	
end
% END OF FUNCTION