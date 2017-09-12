function samples = read_crash(fname)
% reads and preprocesses raw input data

% domain: car crash death rate
% samples: daily summaries of traffic and car crash records

% variables (network nodes):
% AverageSpeed -- the average travel speed (low high)
% Country -- the country/region that provides the summary (US UK Europe)
% DangerLevel -- aggregate crash danger estimate (unknown ingredients) (low high)
% NumberAccidents -- the number of accidents (low medium high)
% NumberFatalities -- the number of fatalities for the given traffic day (low medium high)
% NumberJourneys -- the number of journeys made (low high)
% PoliceActivity -- activity resulting from a car accident fighting police action? (regular increased)
% RoadConditions -- the conditions of roads (bad good)
% Season -- the period of a year (winter spring summer fall)
% Weather -- weather conditions (bad good)
% Weekend -- day type (working weekend holiday)

AverageSpeed = 1; Country = 2; DangerLevel = 3; NumberAccidents = 4; NumberFatalities = 5; NumberJourneys = 6; PoliceActivity = 7; RoadConditions = 8; Season = 9; Weather = 10; Weekend = 11;
 
% the number of variables
N=11;
names = {'AverageSpeed', 'Country', 'DangerLevel', 'NumberAccidents', 'NumberFatalities', 'NumberJourneys', 'PoliceActivity', 'RoadConditions', 'Season', 'Weather', 'Weekend'};
node_sizes = [2 3 2 3 3 2 2 2 4 2 3];

fid = fopen(fname);
data_raw = textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s','delimiter',',');

nsamples = size(data_raw{1,1},1);

% prevod textove reprezentace na ciselnou
for i = 1 : nsamples
    switch data_raw{1,AverageSpeed}{i,1}
        case 'low',              data_raw{1,AverageSpeed}{i,1}=1;
        case 'high',             data_raw{1,AverageSpeed}{i,1}=2;
        case 'NaN',              data_raw{1,AverageSpeed}{i,1}=NaN;
    end
    switch data_raw{1,Country}{i,1}
        case 'US',               data_raw{1,Country}{i,1}=1;
        case 'UK',               data_raw{1,Country}{i,1}=2;
        case 'Europe',           data_raw{1,Country}{i,1}=3;
        case 'NaN',              data_raw{1,Country}{i,1}=NaN;
    end
    switch data_raw{1,DangerLevel}{i,1}
        case 'low',              data_raw{1,DangerLevel}{i,1}=1;
        case 'high',             data_raw{1,DangerLevel}{i,1}=2;
        case 'NaN',              data_raw{1,DangerLevel}{i,1}=NaN;
    end
    switch data_raw{1,NumberAccidents}{i,1}
        case 'low',              data_raw{1,NumberAccidents}{i,1}=1;
        case 'medium',           data_raw{1,NumberAccidents}{i,1}=2;
        case 'high',             data_raw{1,NumberAccidents}{i,1}=3;
        case 'NaN',              data_raw{1,NumberAccidents}{i,1}=NaN;
    end
    switch data_raw{1,NumberFatalities}{i,1}
        case 'low',              data_raw{1,NumberFatalities}{i,1}=1;
        case 'medium',           data_raw{1,NumberFatalities}{i,1}=2;
        case 'high',             data_raw{1,NumberFatalities}{i,1}=3;
        case 'NaN',              data_raw{1,NumberFatalities}{i,1}=NaN;
    end
    switch data_raw{1,NumberJourneys}{i,1}
        case 'low',              data_raw{1,NumberJourneys}{i,1}=1;
        case 'medium',           data_raw{1,NumberJourneys}{i,1}=2;
        case 'high',             data_raw{1,NumberJourneys}{i,1}=3;
        case 'NaN',              data_raw{1,NumberJourneys}{i,1}=NaN;
    end
    switch data_raw{1,PoliceActivity}{i,1}
        case 'regular',          data_raw{1,PoliceActivity}{i,1}=1;
        case 'increased',        data_raw{1,PoliceActivity}{i,1}=2;
        case 'NaN',              data_raw{1,PoliceActivity}{i,1}=NaN;
    end
    switch data_raw{1,RoadConditions}{i,1}
        case 'bad',              data_raw{1,RoadConditions}{i,1}=1;
        case 'good',             data_raw{1,RoadConditions}{i,1}=2;
        case 'NaN',              data_raw{1,RoadConditions}{i,1}=NaN;
    end
    switch data_raw{1,Season}{i,1}
        case 'winter',           data_raw{1,Season}{i,1}=1;
        case 'spring',           data_raw{1,Season}{i,1}=2;
        case 'summer',           data_raw{1,Season}{i,1}=3;
        case 'fall',             data_raw{1,Season}{i,1}=4;
        case 'NaN',              data_raw{1,Season}{i,1}=NaN;
    end
    switch data_raw{1,Weather}{i,1}
        case 'bad',              data_raw{1,Weather}{i,1}=1;
        case 'good',             data_raw{1,Weather}{i,1}=2;
        case 'NaN',              data_raw{1,Weather}{i,1}=NaN;
    end
    switch data_raw{1,Weekend}{i,1}
        case 'working',          data_raw{1,Weekend}{i,1}=1;
        case 'weekend',          data_raw{1,Weekend}{i,1}=2;
        case 'holiday',          data_raw{1,Weekend}{i,1}=3;
        case 'NaN',              data_raw{1,Weekend}{i,1}=NaN;
    end
end

% transformace dat do podoby pozadovane BN algoritmy uceni
samples = cell(N, nsamples);
for i = 1:N
    samples(i,:) = data_raw{1,i}';
end
