function [] = fig4c_decisionStrategies(lagGroups, whichmodulator)

if ~exist('lagGroups', 'var'), lagGroups = 1; end
if ~exist('whichmodulator', 'var'); whichmodulator = 'rt'; end

% ========================================================= %
% panel B: decision strategy for lags 1-3
% ========================================================= %

clc;
subjects = 1:27;
load(sprintf('~/Data/pupilUncertainty/GrandAverage/historyweights_%s.mat', whichmodulator));
colors = linspecer(9);

posRespSj = find(dat.response(:, 1) > 0);
negRespSj = find(dat.response(:, 1) < 0);

%subplot(442);
hold on;

plot([-1 1], [-1 1], 'color', 'k');
plot([-1 1], [1 -1], 'color', 'k');

plot(mean(dat.response(posRespSj, lagGroups), 2), mean(dat.stimulus(posRespSj, lagGroups), 2), ...
    'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', colors(8, :), 'markersize', 3);
plot(mean(dat.response(negRespSj, lagGroups), 2), mean(dat.stimulus(negRespSj, lagGroups), 2), ...
    'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', colors(9, :), 'markersize', 3);
axis tight; axis square; xlims = get(gca, 'xlim'); ylims = get(gca, 'ylim');

% also show the mean
h = ploterr(mean(mean(dat.response(:, lagGroups), 2)), mean(mean(dat.stimulus(:, lagGroups), 2)), ...
    std(mean(dat.response(:, lagGroups), 2)), ...
    std(mean(dat.stimulus(:, lagGroups), 2)), ...
    'o',  'hhxy', 0.0000001);
set(h(1), 'markeredgecolor', colors(7,:), 'markerfacecolor', 'w', 'markersize', 4);
set(h(2), 'color', colors(7,:));
set(h(3), 'color', colors(7,:));

maxlim = 0.3;
xlim([-maxlim maxlim]); ylim([-maxlim maxlim]);
set(gca, 'xtick', -maxlim:maxlim:maxlim, 'ytick', -maxlim:maxlim:maxlim);
xlabel('Response weight'); ylabel('Stimulus weight');
box on; axis square;

fz = 6;
text(0, 0.26, 'win stay', 'horizontalalignment', 'center', 'fontsize', fz);
text(0, 0.22, 'lose switch', 'horizontalalignment', 'center', 'fontsize', fz);

text(0, -0.22, 'win switch', 'horizontalalignment', 'center', 'fontsize', fz);
text(0, -0.26, 'lose stay', 'horizontalalignment', 'center', 'fontsize', fz);

text(0.26, .05, 'stay', 'rotation', 270, 'fontsize', fz);
text(-0.26, -.06, 'switch', 'rotation', 90, 'fontsize', fz);

print(gcf, '-dpdf', sprintf('~/Dropbox/Figures/uncertainty/fig4c_decisionStrategies.pdf'));
