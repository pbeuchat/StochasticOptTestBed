function [ NORMAL_period_total_cost, NORMAL_period_total_error ] = CAOnormBCS_mod (CAO_period_cost, dV, dt, MainPath, UpdateFreq)

% THIS FUNCTION NORMALISES THE CAO DATA WITH THE RESPECTIVE BCS DATA

% structure = load([MainPath,'NORM_COST.mat']);
% NORM_COST = structure.('NORM_COST');
NORM_COST = 1; % CAO mod
%dV = 0; % CAO mod
NORMAL_period_total_cost = CAO_period_cost/NORM_COST;
NORMAL_period_total_error = ( dV + UpdateFreq*dt*NORMAL_period_total_cost );

end