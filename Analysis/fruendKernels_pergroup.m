function [] = fruendKernels_pergroup(whichmodulator, field)
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

if ~exist('whichmodulator', 'var'), whichmodulator = 'plain'; end
if ~exist('field', 'var'), field = 'response'; end

% determine the subjects based on their plain weights
load(sprintf('%s/Data/GrandAverage/historyweights_%s.mat', mypath, whichmodulator));

colors = cbrewer('div', 'PuOr', 6);
subplot(441); hold on;
alternators = find(dat.response(:, 1) < 0);
repeaters = find(dat.response(:, 1) > 0);
lags = 1:7;
plot([1 7], [0 0], 'color', [0.5 0.5 0.5]);

boundedline(lags, nanmean(dat.response(alternators, :)), ...
    nanstd(dat.response(alternators, :)) ./sqrt(length(alternators)), 'alpha', ...
    'cmap', colors(end, :) );
boundedline(lags, nanmean(dat.response(repeaters, :)), ...
    nanstd(dat.response(repeaters, :)) ./sqrt(length(repeaters)), 'alpha', ...
    'cmap', colors(1, :) );
xlabel('Lags'); ylabel('Choice weight');
axis square; set(gca, 'xtick', 1:7);
xlim([0.5 7]); ylim([-0.2 0.2]);
offsetAxes;
print(gcf, '-dpdf', sprintf('%s/Figures/lags_persubgroup.pdf', mypath));

 %% =========================== %
 
figure;
load(sprintf('%s/Data/GrandAverage/historyweights_%s.mat', mypath, 'plain'));

colors = cbrewer('div', 'Spectral', 11);
subplot(441); hold on;
lags = 1:7;
plot([1 7], [0 0], 'color', 'k', 'linewidth', 0.1);

b1 = boundedline(lags, nanmean(dat.response), ...
    nanstd(dat.response) ./sqrt(27), 'alpha', ...
    'cmap', colors(11, :) );
b2 = boundedline(lags, nanmean(dat.stimulus), ...
    nanstd(dat.stimulus) ./sqrt(27), 'alpha', ...
    'cmap', colors(9, :) );
xlabel('Lags'); ylabel('Weight');
axis square; set(gca, 'xtick', 1:7);
xlim([0.5 7]); ylim([-0.2 0.2]);
offsetAxes;

% STATS
[h, pval1] = ttest(dat.response);
yval = -0.14;
plot(find(h==1), yval*ones(1, length(find(h==1))), '-', ...
    'color', colors(11, :), 'markersize', 4);
[h, pval1] = ttest(dat.stimulus);
yval = -0.17;
plot(find(h==1), yval*ones(1, length(find(h==1))), '-', ...
    'color', colors(9, :), 'markersize', 4);

text(7.2, -0.135, 'Choice', 'color', colors(11, :), 'FontSize', 6);
text(7.2, -0.175, 'Stimulus', 'color', colors(9, :), 'FontSize', 6);

% SAVE
print(gcf, '-dpdf', sprintf('%s/Figures/lags_choicestim.pdf', mypath));

end
