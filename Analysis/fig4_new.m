% figure 4 overview

close;
figure;

% top row pure history effects
subplot(441); fig4a_FruendKernels('plain');
set(gca, 'xcolor', 'k', 'ycolor', 'k', 'linewidth', 0.5);

subplot(442); fig4b_decisionStrategies('plain');
set(gca, 'xcolor', 'k', 'ycolor', 'k', 'linewidth', 0.5);

% middle row
nbins = 3;
subplot(445); fig4c_psychFuncShift_Bias_byResp('pupil', 'all', nbins); % todo
subplot(446); fig4d_psychFuncShift_Bias_Slope('pupil', 'all', nbins);

subplot(4,4,7); fig4c_psychFuncShift_Bias_byResp('rt', 'all', nbins); % todo
subplot(4,4,8); fig4d_psychFuncShift_Bias_Slope('rt', 'all', nbins);

% bottom row - unique variance of pupil and RT
subplot(4,4,9); fig4hi_HistoryPupil_Bar('pupil-rt', 'all');
subplot(4,4,10); fig4hi_HistoryPupil_Bar('rt-pupil', 'all');

subplot(4,4,11); fig4j_SjCorrelation('pupil-rt ');
subplot(4,4,12); fig4j_SjCorrelation('rt-pupil');

subplot(4,4,13); fig4k_HistoryPupil_Bar_subGroups('pupil-rt', 'switch');
subplot(4,4,14); fig4k_HistoryPupil_Bar_subGroups('pupil-rt', 'repeat');

print(gcf, '-dpdf', sprintf('~/Dropbox/Figures/uncertainty_paper/figure4_layoutnewLayout.pdf'));


