function [effects_tbl, within_tbl, cross_tbl] = bootstrap_effect_sizes(rawAggData, fields_to_analyze, cond1, cond2, cross_flavor_pairs, trajectory_windows, n_bootstraps, good_subs)

    flavors = fieldnames(rawAggData);
    num_flavors = length(flavors);
    num_valid = length(good_subs);
    
    % The SINGLE master matrix of bootstrap indices for universal synchronization
    master_boot_indices = randi(num_valid, num_valid, n_bootstraps);
    
    dist_store = struct();       
    actual_dzs_store = struct(); 
    
    %% 1. Calculate Individual Effect Sizes
    total_effects = num_flavors * length(fields_to_analyze);
    flavor_names  = strings(total_effects, 1);
    effect_names  = strings(total_effects, 1);
    raw_mean_diffs = NaN(total_effects, 1);
    raw_sd_diffs   = NaN(total_effects, 1);
    actual_dzs    = NaN(total_effects, 1);
    ci_lowers     = NaN(total_effects, 1);
    ci_uppers     = NaN(total_effects, 1);
    
    idx = 1;
    for iF = 1:num_flavors
        flavor = flavors{iF};
        for iField = 1:length(fields_to_analyze)
            f = fields_to_analyze{iField};
            
            % Extract raw data first
            if startsWith(f, 'kb_')
                f_clean = strrep(f, 'kb_', '');
                data1_raw = rawAggData.(flavor).keyboard.(f_clean)(1).(cond1);
                data2_raw = rawAggData.(flavor).keyboard.(f_clean)(1).(cond2);
            elseif strcmp(f, 'traj')
                % If traj is a 3D matrix (time x sub x axis), extract ONLY the X-axis (index 1)
                data1_raw = rawAggData.(flavor).reach.traj(1).(cond1)(:, :, 1);
                data2_raw = rawAggData.(flavor).reach.traj(1).(cond2)(:, :, 1);
            else
                data1_raw = rawAggData.(flavor).reach.(f)(1).(cond1);
                data2_raw = rawAggData.(flavor).reach.(f)(1).(cond2);
            end
            
            % Find the total number of subjects in the raw data
            num_total_subs = max(size(rawAggData.(flavor).reach.rt(1).con));
            
            % If subjects are currently columns, transpose the matrix so subjects are rows!
            if size(data1_raw, 2) == num_total_subs
                data1_raw = data1_raw';
                data2_raw = data2_raw';
            end
            
            % Now it is perfectly safe to extract our valid subjects from the rows
            data1 = data1_raw(good_subs, :);
            data2 = data2_raw(good_subs, :);
            
            % Handle Trajectory Window Averaging (Match permCluster logic)
            if isfield(trajectory_windows, f)
                win = trajectory_windows.(f);
                % Extract just the time window, but DO NOT average across time yet!
                data1 = data1(:, win(1):win(2));
                data2 = data2(:, win(1):win(2));
            elseif size(data1, 2) > 1
                warning('Field %s is a time-series but no window was provided in trajectory_windows. Using ALL timepoints.', f);
                % Keep all timepoints, no averaging yet.
            end
            
            % Calculate actual raw differences
            diff_actual = data1 - data2;
            
            % Calculate per-timepoint means and SDs
            mean_diff_per_time = mean(diff_actual, 1, 'omitnan');
            sd_diff_per_time = std(diff_actual, 0, 1, 'omitnan');
            
            % Calculate per-timepoint dz, THEN average them (just like permCluster)
            dz_per_time = mean_diff_per_time ./ sd_diff_per_time;
            
            % Aggregate across timepoints for the final scalar values in the table
            mean_diff = mean(mean_diff_per_time, 'omitnan');
            sd_diff = mean(sd_diff_per_time, 'omitnan');
            actual_dz = abs(mean(dz_per_time, 'omitnan'));
            
            actual_dzs_store.(flavor).(f) = actual_dz;
            
            % Run Bootstrap and store distribution
            dist = bootCohenDz(data1, data2, master_boot_indices);
            dist_store.(flavor).(f) = dist;
            
            % Store for the table
            flavor_names(idx)   = string(flavor);
            effect_names(idx)   = string(f);
            raw_mean_diffs(idx) = mean_diff;
            raw_sd_diffs(idx)   = sd_diff;
            actual_dzs(idx)     = actual_dz;
            ci_lowers(idx)      = prctile(dist, 2.5);
            ci_uppers(idx)      = prctile(dist, 97.5);
            idx = idx + 1;
        end
    end
    
    effects_tbl = table(flavor_names, effect_names, raw_mean_diffs, raw_sd_diffs, actual_dzs, ci_lowers, ci_uppers, ...
        'VariableNames', {'Flavor', 'Effect', 'Actual_Diff', 'SD_Act_Diff', 'Actual_dz', 'CI_Lower', 'CI_Upper'});
    fprintf('\n--- Individual Effect Sizes (Absolute, 95%% CI) ---\n');
    disp(effects_tbl);
    
    %% 2. Within-Flavor Comparisons
    pair_indices = nchoosek(1:length(fields_to_analyze), 2);
    total_within = num_flavors * size(pair_indices, 1);
    
    wf_flavor_names = strings(total_within, 1);
    wf_comp_names   = strings(total_within, 1);
    wf_actual_diffs = NaN(total_within, 1);
    wf_ci_lowers    = NaN(total_within, 1);
    wf_ci_uppers    = NaN(total_within, 1);
    wf_p_values     = NaN(total_within, 1);
    
    idx = 1;
    for iF = 1:num_flavors
        flavor = flavors{iF};
        for p = 1:size(pair_indices, 1)
            fA = fields_to_analyze{pair_indices(p, 1)};
            fB = fields_to_analyze{pair_indices(p, 2)};
            
            dzA = actual_dzs_store.(flavor).(fA);
            dzB = actual_dzs_store.(flavor).(fB);
            
            % Ensure difference is positive (Larger - Smaller)
            if dzA >= dzB
                larger_f = fA; smaller_f = fB;
            else
                larger_f = fB; smaller_f = fA;
            end
            
            actual_diff = actual_dzs_store.(flavor).(larger_f) - actual_dzs_store.(flavor).(smaller_f);
            diff_dist = dist_store.(flavor).(larger_f) - dist_store.(flavor).(smaller_f);
            
            wf_flavor_names(idx) = string(flavor);
            wf_comp_names(idx)   = sprintf('%s_minus_%s', larger_f, smaller_f);
            wf_actual_diffs(idx) = actual_diff;
            wf_ci_lowers(idx)    = prctile(diff_dist, 2.5);
            wf_ci_uppers(idx)    = prctile(diff_dist, 97.5);
            wf_p_values(idx)     = min(sum(diff_dist > 0), sum(diff_dist < 0)) / n_bootstraps * 2;
            idx = idx + 1;
        end
    end
    
    within_tbl = table(wf_flavor_names, wf_comp_names, wf_actual_diffs, wf_ci_lowers, wf_ci_uppers, wf_p_values, ...
        'VariableNames', {'Flavor', 'Comparison', 'Actual_dz_Diff', 'CI_Lower', 'CI_Upper', 'P_Value'});
    fprintf('\n--- Within-Flavor Pairwise Comparisons ---\n');
    disp(within_tbl);
    
    %% 3. Cross-Flavor Comparisons (Explicit List)
    num_cross = length(cross_flavor_pairs);
    cf_comp_names   = strings(num_cross, 1);
    cf_actual_diffs = NaN(num_cross, 1);
    cf_ci_lowers    = NaN(num_cross, 1);
    cf_ci_uppers    = NaN(num_cross, 1);
    cf_p_values     = NaN(num_cross, 1);
    
    for c = 1:num_cross
        pair = cross_flavor_pairs{c};
        fA = pair{1}{1}; flavA = matlab.lang.makeValidName(pair{1}{2});
        fB = pair{2}{1}; flavB = matlab.lang.makeValidName(pair{2}{2});
        
        dzA = actual_dzs_store.(flavA).(fA);
        dzB = actual_dzs_store.(flavB).(fB);
        
        % Ensure difference is positive
        if dzA >= dzB
            larger_f = fA; larger_flav = flavA; smaller_f = fB; smaller_flav = flavB;
        else
            larger_f = fB; larger_flav = flavB; smaller_f = fA; smaller_flav = flavA;
        end
        
        actual_diff = actual_dzs_store.(larger_flav).(larger_f) - actual_dzs_store.(smaller_flav).(smaller_f);
        diff_dist = dist_store.(larger_flav).(larger_f) - dist_store.(smaller_flav).(smaller_f);
        
        cf_comp_names(c)   = string(sprintf('%s(%s) _minus_ %s(%s)', larger_f, larger_flav, smaller_f, smaller_flav));
        cf_actual_diffs(c) = actual_diff;
        cf_ci_lowers(c)    = prctile(diff_dist, 2.5);
        cf_ci_uppers(c)    = prctile(diff_dist, 97.5);
        cf_p_values(c)     = min(sum(diff_dist > 0), sum(diff_dist < 0)) / n_bootstraps * 2;
    end
    
    if num_cross > 0
        cross_tbl = table(cf_comp_names, cf_actual_diffs, cf_ci_lowers, cf_ci_uppers, cf_p_values, ...
            'VariableNames', {'Comparison', 'Actual_dz_Diff', 'CI_Lower', 'CI_Upper', 'P_Value'});
        fprintf('\n--- Cross-Flavor Explicit Comparisons ---\n');
        disp(cross_tbl);
    else
        cross_tbl = table();
    end
end

function [boot_dz] = bootCohenDz(data1, data2, boot_indices)
    differences = data1 - data2;
    n_boots = size(boot_indices, 2);
    T = size(differences, 2);
    
    if T == 1
        % 1D case (scalar variables like RT, MT, MAD)
        boot_samples = differences(boot_indices);
        boot_means = mean(boot_samples, 1, 'omitnan');
        boot_stds  = std(boot_samples, 0, 1, 'omitnan');
        boot_dz    = abs(boot_means ./ boot_stds);
    else
        % 2D case (time-series like trajectories)
        boot_dz_per_time = zeros(T, n_boots);
        for t = 1:T
            diff_t = differences(:, t); % Extract specific timepoint (N x 1 vector)
            boot_samples_t = diff_t(boot_indices); % N x B bootstrap matrix
            
            boot_means = mean(boot_samples_t, 1, 'omitnan');
            boot_stds  = std(boot_samples_t, 0, 1, 'omitnan');
            boot_dz_per_time(t, :) = boot_means ./ boot_stds;
        end
        % Average the dz values across time, THEN take absolute
        boot_dz = abs(mean(boot_dz_per_time, 1, 'omitnan'));
    end
end