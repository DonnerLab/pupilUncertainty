%% instead of csv files, write text files that are in the format the Fruend toolbox needs

global mypath;
cd(sprintf('%s/Code/serial-dependencies/data', mypath));
subjects = 1:27;

for sj = subjects,
    disp(sj);
    % use files with cleaner pupil data
    data = readtable(sprintf('%s/Data/CSV/2ifc_data_sj%02d.csv', mypath, sj));
    
    % remove first session
    data = data(find(data.sessionnr > 1), :);
    
    % generate block nrs, NOT identical to session nrs! History effects
    % should not continue beyond a block
    blockchange = find(diff(data.trialnr) < 0);
    blocknrs = zeros(height(data), 1);
    for b = 1:length(blockchange)-1,
        blocknrs(blockchange(b)+1:blockchange(b+1)) = blocknrs(blockchange(b))+1;
    end
    blocknrs(blockchange(end)+1:end) = blocknrs(blockchange(end))+1;
    
    % no motionstrength, just coherence
    % this will be used to generate Figure 5b
    newdat = [blocknrs data.sessionnr data.coherence (data.stim > 0) (data.resp > 0)];
    dlmwrite(sprintf('2ifc_plainCoh_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
    % no modulation, just history
    newdat = [blocknrs data.sessionnr abs(data.motionstrength) (data.motionstrength > 0) (data.resp > 0)];
    dlmwrite(sprintf('2ifc_plain_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
    % only decision pupil
    newdat = [blocknrs data.sessionnr abs(data.motionstrength) (data.motionstrength > 0) (data.resp > 0) ...
        zscore(data.decision_pupil)];
    dlmwrite(sprintf('2ifc_pupil_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
    % only RT, take the one that's normalized within each block
    newdat = [blocknrs data.sessionnr abs(data.motionstrength) (data.motionstrength > 0) (data.resp > 0) ...
        data.rtNorm];
    dlmwrite(sprintf('2ifc_rt_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
    % double modulation: decision pupil and rt
    newdat = [blocknrs data.sessionnr abs(data.motionstrength) (data.motionstrength > 0) (data.resp > 0) ...
        zscore(data.decision_pupil) data.rtNorm];
    dlmwrite(sprintf('2ifc_pupil+rt_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
    % feedback pupil
    newdat = [blocknrs data.sessionnr abs(data.motionstrength) (data.motionstrength > 0) (data.resp > 0) ...
        zscore(data.feedback_pupil)];
    dlmwrite(sprintf('2ifc_fbpupil_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
    % feedback pupil with decision pupil in the model
    newdat = [blocknrs data.sessionnr abs(data.motionstrength) (data.motionstrength > 0) (data.resp > 0) ...
        zscore(data.feedback_pupil) zscore(data.decision_pupil)];
    dlmwrite(sprintf('2ifc_fb+decpupil_sj%02d.txt', sj), ...
        newdat,'delimiter','\t','precision',4);
    
end
