function [] = fig1ab_Model
% generate figures to show the uncertainty model from Kepecs et al. 2008
%
% Anne Urai, 2015

figpath = '~/Dropbox/Figures/uncertainty';

%%
clf;
% use nice shades of red and green
cols = linspecer(3); cols = cols(2:3, :);

% ==================================================================
% 1. decision variable
% ==================================================================

gr1 = [0.2 0.2 0.2];
gr2 = [0.6 0.6 0.6];

subplot(441);
stim = -0.6:0.001:0.6;
s1 = normpdf(stim, -.2, 0.1);
s2 = normpdf(stim,  .2, 0.1);
s3 = normpdf(stim, -.05, 0.1);
s4 = normpdf(stim,  .05, 0.1);
p = plot(stim, s1, stim, s2, stim, s3, stim, s4, zeros(1, 2), [0 4.5], 'k');
p(1).Color = gr1; p(2).Color = gr1;
p(3).Color = gr2; p(4).Color = gr2;

hold on;
plot(0.3, s2(dsearchn(stim', 0.3)), '.', ...
    'MarkerFaceColor', gr1, 'MarkerEdgeColor', gr1, 'MarkerSize', 10);
plot([0.3 0.3], [0 s2(dsearchn(stim', 0.3))], 'color', gr1, 'linestyle', ':');

axis tight; ylim([0 5]);
ylabel('Probability density'); xlabel('Decision variable (DV)');
text(-.4, 4.4, 'Stimulus A');
text(.15, 4.4, 'Stimulus B');

% add legend
l = legend([p(3), p(1)], {'weak', 'strong'});
lpos = l.Position;
lpos(1) = lpos(1) + 0.12; % right
lpos(2) = lpos(2) - 0.05; % down
l.Position = lpos;
l.Box = 'off';
text(0.75, 3, 'Intensity');

offsetAxes(gca, 0.1, 1);
set(gca, 'xtick', [0 0.3], 'xticklabel', {'b', 'dv_i'}, ...
    'box', 'off', 'tickdir', 'out', 'ytick', [], 'yticklabel', []);

% ==================================================================
% 2. choice
% ==================================================================

subplot(443);
s1 = sign(stim); s1(s1==0) = 1;
p = plot(stim, s1, zeros(1, 2), [-2 2], 'k');
p(1).Color = [0.6 0.6 0.6];
axis tight; xlabel('Decision variable');
ylim([-2 2.5]);
offsetAxes

set(gca, 'xtick', [0], 'xticklabel', {'b'}, ...
    'box', 'off', 'tickdir', 'out', 'ycolor', 'w');

text(-.4, -1.3, 's2 < s1');
text(.05, -1.1, '-1');
text(.2, 1.3, 's2 > s1');
text(-.15, 1.1, '+1');
title('Choice');

% ==================================================================
% single-trial confidence
% ==================================================================

subplot(444);
stim = -0.6:0.01:0.6;
s1 = normpdf(stim, -.15, 0.1);
s2 = normpdf(stim,  .15, 0.1);
clear p; p = plot(stim, s1, stim, s2, zeros(1, 2), [0 4.5], 'k');
p(1).Color = gr2; p(2).Color = gr2;
hold on;

% error
plot([0.1 0], [s1(dsearchn(stim', 0.1)) s1(dsearchn(stim', 0.1))], 'color', cols(1,:));
plot(0.1, s1(dsearchn(stim', 0.1)), 's', ...
    'MarkerFaceColor',  cols(1,:), 'MarkerEdgeColor', cols(1,:), 'MarkerSize', 3);
plot([-.05 0], [s2(dsearchn(stim', -.05)) s2(dsearchn(stim', -.05))], 'color', cols(1,:));
plot(-.05, s2(dsearchn(stim', -.05)), 's', ...
    'MarkerFaceColor',  cols(1,:), 'MarkerEdgeColor', cols(1,:), 'MarkerSize', 3);

% correct
plot([-.2 0], [s1(dsearchn(stim', -.2)) s1(dsearchn(stim', -.2))], 'color', cols(2,:));
plot(-.2, s1(dsearchn(stim', -.2)), '.', ...
    'MarkerFaceColor', cols(2,:),  'MarkerEdgeColor', cols(2,:), 'MarkerSize', 10);
plot([.3 0], [s2(dsearchn(stim', .3)) s2(dsearchn(stim', .3))], 'color', cols(2,:));
plot(.3, s2(dsearchn(stim', .3)), '.', ...
    'MarkerFaceColor',  cols(2,:),  'MarkerEdgeColor', cols(2,:), 'MarkerSize', 10);

axis tight; ylim([0 5]); offsetAxes;
ylabel('Probability density'); xlabel('Decision variable');
set(gca, 'xtick', [0], 'xticklabel', {'b'}, ...
    'box', 'off', 'tickdir', 'out', 'ytick', []);
title('Confidence');

hold on;
thisax = gca;
% add legend here for correct and error
ph2 = plot([-.2 -.15], mean(get(thisax, 'ylim'))*ones(2, 10), '.w');
lh = legend(ph2, 'Location', 'East'); % make t
lh.String = {'\color[rgb]{0.915294117647059,0.281568627450980,0.287843137254902} Error', ...
    '\color[rgb]{0.441568627450980,0.749019607843137,0.432156862745098} Correct'};
lpos = get(lh, 'Position'); lpos(1) = lpos(1) + .05;
set(lh, 'Position', lpos, 'box', 'off', 'FontSize', 6);

% ==================================================================
% average confidence
% ==================================================================

subplot(449);

gr1 = [0.2 0.2 0.2];
gr2 = [0.6 0.6 0.6];
cols = linspecer(3); cols = cols(2:3, :);

% first the difficult stimulus
% indicate one correct and one error
hold on;
a = area(0:0.0001:0.6, normpdf(0:0.0001:0.6,  .05, 0.1));
a.FaceColor = cols(2,:); a.EdgeColor = 'none';

a = area(-0.6:0.0001:0, normpdf(-0.6:0.0001:0,  .05, 0.1));
a.FaceColor = cols(1,:); a.EdgeColor = 'none';

% now the distributions on top
s3 = normpdf(stim, -.05, 0.1);
s4 = normpdf(stim,  .05, 0.1);
p = plot(stim, s3, ':', stim, s4,  '-', zeros(1, 2), [0 4.5], 'k');
p(1).Color = gr2; p(2).Color = gr2;

axis tight; ylim([0 5]); offsetAxes;
ylabel('Probability density'); xlabel('Decision variable');
set(gca, 'xtick', [0], 'xticklabel', {'b'}, ...
    'box', 'off', 'tickdir', 'out', 'ytick', []);
title('Weak stimulus');

% then the easy stimulus
subplot(4,4,10);
% indicate one correct and one error
hold on;
a = area(0:0.0001:0.6, normpdf(0:0.0001:0.6,  .2, 0.1));
a.FaceColor = cols(2,:); a.EdgeColor = 'none';

a = area(-0.6:0.0001:0, normpdf(-0.6:0.0001:0,  .2, 0.1));
a.FaceColor = cols(1,:); a.EdgeColor = 'none';

% now the distributions on top
s3 = normpdf(stim, -.2, 0.1);
s4 = normpdf(stim,  .2, 0.1);
p = plot(stim, s3, ':', stim, s4,  '-', zeros(1, 2), [0 4.5], 'k');
p(1).Color = gr1; p(2).Color = gr1;

axis tight; ylim([0 5]); offsetAxes;
% ylabel('Probability density');
xlabel('Decision variable');
set(gca, 'xtick', [0], 'xticklabel', {'b'}, ...
    'box', 'off', 'tickdir', 'out', 'ytick', []);
title('Strong stimulus');

% ==================================================================
% confidence split by error vs correct
% ==================================================================

% make a little function that computes this quantity
stimlevs = [0:0.01:0.1];
confE = nan(size(stimlevs)); confC = nan(size(stimlevs));
for s = 1:length(stimlevs),
    [confE(s), confC(s)] = getConf(stimlevs(s));
end

subplot(4,4,11); hold on;
plot(stimlevs, confC, '-',  'color', cols(2, :));
plot(stimlevs, confE, '-', 'color', cols(1, :));
% also add some points

stimpts = [0.02 0.08];
confEpt = nan(size(stimpts)); confCpt = nan(size(stimpts));
for s = 1:length(stimpts),
    [confEpt(s), confCpt(s)] = getConf(stimpts(s));
end
plot(stimpts(1), confEpt(1), 's', 'MarkerFaceColor', gr2, 'MarkerEdgeColor', gr2, 'MarkerSize', 3);
plot(stimpts(1), confCpt(1), '.', 'MarkerFaceColor', gr2, 'MarkerEdgeColor', gr2, 'MarkerSize', 12);
p1 = plot(stimpts(2), confEpt(2), 's', 'MarkerFaceColor', gr1, 'MarkerEdgeColor', gr1, 'MarkerSize', 3);
p2 = plot(stimpts(2), confCpt(2), '.', 'MarkerFaceColor', gr1, 'MarkerEdgeColor', gr1, 'MarkerSize', 12);

axis tight;
set(gca,  'box', 'off', 'tickdir', 'out', 'xlim', [min(stimlevs) max(stimlevs)]);
xlabel('Stimulus difficulty');
ylabel('Confidence');
ylim([0 0.5]); set(gca, 'ytick', [0 0.2]);
offsetAxes(gca, 0.15); set(gca, 'xtick', stimpts, 'xticklabel', {'hard', 'easy'});
%lh = legend([p1 p2], 'Location', 'NorthWest'); % make t
%lh.String = {'\color[rgb]{0.915294117647059,0.281568627450980,0.287843137254902} Error', ...
%    '\color[rgb]{0.441568627450980,0.749019607843137,0.432156862745098} Correct'};
%lpos = get(lh, 'Position'); lpos(3) = lpos(3) /5;
%set(lh, 'Position', lpos, 'box', 'off', 'FontSize', 6);

% ==================================================================
% uncertainty = 1 - confidence
% ==================================================================

subplot(4,4,12); hold on;
p1 = plot(stimlevs, 1-confC, '-', 'color', cols(2, :));
p2 = plot(stimlevs, 1-confE, '-', 'color', cols(1, :));
plot(stimpts(1), 1-confEpt(1), '.', 'MarkerFaceColor', gr2, 'MarkerEdgeColor', gr2, 'MarkerSize', 12);
plot(stimpts(1), 1-confCpt(1), '.', 'MarkerFaceColor', gr2, 'MarkerEdgeColor', gr2, 'MarkerSize', 12);
plot(stimpts(2), 1-confEpt(2), '.', 'MarkerFaceColor', gr1, 'MarkerEdgeColor', gr1, 'MarkerSize', 12);
plot(stimpts(2), 1-confCpt(2), '.', 'MarkerFaceColor', gr1, 'MarkerEdgeColor', gr1, 'MarkerSize', 12);

hold on;
axis tight; axis square;

set(gca,'box', 'off', 'tickdir', 'out', 'xlim', [min(stimlevs) max(stimlevs)]);
xlabel('Stimulus difficulty');
ylabel('Uncertainty');
ylim([0.8 1]); set(gca, 'ytick', [0.8 1]);
offsetAxes(gca, 0.15); set(gca, 'xtick', stimpts, 'xticklabel', {'hard', 'easy'});

print(gcf, '-dpdf', sprintf('%s/figure1_UncertaintyModel.pdf', figpath));

end

function [confE, confC] = getConf(stim)
% compute confidence for correct and error trials based on stimulus
% strength

% assume no bias
bound = 0;

x = -0.6:0.01:0.6;
% transform this one stimulus into a dv distribution
dv = normpdf(x, stim, 0.1);

% split into correct and error trials
corrIdx = find(x > 0);
errIdx  = find(x < 0);

% Kepecs way, distance to bound
confC = (mean(abs(x(corrIdx) .* dv(corrIdx))));
confE = (mean(abs(x(errIdx) .* dv(errIdx))));

end
