function [currClock, currDateTimeStr, currDateStr, currTimeStr] = getCurrentTimeStrings()
%  getCurrentTimeStrings.m
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        1 Oct 2013
%  GOAL:        Towards Double-Sided OPF
%  DESCRIPTION: > This script ...
%               > xxx
%  HOW TO USE:  ... edit the ...
%               ... use the "pre-compile" switches on turn on/off the
%                   the following features
%
% INPUTS:
%       > No inputs required
% OUTPUTS:
%       > A series of various representations of the current time
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



currDateTimeStr = datestr(now);
currClock = clock;
currYear = currClock(1);
currMonth = currClock(2);
currDay = currClock(3);
currHour = currClock(4);
currMin = currClock(5);
currSec = floor(currClock(6));
%monthStrAll = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
%currDateStr = [num2str(currYear),'-',monthStrAll{currMonth},'-',num2str(currDay)];
currDateStr = [num2str(currYear,'%04d'),'-',num2str(currMonth,'%02d'),'-',num2str(currDay,'%02d')];
currTimeStr = [num2str(currHour,'%02d'),'h',num2str(currMin,'%02d'),'m',num2str(currSec,'%02d'),'s'];
