
% reproduces 
global mypath;
close; figure;

correctness = []; % empty; both correct and error trials will be used
nbins = 3;

subplot(441); psychFuncShift_Bias_byResp('pupil', nbins, correctness);
subplot(442); psychFuncShift_Bias_Slope('pupil', nbins, correctness);

subplot(443); psychFuncShift_Bias_byResp('rt', nbins, correctness); 
subplot(444); psychFuncShift_Bias_Slope('rt', nbins, correctness);

print(gcf, '-dpdf', sprintf('%s/Figures/figure6.pdf', mypath));
