n = 500;

mu = zeros(n,1);

sigma = zeros(n,n);

temp = 1;

%sigma = temp*ones(n,n);

sigma = temp*ones(n-100,n-100);




for i=1:n
    sigma(i,i) = 1.02 * temp;    
end

% for i = 1:(n-1)
%     sigma(i,i+1) = 1;
%     sigma(i+1,i) = 1;
% end




N = 10;

xi = mvnrnd(mu,sigma,N);

figure;
plot(xi');
