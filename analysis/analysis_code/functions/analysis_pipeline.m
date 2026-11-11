function [figureHandles,statsTables] = analysis_pipeline(analysisParameters,roundNum)

    %% Parameters
    load('../../experiment/RUN_ME/code/p.mat');

    p.DATA_FOLDER = analysisParameters.rawDataFolder;
    if(~isfield(analysisParameters,'statsTables'))
        statsTables = struct;
    else
        statsTables = analysisParameters.statsTables;
    end
    
    currStatsTable = transferStatsToStatsTable();

    if(analysisParameters.fromRawData)
        switch(analysisParameters.analysisRounds{roundNum})
            case 'noTrajNorm_noStandardization'
                p.PROC_DATA_FOLDER = ...
                    analysisParameters.targetPreProcData_noTrajNorm_noStandardization_folder;
            case 'TrajNorm_noStandardization'
                p.PROC_DATA_FOLDER = ...
                    analysisParameters.targetPreProcData_TrajNorm_noStandardization_folder;
            case 'TrajNorm_Standardization'
                p.PROC_DATA_FOLDER = ...
                    analysisParameters.targetPreProcData_TrajNorm_Standardization_folder;
        end
    else
        switch(analysisParameters.analysisRounds{roundNum})
            case 'noTrajNorm_noStandardization'
                p.PROC_DATA_FOLDER = ...
                    analysisParameters.readyPreProcData_noTrajNorm_noStandardization_folder;
            case 'TrajNorm_noStandardization'
                p.PROC_DATA_FOLDER = ...
                    analysisParameters.readyPreProcData_TrajNorm_noStandardization_folder;
            case 'TrajNorm_Standardization'
                p.PROC_DATA_FOLDER = ...
                    analysisParameters.readyPreProcData_TrajNorm_Standardization_folder;
        end
    end
    
    % Adjustable params.
    p.SUBS = [47, 49:85, 87:90];
    p.ORIG_SUBS = p.SUBS;
    p.DAY = 'day2';
    pas_rate = 1; % to analyze.
    picked_trajs = [1]; % traj to analyze (1=to_target, 2=from_target, 3=to_prime, 4=from_prime).

    switch(analysisParameters.analysisRounds{roundNum})
            case 'noTrajNorm_noStandardization'
                p.NORMALIZE_WITHIN_SUB = 0; % Normalize each variable within each sub.
                p.NORM_TRAJ = 0; % Normalize traj in space. ATTENTION: When NORM_TRAJ=0, change MIN_SAMP_LEN from 0.1 to min length you want trajs to be trimmed to.
                p.MIN_SAMP_LEN = 0.34; % In sec. Shorter trajs are excluded. (for NORM_TRAJ=0 use 0.34, otherwise 0.1).
                                        % When NORM_TRAJ=0, this is the len all trajs will be trimmed to.
                                        % Used "Movement Time Percentiles" section to determine the desired value.
                outFigFolder = analysisParameters.targetFigs_noTrajNorm_noStandardization_folder;
                
            case 'TrajNorm_noStandardization'
                p.NORMALIZE_WITHIN_SUB = 0;
                p.NORM_TRAJ = 1; 
                p.MIN_SAMP_LEN = 0.1;
                outFigFolder = analysisParameters.targetFigs_TrajNorm_noStandardization_folder;

            case 'TrajNorm_Standardization'
                p.NORMALIZE_WITHIN_SUB = 1;
                p.NORM_TRAJ = 1; 
                p.MIN_SAMP_LEN = 0.1;
                outFigFolder = analysisParameters.targetFigs_TrajNorm_Standardization_folder;
    end

    p.MIN_TRIM_FRAMES = p.MIN_SAMP_LEN * p.REF_RATE_HZ; % Minimal length (in samples, also called frames) to trim traj to (instead of normalization).
    p = defineParams_within_round(p, p.SUBS(1));
    
    % Name of trajectory column in output data. each cell is a incon type of traj.
    traj_names = {{'target_x_to' 'target_y_to' 'target_z_to'},...
        {'target_x_from' 'target_y_from' 'target_z_from'},...
        {'prime_x_to' 'prime_y_to' 'prime_z_to'},...
        {'prime_x_from' 'prime_y_from' 'prime_z_from'}};
    traj_names_mat = reshape(string([traj_names{:}]),3,[])';

    if(analysisParameters.fromRawData)
        if ~exist(p.PROC_DATA_FOLDER,"dir")
            mkdir(p.PROC_DATA_FOLDER);
        end
        writematrix(traj_names_mat, [p.PROC_DATA_FOLDER '/traj_names.csv']);
    end

    traj_names = traj_names(picked_trajs);
    % name of normalized traj column in output data.
    traj_names_norm = [traj_names{:,:}];
    traj_names_norm = reshape(traj_names_norm, [], length(traj_names));
    traj_names_norm = strcat(traj_names_norm, '_norm');
    traj_names_norm = traj_names_norm';
    % Traj names without 'x'/'y'/'z'.
    traj_types = [traj_names{:,:}];
    traj_types = reshape(traj_types, [], length(traj_names));
    traj_types = traj_types(1,:);
    traj_types = replace(traj_types, '_x', '');
    disp("Done setting params.");

    % Initializing
    figureHandles = [];

    %% Preprocessing Raw Data
    if(analysisParameters.fromRawData)
        %% Create processed data files
        % Copy the original data to a new file, to keep the data safe.
        tic
        disp('Creating processing data files for sub:');
        for iSub = p.SUBS
            disp(num2str(iSub));
            p = defineParams_within_round(p, iSub);
            reach_traj_table = readtable([p.DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_traj.csv']);
            reach_data_table = readtable([p.DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_data.csv']);
            keyboard_data_table = readtable([p.DATA_FOLDER '/sub' num2str(iSub) p.DAY '_keyboard_data.csv']);

            % Change 'same' column to 'con'.
            if any(contains(reach_data_table.Properties.VariableNames, 'same'))
                reach_data_table.Properties.VariableNames{'same'} = 'con';
                keyboard_data_table.Properties.VariableNames{'same'} = 'con';
            end
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_traj.mat'], 'reach_traj_table'); % '.mat' is faster to read than '.csv'.
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_data.mat'], 'reach_data_table');
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_keyboard_data.mat'], 'keyboard_data_table');
            
        end
        timing = num2str(toc);
        disp(['Done Creating processing data files. ' timing 'Sec'])

        %% Preprocessing & Normalization
        tic
        % Trials too short to filter.
        too_short_to_filter = table('Size', [max(p.SUBS) length(traj_types)],...
            'VariableTypes', repmat({'cell'}, length(traj_types), 1),...
            'VariableNames', traj_types);
        disp('Preprocessing done for subject:');
        % Preprocessing.
        for iSub = p.SUBS
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_traj.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            reach_data_table = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_data.mat']);  reach_data_table = reach_data_table.reach_data_table;
            keyboard_data_table = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_keyboard_data.mat']);  keyboard_data_table = keyboard_data_table.keyboard_data_table;
            
            % remove practice.
            reach_traj_table(reach_traj_table{:,'practice'} > 0, :) = [];
            reach_data_table(reach_data_table{:,'practice'} > 0, :) = [];
            keyboard_data_table(keyboard_data_table{:,'practice'} > 0, :) = [];
            
            % Preprocessing.
            for iTraj = 1:length(traj_names)
                [reach_pre_norm_traj_table, reach_data_table, too_short_to_filter{iSub, iTraj}{:}] = preproc(reach_traj_table, reach_data_table, traj_names{iTraj}, p);
            end
        
            % Save
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat'], 'reach_pre_norm_traj_table');
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_keyboard_data_proc.mat'], 'keyboard_data_table'); % Keyboard data isn't pre-processed because there is no need for that.
        end
        
        % Get minimal traj length.
        min_len = getMinLength(traj_names{1}, p);
        trim_len = p.NORM_TRAJ * p.NORM_FRAMES + ~p.NORM_TRAJ * min_len;
        save([p.PROC_DATA_FOLDER '/trim_len.mat'], 'trim_len');
        
        % Normalize or Trim
        for iSub = p.SUBS
            % Normalize by fitting a B-spline.
            if p.NORM_TRAJ
                [reach_traj_table] = normalize_trajs(iSub, traj_names{1}, p);
            % Trim to minimal traj's length (across subs).
            else
                [reach_traj_table] = trimToLength(iSub, min_len, traj_names{1}, p);
            end
        
            % Trim num samples to new length.
            matrix = reshape(reach_traj_table{:,:}, p.MAX_CAP_LENGTH, p.NUM_TRIALS, width(reach_traj_table));
            matrix = matrix(1:trim_len, :, :);
            reach_traj_table = reach_traj_table(1 : trim_len * p.NUM_TRIALS, :);
            reach_traj_table{:,:} = reshape(matrix, trim_len * p.NUM_TRIALS, width(reach_traj_table));
            % Save
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_traj_proc.mat'], 'reach_traj_table');
            disp(num2str(iSub));
        end
        
        disp('Following trials where too short to filter:');
        disp(too_short_to_filter);
        save([p.PROC_DATA_FOLDER '/too_short_to_filter_'  p.DAY '_subs_' p.SUBS_STRING '.mat'], 'too_short_to_filter');
        timing = num2str(toc);
        disp(['Preprocessing done. ' timing 'Sec']);

        %% Trial Screening
        tic
        for iTraj = 1:length(traj_names)
            [reach_bad_trials, reach_n_bad_trials, reach_bad_trials_i] = trialScreen(traj_names{iTraj}, 'reach', p);
            % % % % Exp 1,2,3 has no keybaord session.
            % % % if any(p.ORIG_SUBS < 43)
            % % %     keyboard_n_bad_trials = array2table(zeros(size(reach_n_bad_trials)), 'VariableNames',reach_n_bad_trials.Properties.VariableNames);
            % % %     keyboard_bad_trials_i = table('size',size(reach_bad_trials_i), 'variableNames',reach_bad_trials_i.Properties.VariableNames, 'VariableTypes',repmat("cell", [1, width(reach_bad_trials_i)]));
            % % %     keyboard_bad_trials = {};
            % % %     for iSub = p.SUBS
            % % %         keyboard_bad_trials{iSub,1} = array2table(zeros(size(reach_bad_trials{iSub})), 'VariableNames',reach_bad_trials{iSub}.Properties.VariableNames);
            % % %     end
            % % % else
                [keyboard_bad_trials, keyboard_n_bad_trials, keyboard_bad_trials_i] = trialScreen(traj_names{iTraj}, 'keyboard', p);
            % % % end
            save([p.PROC_DATA_FOLDER '/bad_trials_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'reach_bad_trials', 'reach_n_bad_trials', 'reach_bad_trials_i', 'keyboard_bad_trials', 'keyboard_n_bad_trials', 'keyboard_bad_trials_i');
        end
        timing = num2str(toc);
        disp(['Trial screening done. ' timing 'Sec']);
        %% Subject screening
        tic
        for iTraj = 1:length(traj_names')
            [reach_bad_subs, reach_valid_trials] = subScreening(traj_names{iTraj}, pas_rate, 'reach', p);
            [keyboard_bad_subs, keyboard_valid_trials] = subScreening(traj_names{iTraj}, pas_rate, 'keyboard', p);
            % Exp 1,2,3 had no keyboard task.
            if any(p.ORIG_SUBS < 43)
                keyboard_bad_subs(:,:) = array2table(zeros(size(keyboard_bad_subs)));
            end
            bad_subs = array2table(reach_bad_subs{:,:} | keyboard_bad_subs{:,:}, 'VariableNames',reach_bad_subs.Properties.VariableNames);
            good_subs = p.SUBS(~ismember(p.SUBS, find(bad_subs.any)));
            save([p.PROC_DATA_FOLDER '/bad_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'bad_subs', 'reach_bad_subs', 'keyboard_bad_subs');
            save([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'good_subs');
            save([p.PROC_DATA_FOLDER '/valid_trials_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'reach_valid_trials', 'keyboard_valid_trials');
        end
        timing = num2str(toc);
        disp(['Sub screening done. ' timing 'Sec']);
        

        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                                                %
        % Preform statistical analyses per-participant:  %
        %                                                %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Maximum absolute deviation
        tic
        for iTraj = 1:length(traj_names)
            for iSub = p.SUBS
                % Load.
                p = defineParams_within_round(p, iSub);
                reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
                reach_prenorm_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat']);  reach_prenorm_traj_table = reach_prenorm_traj_table.reach_pre_norm_traj_table;
                reach_data_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat']);  reach_data_table = reach_data_table.reach_data_table;
                % Compute.
                reach_data_table = calcMAD(reach_traj_table, reach_prenorm_traj_table, reach_data_table, traj_names{iTraj}, p);
                % Save.
                save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
            end
        end
        timing = num2str(toc);
        disp(['MAD calc done. ' timing 'Sec']);

        %% MAD standardized per subject
        if (p.NORMALIZE_WITHIN_SUB)
            tic
            for iTraj = 1:length(traj_names)
                % Get the list of bad trials for all subjects:
                bad_trials = load([p.PROC_DATA_FOLDER '/bad_trials_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);
                reach_bad_trials = bad_trials.reach_bad_trials;
        
                for iSub = p.SUBS
                    % Load.
                    p = defineParams_within_round(p, iSub);
                    reach_data_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat']);  reach_data_table = reach_data_table.reach_data_table;
                    % Find trials which will later be excluded:
                        % Bad trials reasons, Remove reason: "slow_mvmnt", "loop".
                        reasons = string(reach_bad_trials{iSub}.Properties.VariableNames);
                        reasons(reasons == "any" | reasons == "slow_mvmnt" | reasons == "loop") = [];
                        bad = any(reach_bad_trials{iSub}{:, reasons}, 2);
                    % Compute.
                    reach_data_table.target_to_mad_z = nan(size(reach_data_table,1),1);
                    reach_data_table.target_to_mad_z(~isnan(reach_data_table.target_to_mad) & ~bad) = ...
                        zscore(reach_data_table.target_to_mad(~isnan(reach_data_table.target_to_mad) & ~bad));
                    % Save.
                    save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
                end
            end
            timing = num2str(toc);
            disp(['MAD z-scored calc done. ' timing 'Sec']);
        end

        %% Heading angle
        tic
        for iSub = p.SUBS
            % Load.
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            reach_prenorm_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat']);  reach_prenorm_traj_table = reach_prenorm_traj_table.reach_pre_norm_traj_table;
            reach_traj_table = calcHeadAngle(reach_traj_table, reach_prenorm_traj_table, p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat'], 'reach_traj_table');
        end
        timing = num2str(toc);
        disp(['Heading angle calc done. ' timing 'Sec']);
        %% Implied endpoint.
        tic
        for iSub = p.SUBS
            % Load.
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            reach_traj_table = calcIEP(reach_traj_table, traj_names{1}, p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat'], 'reach_traj_table');
        end
        timing = num2str(toc);
        disp(['Implied endpoint calc done. ' timing 'Sec']);
        %% Changes of mind
        tic
        for iSub = p.SUBS
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            reach_data_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat']);  reach_data_table = reach_data_table.reach_data_table;
            reach_data_table = countCom(reach_traj_table, reach_data_table, p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
        end
        timing = num2str(toc);
        disp(['COM calc done. ' timing 'Sec']);
        %% Total distance traveled
        tic
        for iSub = p.SUBS
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat']);  reach_traj_table = reach_traj_table.reach_pre_norm_traj_table;
            reach_data_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat']);  reach_data_table = reach_data_table.reach_data_table;
            reach_data_table = calcTotDistTravel(reach_traj_table, reach_data_table, p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
        end
        timing = num2str(toc);
        disp(['Total distance traveled calc done. ' timing 'Sec']);
        %% AUC
        tic
        for iSub = p.SUBS
            disp(iSub)
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            reach_pre_norm_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat']);  reach_pre_norm_traj_table = reach_pre_norm_traj_table.reach_pre_norm_traj_table;
            reach_data_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat']);  reach_data_table = reach_data_table.reach_data_table;
            reach_data_table = calcAuc(reach_traj_table, reach_data_table, reach_pre_norm_traj_table, p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
        end
        timing = num2str(toc);
        disp(['AUC calc done. ' timing 'Sec']);
        %% Velocity
        tic
        for iSub = p.SUBS
            disp(iSub);
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            prenorm_traj_table = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat']);  prenorm_traj_table = prenorm_traj_table.reach_pre_norm_traj_table;
            reach_traj_table = calcVelAcc(prenorm_traj_table, reach_traj_table, 'vel', p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat'], 'reach_traj_table');
        end
        timing = num2str(toc);
        disp(['Velocity calc done. ' timing 'Sec']);
        %% Max Velocity
        tic
        for iSub = p.SUBS
            disp(iSub);
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            reach_data_table = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_data_proc.mat']);  reach_data_table = reach_data_table.reach_data_table;
            reach_data_table = calcMaxVel(reach_traj_table, reach_data_table, p);
            save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_data_proc.mat'], 'reach_data_table');
        end
        timing = num2str(toc);
        disp(['Max Velocity calc done. ' timing 'Sec']);
        %% Acceleration
        tic
        for iSub = p.SUBS
            p = defineParams_within_round(p, iSub);
            reach_traj_table = load([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat']);  reach_traj_table = reach_traj_table.reach_traj_table;
            prenorm_traj_table = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_reach_pre_norm_traj.mat']);  prenorm_traj_table = prenorm_traj_table.reach_pre_norm_traj_table;
            reach_traj_table = calcVelAcc(prenorm_traj_table, reach_traj_table, 'acc', p);
            save([p.PROC_DATA_FOLDER 'sub' num2str(iSub) p.DAY '_reach_traj_proc.mat'], 'reach_traj_table');
        end
        timing = num2str(toc);
        disp(['Acceleration calc done. ' timing 'Sec']);


        %% Sorting and averaging (within subject) - intermediate step
        tic
        for iTraj = 1:length(traj_names)
            bad_trials = load([p.PROC_DATA_FOLDER '/bad_trials_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);
            reach_bad_trials = bad_trials.reach_bad_trials;
            keyboard_bad_trials = bad_trials.keyboard_bad_trials;
            for iSub = p.SUBS
                disp(iSub);
                if(iSub==50)
                    disp('pause');
                end
                p = defineParams_within_round(p, iSub);
                [r_avg, r_trial, k_avg, k_trial] = avgWithin(iSub, traj_names{iTraj}, reach_bad_trials, keyboard_bad_trials, pas_rate, p.NORMALIZE_WITHIN_SUB, p);
                save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_sorted_trials_' traj_names{iTraj}{1} '.mat'], 'r_trial', 'k_trial');
                save([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_avg_' traj_names{iTraj}{1} '.mat'], 'r_avg', 'k_avg');
            end
        end
        timing = num2str(toc);
        disp(['Sorting and avging within sub done. ' timing 'Sec']);
        %% Reach Area
        % Area between left and right traj for con/incon condition.
        tic
        for iTraj = 1:length(traj_names)
            reach_area.con = NaN(1,p.MAX_SUB);
            reach_area.incon = NaN(1,p.MAX_SUB);
            good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
            for iSub = good_subs
                disp(iSub)
                p = defineParams_within_round(p, iSub);
                r_avg = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_avg_' traj_names{iTraj}{1} '.mat']);  r_avg = r_avg.r_avg;
                reach_area.con(iSub) = calcReachArea(r_avg.traj.con_left, r_avg.traj.con_right, p);
                reach_area.incon(iSub) = calcReachArea(r_avg.traj.incon_left, r_avg.traj.incon_right, p);
            end
            save([p.PROC_DATA_FOLDER 'reach_area_' traj_names{iTraj}{1} '_' p.DAY '_subs_' p.SUBS_STRING '.mat'], 'reach_area');
        end
        timing = num2str(toc);
        disp(['Reach area calc done. ' timing 'Sec']);
% % % %     %% d' computation
% % % %     % Computes each var's d' (sensitivity) many times.
% % % %     % Num iters.
% % % %     iters = 2;
% % % %     % Features when decoding d' for indirect measure (Reach: rt, react, mt, mad, com, tot_dist, auc, traj)
% % % %     r_preds = ["rt","react","mt","mad","tot_dist","auc"];
% % % %     k_preds = ["rt"];
% % % %     % Save a features and labels table to be used in python.
% % % %     save_to_python = 1;
% % % %     if save_to_python
% % % %         iters = 1;
% % % %     end
% % % % 
% % % %     r_coef = {}; % Regression classifier coefficients.
% % % %     k_coef = {}; % Regression classifier coefficients.
% % % %     r_d_prime = struct('direct',NaN(iters, p.MAX_SUB), 'indirect',NaN(iters, p.MAX_SUB));
% % % %     k_d_prime = struct('direct',NaN(iters, p.MAX_SUB), 'indirect',NaN(iters, p.MAX_SUB));
% % % %     % Bad subs have too few trials, so we don't use them.
% % % %     good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{1}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
% % % % 
% % % %     for iIter = 1:iters
% % % %         tic
% % % %         for iSub = good_subs
% % % %             avg = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_avg_' traj_names{1}{1} '.mat']);
% % % %             r_avg = avg.r_avg;
% % % %             k_avg = avg.k_avg;
% % % % 
% % % %             % Direct measure sensitivity. [Meyen et al. (2022) advancing research...]
% % % %             r_d_prime.direct(iIter, iSub) = 2 * norminv(r_avg.fc_prime.incon);
% % % %             k_d_prime.direct(iIter, iSub) = 2 * norminv(k_avg.fc_prime.incon);
% % % %             % Decode indirect measure sensitivity.
% % % %             [r_d_prime.indirect(iIter, iSub), r_coef{iIter}(iSub,:)] = decodeDPrime(iSub, 'reach', r_preds, save_to_python, traj_names{1}{1}, p);
% % % %             [k_d_prime.indirect(iIter, iSub), k_coef{iIter}(iSub,:)] = decodeDPrime(iSub, 'keyboard', k_preds, save_to_python, traj_names{1}{1}, p);
% % % %         end
% % % % 
% % % %         timing = num2str(toc);
% % % %         disp([num2str(iIter) ' iterations of d prime calc done. ' timing 'Sec']);
% % % %     end
% % % %     save([p.PROC_DATA_FOLDER '/d_prime_' p.DAY '_' traj_names{1}{1} '_subs_' p.SUBS_STRING '.mat'], 'r_d_prime', 'k_d_prime');

        %% Velocity profile
        tic
        vel_dist = velProf(p);
        save([p.PROC_DATA_FOLDER,'/vel_dist_' p.DAY '_subs_' p.SUBS_STRING '.mat'], 'vel_dist');
        timing = num2str(toc);
        disp(['Velocity profiling done. ' timing 'Sec']);
        %% Sorting and averaging (between subjects)
        tic
        for iTraj = 1:length(traj_names)
            [reach_subs_avg, keyboard_subs_avg] = avgBetween(traj_names{iTraj}, p);
            save([p.PROC_DATA_FOLDER '/subs_avg_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'reach_subs_avg', 'keyboard_subs_avg');
        end
        timing = num2str(toc);
        disp(['Sorting and avging between sub done. ' timing 'Sec']);

        %% Count trials for each condition
        tic
        for iTraj = 1:length(traj_names)
            for iSub = p.SUBS
                p = defineParams_within_round(p, iSub);
                % Get trials stats for this sub.
                single_trial = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_sorted_trials_' traj_names{iTraj}{1} '.mat']);
                reach_single = single_trial.r_trial;
                keyboard_single = single_trial.k_trial;
                reach_num_trials(iSub).con_left  = size(reach_single.rt.con_left, 1);
                reach_num_trials(iSub).con_right = size(reach_single.rt.con_right, 1);
                reach_num_trials(iSub).incon_left  = size(reach_single.rt.incon_left, 1);
                reach_num_trials(iSub).incon_right = size(reach_single.rt.incon_right, 1);
                reach_num_trials(iSub).con = reach_num_trials(iSub).con_left + reach_num_trials(iSub).con_right;
                reach_num_trials(iSub).incon = reach_num_trials(iSub).incon_left + reach_num_trials(iSub).incon_right;
                keyboard_num_trials(iSub).con_left  = size(keyboard_single.rt.con_left, 1);
                keyboard_num_trials(iSub).con_right = size(keyboard_single.rt.con_right, 1);
                keyboard_num_trials(iSub).incon_left  = size(keyboard_single.rt.incon_left, 1);
                keyboard_num_trials(iSub).incon_right = size(keyboard_single.rt.incon_right, 1);
                keyboard_num_trials(iSub).con = keyboard_num_trials(iSub).con_left + keyboard_num_trials(iSub).con_right;
                keyboard_num_trials(iSub).incon = keyboard_num_trials(iSub).incon_left + keyboard_num_trials(iSub).incon_right;
            end
            save([p.PROC_DATA_FOLDER '/num_trials_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'reach_num_trials', 'keyboard_num_trials');
        end
        timing = num2str(toc);
        disp(['Counting trials in each condition done. ' timing 'Sec']);

    else % Analysis not done from raw data, but from pre-prepared processed data:
        fprintf('Analysis done using pre-made processed data, continuing with the files in folder: %s\n', p.PROC_DATA_FOLDER)
    end % /Pre-process data


    %% Analyzing Group-Level
    load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{1}{1} '_subs_' p.SUBS_STRING '.mat'], 'good_subs');

    %% Plotting & Statistical Params
    disp("Started setting plotting params.");

    plt_p.alpha_size = 0.05; % For confidence interval.
    plt_p.n_perm = 10000; % Number of permutations for permutation and clustering procedure.
    if (p.NORM_TRAJ)
        plt_p.x_as_func_of = "zaxis";
    else
        plt_p.x_as_func_of = "time";
    end

    plt_p.errbar_type = 'se';
    plt_p.n_perm_clust_tests = 1;
    plt_p.avg_plot_width = 4;
    plt_p.space = 3;
    plt_p.f_alpha = 0.2;
    plt_p.linewidth = 4;
    plt_p.con_col = [0 0.35294 0.7098];
    plt_p.con_avg_col = 'b';
    plt_p.incon_col = [0.86275 0.19608 0.12549];
    plt_p.incon_avg_col = 'r';
    plt_p.axes_line_thickness = 2;
    plt_p.time_ticks = 0 : 50 : (p.MIN_SAMP_LEN * 1000);
    plt_p.percent_path_ticks = 0 : 20 : 100;
    plt_p.left_right_ticks = -10 : 5 : 10;
    plt_p.font_name = 'Calibri';
    plt_p.font_size = 15;
    plt_p.labels_font_size = 14;

    %% - Gathering data to be plotted into one data structure
    reach_area = load([p.PROC_DATA_FOLDER 'reach_area_' traj_names{1}{1} '_' p.DAY '_subs_' p.SUBS_STRING '.mat']);  reach_area = reach_area.reach_area;

    for iSub = p.SUBS
        for iTraj = 1:length(traj_names)
            avg = load([p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_' 'avg_' traj_names{iTraj}{1} '.mat']);
            r_avg = avg.r_avg;
            k_avg = avg.k_avg;
            % Separate avg for left and right.
            reach_avg_each.traj(iTraj).con_left(:,iSub,:) = r_avg.traj.con_left;
            reach_avg_each.traj(iTraj).con_right(:,iSub,:) = r_avg.traj.con_right;
            reach_avg_each.traj(iTraj).incon_left(:,iSub,:) = r_avg.traj.incon_left;
            reach_avg_each.traj(iTraj).incon_right(:,iSub,:) = r_avg.traj.incon_right;
            reach_avg_each.head_angle(iTraj).con_left(:,iSub) = r_avg.head_angle.con_left;
            reach_avg_each.head_angle(iTraj).con_right(:,iSub) = r_avg.head_angle.con_right;
            reach_avg_each.head_angle(iTraj).incon_left(:,iSub) = r_avg.head_angle.incon_left;
            reach_avg_each.head_angle(iTraj).incon_right(:,iSub) = r_avg.head_angle.incon_right;
            reach_avg_each.iep(iTraj).con_left(:,iSub) = r_avg.iep.con_left;
            reach_avg_each.iep(iTraj).con_right(:,iSub) = r_avg.iep.con_right;
            reach_avg_each.iep(iTraj).incon_left(:,iSub) = r_avg.iep.incon_left;
            reach_avg_each.iep(iTraj).incon_right(:,iSub) = r_avg.iep.incon_right;
            reach_avg_each.react(iTraj).con_left(iSub)  = r_avg.react.con_left * 1000;
            reach_avg_each.react(iTraj).con_right(iSub) = r_avg.react.con_right * 1000;
            reach_avg_each.react(iTraj).incon_left(iSub)  = r_avg.react.incon_left * 1000;
            reach_avg_each.react(iTraj).incon_right(iSub) = r_avg.react.incon_right * 1000;
            reach_avg_each.mt(iTraj).con_left(iSub)  = r_avg.mt.con_left * 1000;
            reach_avg_each.mt(iTraj).con_right(iSub) = r_avg.mt.con_right * 1000;
            reach_avg_each.mt(iTraj).incon_left(iSub)  = r_avg.mt.incon_left * 1000;
            reach_avg_each.mt(iTraj).incon_right(iSub) = r_avg.mt.incon_right * 1000;
            reach_avg_each.mad(iTraj).con_left(iSub)  = r_avg.mad.con_left;
            reach_avg_each.mad(iTraj).con_right(iSub) = r_avg.mad.con_right;
            reach_avg_each.mad(iTraj).incon_left(iSub)  = r_avg.mad.incon_left;
            reach_avg_each.mad(iTraj).incon_right(iSub) = r_avg.mad.incon_right;
            if (p.NORMALIZE_WITHIN_SUB)
                reach_avg_each.mad_z(iTraj).con_left(iSub)  = r_avg.mad_z.con_left;
                reach_avg_each.mad_z(iTraj).con_right(iSub) = r_avg.mad_z.con_right;
                reach_avg_each.mad_z(iTraj).incon_left(iSub)  = r_avg.mad_z.incon_left;
                reach_avg_each.mad_z(iTraj).incon_right(iSub) = r_avg.mad_z.incon_right;
            end
            reach_avg_each.com(iTraj).con_left(iSub)  = r_avg.com.con_left;
            reach_avg_each.com(iTraj).con_right(iSub) = r_avg.com.con_right;
            reach_avg_each.com(iTraj).incon_left(iSub)  = r_avg.com.incon_left;
            reach_avg_each.com(iTraj).incon_right(iSub) = r_avg.com.incon_right;
            reach_avg_each.tot_dist(iTraj).con_left(iSub)  = r_avg.tot_dist.con_left;
            reach_avg_each.tot_dist(iTraj).con_right(iSub) = r_avg.tot_dist.con_right;
            reach_avg_each.tot_dist(iTraj).incon_left(iSub)  = r_avg.tot_dist.incon_left;
            reach_avg_each.tot_dist(iTraj).incon_right(iSub) = r_avg.tot_dist.incon_right;
            reach_avg_each.auc(iTraj).con_left(iSub)  = r_avg.auc.con_left;
            reach_avg_each.auc(iTraj).con_right(iSub) = r_avg.auc.con_right;
            reach_avg_each.auc(iTraj).incon_left(iSub)  = r_avg.auc.incon_left;
            reach_avg_each.auc(iTraj).incon_right(iSub) = r_avg.auc.incon_right;
            reach_avg_each.x_std(iTraj).con_left(:,iSub)  = r_avg.x_std.con_left;
            reach_avg_each.x_std(iTraj).con_right(:,iSub) = r_avg.x_std.con_right;
            reach_avg_each.x_std(iTraj).incon_left(:,iSub)  = r_avg.x_std.incon_left;
            reach_avg_each.x_std(iTraj).incon_right(:,iSub) = r_avg.x_std.incon_right;
            reach_avg_each.cond_diff(iTraj).left(:,iSub,:)  = r_avg.cond_diff.left;
            reach_avg_each.cond_diff(iTraj).right(:,iSub,:) = r_avg.cond_diff.right;

            if (p.NORMALIZE_WITHIN_SUB)
                timeMultFactor = 1;
            else
                timeMultFactor = 1000;
            end
            keyboard_avg_each.rt(iTraj).con_left(iSub)    = k_avg.rt.con_left * timeMultFactor;
            keyboard_avg_each.rt(iTraj).con_right(iSub)   = k_avg.rt.con_right * timeMultFactor;
            keyboard_avg_each.rt(iTraj).incon_left(iSub)  = k_avg.rt.incon_left * timeMultFactor;
            keyboard_avg_each.rt(iTraj).incon_right(iSub) = k_avg.rt.incon_right * timeMultFactor;
            keyboard_avg_each.rt_std(iTraj).con_left(iSub)    = k_avg.rt_std.con_left;
            keyboard_avg_each.rt_std(iTraj).con_right(iSub)   = k_avg.rt_std.con_right;
            keyboard_avg_each.rt_std(iTraj).incon_left(iSub)  = k_avg.rt_std.incon_left;
            keyboard_avg_each.rt_std(iTraj).incon_right(iSub) = k_avg.rt_std.incon_right;

            % Combined avg of left and right.
            reach_avg_each.traj(iTraj).con(:, iSub, :) = r_avg.traj.con;
            reach_avg_each.traj(iTraj).incon(:, iSub, :) = r_avg.traj.incon;
            reach_avg_each.head_angle(iTraj).con(:, iSub) = r_avg.head_angle.con;
            reach_avg_each.head_angle(iTraj).incon(:, iSub) = r_avg.head_angle.incon;
            reach_avg_each.iep(iTraj).con(:, iSub) = r_avg.iep.con;
            reach_avg_each.iep(iTraj).incon(:, iSub) = r_avg.iep.incon;

            reach_avg_each.react(iTraj).con(iSub)   = r_avg.react.con * timeMultFactor;
            reach_avg_each.react(iTraj).incon(iSub) = r_avg.react.incon * timeMultFactor;
            reach_avg_each.mt(iTraj).con(iSub)      = r_avg.mt.con * timeMultFactor;
            reach_avg_each.mt(iTraj).incon(iSub)    = r_avg.mt.incon * timeMultFactor;
            reach_avg_each.mad(iTraj).con(iSub)     = r_avg.mad.con;
            reach_avg_each.mad(iTraj).incon(iSub)   = r_avg.mad.incon;
            if (p.NORMALIZE_WITHIN_SUB)
                reach_avg_each.mad_z(iTraj).con(iSub)   = r_avg.mad_z.con;
                reach_avg_each.mad_z(iTraj).incon(iSub) = r_avg.mad_z.incon;
            end
            reach_avg_each.com(iTraj).con(iSub)      = r_avg.com.con;
            reach_avg_each.com(iTraj).incon(iSub)    = r_avg.com.incon;
            reach_avg_each.tot_dist(iTraj).con(iSub)   = r_avg.tot_dist.con;
            reach_avg_each.tot_dist(iTraj).incon(iSub) = r_avg.tot_dist.incon;
            reach_avg_each.auc(iTraj).con(iSub)      = r_avg.auc.con;
            reach_avg_each.auc(iTraj).incon(iSub)    = r_avg.auc.incon;
            reach_avg_each.x_std(iTraj).con(:, iSub)   = r_avg.x_std.con;
            reach_avg_each.x_std(iTraj).incon(:, iSub) = r_avg.x_std.incon;
            reach_avg_each.ra(iTraj).con(iSub)       = reach_area.con(iSub);
            reach_avg_each.ra(iTraj).incon(iSub)     = reach_area.incon(iSub);
            reach_avg_each.pas(iTraj).con(iSub,:)    = r_avg.pas.con;
            reach_avg_each.pas(iTraj).incon(iSub,:)  = r_avg.pas.incon;

            keyboard_avg_each.rt(iTraj).con(iSub)      = k_avg.rt.con * timeMultFactor;
            keyboard_avg_each.rt(iTraj).incon(iSub)    = k_avg.rt.incon * timeMultFactor;
            keyboard_avg_each.rt_std(iTraj).con(iSub)   = k_avg.rt_std.con;
            keyboard_avg_each.rt_std(iTraj).incon(iSub) = k_avg.rt_std.incon;
            keyboard_avg_each.pas(iTraj).con(iSub,:)   = k_avg.pas.con;
            keyboard_avg_each.pas(iTraj).incon(iSub,:) = k_avg.pas.incon;

            sorted_file = [p.PROC_DATA_FOLDER '/sub' num2str(iSub) p.DAY '_sorted_trials_' traj_names{iTraj}{1} '.mat'];
            if exist(sorted_file, 'file')
                s_trials = load(sorted_file);
                r_tr = s_trials.r_trial;
                k_tr = s_trials.k_trial;

                n_r_con = length(r_tr.react.con);
                n_r_incon = length(r_tr.react.incon);
                n_k_con = length(k_tr.rt.con);
                n_k_incon = length(k_tr.rt.incon);

                reach_avg_each.n_trials(iTraj).con(iSub)   = n_r_con;
                reach_avg_each.n_trials(iTraj).incon(iSub) = n_r_incon;
                reach_avg_each.n_trials(iTraj).total(iSub) = n_r_con + n_r_incon;

                keyboard_avg_each.n_trials(iTraj).con(iSub)   = n_k_con;
                keyboard_avg_each.n_trials(iTraj).incon(iSub) = n_k_incon;
                keyboard_avg_each.n_trials(iTraj).total(iSub) = n_k_con + n_k_incon;

                keyboard_avg_each.rt(iTraj).total(iSub) = mean([k_tr.rt.con; k_tr.rt.incon]) * timeMultFactor;
                reach_avg_each.react(iTraj).total(iSub) = mean([r_tr.react.con; r_tr.react.incon]) * timeMultFactor;
                reach_avg_each.mt(iTraj).total(iSub)    = mean([r_tr.mt.con; r_tr.mt.incon]) * timeMultFactor;

                if (p.NORMALIZE_WITHIN_SUB)
                    reach_avg_each.mad_z(iTraj).total(iSub) = mean([r_tr.mad_z.con; r_tr.mad_z.incon]);
                    reach_avg_each.mad(iTraj).total(iSub)   = reach_avg_each.mad_z(iTraj).total(iSub);
                else
                    reach_avg_each.mad(iTraj).total(iSub)   = mean([r_tr.mad.con; r_tr.mad.incon]);
                end

                reach_avg_each.com(iTraj).total(iSub)      = mean([r_tr.com.con; r_tr.com.incon]);
                reach_avg_each.tot_dist(iTraj).total(iSub) = mean([r_tr.tot_dist.con; r_tr.tot_dist.incon]);
                reach_avg_each.auc(iTraj).total(iSub)      = mean([r_tr.auc.con; r_tr.auc.incon]);

                if (n_r_con + n_r_incon) > 0
                    reach_avg_each.ra(iTraj).total(iSub) = (n_r_con * reach_area.con(iSub) + n_r_incon * reach_area.incon(iSub)) / (n_r_con + n_r_incon);
                else
                    reach_avg_each.ra(iTraj).total(iSub) = NaN;
                end
            end

            % Compute diff between conditions (con/incon).
            reach_avg_each.react(iTraj).diff(iSub) = mean([r_avg.react.con_left - r_avg.react.incon_left, ...
                                                           r_avg.react.con_right - r_avg.react.incon_right]) * timeMultFactor;
            reach_avg_each.mt(iTraj).diff(iSub)    = mean([r_avg.mt.con_left - r_avg.mt.incon_left, ...
                                                           r_avg.mt.con_right - r_avg.mt.incon_right]) * timeMultFactor;
            reach_avg_each.mad(iTraj).diff(iSub)   = mean([r_avg.mad.con_left - r_avg.mad.incon_left, ...
                                                           r_avg.mad.con_right - r_avg.mad.incon_right]);
            if (p.NORMALIZE_WITHIN_SUB)
                reach_avg_each.mad_z(iTraj).diff(iSub) = mean([r_avg.mad_z.con_left - r_avg.mad_z.incon_left, ...
                                                               r_avg.mad_z.con_right - r_avg.mad_z.incon_right]);
            end
            reach_avg_each.x_dev(iTraj).diff(:,iSub) = mean([-1 * (r_avg.traj.con_left(:,1) - r_avg.traj.incon_left(:,1)), ...
                                                             (r_avg.traj.con_right(:,1) - r_avg.traj.incon_right(:,1))], 2);
            reach_avg_each.x_std(iTraj).diff(:,iSub) = mean([r_avg.x_std.con_left - r_avg.x_std.incon_left, ...
                                                             r_avg.x_std.con_right - r_avg.x_std.incon_right], 2);
            reach_avg_each.ra(iTraj).diff(iSub) = reach_area.con(iSub) - reach_area.incon(iSub);
            keyboard_avg_each.rt(iTraj).diff(iSub) = mean([k_avg.rt.con_left - k_avg.rt.incon_left, ...
                                                           k_avg.rt.con_right - k_avg.rt.incon_right]) * timeMultFactor;
        end
        reach_avg_each.fc_prime.con(iSub)      = r_avg.fc_prime.con;
        reach_avg_each.fc_prime.incon(iSub)    = r_avg.fc_prime.incon;
        keyboard_avg_each.fc_prime.con(iSub)   = k_avg.fc_prime.con;
        keyboard_avg_each.fc_prime.incon(iSub) = k_avg.fc_prime.incon;
    end
    save([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat'], 'reach_avg_each', 'keyboard_avg_each');
    disp("Done setting plotting params.");

    %%% Gather Perceptual Awareness Scores into stats tables (from primary TrajNorm_noStd round):
    if (p.NORM_TRAJ && ~p.NORMALIZE_WITHIN_SUB)
        out_stats_dir = analysisParameters.targetStats_allAnalysesCombined;
        [pas_summary_table, pas_by_sub_table, pas_stats_table, kb_PAS_Pct_Table, reach_PAS_Pct_Table] = ...
            compute_pas_analyses(reach_avg_each, keyboard_avg_each, good_subs, out_stats_dir);
        
        statsTables.primeAwarenessDist = struct(...
            'Keyboard', kb_PAS_Pct_Table, ...
            'Reaching', reach_PAS_Pct_Table, ...
            'PAS_Summary', pas_summary_table, ...
            'PAS_Statistical_Tests', pas_stats_table, ...
            'PAS_By_Sub', pas_by_sub_table);
    end

    % Export raw aggregated data into persistent statsTables struct
    roundName = matlab.lang.makeValidName(analysisParameters.analysisRounds{roundNum});
    statsTables.rawAggData.(roundName).reach    = reach_avg_each;
    statsTables.rawAggData.(roundName).keyboard = keyboard_avg_each;
    statsTables.good_subs = good_subs;

    % Aggregate figure handles
    if (isfield(analysisParameters,'figureHandles'))
        p.figureHandles = analysisParameters.figureHandles;
    else
        p.figureHandles = struct();
    end
    if ~isfield(p.figureHandles, roundName)
        p.figureHandles.(roundName) = struct();
    end

    %% - Fig. 2 + Supp. Fig. 3 (Prime Recognition — identical across flavors; run once in primary round)
    if (p.NORM_TRAJ && ~p.NORMALIZE_WITHIN_SUB)
        [RecogFigHandles, Recog_Stats, Recog_Sub_Stats] = plotMultiRecognition_SepByCong('good_subs', traj_names{1}{1}, plt_p, p);
        p.figureHandles.(roundName).fig2     = RecogFigHandles.incon;
        p.figureHandles.(roundName).suppFig3 = RecogFigHandles.con;

        statsTables.Prime_Performance_Stats  = Recog_Stats;
        statsTables.Prime_Performance_By_Sub = Recog_Sub_Stats;
    end

    %% - Fig. 3 i-l - Single Participants plots (TrajNorm_noStandardization only)
    if (p.NORM_TRAJ && ~p.NORMALIZE_WITHIN_SUB)
        subs_to_present = good_subs([5,10]);
        subFigsDesignation = {'i,k','j,l'};
        iDesig = 1;
        for iSub = subs_to_present
            sub_f(iSub,1) = figure('Name',[' Figure 3)' subFigsDesignation{iDesig} '  Sub ' num2str(iSub) ' - ' roundName], 'Position',[597 84 602 760], 'MenuBar','figure');
            theme light;
            iDesig = iDesig + 1;
        end
        for iSub = subs_to_present
            figure(sub_f(iSub,1));
            plotAllTrajs(iSub, traj_names, plt_p, p);
        end
        p.figureHandles.(roundName).fig_3_ik = sub_f(53,1);
        figure(p.figureHandles.(roundName).fig_3_ik);
        title('Figure 3) i,k');
        p.figureHandles.(roundName).fig_3_jl = sub_f(59,1);
        figure(p.figureHandles.(roundName).fig_3_jl);
        title('Figure 3) j,l');
    end

    %% - Fig. 3 a-h & Discrete Variable Statistics (ONLY for TrajNorm flavors; excluded in noTrajNorm)
    if (p.NORM_TRAJ)
        fig_3_ah_handle = figure('Name',['All Subs - ' roundName], 'Color', 'w', 'Position', [40 40 1650 900], 'MenuBar','figure');
        p.figureHandles.(roundName).fig_3_ah = fig_3_ah_handle;
        plotFlag = true;

        % ------- Avg traj with shade -------
        figure(fig_3_ah_handle);
        subplot(2,10,[2:5]);
        plotMultiAvgTrajWithShade(traj_names, plt_p, p, plotFlag);

        % ------- Response Times Keyboard -------
        figure(fig_3_ah_handle);
        subplot(2,5,4);
        KB_RT_stats = plotMultiKeyboardRt(traj_names, plt_p, p);
        currStatsTable = transferStatsToStatsTable(KB_RT_stats, currStatsTable);

        % ------- Reach Area -------
        figure(fig_3_ah_handle);
        subplot(2,5,5);
        ReachArea_Stats = plotMultiReachArea(traj_names, plt_p, p, plotFlag);
        currStatsTable = transferStatsToStatsTable(ReachArea_Stats, currStatsTable);

        % ------- MAD -------
        figure(fig_3_ah_handle);
        subplot(2,5,6);
        MAD_Stats = plotMultiMad_CongIncong(traj_names, plt_p, p, plotFlag);
        currStatsTable = transferStatsToStatsTable(MAD_Stats, currStatsTable);

        % ------- Reaching Onset + Reaching Duration -------
        figure(fig_3_ah_handle);
        subplot_p_rmt = [2,5,9; 2,5,7];
        [Reach_RT_Stats, Reach_MT_Stats] = plotMultiReactMtRt(traj_names, subplot_p_rmt, plt_p, p, plotFlag);
        currStatsTable = transferStatsToStatsTable(Reach_RT_Stats, currStatsTable);
        currStatsTable = transferStatsToStatsTable(Reach_MT_Stats, currStatsTable);

        % ------- Total distance traveled -------
        figure(fig_3_ah_handle);
        subplot(2,5,8);
        Total_Distance_Stats = plotMultiTotDist(traj_names, plt_p, p, plotFlag);
        currStatsTable = transferStatsToStatsTable(Total_Distance_Stats, currStatsTable);

        % ------- COM -------
        figure(fig_3_ah_handle);
        subplot(2,5,10);
        COM_Stats = plotMultiCom(traj_names, plt_p, p, plotFlag);
        currStatsTable = transferStatsToStatsTable(COM_Stats, currStatsTable);

        % ------- Area Under Curve (AUC) -------
        if isfield(reach_avg_each, 'auc') && isfield(reach_avg_each.auc, 'con')
            auc_con   = reach_avg_each.auc(iTraj).con(good_subs);
            auc_incon = reach_avg_each.auc(iTraj).incon(good_subs);
            [~, p_auc, ci_auc, stats_auc] = ttest(auc_con, auc_incon);
            auc_total = [];
            if isfield(reach_avg_each.auc(iTraj), 'total')
                auc_total = reach_avg_each.auc(iTraj).total(good_subs);
            end
            AUC_Stats = printStats('Area Under Curve (AUC)', auc_con, auc_incon, ["Con","Incon"], p_auc, ci_auc, stats_auc, auc_total);
            currStatsTable = transferStatsToStatsTable(AUC_Stats, currStatsTable);
        end
    end

    %% - Fig. 4 (Full-Trajectory Permutation Testing — Scoped Strictly to Relevant Features per Flavor)
    plt_p.errbar_type = 'ci';

    fullTraj_Stats = struct('name',[], ...
        'cluster',[], ...
        'start_time',[], ...
        'end_time',[], ...
        'cluster_size',[], ...
        'p_val',[], ...
        'cohens_dz',[], ...
        'tStar',[]);
    fullTraj_Stats_Table = struct2table(fullTraj_Stats);
    fullTraj_Stats_Table.Properties.VariableNames{end} = 't*';

    if ~p.NORM_TRAJ
        % --- Flavor: noTrajNorm_noStandardization (4 analyzed trajectory features, 1x4 Fig. 4) ---
        fig4Handle = figure('Name', sprintf('Figure 4 - %s', roundName), 'Color', 'w', ...
            'Position', [50, 200, 1750, 500], 'MenuBar', 'figure');
        tl4 = tiledlayout(fig4Handle, 1, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

        ax_f4_1 = nexttile(tl4, 1);
        fprintf('Average trajectory permutation (%s):\n', roundName);
        AVG_Trajectory_Clusters_Stats = plotMultiAvgTrajWithShade(traj_names, plt_p, p, true);
        title(ax_f4_1, '(a) Deviation From Center');
        fullTraj_Stats_Table = transferStatsToStatsTable(AVG_Trajectory_Clusters_Stats, fullTraj_Stats_Table);

        ax_f4_2 = nexttile(tl4, 2);
        fprintf('Implied endpoint permutation (%s):\n', roundName);
        IEP_Clusters_Stats = plotMultiIEP(traj_names, [], 0, plt_p, p);
        title(ax_f4_2, '(b) Implied End Point');
        fullTraj_Stats_Table = transferStatsToStatsTable(IEP_Clusters_Stats, fullTraj_Stats_Table);

        ax_f4_3 = nexttile(tl4, 3);
        fprintf('Movement variance along X-axis permutation (%s):\n', roundName);
        Xaxis_STD_Clusters_Stats = plotMultiXStd(traj_names, plt_p, p);
        title(ax_f4_3, '(c) Movement Variation');
        fullTraj_Stats_Table = transferStatsToStatsTable(Xaxis_STD_Clusters_Stats, fullTraj_Stats_Table);

        ax_f4_4 = nexttile(tl4, 4);
        fprintf('Heading angle permutation (%s):\n', roundName);
        HeadingAngle_Clusters_Stats = plotMultiHeadAngle(traj_names, plt_p, p, 'xangle', true);
        title(ax_f4_4, '(d) Heading Angle');
        fullTraj_Stats_Table = transferStatsToStatsTable(HeadingAngle_Clusters_Stats, fullTraj_Stats_Table);

        p.figureHandles.(roundName).fig4 = fig4Handle;
        p.figureHandles.Fig_4_Main       = fig4Handle;

    elseif ~p.NORMALIZE_WITHIN_SUB
        % --- Flavor: TrajNorm_noStandardization (3 valid trajectory features, 1x3 Fig. 4) ---
        fig4Handle = figure('Name', sprintf('Figure 4 - %s', roundName), 'Color', 'w', ...
            'Position', [50, 200, 1350, 500], 'MenuBar', 'figure');
        tl4 = tiledlayout(fig4Handle, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

        ax_f4_1 = nexttile(tl4, 1);
        fprintf('Average trajectory permutation (%s):\n', roundName);
        AVG_Trajectory_Clusters_Stats = plotMultiAvgTrajWithShade(traj_names, plt_p, p, true);
        title(ax_f4_1, '(a) Deviation From Center');
        fullTraj_Stats_Table = transferStatsToStatsTable(AVG_Trajectory_Clusters_Stats, fullTraj_Stats_Table);

        ax_f4_2 = nexttile(tl4, 2);
        fprintf('Implied endpoint permutation (%s):\n', roundName);
        IEP_Clusters_Stats = plotMultiIEP(traj_names, [], 0, plt_p, p);
        title(ax_f4_2, '(b) Implied End Point');
        fullTraj_Stats_Table = transferStatsToStatsTable(IEP_Clusters_Stats, fullTraj_Stats_Table);

        ax_f4_3 = nexttile(tl4, 3);
        fprintf('Movement variance along X-axis permutation (%s):\n', roundName);
        Xaxis_STD_Clusters_Stats = plotMultiXStd(traj_names, plt_p, p);
        title(ax_f4_3, '(c) Movement Variation');
        fullTraj_Stats_Table = transferStatsToStatsTable(Xaxis_STD_Clusters_Stats, fullTraj_Stats_Table);

        p.figureHandles.(roundName).fig4 = fig4Handle;

        % Silently compute Heading Angle cluster strictly for Figure S1 (2022 pre-reg audit tree)
        s1_ha_stats = plotMultiHeadAngle(traj_names, plt_p, p, 'xangle', false);
        statsTables.s1_prereg_head_angle_stats = s1_ha_stats;
    end
    % Note: TrajNorm_Standardization has bit-for-bit identical continuous trajectories to
    % TrajNorm_noStandardization, so full-trajectory permutation is not duplicated here.

    % Add Flavor column to fullTraj_Stats_Table
    if ~isempty(fullTraj_Stats_Table)
        fullTraj_Stats_Table = addvars(fullTraj_Stats_Table, repmat(string(roundName), height(fullTraj_Stats_Table), 1), ...
            'Before', 1, 'NewVariableNames', 'Flavor');
    end

    % --- Dynamically extract cluster windows and add summaries to currStatsTable ---
    dynamic_windows = struct();
    for iRow = 1:height(fullTraj_Stats_Table)
        meas_name = fullTraj_Stats_Table.name(iRow);
        st = fullTraj_Stats_Table.start_time(iRow);
        en = fullTraj_Stats_Table.end_time(iRow);

        data_con = [];
        data_incon = [];
        field_key = '';
        clean_base_name = '';

        if contains(meas_name, "Deviation From center", 'IgnoreCase', true)
            data_con = reach_avg_each.traj(iTraj).con(:, good_subs, 1);
            data_incon = reach_avg_each.traj(iTraj).incon(:, good_subs, 1);
            field_key = 'traj';
            clean_base_name = 'Deviation From Center';
        elseif contains(meas_name, "iEP", 'IgnoreCase', true)
            data_con = reach_avg_each.iep(iTraj).con(:, good_subs);
            data_incon = reach_avg_each.iep(iTraj).incon(:, good_subs);
            field_key = 'iep';
            clean_base_name = 'Implied End Point (IEP)';
        elseif contains(meas_name, "Heading angle", 'IgnoreCase', true)
            data_con = reach_avg_each.head_angle(iTraj).con(:, good_subs);
            data_incon = reach_avg_each.head_angle(iTraj).incon(:, good_subs);
            field_key = 'head_angle';
            clean_base_name = 'Heading Angle';
        elseif contains(meas_name, "Movement variation", 'IgnoreCase', true) || contains(meas_name, "X-axis", 'IgnoreCase', true)
            data_con = reach_avg_each.x_std(iTraj).con(:, good_subs);
            data_incon = reach_avg_each.x_std(iTraj).incon(:, good_subs);
            field_key = 'x_std';
            clean_base_name = 'Movement Variance (X-STD)';
        end

        if ~isempty(field_key)
            if ~isfield(dynamic_windows, field_key)
                dynamic_windows.(field_key) = [st, en];
            end

            is_multi = sum(fullTraj_Stats_Table.name == meas_name) > 1;
            cluster_suffix = '';
            if is_multi
                cluster_suffix = sprintf(' (Cluster %d)', fullTraj_Stats_Table.cluster(iRow));
            end

            if ~p.NORM_TRAJ
                ms_start = round(st * 10);
                ms_end   = round(en * 10);
                title_str = sprintf('%s%s [%d-%d samples, %d-%d ms]', clean_base_name, cluster_suffix, st, en, ms_start, ms_end);
            else
                pct_start = st / 2;
                pct_end   = en / 2;
                title_str = sprintf('%s%s [%d-%d points, %.1f-%.1f%% path]', clean_base_name, cluster_suffix, st, en, pct_start, pct_end);
            end

            sub_con   = mean(data_con(st:en, :), 1);
            sub_incon = mean(data_incon(st:en, :), 1);
            [~, p_win, ci_win, stats_win] = ttest(sub_con, sub_incon);
            if isfield(reach_avg_each, 'n_trials') && isfield(reach_avg_each.n_trials, 'con')
                n_con_sub = reach_avg_each.n_trials(iTraj).con(good_subs);
                n_incon_sub = reach_avg_each.n_trials(iTraj).incon(good_subs);
                sub_total = (n_con_sub .* sub_con + n_incon_sub .* sub_incon) ./ (n_con_sub + n_incon_sub);
            else
                sub_total = (sub_con + sub_incon) / 2;
            end
            win_stats = printStats(title_str, sub_con, sub_incon, ["Con","Incon"], p_win, ci_win, stats_win, sub_total);
            currStatsTable = transferStatsToStatsTable(win_stats, currStatsTable);
        end
    end

    figureHandles = p.figureHandles;
    statsTables.(roundName) = currStatsTable;
    statsTables.dynamic_trajectory_windows.(roundName) = dynamic_windows;

    % If dynamic_windows is empty (e.g. TrajNorm_Standardization), inherit from TrajNorm_noStandardization if available
    if isempty(fieldnames(dynamic_windows)) && isfield(statsTables, 'dynamic_trajectory_windows') && isfield(statsTables.dynamic_trajectory_windows, 'TrajNorm_noStandardization')
        dynamic_windows = statsTables.dynamic_trajectory_windows.TrajNorm_noStandardization;
    end

    % Build participant-level statistics table
    part_table = build_participant_measures_table(roundName, p.PROC_DATA_FOLDER, good_subs, reach_avg_each, keyboard_avg_each, reach_area, dynamic_windows, p);
    statsTables.Participant_Measures.(roundName) = part_table;

    if ~isempty(fullTraj_Stats_Table)
        if isfield(statsTables, 'fullTrajAnalysis') && istable(statsTables.fullTrajAnalysis)
            statsTables.fullTrajAnalysis = [statsTables.fullTrajAnalysis; fullTraj_Stats_Table];
        else
            statsTables.fullTrajAnalysis = fullTraj_Stats_Table;
        end
    end
end
