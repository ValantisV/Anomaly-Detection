%% Filter Data by price
indxPrice2 = find(Price>250); 
Price2 = Price(indxPrice2); 
x1 = x(indxPrice2);
Demand2 = Demand(indxPrice2); 

% 2D plot
figure('visible','on')
scatter(Demand2,Price2), title('Demand and Price for price>$250')
xlabel('Demand [MW]') 
ylabel('Spot Price [$/MWh]')

