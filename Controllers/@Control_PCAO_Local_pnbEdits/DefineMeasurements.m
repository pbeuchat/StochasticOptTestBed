function [ MEASUREData_t ] = DefineMeasurements(Param,Cost_vector,current_folder,System,x,xi,predictions,actions )


CHI_VECTOR=x;
D_VECTOR=xi;
PREDICT_D_VECTOR=predictions.mean;
ENERGY_COST=Cost_vector(2)/1000;
COMFORT_COST=Cost_vector(3);

if exist([current_folder,'U_Actions.mat'],'file')
       load([current_folder,'U_Actions.mat'])
else
     u_tt = 1.8*ones(actions,1);
end


UBAR_VECTOR=u_tt;

% CHI_VECTOR = [ random('Uniform',18,30,[1, 10]), random('Uniform',30,80,[1, 10]) ]; % = [ ZoneTemps, ZoneHumids ];
% UBAR_VECTOR = 25*ones(10,1)';
% D_VECTOR = [random('Uniform',30,80,[1, 2]) ];
% PREDICT_D_VECTOR = [random('Uniform',15,30,[1,2*6])];
% ENERGY_COST = sum([random('Uniform',1500,3000,[1, 10/2])]);
% COMFORT_COST = 0*ones(10,1)';
% 
% 


MEASUREData_t = [ CHI_VECTOR', UBAR_VECTOR', D_VECTOR', PREDICT_D_VECTOR', ENERGY_COST', COMFORT_COST' ];
