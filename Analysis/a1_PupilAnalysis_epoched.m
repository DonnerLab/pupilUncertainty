% add paths and fieldtrip
addpath(genpath('~/code/Pupil_Learning'));
addpath(genpath('~/code/Tools'));
addpath('~/Documents/fieldtrip/'); 
ft_defaults;
subjects = 1:27; close all;

for sj = unique(subjects),
    clearvars -except sj subjects;
    
    cd(sprintf('~/Data/UvA_pupil/P%02d/', sj));
    
    clear sessions;
    % check which sessions to use
    s = dir('S*');
    s = {s(:).name};
    for i = 1:length(s), sessions(i) = str2num(s{i}(2)); end
    
    for session = unique(sessions),
        
        cd([sprintf('~/Data/UvA_pupil/P%02d/', sj) 'S' num2str(session)]);
        
        % ==================================================================
        % LOAD IN SUBJECT SPECIFICS AND READ DATA
        % ==================================================================
        
        blocks = 1:10;
        
        % some subjects didnt do all blocks, manually correct
        if sj == 2 && session == 1,
            blocks = 4:9;
        elseif sj == 17 && session == 1,
            blocks = 1:5;
        elseif sj == 15 && session == 3,
            blocks = 1:5;
        elseif sj == 15 && session == 6,
            blocks = 1:5;
        end
        
        for block = unique(blocks),
            disp(['Analysing subject ' num2str(sj) ', session ' num2str(session) ', block ' num2str(block)]);
            
            edffile   = dir(sprintf('P%d_s%d_b%d_*.edf', sj, session, block));
            ascfile   = dir(sprintf('P%d_s%d_b%d_*.asc', sj, session, block));
            
            if ~exist(sprintf('~/Data/UvA_pupil/P%02d/P%02d_s%d_b%02d_eyeclean.mat', sj, sj, session, block), 'file'),
                if ~exist(sprintf('P%02d_s%d_b%02d_eye.mat', sj, session, block), 'file'),
                    
                    % specify the filename
                    if ~exist(ascfile.name, 'file'),
                        
                        % CONVERT TO ASC
                        if exist('~/code/Tools/eye/edf2asc-linux', 'file'),
                            system(sprintf('%s %s -input', '~/code/Tools/eye/edf2asc-linux', edffile.name));
                        else
                            system(sprintf('%s %s -input', '~/Dropbox/code/Tools/eye/edf2asc-mac', edffile.name));
                        end
                        ascfile   = dir(sprintf('P%d_s%d_b%d_*.asc', sj, session, block));
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % making a FieldTrip structure out of EyeLink data
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % read in the asc EyeLink file
                    asc = read_eyelink_ascNK_AU(ascfile.name);
                    
                    % create events and data structure
                    [data, event] = asc2dat(asc);
                    
                    % save
                    savefast(sprintf('P%02d_s%d_b%02d_eye.mat', sj, session, block), 'data', 'asc', 'event');
                else
                    load(sprintf('P%02d_s%d_b%02d_eye.mat', sj, session, block));
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % linear blink interpolation
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                close all;
                
                pupilchan    = find(strcmp(data.label, 'EyePupil')==1);
                pupildat     = data.trial{1}(pupilchan,:);
                [blinksmp, newpupildat] = blinkinterpolate_gui(pupildat, data.fsample);
                data.trial{1}(pupilchan, :) = newpupildat;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % lowpass filter
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                cfg                 = [];
                cfg.lpfilter        = 'yes';
                cfg.lpfreq          = 10; % lowpass at 10 to get rid of fast noise
                datafilt            = ft_preprocessing(cfg, data);
                
                pupilchan   = find(strcmp(datafilt.label, 'EyePupil')==1);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % compute percent signal change rather than zscore
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                pupildat    = datafilt.trial{1}(pupilchan,:);
                medianpupil = median(pupildat);
                
                % normalize
                pupiltimecourse = (pupildat - medianpupil) ./ medianpupil * 100; % normalize
                datafilt.trial{1}(pupilchan,:) = pupiltimecourse; % put back in

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % define trials
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % same idea as for MEG data
                cfg                         = [];
                cfg.trialfun                = 'trialfun_EL_UvA';
                cfg.trialdef.pre            = 0;
                cfg.trialdef.post           = 4;
                cfg.event                   = event;
                cfg.dataset                 = ascfile.name;
                cfg.fsample                 = asc.fsample;
                cfg.sj                      = sj;
                cfg.session                 = session;
                [cfg]                       = ft_definetrial(cfg);
                
                data                        = ft_redefinetrial(cfg, datafilt); %make trials
                data.trialinfo              = cfg.trl(:,4:end);
                
                % in sj 3 and 5, recode the block nrs
                if (sj == 5 && session == 1) || (sj == 3 && session == 1),
                    data.trialinfo(:,13) = block;
                elseif sj == 15 && session == 6,
                    data.trialinfo(:,13) = block;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % downsample before saving
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                cfg             = [];
                cfg.resamplefs  = 100;
                cfg.fsample     = data.fsample;
                
                % see Niels' message on the FT mailing list
                samplerows = find(data.trialinfo(1,:)>100); %indices of the rows with sample values (and not event codes)
                data.trialinfo(:,samplerows) = round(data.trialinfo(:,samplerows) * (cfg.resamplefs/cfg.fsample));
                
                % use fieldtrip to resample
                data = ft_resampledata(cfg, data);
                
                cd ..
                disp(['Saving... ' sprintf('P%02d_s%d_b%02d_eyeclean.mat', sj, session, block)]);
                % save these datafiles before appending
                savefast(sprintf('P%02d_s%d_b%02d_eyeclean.mat', sj, session, block), 'data');
                cd(['S' num2str(session)]);
                
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % now append all the eyelink files together
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % check if the full dataset is not there yet
    cd(sprintf('~/Data/UvA_pupil/P%02d/', sj));
    eyelinkfiles = dir(sprintf('P%02d*_eyeclean.mat', sj));
    
    % make sure these are in the right order!
    % otherwise, indexing of trials will go awry
    for f = 1:length(eyelinkfiles),
        scandat         = sscanf(eyelinkfiles(f).name, 'P%*d_s%d_b%d*.mat');
        snum(f,:)       = scandat';
    end
    [sorted, sortidx]   = sort(snum(:,1)); % sort by session
    sorted(:,2)         = snum(sortidx, 2); % sort by block
    eyelinkfiles        = eyelinkfiles(sortidx);
    
    cfg = [];
    cfg.inputfile = {eyelinkfiles.name};
    cfg.outputfile = sprintf('~/Data/UvA_pupil/P%02d_alleye.mat', sj);
    ft_appenddata(cfg);
    
end
