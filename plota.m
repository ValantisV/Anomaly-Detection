%% Plot data
figure('visible','off')
plot3(x,Demand,Price) % plot raw data
xlabel('time') 
ylabel('Demand [MW]') 
zlabel('Spot Price [$/MWh]') 
rotate3d

% 2D plot
figure('visible','on')
scatter(Demand,Price)
xlabel('Demand [MW]') 
ylabel('Spot Price [$/MWh]') 




