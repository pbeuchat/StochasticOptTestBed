%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     storeOptResult.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [currClock, currDateTimeStr, currDateStr, currTimeStr] = getCurrentTimeStrings()

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
%
% OUTPUTS:
%       > No inputs required

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
