%% Filter Data

% 1: filter out data for demand below 5500 MW. 
indxDemand1 = find(Demand<5500); % get indices for demand < 5500 MW
Price1 = Price(indxDemand1); % get prices corresponding to demand < 5500 MW
x1 = x(indxDemand1); % create an array x1 with the length of data for demand < 5500 MW
Demand1 = Demand(indxDemand1); % get demand values at indices where demand < 5500 MW

figure('visible','off')
plot3(x1,Demand1,Price1,'Color','r') % plot filtered data
xlabel('time') 
ylabel('Demand [MW]') 
zlabel('Spot Price [$/MWh]') 
rotate3D

% 2D plot
figure('visible','on')
scatter(Demand1,Price1), title('Demand and Price for demand<5500 MW')
xlabel('Demand [MW]') 
ylabel('Spot Price [$/MWh]')