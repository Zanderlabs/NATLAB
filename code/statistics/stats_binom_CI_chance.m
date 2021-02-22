
function [dChanceAcc, iNumCorrectTrials] = stats_binom_CI_chance ( varargin )

% Returns minimum classification accuracy under the confidence limit alpha.
% [dChanceAcc, iNumCorrectTrials] = stats_binom_CI_chance ( trials_per_class, alpha, Arguments... )
%
%  A single classification result can either be correct or incorrect. When
%  class c appears with a probabilty of p_c, the random classifier selects
%  this class with the same probabilty p_c (assumption). Thus the probabilty
%  of correctly classifying class c by chance is p_c*p_c. The total
%  probability of correct classification (i.e. the classification accuracy
%  due to chance, p0) is the sum of p_c*p_c for all c. Thus the random
%  classifier produces correct results that are binomially distributed with
%  probability p.
%
%  From the CDF of that binomial distribution, the treshold for non-random
%  classification can be determined at a given alpha-error.
%
% In:
%   trials_per_class :  Number of trials for the different classes. [1 x N] row vector of N integers
%                       where N corresponds to the number of classes (typically 2) and where every 
%                       integer reflects the number of trials for that particular class. The only 
%                       mandatory parameters of this function.
% 
%   alpha :   Significance level alpha. A scalar double precision floating point number between 0 and 1,
%             typically < 0.1, indicating the alpha level assumed for statistical significance. (default:
%             0.05).
%
%   Arguments : optional name-value pairs specifying the arguments:
%
%               'cfr_type' :  Strategy/bias of the chance classifier. Is the bias of the chance 
%                             classifier such that it outputs random labels for classes at the same
%                             rate as they occur in the data ('stratified') or instead the
%                             worst case, where the classifier is biased toward the most frequently
%                             occuring class ('most_frequent). (default: 'stratified')
%
% Out:
%   dChanceAcc :  Threshold of chance accuracy for given parameters. This accuracy threshold corresponds
%                 to the upper limit of the Wilson score based confidence interval around the level of 
%                 chance accuracy for the given parameters (number of trials per class, significance level 
%                 and bias type of assumed random classifier).
%
%   iNumCorrectTrials :   Number of minium correct classifications to achieve significantly better than
%                         chance performance. 
%
% Example:
%
%   % Calculate chance level performance for 50 trials of class 1 and 100 for class 2, for a alpha level
%   % of 0.05 and an assumed random classifier that picks classes at random in accordance with the
%   % ratio of the classes, here 1:2. 
%   [dChanceAcc, iNumCorrectTrials] = stats_binom_CI_chance ( [50 100] )
%
%   % Set alpha level explicitly.
%   [dChanceAcc, iNumCorrectTrials] = stats_binom_CI_chance ( [50 100], 0.05 )
%
%   % Assume the random classifier consistently picks the most frequently occurring class label.
%   [dChanceAcc, iNumCorrectTrials] = stats_binom_CI_chance ( [50 100], 0.05, 'cfr_type', 'most_frequent' )
% 
% Credits:
%
%   Based on code by Drs. Martin Billinger and Clemens Brunner as well as [1].
% 
% References:
%   [1] Billinger, M., Daly, I., Kaiser, V., Jin, J., Allison, B. Z., 
%       Müller-Putz, G. R., & Brunner, C. (2012). Is it significant? 
%       Guidelines for reporting BCI performance. In Towards Practical 
%       Brain-Computer Interfaces (pp. 333-354). Springer, Berlin, 
%       Heidelberg.
%

  dp;

  %% Read arguments
  opts = arg_define(1:2,varargin, ...
      ... % evaluation parameters
      arg ( { 'trials_per_class', 'TrialsPerClass' }, [], [], 'Number of trials per class. .', 'shape', 'row' ), ...
      arg ( { 'alpha', 'AlphaLevel' }, [0.05], [0 1], 'Alpha (significance) level. .'), ...
      arg ( { 'cfr_type', 'ChanceClassifierType' }, 'stratified', { 'stratified', 'most_frequent' }, 'Strategy of random classifier. .') );

  trials_per_class  = opts.trials_per_class; 
  alpha             = opts.alpha;
  cfr_type          = opts.cfr_type;

  
  %% Error, when information is not provided for at least 2 classes
  
  if ( size ( trials_per_class, 2 ) < 2 )
    error ( 'Determining chance accuracy using this implementation only possible for at least 2 classes.' );
  end

  
  %% Calculate class priors and other variables 
  
  % Total trials
  N_trials = sum ( trials_per_class );

  % Prevalence of particular classes in data set
  aClassPriors = trials_per_class ./ N_trials;

  
  %% Theoretical chancel level of the classifier
  dP_cfr = nan;

  switch ( cfr_type )
    
    % Classifier picks classes at the rate they occur in the data
    case 'stratified'
      dP_cfr = sum ( trials_per_class .* aClassPriors ./ N_trials );

    % Classifier returns
    case 'most_frequent'
      dP_cfr = max ( trials_per_class ./ N_trials );

  end    

  %% Calculate Wilson score based confidence interval 
  z = norminv ( 1 - alpha, 0, 1 );
  
  dChanceAcc = ( dP_cfr + z^2/(2*N_trials) + z*sqrt( dP_cfr*(1-dP_cfr)/N_trials + z^2/(4*N_trials^2) ) ) / ( 1 + z^2/N_trials );
  
  iNumCorrectTrials = ceil ( N_trials * dChanceAcc );

end


