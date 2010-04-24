% ---------------------- load_SAGendata.m --------------------- %
%                                                               %
% This file reads in the scheduled generator data from the      %
% files obtained from NEMMCO's website. The data is found in    %
% Daily Aggregated Dispatch archive files located at:           %
% http://www.nemmco.com.au/data/csv.htm#DailyAgg                %
% The files are really big so this code reads in the data of    %
% interest - the half hour 'TOTALCLEARED' MW values metered     %
% from the . These are NPS1, NPS2, PLAYB-AG, OSB-AG,            %
% TORRA1, TORRA2, TORRA3, TORRA4, TORRB1, TORRB2, TORRB3,       %
% TORRB4, ANGAS1, ANGAS2, LADBROK1, LADBROK2, QPS1,             %
% QPS2, QPS3, QPS4, QPS5, PPCCGT, DRYCGT1, DRYCGT2, DRYCGT3,    %
% MINTARO, POR01, SNUG1 and AGLHAL. NPS1, NPS2 and PLAYB-AG are %
% coal and the rest gas except ANGAS1 and ANGAS2 which are      %
% diesel. This data does not start in                           %
% the files until after line 230177, so to save space, the      %
% files are later deleted from the hard drive to save space.
% 
% Nicholas Cutler
% Initialised: 5 August 2009.
% 

close all; clear all; clc

% SA Generator data IDs to get:
DUIDs_sched = {'AGLHAL', 'ANGAS1', 'ANGAS2', 'DRYCGT1', 'DRYCGT2', ...
    'DRYCGT3', 'LADBROK1', 'LADBROK2', 'MINTARO', ...
    'NPS1', 'NPS2', 'OSB-AG', 'PLAYB-AG', 'POR01', 'PPCCGT', 'QPS1', ...
    'QPS2', 'QPS3', 'QPS4', 'QPS5', 'SNUG1', 'TORRA1', 'TORRA2', ...
    'TORRA3', 'TORRA4', 'TORRB1', 'TORRB2', 'TORRB3', 'TORRB4'};

Ratings_sched = [180, 30, 20, 52, 52, 52, 40, 40, 90, ...
    265, 265, 180, 240, 50, 478, 24, 24, 24, 24, 128, 63, ...
    120, 120, 120, 120, 200, 200, 200, 200];

% Value column to obtain.
vc2ob = 'TOTALCLEARED';

% Start and end date for data files.
StartDate = '01-Jul-2008 00:00:00';
EndDate   = '30-Jun-2009 00:00:00';

file_path = '../Data/Dispatch/';
if isequal(vc2ob, 'TOTALCLEARED')
    line_format = ['%*s %*s %*s %*n %s %*n %s %*f %f %*n %*n %*n ',...
        '%*n %*n %*n %*n %*n %*n %*n %*n'];
elseif isequal(vc2ob, 'INITIALMW')
    line_format = ['%*s %*s %*s %*n %s %*n %s %f %*f %*n %*n %*n ',...
        '%*n %*n %*n %*n %*n %*n %*n %*n'];
end

rowStartSearch = 215000;
% Number of lines to search at a time to find the start row.
searchAmount = 10000; 

StartDateNum = datenum(StartDate);
EndDateNum   = datenum(EndDate);
LDUIDs_sched = length(DUIDs_sched);
L_DS = (EndDateNum - StartDateNum + 1)*48; % * 48 for 30-min data.
% Initialise wind farm power data array.
SAGen_power_sched = zeros(LDUIDs_sched, L_DS);
DS_sched = zeros(1, L_DS);

% Loop to create the file names so we can open each one. One 
% issue here is that the file names include the exact time they 
% were created to the nearest second. These are not consistent
% and could end in 00, 01, 02, 03 or 04. So the code tries to 
% read in all of them but only one will exist.
% Furthermore the files have different numbers of lines in them,
% so the code needs to find quickly where the data of interest
% starts and finishes - to do this it scans 10000 lines of code at a
% time looking for where the 4th column changes from 1 to 2.
% It starts at line 215000 which is before the start line for the
% smallest file in the data set.
dsi = 0; % Count up through the number of date stamps.
for dd = StartDateNum:1:EndDateNum % Count up daily.
    
    cd_vec = datevec(dd); % Get vector of year,month,day,etc.
    % Put date in 12 digit number YYYYMMDDHHmm for file name.
    curr_date = cd_vec(1)*1e8 + cd_vec(2)*1e6 + ...
        cd_vec(3)*1e4 + cd_vec(4)*1e2 + round(cd_vec(5));

    % Also need date string for 28 hours and 5 minutes 
    % later for file name.
    cd_vec = datevec(dd + 28/24 + 5/60/24);
    % Put date in 12 digit number YYYYMMDDHHmmss for file name.
    curr_date_plus28 = cd_vec(1)*1e10 + cd_vec(2)*1e8 + ...
        cd_vec(3)*1e6 + cd_vec(4)*1e4 + round(cd_vec(5))*1e2;
    
    % Extra loop to find which second the file was created.
    for ss = 0:4
        
        file_name = ['PUBLIC_DAILY_', num2str(curr_date), ...
            '_', num2str(curr_date_plus28 + ss), '.CSV'];
        
        % First check that file exists.
        fid = fopen([file_path, file_name] , 'r');

        if fid > 0 % File exists and can be opened.
            
            % First loop to find first line of desired data.
            % It must be at least after rowStartSearch.
            cn = 0; % Count the number of lines.
            for cn = 1:rowStartSearch
                cline = fgetl(fid);
            end
            while 1
                cn = cn + 1;
                cline = fgetl(fid);
                if isequal(cline(1:10),'I,TUNIT,,2')
                    break;
                end
            end
            row1 = cn;
            
            fclose(fid);
            fid = fopen([file_path, file_name] , 'r');
            
            % Extract section of data of interest.
            DM = textscan(fid, line_format, ...
                'headerlines', row1, 'delimiter', ',');
            
            D_dates = DM{1};
            D_DUIDs = DM{2};
            D_MW = DM{3};
            clear DM;
            
            % Loop through data picking out the data, expecting
            % the DUIDs to be in alphabetical order for each
            % time stamp with none missing to save time.
            jj = 1; % Count through the desired DUIDs.
            LD = length(D_DUIDs);
            for ii = 1:LD
                if isequal(D_DUIDs{ii}, DUIDs_sched{jj})
                    if jj == 1 % This is a new date stamp.
                        dsi = dsi + 1;
                        DSstr = D_dates{ii};
                        DS_sched(dsi) = str2num(DSstr(2:5))*1e8 + ...
                            str2num(DSstr(7:8))*1e6 + ...
                            str2num(DSstr(10:11))*1e4 + ...
                            str2num(DSstr(13:14))*1e2 + ...
                            str2num(DSstr(16:17));
                    end
                    SAGen_power_sched(jj, dsi) = D_MW(ii);
                    jj = jj + 1;
                    if jj == LDUIDs_sched + 1
                        jj = 1;
                    end
                % This elseif line was added to account for QPS5 only
                % coming online during the period analysed.
                % It will work for any other missing DUID, as long as
                % there aren't two missing ones in a row.
                % It also can't be the first one in the list.
                elseif jj < LDUIDs_sched & ...
                        isequal(D_DUIDs{ii}, DUIDs_sched{jj+1})
                    % We've found that the next recognisable DUID in
                    % the column skips one in the list.
                    % So the missing one gets NaN.
                    SAGen_power_sched(jj, dsi) = NaN;
                    jj = jj + 1;
                    % And the next one can be filled in.
                    SAGen_power_sched(jj, dsi) = D_MW(ii);
                    jj = jj + 1;
                end
            end
                    
            fclose(fid);
        end
    end
    
    if mod(dsi, 48*30) == 0
        '1 month done'
    end
end
% Although it is not necessary to create the DSplot array in this way,
% it is a good way to check the dates read in from the file are 
% consistent.
DSplot_sched = zeros(1,length(DS_sched));
for ii = 1:length(DS_sched)
    DSplot_sched(ii) = ...
        datenum(conv_date_12d_to_0str(DS_sched(ii)));
end

% Save data.
savename = ['MatlabDataFiles/','SAGen_power_sched'];

save(savename, 'DSplot_sched', 'DS_sched', 'DUIDs_sched', ...
    'SAGen_power_sched', 'Ratings_sched')