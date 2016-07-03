function [b] = PsychFuncs_byUncertainty(field)

global mypath;
nbins = 6;

% can try this also with all subjects
subjects        = 1:27;
grandavg.ev     = nan(length(subjects), 2, nbins);
grandavg.acc    = nan(length(subjects), 2, nbins);

for sj = subjects,
    
    data = readtable(sprintf('%s/Data/CSV/2ifc_data_sj%02d.csv', mypath, sj));
    
    % split by low and high RT
    rtMed = quantile(data.(field), 2);
    
    for r = 1:2,
        switch r
            case 1
                trls = find(data.(field) < rtMed(1));
            case 2
                trls = find(data.(field) > rtMed(2));
        end
        [grandavg.ev(sj, r, :), grandavg.acc(sj, r, :)] = ...
            divideintobins(abs(data.motionstrength(trls)), data.correct(trls), nbins);
        
    end
    
    % project RT out of the pupil and vice versa
    switch field
        case 'rt'
            data.(field) = projectout(zscore(log(data.(field) + 0.1)), zscore(data.decision_pupil));
        case 'decision_pupil'
            data.(field) = projectout(data.(field), zscore(log(data.rt + 0.1)));
    end
    
    % split by low and high RT
    rtMed = quantile(data.(field), 2);
    
    for r = 1:2,
        switch r
            case 1
                trls = find(data.(field) < rtMed(1));
            case 2
                trls = find(data.(field) > rtMed(2));
        end
        
        % fit cumulative weibull to this psychfunc
        data.intensity = data.motionstrength;
        pBest = fminsearchbnd(@(p) cumWB_LL(p, ...
            abs(data.motionstrength(trls)), data.correct(trls)), ...
            [1 3 0.1], [0 0 0], [3 6 1]);
        grandavg.b(sj, r, :) = pBest;
        
    end
end

colors(1,:) = [0.5 0.5 0.5];
colors(2,:) = [0.2 0.2 0.2];

% PLOT
hold on;
for r = 1:2,
    
    % show the mean curve for the Weibull fit
    newx = linspace(0.1, 5.5, 100);
    plot(newx,  100* Weibull(squeeze(nanmean(grandavg.b(:, r, :))), newx), 'color', colors(r, :)) ;
    
    % datapoints on top
    h = ploterr( squeeze(nanmean(grandavg.ev(:, r, :))), squeeze(100* nanmean(grandavg.acc(:, r, :))), ...
        squeeze( nanstd(grandavg.ev(:, r, :))) ./ sqrt(length(subjects)), ...
        100 * squeeze(nanstd(grandavg.acc(:, r, :))) ./ sqrt(length(subjects)), ...
        '.', 'abshhxy', 0);
    set(h(1), 'color', colors(r,:), 'marker', '.', 'markersize', 12);
    set(h(2), 'color', colors(r,:));
    set(h(3), 'color', colors(r,:));
    handles{r} = h(1);
end

set(gca, 'xlim', [-0.5 5.5], 'ylim', [45 100], 'ytick', 50:25:100);
xlim([-0.5 5.5]); set(gca, 'xtick', [0 2.75 5.5], 'xticklabel', {'weak', 'medium', 'strong'}, 'xminortick', 'off');
ylabel('Accuracy (%)'); xlabel('Evidence');
axis square; box off;

switch field
    case 'rt'
        l = legend([handles{:}], {'fast', 'slow'}, 'location', 'southeast');
        legend boxoff;
    case 'decision_pupil'
        l = legend([handles{:}], {'low', 'high'}, 'location', 'southeast');
        legend boxoff;
end
lpos = get(l, 'position');
lpos(1) = lpos(1) + 0.05;
set(l, 'position', lpos);

b = grandavg.b(:, :, 2);

end

% see http://courses.washington.edu/matlab1/Lesson_5.html#1
function err = cumWB_LL(p, intensity, responses)

% compute the vector of responses for each level of intensity
w = Weibull(p, intensity);

% negative loglikelihood, to be minimised
err = -sum(responses .*log(w) + (1-responses).*log(1-w));
end

function y = Weibull(p, x)
% Parameters:  p(1) slope
%             p(2) threshold yeilding ~80% correct
%             p(3) lapse rate
%             x   intensity values.

g = 0.5;  %chance performance

% include a lapse rate, see Wichmann and Hill parameterisation
y = g + (1 - g - p(3)) * (1-exp(- (x/p(2)).^p(1)));

end