function [ x ] = createTRAININGdata(X_buffer, P_ij_buffer, Global_Cost_buffer, GlobalCapBuffer, i)
% THIS FUNCTION CREATES A COMPATIBLE DATA SET FOR TRAINING THE ESTIMATOR OR
% VALIDATING THE CANDIDATE MATRICES

if i>GlobalCapBuffer
    ReducedGlobalBuffer = [ Global_Cost_buffer(i-GlobalCapBuffer+1:i) ];
    ReducedXbuffer = [ X_buffer(:,i-GlobalCapBuffer+1:i) ];
else
    ReducedGlobalBuffer = [ Global_Cost_buffer(1:i); zeros(GlobalCapBuffer-i,1) ]; % filling with zeros the rest of the missing historical data points
    ReducedXbuffer = [ X_buffer(:,1:i), zeros(size(X_buffer,1),GlobalCapBuffer-i) ];
end
x = [ P_ij_buffer; reshape(ReducedXbuffer,size(ReducedXbuffer,2)*size(ReducedXbuffer,1),1); ReducedGlobalBuffer ];

end