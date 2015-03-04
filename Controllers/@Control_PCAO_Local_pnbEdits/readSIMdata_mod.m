function [ chi_t, u_t, dist_t, predict_dist_t, chi_s, u_s, dist_s, predict_dist_s, cost_t, cost_s, t ]...
    = readSIMdata_mod(n, m, num_of_dist, predict_horizon, data)
    

    
    t = size(data,1);
    chi_t = data(t,1:n)';
    u_t = data(t,n+1:n+m)';
    dist_t = data(t,n+m+1:n+m+num_of_dist)';
    predict_dist_t = data(t,n+m+num_of_dist+1:n+m+num_of_dist+predict_horizon)';
    
    Energy_Cost_t = data(t,n+m+num_of_dist+predict_horizon+1);
    Comfort_Cost_t = data(t,n+m+num_of_dist+predict_horizon+2);
    cost_t = Energy_Cost_t + Comfort_Cost_t; % mod probably the normalization will be realized using BCS cost inside CAOnormBCS function
    
    if t>1
        chi_s = data(t-1,1:n)';
        u_s = data(t-1,n+1:n+m)';
        dist_s = data(t-1,n+m+1:n+m+num_of_dist)';
        predict_dist_s = data(t-1,n+m+num_of_dist+1:n+m+num_of_dist+predict_horizon)';
		
		Energy_Cost_s = data(t-1,n+m+num_of_dist+predict_horizon+1);
		Comfort_Cost_s = data(t-1,n+m+num_of_dist+predict_horizon+2);
        cost_s = Energy_Cost_s + Comfort_Cost_s; % mod probably the normalization will be realized using BCS cost inside CAOnormBCS function
    else
        chi_s = 0;
        u_s = 0;
        cost_s = 0;
        dist_s = 0;
        predict_dist_s = 0;
    end
end