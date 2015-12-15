function fig4d_psychFuncShift_Bias(lagGroups, whichmodulator, grouping)

if ~exist('lagGroups', 'var'), lagGroups = 1; end
if ~exist('whichmodulator', 'var'); whichmodulator = 'pupil'; end
if ~exist('grouping', 'var'); grouping = 'all'; end

% plot both the effect of pupil on overall repetition bias and show that
% this is symmetrical for both previous choices
% subplot(443);

switch whichmodulator
    case 'pupil'
        whichMod = 'decision_pupil';
    case 'feedbackpupil'
        whichMod = 'feedback_pupil';
    case 'fb-decpupil'
        % see below for projecting out
        whichMod = 'feedback_pupil';
    case 'rt'
        whichMod = 'rt';
end

nbins = 3;
subjects = 1:27;
clear grandavg;
whichLags = 1:3; % lag 1

for lag = whichLags,
    for sj = unique(subjects),
        data = readtable(sprintf('~/Data/pupilUncertainty/CSV/2ifc_data_sj%02d.csv', sj));
        
        % in this case, take out decision effects
        switch whichmodulator
            case 'fb-decpupil'
                data.feedback_pupil = projectout(data.feedback_pupil, data.decision_pupil);
        end
        
        % outcome vector need to be 0 1 for logistic regression
        data.resp(data.resp == -1) = 0;
        
        % get an overall logistic fit for normalization
        grandavg.overallLogistic(sj, :) = glmfit(data.motionstrength, ...
            data.resp, ...
            'binomial','link','logit');
        
        % previous response
        resps = [0 1];
        for r = 1:2,
            
            % select for response and correctness
            trls = find(data.resp == resps(r));
            
            laggedtrls = trls+lag;
            % exclude trials at the end of the block
            if any(laggedtrls > size(data, 1)),
                trls(laggedtrls > size(data, 1)) = [];
                laggedtrls(laggedtrls > size(data, 1)) = [];
            end
            
            % remove trials that dont match in block nr
            removeTrls = data.blocknr(laggedtrls) ~= data.blocknr(trls);
            laggedtrls(removeTrls) = [];
            trls(removeTrls) = [];
            
            % fit logistic regression
            thisdat = data(laggedtrls, :);
            
            % get an overall logistic fit
            grandavg.respBiasNoPupilSplit(sj, r, lag, :) = glmfit(thisdat.motionstrength, thisdat.resp, ...
                'binomial','link','logit');
            
            %% split into pupil bins
            if nbins > 2,
                uncQs = quantile(data.(whichMod)(data.resp == resps(r)), nbins - 1);
            elseif nbins == 2,
                uncQs = median(data.(whichMod)(data.resp == resps(r)));
            end
            
            % uncertainty bins
            for u = 1:nbins,
                
                switch u
                    case 1
                        trls = find(data.resp == resps(r) & data.(whichMod) < uncQs(u));
                    case nbins
                        trls = find(data.resp == resps(r) & data.(whichMod) > uncQs(u-1));
                    otherwise
                        trls = find(data.resp == resps(r) & ...
                            data.(whichMod) > uncQs(u-1) & data.(whichMod) < uncQs(u));
                end
                
                % with this selection, take the trials after that
                laggedtrls = trls+lag;
                % exclude trials at the end of the block
                if any(laggedtrls > size(data, 1)),
                    trls(laggedtrls > size(data, 1)) = [];
                    laggedtrls(laggedtrls > size(data, 1)) = [];
                end
                
                % remove trials that dont match in block nr
                removeTrls = data.blocknr(laggedtrls) ~= data.blocknr(trls);
                laggedtrls(removeTrls) = [];
                trls(removeTrls) = [];
                
                % fit logistic regression
                thisdat = data(laggedtrls, :);
                
                [b, dev, stats] = glmfit(thisdat.motionstrength, thisdat.resp, ...
                    'binomial','link','logit');
                
                % save betas
                grandavg.logistic(sj, r, u, lag, :) = b;
                
            end % uncertainty bin
        end % resp
    end % sj
end

% ========================================================= %
% normalize by their overall bias
% ========================================================= %

grandavg.logistic = bsxfun(@minus, grandavg.logistic, grandavg.overallLogistic(:, 1));
grandavg.respBiasNoPupilSplit = bsxfun(@minus, grandavg.respBiasNoPupilSplit, grandavg.overallLogistic(:, 1));

% ========================================================= %
% make one plot with repetition (rather than response) bias
% ========================================================= %

resp1 = squeeze(grandavg.logistic(:, 1, :, :, 1));
resp2 = squeeze(grandavg.logistic(:, 2, :, :, 1));

grandavg.logisticRep = (-resp1 + resp2) ./ 2;

resp1 = squeeze(grandavg.respBiasNoPupilSplit(:, 1, :, 1));
resp2 = squeeze(grandavg.respBiasNoPupilSplit(:, 2, :, 1));

grandavg.repetitionBias = (-resp1 + resp2) ./ 2;

% ========================================================= %
% combine the lag groups
% ========================================================= %

grandavg.logisticRep = squeeze(nanmean(grandavg.logisticRep(:, :, lagGroups), 3));
grandavg.logistic = squeeze(nanmean(grandavg.logistic(:, :, :, lagGroups, :), 4));
grandavg.respBiasNoPupilSplit = squeeze(nanmean(grandavg.respBiasNoPupilSplit(:, :, lagGroups, 1), 3));
grandavg.repetitionBias  = squeeze(nanmean(grandavg.repetitionBias(:, lagGroups), 2));

% ========================================================= %
% plot
% ========================================================= %

colors = linspecer(9);
% split subjects based on their plain history weights
load(sprintf('~/Data/pupilUncertainty/GrandAverage/historyweights_%s.mat', 'plain'));

hold on;

switch grouping
    
    case 'all'
        theseSj = 1:27;
        thiscolor = colors(2, :);
    case 'repeat'
        theseSj = find(dat.response(:, 1) > 0);
        thiscolor = colors(8, :);
    case 'switch'
        theseSj = find(dat.response(:, 1) < 0);
        thiscolor = colors(9, :);
end

stimx2 = 1:u;
errorbar(stimx2, ...
    nanmean(grandavg.logisticRep(theseSj, :)), ...
    nanstd(grandavg.logisticRep(theseSj, :)) ./ sqrt(length(theseSj)), ...
    'o-', 'color', thiscolor, 'markerfacecolor', thiscolor, 'markersize', 4);

errorbar(nbins+1, nanmean(grandavg.repetitionBias(theseSj)), ...
    nanstd(grandavg.repetitionBias(theseSj)) ./ sqrt(length(theseSj)), 'o-', 'color', ...
    thiscolor, 'markerfacecolor', thiscolor, 'markersize', 4);

% repeated measures anova on those bins
cnt = 0; clear x s f
for sj = 1:length(theseSj),
    for u = 1:nbins,
        cnt = cnt + 1;
        x(cnt) = grandavg.logisticRep(theseSj(sj), u);
        s(cnt) = sj;
        f{1}(cnt) = u; % factor of previous uncertainty
    end
end
clear stats
stats = rm_anova(x, s, f);
% axis square;
axis tight;

% low vs high
[~, pval(1)] = ttest(grandavg.logisticRep(theseSj, 1), grandavg.logisticRep(theseSj, 3));
ymax = max( nanmean(grandavg.logisticRep(theseSj, :)) + ...
   2* nanstd(grandavg.logisticRep(theseSj, :)) ./ sqrt(length(theseSj)));
mysigstar([1 3], [ymax ymax], pval(1));

% medium vs high
[~, pval(2)] = ttest(grandavg.logisticRep(theseSj, 2), grandavg.logisticRep(theseSj, 3));
ymax = max( nanmean(grandavg.logisticRep(theseSj, [2:3])) + ...
   1.5* nanstd(grandavg.logisticRep(theseSj, [2:3])) ./ sqrt(length(theseSj)));
mysigstar([2 3], [ymax ymax], pval(2));

% only test for a repetition bias when we haven't split the subjects
switch grouping
    case 'all'
        [~, pval(3)] = ttest(grandavg.repetitionBias(theseSj));
        max( nanmean(grandavg.repetitionBias(theseSj)) + ...
            nanstd(grandavg.repetitionBias(theseSj)) ./ sqrt(length(theseSj)));
        mysigstar(nbins+1, ymax, pval(3));
end

switch whichMod,
    case 'baseline_pupil';
        xlabel(sprintf('Baseline pupil', 0));
    case 'decision_pupil'
        xlabel(sprintf('Pupil response'));
    case 'rt'
        xlabel(sprintf('Reaction time'));
    case 'feedback_pupil',
        xlabel('Feedback pupil');
        
        switch whichmodulator
            case 'fb-decpupil'
                xlabel('Feedback-dec pupil');
        end
    otherwise
        %  xlabel(sprintf('%s_{t-%d}', whichModTitle, whichLag));
end
ylabel('Next trial repetition');

xlim([0.5 nbins+1.5]); set(gca, 'xtick', 1:nbins+1, ...
    'xticklabel', {'low', 'med', 'high', 'all'}, 'xticklabelrotation', 0);
box off;

ylims = get(gca, 'ylim');
set(gca, 'ylim', [ylims(1) - 0.2*range(ylims) ylims(2)+0.2*range(ylims)]);

end
