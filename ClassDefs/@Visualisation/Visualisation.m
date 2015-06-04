classdef Visualisation < handle
% This class interfaces plots things
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > 
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




    properties(Hidden,Constant)
        % Name of this class for displaying relevant messages
        thisClassName@string = 'Visualisation';
    end
    
    properties(Constant)
        %colourArrayLength@double = 6;
        %colourArrayDefault@cell = {'-b','-r','-g','-c','-m','-k'};
        colourArrayLength@double = 6;
        colourArrayDefault@cell = {   [228, 26 , 28 ]/255      ;...     % RED
                                      [55 , 126, 184]/255      ;...     % BLUE
                                      [152, 78 , 163]/255      ;...     % PURPLE
                                      [255, 127, 0  ]/255      ;...
                                      [77 , 175, 74 ]/255      ;...
                                      [204, 204, 0  ]/255      ;...
                                  };
%                                       [166, 86 , 40 ]/255      ;...
%                                       [247, 129, 191]/255       ...
%                                    };
        markerArrayLength@double = 13;
        markerArrayDefault@cell = {'o','+','*','.','x','square','diamond','^','v','<','>','pentagram','hexagram'};
        markerNoneString@string = 'none';
        
        figure_backgroundColour@double = [0.75 , 0.75 , 0.75 ];
        
        lineWidthFeint@double      = 0.5;
        lineWidthThin@double       = 1.0;
        lineWidthDefault@double    = 1.5;
        lineWidthThick@double      = 2.5;
        
        fontWeightOptions = {'normal','bold'}
        interpretterOptions = {'tex','latex','none'};
        legendLocationOptions = {'north', 'south', 'east', 'west', 'northeast', 'northwest', 'southeast', 'southwest', ...
                    'northoutside', 'southoutside', 'eastoutside', 'westoutside', 'northeastoutside', 'northwestoutside',...
                    'southeastoutside', 'southwestoutside', 'best', 'bestoutside', 'none'};
        onOffOptions = {'on','off'};
        gridStyleOptions = {'-', '--', ':', '-.', 'none'};
        colourOptions = {'y', 'yellow', 'm', 'magenta', 'c', 'cyan', 'r', 'red', 'g', 'green', 'b', 'blue', 'w', 'white', 'k', 'black' };
        
        
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
        
        
    end
    
    properties (Access = private)
        
    end
    
    
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = Visualisation()
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            if nargin > 0
                
            end
            % END OF: "if nargin > 0"
        end
        % END OF: "function obj = ProgressModelEngine(inputModel,inputModelType)"
      
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    %methods (Static = false , Access = public)
    %end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    methods (Static = true , Access = public)
        
        [ ] = visualise_singleController( inputControllerSpecs , inputDataStruct , inputPropertyNames , plotOptions );
        
        [ ] = visualise_multipleControllers( inputControllerSpecs , inputDataCellArray , inputPropertyNames , plotOptions );
        
        [ ] = visualise_plotMultipleLines( hAxes , data_x , data_y , varargin );
        
        [ ] = visualise_plotMultipleHistogramAsScatter( hAxes , data_y , varargin );
        
        [ ] = visualise_plotMultipleHistogram( hAxes , data_y , varargin );
        
        [] = visualise_plotParetoFrontAsScatter( hAxes , data_x , data_y , thisPlotOptions  );
        
        [] = visualise_plotParetoFrontSummary( hAxes , data_x , data_y , thisPlotOptions  );
        
        function returnColour = getDefaultColourForIndex( inputIndex )
            thisIndex = mod(inputIndex-1, Visualisation.colourArrayLength ) + 1;
            returnColour = Visualisation.colourArrayDefault{thisIndex,1};
        end
        
        
        
        function returnMarker = getDefaultMarkerForIndex( inputIndex )
            if inputIndex == 0
                returnMarker = Visualisation.markerNoneString;
            else
                thisIndex = mod(inputIndex-1, Visualisation.markerArrayLength ) + 1;
                returnMarker = Visualisation.markerArrayDefault{thisIndex};
            end
        end
        
        
        function figurePosition = getFigurePositionInFullScreenGrid( inputNumRows, inputNumCols, inputThisFigureIndex, inputIndexType )
            
            % First get the size of the screen
            screenSize = get(0,'ScreenSize');
            screenWidth = screenSize(1,3);
            screenHeight = screenSize(1,4) - 20;
            
            % Specify the buffers
            topBuffer = 50;
            botBuffer = 50;
            leftBuffer = 20;
            rightBuffer = 20;
            
            % Get the position of the figure
            if strcmpi( inputIndexType , 'rowwise')
                % Check the index is valid
                if inputThisFigureIndex <= (inputNumRows * inputNumCols)
                    thisRow = floor( (double(inputThisFigureIndex)+1) / double(inputNumCols) );
                    thisCol = double(inputThisFigureIndex) - (thisRow-1) * double(inputNumCols);
                else
                    disp( ' ... ERROR: the input index is greater than #rows x #cols' );
                    disp( '            placing figure in the last tile' );
                    thisRow = inputNumRows;
                    thisCol = inputNumCols;
                end
                    
            elseif strcmpi( inputIndexType , 'columnwise')
                % Check the index is valid
                if inputThisFigureIndex <= (inputNumRows * inputNumCols)
                    thisCol = floor( (double(inputThisFigureIndex)+1) / double(inputNumRows) );
                    thisRow = double(inputThisFigureIndex) - (thisCol-1) * double(inputNumRows);
                else
                    disp( ' ... ERROR: the input index is greater than #rows x #cols' );
                    disp( '            placing figure in the last tile' );
                    thisRow = inputNumRows;
                    thisCol = inputNumCols;
                end
                
            elseif strcmpi( inputIndexType , 'rowandcolumn')
                thisRow = inputThisFigureIndex(1);
                thisCol = inputThisFigureIndex(2);
                
            else
                disp( ' ... ERROR: the specified "Index Type" was not recognised' );
                disp( '            returning a default position' );
                figurePosition = [0, 0, 100, 50];
                return;
            end
            
            % Now COMPUTE THE HEIGHT AND WIDTH OF EACH GRAPH
            rowHeight = double(screenHeight - topBuffer  - botBuffer)   /  double(inputNumRows);
            colWidth  = double(screenWidth  - leftBuffer - rightBuffer)  /  double(inputNumCols);
            
            % NOW COMPUTE THE POSITION OF THE FIGURE
            figpos_x = leftBuffer + colWidth   *  double( (thisCol-1) );
            figpos_y = botBuffer  + rowHeight  *  double( (inputNumRows - thisRow) );

            % FINALLY PUT TOGHETHER THE RETURN VARIABLE
            figurePosition= [ figpos_x , figpos_y , colWidth , rowHeight ];
            
        end
        
        
    end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

