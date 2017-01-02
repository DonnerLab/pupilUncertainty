function grandavg = postPupilBehaviour(whichmodulator, nbins, correctness)
% This code reproduces the analyses in the paper
% Urai AE, Braun A, Donner THD (2016) Pupil-linked arousal is driven
% by decision uncertainty and alters serial choice bias.
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"),
% to deal in the Software without restriction, including without limitation
% the rights to use, copy, modify, merge, publish, distribute, sublicense,
% and/or sell copies of the Software, and to permit persons to whom the
% Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
% If you use the Software for your own research, cite the paper.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.
%
% Anne Urai, 2016
% anne.urai@gmail.com

global mypath;

if ~exist('whichmodulator', 'var');     whichmodulator = 'pupil';   end
if ~exist('correctness', 'var');        correctness = [];           end
if ~exist('nbins', 'var');              nbins = 3;                  end
lag = 1; % look at 1 trial in the past

% =========================================== %

subjects = 1:27;

% get data
alldata = readtable(sprintf('%s/Data/CSV/2ifc_data_allsj.csv', mypath));
if ~isempty(strfind(whichmodulator, 'latenc')),
    alldata = readtable(sprintf('%s/Data/CSV/2ifc_data_allsj_withlatencies.csv', mypath));
end

% loop over subjects
for sj = unique(subjects),
    
    % individual sj data, get rid of residual learning effects
    data = alldata((alldata.subjnr == sj & alldata.sessionnr > 1), :);
    
    % =========================================== %
    % session-specific threshold
    % =========================================== %
    
    [slope, threshold, lapse] = fitWeibull( ...
        abs(data.coherence), data.correct);
    
    % read out the 70% correct threshold instead of 80%
    newx    = linspace(0, 0.4, 100);
    curve   = weibull([slope threshold lapse], newx);
    thisthreshold = newx(dsearchn(curve', 0.7));
    data.thisthreshold = thisthreshold * ones(size(data.correct));
    
    % =========================================== %
    % prepare data to bin by
    % =========================================== %
    
    switch whichmodulator
        case 'fbpupil'
            whichMod = 'feedback_pupil';
        case 'fb+decpupil'
            whichMod = 'feedback_pupil';
            data.feedback_pupil = projectout(data.feedback_pupil, data.decision_pupil);
        case 'dec+fbpupil'
            whichMod = 'decision_pupil';
            data.decision_pupil = projectout(data.decision_pupil, data.feedback_pupil);
        case 'pupil',
            whichMod = 'decision_pupil';
            if isempty(correctness),
                data.decision_pupil = projectout(data.decision_pupil, data.rtNorm); % take out RT
            end
        case 'rt'
            whichMod = 'rtNorm'; % t
            data.rtNorm = projectout(data.rtNorm, data.decision_pupil);
        case 'evidence'
            % single-trial evidence strength is absolute motionenergy
            data.evidence = abs(data.motionstrength);
            % make sure to use the same range of evidence for each session
            for session = unique(data.sessionnr)',
                data.evidence(data.sessionnr == session) = ...
                    zscore(data.evidence(data.sessionnr == session));
            end
        case 'rt_withlatencies'
            whichMod = 'rtNorm';
            data.rtNorm = projectout(data.rtNorm, data.latency_total);
        case 'baseline_pupil';
            whichMod = 'baseline_pupil';
            data.baseline_pupil = circshift(data.baseline_pupil, -1);
        otherwise
            whichMod = whichmodulator;
    end
    
    % outcome vector need to be 0 1 for logistic regression
    data.resp(data.resp == -1) = 0;
    
    % get an overall logistic fit for normalization
    [bias, slope, lapseLow, lapseHigh] = fitLogistic(data.motionstrength, data.resp);
    grandavg.overallLogistic(sj, :) = [bias slope];
    
    % split into quantiles of the modulator
    if isempty(correctness),
        uncQs = quantile(data.(whichMod), nbins - 1);
    else
        uncQs = quantile(data.(whichMod)(data.correct == correctness), nbins - 1);
    end
    
    % for two bins, quantile doesn't work so take the median
    if nbins == 2,
        if isempty(correctness),
            uncQs = median(data.(whichMod));
        else
            uncQs = median(data.(whichMod)(data.correct == correctness));
        end
    end
    
    % =========================================== %
    % loop over bins
    % =========================================== %
    
    for u = 1:nbins,
        
        % find the trials in this bin
        if isempty(correctness), % take all trials
            switch u
                case 1
                    trls = find(data.(whichMod) <= uncQs(u));
                case nbins % last one
                    trls = find(data.(whichMod) > uncQs(u-1));
                otherwise
                    trls = find(data.(whichMod) > uncQs(u-1) & data.(whichMod) <= uncQs(u));
            end
            
        else % either correct or error trials
            switch u
                case 1
                    trls = find(data.correct == correctness & data.(whichMod) <= uncQs(u));
                case nbins % last one
                    trls = find(data.correct == correctness & data.(whichMod) > uncQs(u-1));
                otherwise
                    trls = find(data.correct == correctness & ...
                        data.(whichMod) > uncQs(u-1) & data.(whichMod) <= uncQs(u));
            end
        end
        
        % with this selection, take the trials after that
        laggedtrls = trls+lag;
        
        % exclude trial at the end of the dataset
        if any(laggedtrls > size(data, 1)),
            trls(laggedtrls > size(data, 1)) = [];
            laggedtrls(laggedtrls > size(data, 1)) = [];
        end
        
        % remove trials that dont match in block nr
        laggedtrls(data.blocknr(laggedtrls) ~= data.blocknr(trls)) = [];
        
        % use these data
        thisdat = data(laggedtrls, :);
        
        % =========================================== %
        % logistic for slope
        % =========================================== %
        
        [bias, slope, lapse] = fitLogistic(thisdat.motionstrength,thisdat.resp);
        grandavg.logistic(sj, u, :) = [bias slope lapse];
        
        % =========================================== %
        % overall RT and accuracy
        % =========================================== %
        
        grandavg.RT(sj, u)       = nanmedian(thisdat.rt);
        grandavg.accuracy(sj, u) = nanmean(thisdat.correct);
        
        % only for difficult trials, use coherences of 2.5 and 5%
        grandavg.accuracyHard(sj, u) = ...
            nanmean(thisdat.correct(thisdat.coherence < thisdat.thisthreshold));
        
        % =========================================== %
        % threshold parameter from cumulative Weibull fit
        % =========================================== %
        
        [slope, threshold, lapse] = fitWeibull(abs(thisdat.motionstrength), thisdat.correct);
        grandavg.weibull(sj, u)   = threshold; % only keep this
        
        % =========================================== %
        % Post-error slowing, Dutilh et al. 2012
        % =========================================== %
        
        errortrls = intersect(trls, find(data.correct == 0));
        
        % remove trls that are not in a continuous sequence
        errortrls(errortrls > size(data, 1)) = [];
        errortrls(errortrls < 2) = [];
        errortrls((data.trialnr(errortrls) - data.trialnr(errortrls - 1)) ~= 1) = [];
        errortrls((data.trialnr(errortrls) - data.trialnr(errortrls + 1)) ~= -1) = [];
        
        % use only those trials where both the pre-error and the
        % post-error are correct
        errortrls(data.correct(errortrls-1) == 0) = [];
        errortrls(data.correct(errortrls+1) == 0) = [];
        
        % for the matched analysis, only compare pre- and post-error trials
        % with the same level of evidence
        errortrls_matched = errortrls(find(data.coherence(errortrls - 1) == data.coherence(errortrls + 1)));
        
        % see very clear image of this analysis http://www.ncbi.nlm.nih.gov/pmc/articles/PMC4807057/figure/pone.0151763.g001/
        grandavg.pesMatched(sj, u) =  median(data.rt(errortrls_matched + 1) - data.rt(errortrls_matched - 1));
        
        % also regress out the evidence strength
        data.rt                         = projectout(data.rt, zscore(abs(data.motionstrength)));
        grandavg.pesRegressedout(sj, u) = median(data.rt(errortrls + 1) - data.rt(errortrls - 1));
        
        % =========================================== %
        % history-dependent logistic
        % =========================================== %
        
        % previous response
        resps = [0 1];
        for r = 1:2,
            
            % take a further subset of trials with previous response 1 or 0
            laggedresptrls  = find(data.resp == resps(r));
            laggedresptrls  = laggedresptrls + 1; % go one trial later
            laggedresptrls  = intersect(laggedtrls, laggedresptrls);
            thisdat         = data(laggedresptrls, :);
            
            [bias, slope, lapseLow, lapseHigh] = fitLogistic(...
                thisdat.motionstrength, thisdat.resp);
            
            % save betas
            grandavg.logisticHistory(sj, r, u, :) = [bias slope];
        end
        
    end % uncertainty bin
end % sj

% ========================================================= %
% transform history-dependent bias into repetition bias
% ========================================================= %

resp1 = -1 * squeeze(grandavg.logisticHistory(:, 1, :, 1)); % take the 1st beta weigth only, ignore history-dependent slope
resp2 =      squeeze(grandavg.logisticHistory(:, 2, :, 1));

% since this is centred at 0.5, treat it that way
grandavg.repetition = (resp1 + resp2) ./ 2;

% ========================================================= %
% transform from log(odds) to probability
% ========================================================= %

logOdds2Probability = @(x) exp(x) ./ (1 + exp(x));
grandavg.repetition = logOdds2Probability(grandavg.repetition);

% also for saying 1 over 2 - get rid of the slope
grandavg.logisticHistory = logOdds2Probability(grandavg.logisticHistory(:, :, :, 1));

% ========================================================= %
% pull out sensitivity and absolute side bias
% ========================================================= %

grandavg.sensitivity    = grandavg.logistic(:, :, 2);
grandavg.signedBias     = grandavg.logistic(:, :, 1);
grandavg.absoluteBias   = abs(grandavg.logistic(:, :, 1));
grandavg.lapse          = grandavg.logistic(:, :, 3);

end
