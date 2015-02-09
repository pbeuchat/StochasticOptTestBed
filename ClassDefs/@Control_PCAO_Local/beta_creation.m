function [GC_temp, GC_humid, temp_sigma, humid_sigma] = beta_creation( L, y_max, y_min )

% NORMALISED BETA FUNCTION CALCULATION (GAUSSIAN DISTRIBUTION IMPLEMENTED)

% y_min,y_max: are the vectors that contain the min and max values of the states 
% L: is the number of the mixing functions used for system approximation
    
    zone_number = length(y_min)/2;
    temperatures_min = y_min(1:zone_number);
    humidities_min = y_min(zone_number+1:end);
    temperatures_max = y_max(1:zone_number);
    humidities_max = y_max(zone_number+1:end);
    %--------------------------------------------------------------------------
    % norm calculation of state vectors for all time instances in order to
    % construct properly the the beta functions and find their characteristics
    %--------------------------------------------------------------------------
    
    temp_sigma=(norm(temperatures_max)-norm(temperatures_min))/(6*L); % Guassian variance
    humid_sigma=(norm(humidities_max)-norm(humidities_min))/(6*L); % Guassian variance

    GC_temp=zeros(1,L); % Gaussian Centers
    GC_temp(1)=norm(temperatures_min)+3*temp_sigma; 
    for i=2:L

        GC_temp(i)=GC_temp(1)+6*(i-1)*temp_sigma;

    end

    GC_humid=zeros(1,L); % Gaussian Centers
    GC_humid(1)=norm(humidities_min)+3*humid_sigma; 
    for i=2:L

        GC_humid(i)=GC_humid(1)+6*(i-1)*humid_sigma;

    end

end