% --------------------- load_SAPredispatch.m ------------------ %
%                                                               %
% This file reads in the demand forecast data from the          %
% files obtained from AEMO's website. The data is found in      %
% Predispatch archive files located at:                         %
% http://www.aemo.com.au/data/csv.htm                           %
%                                                               %
% 20/8/09: When I did this I could only do 51 days at a time    %
% because of disc space limitations with the raw files.         %
% 
% Nicholas Cutler
% Initialised: 19 August 2009.
% 

close all; clear all; clc

% Choose batch.
Batch = 7;

% Start and end date for data files.
if Batch == 1
    StartDate = '20-Jul-2008 00:00:00';
    EndDate   = '10-Sep-2008 00:00:00';
elseif Batch == 2
    StartDate = '10-Sep-2008 00:00:00';
    EndDate   = '01-Nov-2008 00:00:00';
elseif Batch == 3
    StartDate = '01-Nov-2008 00:00:00';
    EndDate   = '22-Dec-2008 00:00:00';
elseif Batch == 4
    StartDate = '22-Dec-2008 00:00:00';
    EndDate   = '14-Feb-2009 00:00:00';
elseif Batch == 5
    StartDate = '14-Feb-2009 00:00:00';
    EndDate   = '18-Apr-2009 00:00:00';
elseif Batch == 6
    StartDate = '18-Apr-2009 00:00:00';
    EndDate   = '07-Jun-2009 00:00:00';
elseif Batch == 7
    StartDate = '07-Jun-2009 00:00:00';
    EndDate   = '26-Jul-2009 00:00:00';
end

% REGIONID - South Australia!
desired_REGIONID = 'SA1';

line_format =['%*s %*s %*s %*n %*n %*n %s %n %*n',...
   ' %f %f %f %*f %f %f',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %s %*f %f %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s',...
   ' %*s %*s %*s %*s %*s %*s %*s %*s %*s %f %f'];

extras_X4 = ' %*f %*f %*f';

Data_Headers = {'REGIONID','PERIODID','TOTALDEMAND',...
    'AVAILABLEGENERATION','AVAILABLELOAD','DISPATCHABLEGENERATION',...
    'DISPATCHABLELOAD','DATETIME','CLEAREDSUPPLY',...
    'TOTALINTERMITTENTGENERATION','DEMAND_AND_NONSCHEDGEN'};

file_path = '../Data/Predispatch/';

StartDateNum = datenum(StartDate);
EndDateNum   = datenum(EndDate);

% How many forecast runs are made in the data - updated very half-hour.
L_FR = (EndDateNum - StartDateNum)*48; % * 48 for 30-min data.
% What is the maximum projection time of the forecasts (56 hours).
MaxPT = 79;

% Demand_fc has the Demand forecast data. It has two dimensions, one
% has length L_FR for each forecast run, and the other dimension has
% size MaxPT for projection horizons for the forecasts made for each
% forecats run.
Demand_fc = zeros(MaxPT, L_FR);
% And the other values/column to read in:
AvailGen_fc = zeros(MaxPT, L_FR);
AvailLoad_fc = zeros(MaxPT, L_FR);
DispatchableGen_fc = zeros(MaxPT, L_FR);
DispatchableLoad_fc = zeros(MaxPT, L_FR);
Supply_cleared = zeros(MaxPT, L_FR);
IntermittentGen = zeros(MaxPT, L_FR);
DemandAndNonSchedGen = zeros(MaxPT, L_FR);

% Make two DateStamps (DS) arrays. The projection time of the
%       forecasts is the first indicy of the forecats value.
% DS_in is the time each of the forecats runs are initialised. It has
%       only one value for each run, matching with the dimension
%       of Demand_fc for each half an hour in the data set.
% DS_it is the issued time for each of the forecasts.
DS_init = zeros(1, L_FR);
DS_it = zeros(MaxPT, L_FR);

% Loop to create the file names so we can open each one. One 
% issue here is that the file names include a seemingly random number
% in the filename. The code gets all the file names starting with the
% text and the date as seen in the code - only one will exist.
% Then this file name can be used to open the file and get the data.
% Furthermore the files have different numbers of lines in them,
% so the code finds where the data of interest
% starts and finishes.
dsi = 0; % Count up through the number of date stamps.
X = 3; % X is the number in the fourth column of the data.
for dd = StartDateNum+1/48:1/48:EndDateNum % Count up half hourly.
    
    cd_vec = datevec(dd); % Get vector of year,month,day,etc.
    % Put date in 12 digit number YYYYMMDDHHmm for file name.
    curr_date = cd_vec(1)*1e8 + cd_vec(2)*1e6 + ...
        cd_vec(3)*1e4 + cd_vec(4)*1e2 + round(cd_vec(5));
    
    % Get rest of file name:
    file_name1 = ['PUBLIC_PREDISPATCHIS_', num2str(curr_date),'_'];

    % Get rest of file name.
    [N, FA] = fileattrib([file_path, file_name1, '*.CSV']);

    % Open file with full file name.
    fid = fopen(FA.Name, 'r');
        
    % First check that file exists.
    if fid > 0 % File exists and can be opened.

        % This is a new file with its own forecast run and date stamp.
        dsi = dsi + 1;
        DS_init(dsi) = curr_date;
        
        % First loop to find first line of desired data.
        % It must be at least after rowStartSearch.
        cn = 0; % Count the number of lines.
        while 1
            cn = cn + 1;
            cline = fgetl(fid);
            if isequal(cline(1:31),'I,PREDISPATCH,REGION_SOLUTION,3')
                if X == 4
                    X = 1; % 1 means we were 4 but now we are 3 again.
                    % I don't think this happens in the data.
                end
                break;
            elseif isequal(cline(1:31),...
                    'I,PREDISPATCH,REGION_SOLUTION,4')
                if X == 3 % First time we've seen it.
                    X = 4;
                elseif X == 4
                    X = 2; % 2 means we are in the 4's now.
                end
                break;
            end
        end
        row1 = cn;
        
        if X == 4
            line_format = [line_format, extras_X4];
        elseif X == 1
            'warning: X = 1'
        end
        
        % Close file and open again ready 
        % for different form of extraction.
        fclose(fid);
        fid = fopen(FA.Name , 'r');
        
        % Extract section of data of interest.
        DM = textscan(fid, line_format, ...
            'headerlines', row1, 'delimiter', ',');
        
        D_REGIONID = DM{1};
        D_PERIODID = DM{2};
        D_Demand_fc = DM{3};
        D_AvailGen = DM{4};
        D_AvailLoad = DM{5};
        D_DispatchableGen = DM{6};
        D_DispatchableLoad = DM{7};
        D_DS_it = DM{8};
        D_Supply = DM{9};
        D_IntermittentGen = DM{10};
        D_DemandAndNonSchedGen = DM{11};

        % Loop through data picking out the data for the desired
        % region set by desired_REGIONID above.
        jj = 0;
        for ii = 1:length(D_REGIONID)
            if isequal(D_REGIONID{ii}, desired_REGIONID)
                jj = jj + 1;
                % The Demand forecast:
                Demand_fc(D_PERIODID(jj), dsi) = D_Demand_fc(ii);
                % And the other values/column to read in:
                AvailGen_fc(D_PERIODID(jj), dsi) = D_AvailGen(ii);
                AvailLoad_fc(D_PERIODID(jj), dsi) = D_AvailLoad(ii);
                DispatchableGen_fc(D_PERIODID(jj), dsi) = ...
                    D_DispatchableGen(ii);
                DispatchableLoad_fc(D_PERIODID(jj), dsi) = ...
                    D_DispatchableLoad(ii);
                Supply_cleared(D_PERIODID(jj), dsi) = D_Supply(ii);
                IntermittentGen(D_PERIODID(jj), dsi) = ...
                    D_IntermittentGen(ii);
                DemandAndNonSchedGen(D_PERIODID(jj), dsi) = ...
                    D_DemandAndNonSchedGen(ii);
                % And the issued times.
                TD = char(D_DS_it(ii));
                DS_it(D_PERIODID(jj), dsi) = str2num(TD(2:5))*1e8 + ...
                    str2num(TD(7:8))*1e6 + str2num(TD(10:11))*1e4 + ...
                    str2num(TD(13:14))*1e2 + str2num(TD(16:17));
            end
        end
        
        % For the cases where the forecasts are for less than MaxPT
        % hours projection time, make missing ones NaN.
        % This appears to be for dates prior 200807201300.
        if D_PERIODID(jj) < MaxPT
            Demand_fc(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            AvailGen_fc(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            AvailLoad_fc(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            DispatchableGen_fc(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            DispatchableLoad_fc(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            Supply_cleared(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            IntermittentGen(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            DemandAndNonSchedGen(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
            DS_it(D_PERIODID(jj)+1:MaxPT, dsi) = NaN;
        end

        fclose(fid);
    end
    
    
end

% Save data.
if Batch == 1
    DatesTag = '20JulyTo10Sep';
elseif Batch == 2
    DatesTag = '10SepTo1Nov';
elseif Batch == 3
    DatesTag = '1NovTo22Dec';
elseif Batch == 4
    DatesTag = '22DecTo14Feb';
elseif Batch == 5
    DatesTag = '14FebTo18Apr';
elseif Batch == 6
    DatesTag = '18AprTo7Jun';
elseif Batch == 7
    DatesTag = '7JunTo26Jul';
end

savename = ['MatlabDataFiles/','SADemandForecasts_',DatesTag];

save(savename, 'DS_init', 'DS_it', 'Demand_fc', 'AvailGen_fc', ...
    'AvailLoad_fc', 'DispatchableGen_fc', 'DispatchableLoad_fc', ...
    'Supply_cleared', 'IntermittentGen', 'DemandAndNonSchedGen')