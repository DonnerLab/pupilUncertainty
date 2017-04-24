function boundUpdate_Kepecs_curve
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
% See email 18/02/2017
%
% Anne Urai, 2017
% anne.urai@gmail.com

clearvars -except mypath; close all;
global mypath;
mypath = '/Users/anne/Data/pupilUncertainty_FigShare';

% warnings
warning('error', 'stats:glmfit:PerfectSeparation');
warning('error', 'stats:glmfit:IterationLimit');
warning('error', 'stats:glmfit:IllConditioned');

% get all data
colormap(cbrewer('div', 'RdBu', 64));
set(groot, 'defaultaxescolororder', viridis(3), 'DefaultAxesFontSize', 6);

colors = cbrewer('div', 'BrBG', 9); colors = colors([1:3 end-3:end], :);
xpos = [3 2 1 4 5 6];
labtxt = {'choice -1, hard', 'choice -1, medium', 'choice -1, easy', ...
    'choice 1, hard', 'choice 1, medium', 'choice 1, easy'};

% sort by history weigths
load(sprintf('%s/Data/Grandaverage/historyweights_plain.mat', mypath));
historyweights = dat.response(:, 1);
[val, spidx] = sort(historyweights);

correct = [1 0];
for prevcorrect = 1:2,
    clf;
    
    subjects = 1:27;
    for sj = subjects,
        
        % get data
        data     = readtable(sprintf('%s/Data/CSV/2ifc_data_sj%02d.csv', mypath, sj));
        
        % make ME evenly distributed over trials
        for s = unique(data.sessionnr)',
            data.motionstrength(s == data.sessionnr) = ...
                zscore(data.motionstrength(s == data.sessionnr));
        end
        
        % add some stuff
        data.prevcorrect            = circshift(data.correct, 1);
        data.prevresp               = circshift(data.resp, 1);
        data.prevmotionstrength     = circshift(zscore(log(data.rt + 0.5)) + 10, 1);
        
        % plot
        subplot(5,6,spidx(sj));
        hold on; cnt = 1;
        plot(1:length(labtxt), zeros(size(labtxt)), 'color', [0.5 0.5 0.5], 'linewidth', 0.1);
        
        % remove non-continuous trials?
        choices = [-1 1];
        for prevchoice = 1:2,
            
            % subset of trials
            trls = find(data.prevcorrect == correct(prevcorrect) & ...
                data.prevresp == choices(prevchoice));
            thisdat = data(trls, :);
            
            prevdifficulty = findgroups(discretize(abs(thisdat.prevmotionstrength), ...
                [-inf quantile(abs(thisdat.prevmotionstrength), 3) inf]));
            for prevdiff = 1:3,
                thisdat2 = thisdat(prevdifficulty == prevdiff, :);
                
                % fit curve
                [b, ~, stats] = glmfit(thisdat2.motionstrength, ...
                    (thisdat2.resp > 0), 'binomial', 'link', 'logit');
                
                % save
                grandavg(sj, prevcorrect, prevchoice, prevdiff, :) = b;
                
                % plot
                p = ploterr(xpos(cnt), b(1), [], stats.se(1), 'o', 'abshhxy', 0);
                set(p(1), 'markerfacecolor', colors(xpos(cnt), :), 'markeredgecolor', 'w');
                set(p(2), 'color', colors(xpos(cnt), :));
                cnt = cnt + 1;
                
            end
        end
        
        title(sprintf('P%02d', sj), 'fontweight', 'normal'); box off;
        ylims = get(gca, 'ylim');
        ylims = max(abs(ylims));
        ylim([-ylims ylims]);
        axis tight; axis square
        % offsetAxes;
        set(gca, 'xtick', 1:cnt-1, 'xticklabel', [-3 -2 -1 1 2 3], ...
            'xlim', [0.5 max(get(gca, 'xlim'))]);
        
    end
    
    % =================================================== %
    % grand average
    % =================================================== %
    
    subplot(5,6,28);
    hold on; cnt = 1;
    plot(1:length(labtxt), zeros(size(labtxt)), 'color', [0.5 0.5 0.5], 'linewidth', 0.1);
    for prevchoice = 1:2,
        for prevdiff = 1:3,
            
            p = ploterr(xpos(cnt), nanmean(grandavg(:, prevcorrect, prevchoice, prevdiff, 1)), ...
                [], nanstd(grandavg(:, prevcorrect, prevchoice, prevdiff, 1)) ./ sqrt(27), 'o', 'abshhxy', 0);
            set(p(1), 'markerfacecolor', colors(xpos(cnt), :), 'markeredgecolor', 'w');
            set(p(2), 'color', colors(xpos(cnt), :));
            h(cnt) = p(1);
            cnt = cnt + 1;
        end
    end
    
    title('Grand Average');
    box off; axis tight;
    ylim([-0.3 0.3]); set(gca, 'ytick', [-0.3 0 0.3]);
    % offsetAxes;
    set(gca, 'xtick', 1:cnt-1, 'xticklabel', [-3 -2 -1 1 2 3], ...
        'xlim', [0.5 max(get(gca, 'xlim'))]);
    
    % if c == 2,
    l = legend(h(xpos), labtxt(xpos));
    legend boxoff;
    l.Position(1) = l.Position(1) + 0.2;
    
    switch correct(prevcorrect)
        case 0
            suplabel('Previous error', 't');
            name = 'error';
        case 1
            suplabel('Previous correct', 't');
            name = 'correct';
    end
    
    suplabel('Previous stimulus strength', 'x');
    suplabel('Current choice bias', 'y');
    print(gcf, '-dpdf', sprintf('%s/Figures/boundUpdate_curve_%s_rt.pdf', mypath, name));
end
end
