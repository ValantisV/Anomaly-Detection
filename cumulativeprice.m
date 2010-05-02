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
