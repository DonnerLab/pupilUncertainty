function ExamplePsychFunc(sj)

global mypath;

data = readtable(sprintf('%s/Data/CSV/2ifc_data_sj%02d.csv', mypath, sj));
data = data(find(data.sessionnr > 1), :);
% outcome vector need to be 0 1 for logistic regression
data.resp(data.resp == -1) = 0;

[bias, slope, lapse] = fitLogistic(data.motionstrength, data.resp);
xvals = -5:0.1:5;
Logistic = @(p, x) p(3)+(1-p(3)-p(3)) * (1./(1+exp(-p(2).*(x+p(1)))));
psychCurve = Logistic([bias slope lapse], xvals);
[binnedx, binnedy] = divideintobins(data.motionstrength, data.resp, 15);

%% plot these two in the colors we will also use later on
hold on;
plot([0 0], [0 1], 'k', 'linewidth', 0.1);
plot([min(xvals) max(xvals)], [0.5 0.5], 'k', 'linewidth', 0.1);
plot(xvals, psychCurve, '-', 'color', 'k', 'linewidth', 1);
plot(binnedx, binnedy, '.k', 'markersize', 12);

xlim([min(xvals) max(xvals)]); set(gca, 'xtick', [min(xvals) 0 max(xvals)]);
ylim([-0.05 1]); set(gca, 'ytick', [0 0.5 1]);
xlabel('Sensory evidence (a.u.)');
ylabel('P(choice = 1)');
axis square;
box off;

end