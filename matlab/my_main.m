%% ================================================   
%  Exploratory data analysis
%  Construt table with p-value from chi-square test on independence
%  ================================================   
fprintf(1,'Explore the data ...\n');
fprintf(1,'Pairwise calculation of chi-sq test on independence ...\n');

data = read_crash('crash_txt.csv');
[n,m] = size(data);
data_mat = cell2mat(data);
[idx1 idx2] = find(isnan(data_mat));
data_miss_mat = data_mat(:,unique(idx2));
data_mat(:,idx2)=[];

% for constructing such a table we need only completed observations,
% without missing data
data_learn_num = data_mat;

chi_sq = zeros(n,n);
for i = 1:n
    for j = 1:n
        [tbl,chi2stat,pval] = crosstab(data_learn_num(i,:), data_learn_num(j,:));
        chi_sq(i,j) = pval;
    end
end

% plotting of p-values for chi-squar tests for each pair
figure();
imagesc(chi_sq <= 0.01);
title('p-value for all pairs of variables (chi-sq test on independence)')
fprintf(1,'table with p-values ...\n');
display(chi_sq)

%% ================================================   
%  Reading and data preparation
%  ================================================  
fprintf(1,'Data preparation ...\n');

data = read_crash('crash_txt.csv');
% data(2,:) = []; %let's remove inforamtion about countries

[n,m] = size(data);

top_list = 1:n;
original_list = [9, 10, 8, 1, 3, 7, 11, 6, 4, 5, 2]; % we know topological order of our hand made graph

data_mat = cell2mat(data);
top_data = data_mat;

% top sorting
fprintf(1,'Topologocal sort ...\n');

for i=1:length(original_list)
    top_data(top_list(i),:) = data_mat(original_list(i),:);
end

%% ================================================    
%  Splitting dataset: full, complete data and missing data
%  ================================================  
% now we are working only with topologically sorted data
fprintf(1,'Splitting data into train and test sets ...\n');

% split data into two sets: train and test (50/50 since we have a lot of missing data in test part)
data_mat = top_data;
data_train_all = data_mat(:,1:7000);
data_test_all = data_mat(:,7001:end);

% we need data_train_all (with missing values) and data_train_compl (without missing values)
[idx1 idx2] = find(isnan(data_train_all));
data_train_compl = data_train_all;
data_train_compl(:,idx2)=[];
data_train_compl = num2cell(data_train_compl);

% we need data_test_compl (testing only on complete data)
[idx1 idx2] = find(isnan(data_test_all));
data_test_compl = data_test_all;
data_test_compl(:,idx2)=[];
data_test_compl = num2cell(data_test_compl);


% replace NaN with [] in data_train_all
[idx1 idx2]=find(isnan(data_train_all));
data_train_all = num2cell(data_train_all);

for i=1:length(idx1)
    data_train_all{idx1(i),idx2(i)}=[];
end

% replace NaN with [] in data_test_all
[idx1 idx2]=find(isnan(data_test_all));
data_test_all = num2cell(data_test_all);

for i=1:length(idx1)
    data_test_all{idx1(i),idx2(i)}=[];
end


% DATA we have: 
data_train_all; % cell array for training (both complete + missing obs)
data_train_compl; % cell array for training (only complete)

data_test_compl; % cell array for training (only complete)


%% ================================================     
%   Create BN structure by hand
%  ================================================   
% we lookd at table with pairwise p-value from chi_sq teast and saw dependent variables
fprintf(1,'Creating first BN structure ...\n');

names = {'Country', 'Weekend','Season','Weather','RoadConditions','NumberJourneys','AverageSpeed','DangerLevel','PoliceActivity','NumberFatalities','NumberAccidents'}';
interc = {...
%            'Country', 'Weather';
           'Season', 'NumberJourneys'; %new
           'Season', 'Weather';
           'Weather', 'AverageSpeed';
           'Weather', 'RoadConditions';
           'RoadConditions', 'AverageSpeed';  %new
           'Weather', 'NumberJourneys';
           'AverageSpeed', 'DangerLevel';
           'RoadConditions', 'DangerLevel'; 
           'DangerLevel', 'PoliceActivity';
           'DangerLevel', 'NumberAccidents'; 
           'DangerLevel', 'NumberFatalities';
           'Weekend', 'NumberJourneys';
           'NumberJourneys', 'NumberAccidents';
           'NumberJourneys', 'NumberFatalities';
           'NumberAccidents', 'NumberFatalities'; %new
           };
       
[dag, names] = mk_adj_mat(interc, names, 1);
inter = mk_adj_mat(interc, names, 0);
l = length(names);
dnodes = 1:l; 
node_sizes = [4, 2, 2, 2, 2, 2, 3, 2, 3, 3, 3];

bnet = mk_bnet(dag, node_sizes, 'names', names);

% random parameters
seed = 1;
rand('state', seed);
for i=1:l
  bnet.CPD{i} = tabular_CPD(bnet, i);
end

AS = 4; 
CO = 11;
DL = 5; 
NA = 9;
NF = 10;
NJ = 8; 
PA = 6; 
RC = 3; 
SE = 1; 
WEA = 2; 
WEE = 7;

%% ================================================== 
%  I. Learn parameters: 
%  Known structure + complete data for learning (ML)
%  ==================================================
fprintf(1,'I. Learn parameters: Known structure + complete data for learning ...\n');

bnet1 = learn_params(bnet, data_train_compl);

CPT_show = cell(1,n);
for j=1:n
    s=struct(bnet1.CPD{j});
    CPT_show{j}=s.CPT;
end

% --- see parameters for nodes: ---
show_cpt = @(bnet,node) dispcpt(struct(bnet1.CPD{node}).CPT);
show_cpt(bnet1, DL);

% check logLL on train data 
L1 = log_lik_complete(bnet1, data_test_compl); 
score_bic1 = score_dags(data_test_compl, node_sizes, {bnet1.dag}, 'scoring_fn', 'bic');
score_bay1 = score_dags(data_test_compl, node_sizes, {bnet1.dag}, 'scoring_fn', 'bayesian');

fprintf(1,'Result 1...\n');
display(L1)
display(score_bic1)
display(score_bay1)

%% ====================================================  
%   II. Learn parameters: 
%   Known structure + uncomplete data for learning (EM)
%  ====================================================  
fprintf(1,'II. Learn parameters: Known structure + data with missing values for learning ...\n');

engine = jtree_inf_engine(bnet);

[bnet2, LL, engine2] = learn_params_em(engine, data_train_all, 10, 0.001);

L2 = log_lik_complete(bnet2, data_test_compl);
score_bic2 = score_dags(data_test_compl, node_sizes, {bnet2.dag}, 'scoring_fn', 'bic');
score_bay2 = score_dags(data_test_compl, node_sizes, {bnet2.dag}, 'scoring_fn', 'bayesian');

fprintf(1,'Result 2 ...\n');
display(L2)
display(score_bic2)
display(score_bay2)
%% ======================================================================  
%   Improvement of hand made BN structure -> Learning with impr.structure
%  ======================================================================
fprintf(1,'Improvement of current structure ...\n');

% -------------------
% MCMC algorithm 
% -------------------
fprintf(1,'1. Improvement with MCMC ...\n');

dag = bnet2.dag;
[sampled_graphs, accept_ratio] = learn_struct_mcmc(data_train_compl, node_sizes, 'init_dag', dag);   
score = score_dags(data_train_compl, node_sizes, sampled_graphs);   
best_dag = find(score == max(score));
best_dag_mcmc = sampled_graphs{1,best_dag(1)};

% create new BN with improved structure
bnet_mcmc = mk_bnet(best_dag_mcmc, node_sizes, 'names', names);
% random parameters
seed = 1;
rand('state', seed);
for i=1:l
  bnet_mcmc.CPD{i} = tabular_CPD(bnet_mcmc, i);
end

% learn new bn with improved structure (MCMC)
engine2 = jtree_inf_engine(bnet_mcmc);
[bnet3, LL, engine3] = learn_params_em(engine2, data_train_all, 10, 0.001);
L3 = log_lik_complete(bnet3, data_test_compl);
score_bic3 = score_dags(data_test_compl, node_sizes, {bnet3.dag}, 'scoring_fn', 'bic');
score_bay3 = score_dags(data_test_compl, node_sizes, {bnet3.dag}, 'scoring_fn', 'bayesian');

fprintf(1,'Result 3 ...\n');
display(L3)
display(score_bic3)
display(score_bay3)
%%
% -------------------
% K2 algorithm 
% -------------------
fprintf(1,'2. Improvement with K2 algorithm ...\n');

order_user = 1:11; % our data is alreay in topological order
dagK2 = learn_struct_K2(data_train_compl, node_sizes, order_user, 'verbose','yes');
% create new BN with improved structure
bnet_k2 = mk_bnet(dagK2, node_sizes, 'names', names);
% random parameters
seed = 1;
rand('state', seed);
for i=1:l
  bnet_k2.CPD{i} = tabular_CPD(bnet_k2, i);
end

% learn new bn with improved structure (K2)
engine3 = jtree_inf_engine(bnet_k2);
[bnet4, LL, engine4] = learn_params_em(engine3, data_train_all, 10, 0.001);
L4 = log_lik_complete(bnet4, data_test_compl);
score_bic4 = score_dags(data_test_compl, node_sizes, {bnet4.dag}, 'scoring_fn', 'bic');
score_bay4 = score_dags(data_test_compl, node_sizes, {bnet4.dag}, 'scoring_fn', 'bayesian');

fprintf(1,'Result 4 ...\n');
display(L4)
display(score_bic4)
display(score_bay4)

%% ================================================  
%   Learn parameters: 
%   Unknown structure (EM and MCMC) + uncomplete data for learning (EM)
%  ================================================  
% ----------
%  EM structural algorithm
% ----------
fprintf(1,'IIIa. Learn parameters: Unknown structure (EM algoritm) + data witth missing values for learning ...\n');

dag_empty = zeros(11,11);
bnet_new = mk_bnet(dag_empty, node_sizes, 'names', names);
seed = 1;
rand('state', seed);
for i=1:l
  bnet_new.CPD{i} = tabular_CPD(bnet_new, i);
end

[bnetEM, orderEM, BIC_score] = learn_struct_EM(bnet_new, data_train_all, 3); % only 3-4 iteration is ok

L5 = log_lik_complete(bnetEM, data_test_compl);
score_bic5 = score_dags(data_test_compl, node_sizes, {bnetEM.dag}, 'scoring_fn', 'bic');
score_bay5 = score_dags(data_test_compl, node_sizes, {bnetEM.dag}, 'scoring_fn', 'bayesian');

fprintf(1,'Result 5 ...\n');
display(L5)
display(score_bic5)
display(score_bay5)

% show_cpt = @(bnet,node) dispcpt(struct(bnet1.CPD{node}).CPT);
show_cpt(bnetEM, DL);

%% -------
%   MCMC
%  --------
% Create BN  from scratch with MCMC algorithm
fprintf(1,'IIIb. Learn parameters: Unknown structure (MCMC algorithm) + data witth missing values for learning ...\n');

dag_empty = zeros(11,11);
[sampled_graphs1, ~] = learn_struct_mcmc(data_train_compl, node_sizes, 'init_dag', dag_empty);   
score1 = score_dags(data_train_compl, node_sizes, sampled_graphs1);   
best_dag1 = find(score1 == max(score1));
best_dag_mcmc1 = sampled_graphs{1,best_dag1(1)};

% create new BN with improved structure
bnet_mcmc_new = mk_bnet(best_dag_mcmc1, node_sizes, 'names', names);
seed = 1;
rand('state', seed);
for i=1:l
  bnet_mcmc_new.CPD{i} = tabular_CPD(bnet_mcmc_new, i);
end

engine4 = jtree_inf_engine(bnet_mcmc_new);
[bnet5, LL5, engine5] = learn_params_em(engine4, data_train_all, 10, 0.001);

L6 = log_lik_complete(bnet5, data_test_compl);
score_bic6 = score_dags(data_test_compl, node_sizes, {bnet5.dag}, 'scoring_fn', 'bic');
score_bay6 = score_dags(data_test_compl, node_sizes, {bnet5.dag}, 'scoring_fn', 'bayesian');

fprintf(1,'Result 6 ...\n');
display(L6)
display(score_bic6)
display(score_bay6)

% show_cpt = @(bnet,node) dispcpt(struct(bnet1.CPD{node}).CPT);
% show_cpt(bnet5, DL);

%% ============================= 
% Experementing with changed BN3
%  =============================
% Let's experement and change improved bnet3 (it was improved by MCMC)
fprintf(1,'Experementing with BN3, editing edges...\n');

new_dag = bnet3.dag;
new_dag(2,1) = 0; % remove Weather -> Season
new_dag(1,2) = 1; % add Season -> Weather

new_dag(8,1) = 0; % remove Number of Jorneys -> Season
new_dag(1,8) = 1; % add Season -> Weather

bnet3_new = mk_bnet(new_dag, node_sizes, 'names', names);

% random parameters
seed = 1;
rand('state', seed);
for i=1:l
  bnet3_new.CPD{i} = tabular_CPD(bnet3_new, i);
end

engine_new = jtree_inf_engine(bnet3_new);
[bnet3_new1, LL1, engine_new1] = learn_params_em(engine_new, data_train_all, 10, 0.001);

fprintf(1,'Result 3* ...\n');
L3_star = log_lik_complete(bnet3_new1, data_test_compl);
score_bic3_star = score_dags(data_test_compl, node_sizes, {bnet3_new1.dag}, 'scoring_fn', 'bic');
score_bay3_star = score_dags(data_test_compl, node_sizes, {bnet3_new1.dag}, 'scoring_fn', 'bayesian');
%% ===================
%   Inference 
%  ===================
fprintf(1,'Inference and best BN...\n');

%  1''Season' (winter spring summer fall)
%  2''Weather' (bad good)
%  3''RoadConditions'(bad good)
%  4''AverageSpeed' (low high)
%  5''DangerLevel' (low high)
%  6''PoliceActivity' (regular increased)
%  7'Weekend' (working weekend holiday)
%  8''NumberJourneys' (low high)
%  9''NumberAccidents' (low medium high)
%  10'NumberFatalities' (low medium high)
%  11'Country' (US UK Europe)

evidence1 = {1;1;1;2;2;2;2;2;3;[];1} % everything is bad! 
evidence2 = {2;2;2;1;[];1;1;1;1;1;3} % everything is good
engine_best = jtree_inf_engine(bnet3_new1);

engine_best1 = enter_evidence(engine_best, evidence1);
p_m_1 = marginal_nodes(engine_best1, 10);

engine_best2 = enter_evidence(engine_best, evidence2);
p_m_2 = marginal_nodes(engine_best2, 5);


%%
bnet=bnet3_new1; 
save('bnet','bnet');
