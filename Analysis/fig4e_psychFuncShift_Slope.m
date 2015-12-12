function fig4e_psychFuncShift_Slope(lagGroups, whichmodulator)
% plot both the effect of pupil on overall repetition bias and show that
% this is symmetrical for both previous choices

if ~exist('lagGroups', 'var'), lagGroups = 1; end
subplot(449);

switch whichmodulator
    case 'pupil'
        whichMod = 'decision_pupil';
    case 'rt'
        whichMod = 'rt';
end

nbins = 3;
subjects = 1:27;
whichLags = 1:3; % lag 1

for lag = whichLags,
    for sj = unique(subjects),
        data = readtable(sprintf('~/Data/pupilUncertainty/CSV/2ifc_data_sj%02d.csv', sj));
        
        
        % outcome vector need to be 0 1 for logistic regression
        data.resp(data.resp == -1) = 0;
        
        % get an overall logistic fit
        grandavg.overallLogistic(sj, :) = glmfit(data.motionstrength, data.resp, ...
            'binomial','link','logit');
        
        % previous response
        if nbins > 2,
            uncQs = quantile(data.(whichMod), nbins - 1);
        elseif nbins == 2,
            uncQs = median(data.(whichMod));
        end
        
        % uncertainty bins
        for u = 1:nbins,
            
            switch u
                case 1
                    trls = find(data.(whichMod) < uncQs(u));
                case nbins
                    trls = find(data.(whichMod) > uncQs(u-1));
                otherwise
                    trls = find(data.(whichMod) > uncQs(u-1) & data.(whichMod) < uncQs(u));
            end
            
            % only use correct trials!
            % trls = intersect(trls, find(data.correct == 1));
            
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
            
            [b] = glmfit(thisdat.motionstrength, thisdat.resp, ...
                'binomial','link','logit');
            
            % save betas
            grandavg.logistic(sj, u, lag, :) = b;
            
        end % uncertainty bin
    end % sj
end

% ========================================================= %
% normalize by their overall slope
% ========================================================= %

% grandavg.logistic = bsxfun(@minus, grandavg.logistic, grandavg.overallLogistic(:, 2));

% ========================================================= %
% combine the lag groups
% ========================================================= %

grandavg.logisticSlope = squeeze(mean(grandavg.logistic(:, :, lagGroups, 2), 3));
colors = linspecer(9);

load(sprintf('~/Data/pupilUncertainty/GrandAverage/historyweights_%s.mat', 'pupil'));
posRespSj = find(mean(dat.response(:, lagGroups), 2) > 0);
negRespSj = find(mean(dat.response(:, lagGroups), 2) < 0);

stimx2 = 1:u;
hold on;
errorbar(stimx2, ...
    nanmean(grandavg.logisticSlope(posRespSj, :)), ...
    nanstd(grandavg.logisticSlope(posRespSj, :)) ./ sqrt(length(posRespSj)), ...
    'o-', 'color', colors(8, :), 'markeredgecolor', 'w', 'markerfacecolor', colors(8, :));
errorbar(stimx2, ...
    nanmean(grandavg.logisticSlope(negRespSj, :)), ...
    nanstd(grandavg.logisticSlope(negRespSj, :)) ./ sqrt(length(negRespSj)), ...
    'o-', 'color', colors(9, :), 'markeredgecolor', 'w', 'markerfacecolor', colors(9, :));

axis square; axis tight;
xlim([0.5 nbins+1.5]); set(gca, 'xtick', 1:4, ...
    'xticklabel', {'low', 'med', 'high', 'all'}, 'xticklabelrotation', 0);
box off;

switch whichMod,
    case 'baseline_pupil';
        xlabel(sprintf('Baseline pupil'));
    case 'decision_pupil'
        xlabel(sprintf('Pupil response'));
    case 'rt'
        xlabel(sprintf('Reaction time'));
        
    otherwise
        xlabel(sprintf('%s_{t-%d}', whichModTitle, whichLag));
end
ylabel({'Next trial slope'});

axis tight;
axis square;
xlim([0.5 3.5]); set(gca, 'xtick', 1:3, 'xticklabel', {'low', 'med', 'high'});
box off;

% repeated measures anova on those bins
cnt = 0; clear x s f
for sj = 1:27,
    for u = 1:3,
        cnt = cnt + 1;
        x(cnt) = grandavg.logisticSlope(sj, u);
        s(cnt) = sj;
        f{1}(cnt) = u; % factor of previous uncertainty
    end
end
clear stats
stats = rm_anova(x, s, f);

% also test for the 2 pairwise comparisons
[~, pval(1)] = ttest(grandavg.logisticSlope(:, 1), grandavg.logisticSlope(:, 2));
[~, pval(2)] = ttest(grandavg.logisticSlope(:, 2), grandavg.logisticSlope(:, 3));

sigstar2({[1 3]}, [stats.f1.pvalue]);
ylim([1.1 1.53]);

print(gcf, '-dpdf', sprintf('~/Dropbox/Figures/uncertainty/fig4d_psychFuncShift_slope.pdf'));

end
