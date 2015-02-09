function [ y ] = vectorBOUNDnormalisation( x, bounds, w )
% THIS FUNCTION NORMALISES x ACCORDING TO THE RESPECTIVE BOUNDS
% if w>0 then the function normalises the given input X between -w and w
% if w=0 then the function normalises the given input between 0 and 1
% if w<0 then the function is disabled

y = ones(size(x));
if w>=0
    for ii=1:length(x)
        if bounds(ii,1)~=bounds(ii,2) % checking whether a normalisation problem occurs
            temp = double(x(ii)-bounds(ii,1))./(bounds(ii,2)-bounds(ii,1));
            if w==0
                y(ii) = temp;
            else
                y(ii) = 2*w*temp - w;
            end
        else
            if bounds(ii,1)==0
                y(ii) = 0;
            end
        end
    end
else
    y = x;
end

end