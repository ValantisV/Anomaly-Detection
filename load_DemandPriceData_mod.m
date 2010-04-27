% ------------------- load_DemandPriceData.m ------------------ %
%                                                               %
% This file reads in the demand and spot price data (30min)     %
% from the files obtained from the NEMMCO website at            %
% the Aggregated Price and Demand Data - Historical at:         %
% http://www.nemmco.com.au/data/market_data.htm                 %
% 
% 
% Nicholas Cutler
% Initialised: 20 May 2009.
% Updated: 5 August 2009.

close all; clear all; clc

% Start and end date for data files.
StartDate = '01-Jan-2002 00:00:00';
EndDate   = '01-Jan-2009 00:00:00';

% % For 2000-1 year.
% StartDate = '01-Jul-2000 00:00:00';
% EndDate   = '01-Jun-2001 00:00:00';

file_path = 'Data/DemandPrice/';
line_format = '%*s %s %f %f %*s';

StartDateNum = datenum(StartDate);
EndDateNum   = datenum(EndDate);

L_DS = (EndDateNum - StartDateNum + 1)*48; % *48 for 30-min data.

% Initialise wind farm power data array.
Demand = zeros(1, L_DS);
Price = zeros(1, L_DS);
DS_dp = zeros(1, L_DS);

% Loop to create the file names so we can open each one.
dsi = 0; % Count up through the number of date stamps.
for dd = StartDateNum:1:EndDateNum % Count up daily.
    
    cd_vec = datevec(dd); % Get vector of year,month,day,etc.
    % The files are monthly so find the dates on the 1st of each month.
    if cd_vec(3) == 1
        % Put date in 6 digit number YYYYMM for file name.
        curr_date = cd_vec(1)*1e2 + cd_vec(2);
        
        file_name = ['DATA', num2str(curr_date), '_SA1.csv']
        % Open file.
        fid = fopen([file_path, file_name] , 'r');

        % Extract section of data of interest.
        DM = textscan(fid, line_format, ...
            'headerlines', 1, 'delimiter', ',');

        D_dates = DM{1};
        D_demand = DM{2};
        D_RRP = DM{3};
        clear DM;
        
        for ii = 1:length(D_demand)
            dsi = dsi + 1;
            DSstr = D_dates{ii};
            DS_dp(dsi) = str2num(DSstr(2:5))*1e8 + ...
                str2num(DSstr(7:8))*1e6 + ...
                str2num(DSstr(10:11))*1e4 + ...
                str2num(DSstr(13:14))*1e2 + ...
                str2num(DSstr(16:17));
        end
        Demand(dsi-length(D_demand)+1:dsi) = D_demand;
        Price(dsi-length(D_demand)+1:dsi) = D_RRP;
        
        fclose(fid);
    end
end

% % Although it is not necessary to create the DSplot array in this way,
% % it is a good way to check the dates read in from the file are 
% % consistent.
% DSplot_dp = zeros(1,length(DS_dp));
% for ii = 1:length(DS_dp)
%     DSplot_dp(ii) = ...
%         datenum(conv_date_12d_to_0str(DS_dp(ii)));
% end

l_Demand = length(Demand)
l_Price = length(Price)
l_L_DS = length(DS_dp)

[sdate,remain]= strtok(StartDate)
[edate,remain]= strtok(EndDate)
% Save 30-min data.
targetfolder = 'Data/MatlabDataFiles/';
savename = ['DemandPrice_SA1','_',sdate,'_',edate]

save(strcat(targetfolder,savename),'Demand', 'Price')


Matrix = [L_DS,Demand,Price];


x = 1:1:length(DS_dp);

l_x = length(x);


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


%% Cumulative Price calculation

if length(Price)<336
    fprintf('Chosen data interval less than a week\n')
    break    
end

CPcount = 0; %initialization
CParray = 0; %initialization
CPmax = 0; %initialization
CPT = 150000;
for i= 1:(length(Price)-336)
    CP(i) = sum(Price(i:i+336));
%     if CP>CPmax % replace
%         CPmax = CP;
%     end
    if CP(i)>CPT % check if CPT is exceeded
        %fprintf('CP: %f\n',CP)
        CParray(i) = CP(i);
        CPcount = CPcount + 1;
    end
end

figure()
hist(CP,100), title('Histogram of 7-day Cumulative Sums')

fprintf('Maximum of all rolling CPs: %f\n\n',CPmax)


fprintf('No of CP violations: %d\n',CPcount)
fprintf('Average CP: %f\n',mean(CParray))
fprintf('Min CP: %f\n',min(CParray))
fprintf('Max CP: %f\n',max(CParray))


%%
fprintf('Script completed\n')

