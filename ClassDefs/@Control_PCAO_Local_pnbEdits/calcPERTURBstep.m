function [ a ] = calcPERTURBstep( a0, timestep_counter )

% OPTIMISATION PERTURBATION STEP
h = 0.5;
a = a0/(1+timestep_counter)^h;
a = a0; % MOD: delete this line if decaying exploration step is needed

end