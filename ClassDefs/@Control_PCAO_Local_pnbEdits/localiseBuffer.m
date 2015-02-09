function [ localBuffer ] = localiseBuffer( generalBuffer, Beta_buffer, CurrentActiveBeta, T_localBuffer )
% THIS FUNCTION CREATES A LOCAL BUFFER RESPECT TO CURRENT ACTIVE BETA
% if Local buffer exceeds T_localBuffer size then localbuffer completion stops 
% (if T_localBuffer=+Inf then local buffer is the full buffer)

prev_active_beta = Beta_buffer(end);
timestep = size(Beta_buffer,2);
[ buffer_rows, buffer_columns ] = size(generalBuffer);
matrix_buffer = 0; % generalBuffer is a vector

if buffer_rows>1
   matrix_buffer = 1; % generalBuffer is a matrix of tall vectors
end

localBuffer = [];

start = timestep;
step = -1;
stop = 1;
%start = 1;
%step = 1;
%stop = timestep;

number_of_buffered_elements_WRT_activeBeta = sum(Beta_buffer == CurrentActiveBeta);
ii = 0;
switch matrix_buffer
    case 0
        for i = start:step:stop
            if Beta_buffer(i) == CurrentActiveBeta
                ii = ii + 1;
                localBuffer = [ localBuffer, generalBuffer(i) ];
            end
            if ii>=T_localBuffer
                break
            end
        end
    case 1
        for i = start:step:stop
            if Beta_buffer(i) == CurrentActiveBeta
                ii = ii + 1;
                localBuffer = [ localBuffer, generalBuffer(:,i) ];
            end
            if ii>=T_localBuffer
                break
            end
        end
end

end

