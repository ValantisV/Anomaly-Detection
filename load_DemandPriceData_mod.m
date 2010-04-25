% ------------------- load_DemandPriceData.m ------------------ %
%                                                               %
% This file reads in the demand and spot price data (30min)     %
% from the files obtained from the NEMMCO website at            %
% the Aggregated Price and Demand Data - Historical at:         %
% http://www.nemmco.com.au/data/market_data.htm                 %
% 
% 
% Nicholas Cutler/Valantis Vais
% Initialised: 20 May 2009.
% Updated: 5 August 2009.
%
close all; clear all; clc

% Start and end date for data files.
StartDate = '01-Jan-2009 00:00:00';
EndDate   = '01-Dec-2009 00:00:00';

% % For 2000-1 year.
% StartDate = '01-Jul-2000 00:00:00';
% EndDate   = '01-Jun-2001 00:00:00';

file_path = 'Data/DemandPrice/';
 %file_path =  uigetdir;
line_format = '%*s %s %f %f %*s';

StartDateNum = datenum(StartDate);
EndDateNum   = datenum(EndDate);

L_DS = (EndDateNum - StartDateNum + 1)*48; % *48 for 30-min data.

% Initialise power data array.
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
        
        file_name = ['DATA', num2str(curr_date), '_SA1.csv'];
        % Open file.
        fid = fopen([file_path,'\', file_name] , 'r');

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

[sdate,remain]= strtok(StartDate);
[edate,remain]= strtok(EndDate);
% Save 30-min data.
targetfolder = 'Data/MatlabDataFiles/';
savename = ['DemandPrice_SA1','_',sdate,'_',edate];
% savename = ['MatlabDataFiles/','DemandPrice_SA_2000-1'];

save(strcat(targetfolder,savename),'Demand', 'Price')




Matrix = [L_DS,Demand,Price];

l_Demand = length(Demand);
l_Price = length(Price);
l_L_DS = length(DS_dp);

DS_dp(1:100)

x = 1:1:length(DS_dp);

l_x = length(x);


%Matrix(0:200,0:200)



%% Plot data

plot3(x,Demand,Price) % plot raw data
xlabel('time') 
ylabel('Demand [MW]') 
zlabel('Spot Price [$/MWh]') 
rotate3d


%% Filter Data

% 1: filter out data for demand below 5500 MW. 
indxDemand1 = find(Demand<5500); % get indices for demand < 5500 MW
Price1 = Price(indxDemand1); % get prices corresponding to demand < 5500 MW
x1 = x(indxDemand1); % create an array x1 with the length of data for demand < 5500 MW
Demand1 = Demand(indxDemand1); % get demand values at indices where demand < 5500 MW

figure()
plot3(x1,Demand1,Price1,'Color','r') % plot filtered data
xlabel('time') 
ylabel('Demand [MW]') 
zlabel('Spot Price [$/MWh]') 
rotate3D
