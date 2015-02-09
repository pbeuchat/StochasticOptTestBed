function RBCaction  = DECISIONS_RBC_mod (No)
%  THIS FUNCTION IS RESPONSIBLE OF DEFINING THE BASE CASE SCENARIO
%  COSNIDERED AS AN INITIAL POINT OF PCAO CONTROL STRATEGY

%[ ]; % extracted from common control practise for just one day
% BCSactions is a matrix of size = (NoActions) X
% (day_timesteps) (see MAIN_CAO Line 74 -- ubarBCS = BCSactions; it depends on the evitar's common control practise)

                           
% AT THIS POINT CONTROL RULES SHOULD BE DEFINED
RBCaction=25*ones(No,1);


end