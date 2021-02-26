
%% --- Tests of commonly used approaches in NATLAB ---

iTestCase = 0;


%% --- CASE 1: FBCSP + LDA ---

% load the data set (BCI2000 format)
traindata = io_loadset('bcilab:/userdata/tutorial/imag_movements1/calib/DanielS001R01.dat','channels',1:29);

iTestCase = iTestCase + 1; sDesc = 'Standard FBCSP; stratify class balances; Rob. LDA';
fprintf ( '\n------------------------------------------------------------------' );
fprintf ( '\n Starting TEST-CASE [%d]: %s', iTestCase, sDesc );
fprintf ( '\n------------------------------------------------------------------\n\n' );


% define the approach (here: FBCSP)
myapproach = {  'FBCSP', 'flt',  { 'EpochExtraction', [0.5 3] }, ...
                'pred', { 'fex', { 'FreqWindows', [1 4; 4 8; 8 15; 15 24; 24 30; 30 40] }, ...
                          'ml',  { 'Learner', { 'lda', 'Robust', true, 'weight_bias', 1, 'weight_cov', 1 }  } } };
                        

% learn a predictive model
[trainloss,lastmodel,laststats] = bci_train ( 'Data', traindata, 'Approach', myapproach, ...
                                              'TargetMarkers', {'StimulusCode_2','StimulusCode_3'}, ...
                                              'EvaluationScheme', [2 2], 'OptimizationScheme', [2 2], ...
                                              'stratify', true ); 


[~, ~, teststats] = bci_predict ( lastmodel, traindata, 'EvaluationMetric', 'auc' );

if ( trainloss < 0.2 && isfield(laststats,'chance_wilson_strat_p05') && ...
      ( laststats.chance_wilson_strat_p05 > 0.5 ) && ( laststats.chance_wilson_strat_p05 < 0.6 ) && ...
      (teststats.auc*-1)>0.95 )

  fprintf ( '\n------------------------------------------------------------------' );
  fprintf ( '\n SUCCESS on TEST-CASE [%d]: %s', iTestCase, sDesc );
  fprintf ( '\n------------------------------------------------------------------\n\n' );

else
  
  fprintf ( 2, '\n------------------------------------------------------------------ ' );
  fprintf ( 2, '\n FAILED TEST-CASE [%d]: %s ', iTestCase, sDesc );
  fprintf ( 2, '\n------------------------------------------------------------------ \n\n' );
  
end



%% --- CASE 2: Robust FBCSP + Log. Reg. ---

% load the data set (BCI2000 format)
traindata = io_loadset('bcilab:/userdata/tutorial/imag_movements1/calib/DanielS001R01.dat','channels',1:29);

iTestCase = iTestCase + 1; sDesc = 'FBCSP shrink./rob.; Log.reg.; Predict; Onl. sim.; Onl.';
fprintf ( '\n------------------------------------------------------------------' );
fprintf ( '\n Starting TEST-CASE [%d]: %s', iTestCase, sDesc );
fprintf ( '\n------------------------------------------------------------------\n\n' );

              
myapproach = { 'FBCSP', 'flt',  { 'EpochExtraction', [0.5  3] }, ...
             'pred', { 'fex', { 'FreqWindows', [1 4; 4 8; 8 15; 15 24; 24 30; 30 40], ...
                                'shrinkage_cov', true, 'robust_cov', true }, ...
                       'ml', {  'Learner', {'logreg' 'Variant', {'lars' 'ElasticMixing', 0.5 } } } } };
              

% learn a predictive model
[trainloss,lastmodel,laststats] = bci_train ( 'Data', traindata, 'Approach', myapproach, ...
                                              'TargetMarkers', {'StimulusCode_2','StimulusCode_3'}, ...
                                              'EvaluationScheme', [2 3], 'OptimizationScheme', [2 3], ...
                                              'stratify', false ); 

[~, ~, teststats] = bci_predict ( lastmodel, traindata, 'EvaluationMetric', 'auc' );

[predictions,latencies] = onl_simulate ( traindata, lastmodel, 'markers', {'StimulusCode_2','StimulusCode_3'}, 'offset',3 );


% play it back in real time
run_readdataset('Dataset',traindata);

% process data in real time using lastmodel, and visualize outputs
run_writevisualization('Model',lastmodel, 'VisFunction','bar(y);ylim([0 1])');

pause ( 10 ); onl_clear; close(gcf);

 
if ( trainloss < 0.2 && isfield(laststats,'chance_wilson_strat_p05') && ...
      ( laststats.chance_wilson_strat_p05 > 0.5 ) && ( laststats.chance_wilson_strat_p05 < 0.6 ) && ...
      (teststats.auc*-1)>0.95 && ( size ( predictions, 1 ) == 128 ) )

  fprintf ( '\n------------------------------------------------------------------' );
  fprintf ( '\n SUCCESS on TEST-CASE [%d]: %s', iTestCase, sDesc );
  fprintf ( '\n------------------------------------------------------------------\n\n' );

else
  
  fprintf ( 2, '\n------------------------------------------------------------------ ' );
  fprintf ( 2, '\n FAILED TEST-CASE [%d]: %s ', iTestCase, sDesc );
  fprintf ( 2, '\n------------------------------------------------------------------ \n\n' );
  
end




%% --- CASE 3: WM ---

mrks = {{'S101','S102'},{'S201','S202'}};

% define ERP windows of interest; here, 7 consecutive windows of 50ms length each are being
% specified, starting from 250ms after the subject response
wnds = [0.25 0.3;0.3 0.35;0.35 0.4; 0.4 0.45;0.45 0.5;0.5 0.55;0.55 0.6];

% define load training data (BrainVision format); 
% MAKE SURE THE Brain Vision Loading plugin is installed in EEGLAB
traindata = io_loadset('bcilab:/userdata/tutorial/flanker_task/12-08-001_ERN.vhdr');

iTestCase = iTestCase + 1; sDesc = 'WM; Predict; Onl. sim.; Onl.';
fprintf ( '\n------------------------------------------------------------------' );
fprintf ( '\n Starting TEST-CASE [%d]: %s', iTestCase, sDesc );
fprintf ( '\n------------------------------------------------------------------\n\n' );

% define approach
myapproach = {  'Windowmeans' 'SignalProcessing', {'Resampling','off','EpochExtraction',[-0.2 0.8], ...
                'SpectralSelection',[0.1 15]}, 'Prediction',{'FeatureExtraction',{'TimeWindows',wnds}}};

%learn model 
[trainloss,lastmodel,laststats] = bci_train(  'Data',traindata,'Approach',myapproach,'TargetMarkers',mrks, ...
                                              'EvaluationScheme', [2 3], 'OptimizationScheme', [2 3], ...
                                              'stratify', true );
              
[~, ~, teststats] = bci_predict ( lastmodel, traindata, 'EvaluationMetric', 'auc' );


[predictions,latencies] = onl_simulate('Data',traindata,'Model',lastmodel,'UpdateRate',10,'TargetMarkers',{'S101','S102','S201','S202'});


% play it back in real time
run_readdataset('Dataset',traindata);

% process it in real time using lastmodel, and visualize outputs
run_writevisualization('Model',lastmodel, 'VisFunction','bar(y);ylim([0 1])');


pause ( 10 ); onl_clear; close(gcf);

 
if ( trainloss < 0.2 && isfield(laststats,'chance_wilson_strat_p05') && ...
      ( laststats.chance_wilson_strat_p05 > 0.7 ) && ( laststats.chance_wilson_strat_p05 < 0.8 ) && ...
      (teststats.auc*-1)>0.95 && ( size ( predictions, 1 ) == 408 ) )

  fprintf ( '\n------------------------------------------------------------------' );
  fprintf ( '\n SUCCESS on TEST-CASE [%d]: %s', iTestCase, sDesc );
  fprintf ( '\n------------------------------------------------------------------\n\n' );

else
  
  fprintf ( 2, '\n------------------------------------------------------------------ ' );
  fprintf ( 2, '\n FAILED TEST-CASE [%d]: %s ', iTestCase, sDesc );
  fprintf ( 2, '\n------------------------------------------------------------------ \n\n' );
  
end







