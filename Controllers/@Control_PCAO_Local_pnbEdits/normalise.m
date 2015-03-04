function [ Y, bounds ] = normalise( X, w )
% THIS FUNCTION NORMALISES EACH ROW OF X USING ITS RESPECTIVE ROW DATA
% IN ORDER TO SET THE VALUES OF THIS ROW BETWEEN -w AND w
% if w>0 then the function normalises the given input X between -w and w
% if w=0 then the function normalises the given input between 0 and 1
% if w<0 then the function is disabled

if w>=0
    [ variables, samples ] = size(X);
    Y = ones(variables, samples);
    bounds = double(minmax(X));
    for i=1:variables
        if bounds(i,1)~=bounds(i,2) % checking whether a normalisation problem occurs
            temp = double(X(i,:)-bounds(i,1))./(bounds(i,2)-bounds(i,1));
            if w==0
               Y(i,:) = temp;
            else
               Y(i,:) = 2*w*temp - w;
            end
        else
            if bounds(i,1)==0
                Y(i,:) = zeros(1,samples);
            end
        end
    end
else
    Y = X;
    bounds = [];
end

end

