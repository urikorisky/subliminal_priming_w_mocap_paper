function [effects_tbl, within_tbl] = bootstrap_effect_sizes(rawAggData, ~, cond1, cond2, trajectory_windows, n_bootstraps, good_subs)
% BOOTSTRAP_EFFECT_SIZES Computes bootstrap standardized effect sizes (Cohen's dz / Dependent AKP)
% and within-flavor pairwise contrasts strictly for the valid metrics of each flavor:
%   - noTrajNorm_noStandardization: 4 full-trajectory features (traj, iep, head_angle, x_std)
%     (contrasted against raw kb_rt baseline solely for Component 6 peak sensitivity contrasts)
%   - TrajNorm_noStandardization: 8 discrete variables + 3 valid trajectory features (traj, iep, x_std)
%   - TrajNorm_Standardization: 8 standardized discrete variables
%     (reusing TrajNorm_noStandardization's identical trajectory cluster distributions in within_tbl
%      solely for Figure S2b sensitivity contrasts against standardized kb_rt)

    flavors = fieldnames(rawAggData);
    num_valid = length(good_subs);

    rng(42, 'twister');
    master_boot_indices = randi(num_valid, num_valid, n_bootstraps);

    discrete_fields = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'};

    dist_store       = struct();
    actual_dzs_store = struct();

    eff_rows = {};

    %% 1. Calculate Individual Effect Sizes per Flavor (Strictly Scoped)
    % Manuscript order: Flavor 1 (TrajNorm_noStandardization), Flavor 2 (TrajNorm_Standardization),
    % Flavor 3 (noTrajNorm_noStandardization). Note Flavor 1 precedes Flavor 2 so shared trajectory
    % cluster distributions are ready for Figure S2b contrasts.
    ordered_flavors = {'TrajNorm_noStandardization', 'TrajNorm_Standardization', 'noTrajNorm_noStandardization'};
    ordered_flavors = intersect(ordered_flavors, flavors, 'stable');

    for iF = 1:length(ordered_flavors)
        flavor = ordered_flavors{iF};

        switch flavor
            case 'noTrajNorm_noStandardization'
                % Report ONLY valid full-trajectory features in effects_tbl;
                % compute kb_rt internally in dist_store strictly for Component 6 contrasts.
                report_fields   = {'traj', 'iep', 'head_angle', 'x_std'};
                internal_fields = {'kb_rt', 'traj', 'iep', 'head_angle', 'x_std'};
            case 'TrajNorm_noStandardization'
                report_fields   = [discrete_fields, {'traj', 'iep', 'x_std'}];
                internal_fields = report_fields;
            case 'TrajNorm_Standardization'
                report_fields   = discrete_fields;
                internal_fields = discrete_fields;
            otherwise
                report_fields   = discrete_fields;
                internal_fields = discrete_fields;
        end

        for iField = 1:length(internal_fields)
            f = internal_fields{iField};

            if startsWith(f, 'kb_')
                f_clean = strrep(f, 'kb_', '');
                data1_raw = rawAggData.(flavor).keyboard.(f_clean)(1).(cond1);
                data2_raw = rawAggData.(flavor).keyboard.(f_clean)(1).(cond2);
            elseif strcmp(f, 'traj')
                data1_raw = rawAggData.(flavor).reach.traj(1).(cond1)(:, :, 1);
                data2_raw = rawAggData.(flavor).reach.traj(1).(cond2)(:, :, 1);
            else
                data1_raw = rawAggData.(flavor).reach.(f)(1).(cond1);
                data2_raw = rawAggData.(flavor).reach.(f)(1).(cond2);
            end

            num_total_subs = max(size(rawAggData.(flavor).reach.react(1).con));
            if size(data1_raw, 2) == num_total_subs
                data1_raw = data1_raw';
                data2_raw = data2_raw';
            end

            data1 = data1_raw(good_subs, :);
            data2 = data2_raw(good_subs, :);

            % Handle Trajectory Window Averaging (Dynamic per-flavor cluster windows)
            win = [];
            if isfield(trajectory_windows, flavor) && isfield(trajectory_windows.(flavor), f)
                win = trajectory_windows.(flavor).(f);
            end

            if ~isempty(win)
                data1 = data1(:, win(1):win(2));
                data2 = data2(:, win(1):win(2));
            elseif size(data1, 2) > 1
                % No significant cluster detected for this trajectory metric in this flavor:
                % skip reporting a spurious un-windowed effect size if no cluster exists!
                if strcmp(flavor, 'noTrajNorm_noStandardization')
                    continue;
                end
            end

            diff_actual = data1 - data2;
            mean_diff_per_time = mean(diff_actual, 1, 'omitnan');
            sd_diff_per_time   = std(diff_actual, 0, 1, 'omitnan');
            dz_per_time        = mean_diff_per_time ./ sd_diff_per_time;

            mean_diff    = mean(mean_diff_per_time, 'omitnan');
            sd_diff      = mean(sd_diff_per_time, 'omitnan');
            cohen_dz_val = abs(mean(dz_per_time, 'omitnan'));

            if size(diff_actual, 2) == 1
                q1 = prctile(diff_actual, 25);
                q3 = prctile(diff_actual, 75);
                iqr_val = q3 - q1;
                has_outliers = any(diff_actual < (q1 - 1.5 * iqr_val) | diff_actual > (q3 + 1.5 * iqr_val));
                dep_akp_val = abs(calc_dependent_akp(data1, data2));
            else
                has_outliers = false;
                dep_akp_val  = cohen_dz_val;
            end

            if has_outliers
                reported_eff = dep_akp_val;
                metric_name  = "Dependent_AKP";
                dist = bootDependentAKP(data1, data2, master_boot_indices);
            else
                reported_eff = cohen_dz_val;
                metric_name  = "Cohen_dz";
                dist = bootCohenDz(data1, data2, master_boot_indices);
            end

            actual_dzs_store.(flavor).(f) = reported_eff;
            dist_store.(flavor).(f)       = dist;

            if ismember(f, report_fields)
                eff_rows = [eff_rows; { ...
                    string(flavor), string(f), metric_name, has_outliers, ...
                    mean_diff, sd_diff, reported_eff, cohen_dz_val, dep_akp_val, ...
                    prctile(dist, 2.5), prctile(dist, 97.5) ...
                }]; %#ok<AGROW>
            end
        end

        % For TrajNorm_Standardization, reuse TrajNorm_noStandardization's identical trajectory
        % cluster distributions in dist_store solely for Figure S2b contrasts against standardized kb_rt
        if strcmp(flavor, 'TrajNorm_Standardization') && isfield(dist_store, 'TrajNorm_noStandardization')
            for tr_cell = {'traj', 'iep', 'x_std'}
                tr_f = tr_cell{1};
                if isfield(dist_store.TrajNorm_noStandardization, tr_f)
                    actual_dzs_store.(flavor).(tr_f) = actual_dzs_store.TrajNorm_noStandardization.(tr_f);
                    dist_store.(flavor).(tr_f)       = dist_store.TrajNorm_noStandardization.(tr_f);
                end
            end
        end
    end

    effects_tbl = cell2table(eff_rows, 'VariableNames', { ...
        'Flavor', 'Effect', 'Metric_Used', 'Has_Outliers', 'Mean_Diff', 'SD_Diff', ...
        'Reported_Effect_Size', 'Cohens_dz', 'Dependent_AKP', 'CI_Lower', 'CI_Upper'});

    fprintf('\n--- Individual Effect Sizes (Absolute, 95%% CI) ---\n');
    disp(effects_tbl);

    %% 2. Within-Flavor Pairwise Comparisons (Strictly Scoped)
    within_rows = {};

    for iF = 1:length(ordered_flavors)
        flavor = ordered_flavors{iF};
        avail_fields = fieldnames(actual_dzs_store.(flavor));

        if strcmp(flavor, 'noTrajNorm_noStandardization')
            % Only contrasts of detected chronological trajectory clusters against kb_rt
            traj_only = setdiff(avail_fields, {'kb_rt'}, 'stable');
            pairs = cell(numel(traj_only), 2);
            for k = 1:numel(traj_only)
                pairs{k, 1} = traj_only{k};
                pairs{k, 2} = 'kb_rt';
            end
        else
            if numel(avail_fields) < 2, continue; end
            p_idx = nchoosek(1:numel(avail_fields), 2);
            pairs = cell(size(p_idx, 1), 2);
            for k = 1:size(p_idx, 1)
                pairs{k, 1} = avail_fields{p_idx(k, 1)};
                pairs{k, 2} = avail_fields{p_idx(k, 2)};
            end
        end

        for p = 1:size(pairs, 1)
            fA = pairs{p, 1};
            fB = pairs{p, 2};

            % In TrajNorm_Standardization, borrowed trajectory clusters are only contrasted against kb_rt (for Figure S2b)
            if strcmp(flavor, 'TrajNorm_Standardization') && ...
               (ismember(fA, {'traj','iep','x_std'}) || ismember(fB, {'traj','iep','x_std'})) && ...
               ~(strcmp(fA, 'kb_rt') || strcmp(fB, 'kb_rt'))
                continue;
            end

            dzA = actual_dzs_store.(flavor).(fA);
            dzB = actual_dzs_store.(flavor).(fB);

            if dzA >= dzB
                larger_f = fA; smaller_f = fB;
            else
                larger_f = fB; smaller_f = fA;
            end

            actual_diff = actual_dzs_store.(flavor).(larger_f) - actual_dzs_store.(flavor).(smaller_f);
            diff_dist   = dist_store.(flavor).(larger_f) - dist_store.(flavor).(smaller_f);
            p_val_2s    = min(sum(diff_dist > 0), sum(diff_dist < 0)) / n_bootstraps * 2;

            within_rows = [within_rows; { ...
                string(flavor), ...
                string(sprintf('%s_minus_%s', larger_f, smaller_f)), ...
                actual_diff, ...
                prctile(diff_dist, 2.5), ...
                prctile(diff_dist, 97.5), ...
                p_val_2s ...
            }]; %#ok<AGROW>
        end
    end

    within_tbl = cell2table(within_rows, 'VariableNames', { ...
        'Flavor', 'Comparison', 'Effect_Size_Diff', 'CI_Lower', 'CI_Upper', 'P_Value'});

    fprintf('\n--- Within-Flavor Pairwise Comparisons ---\n');
    disp(within_tbl);
end

function [boot_dz] = bootCohenDz(data1, data2, boot_indices)
    differences = data1 - data2;
    n_boots = size(boot_indices, 2);
    T = size(differences, 2);

    if T == 1
        boot_samples = differences(boot_indices);
        boot_means   = mean(boot_samples, 1, 'omitnan');
        boot_stds    = std(boot_samples, 0, 1, 'omitnan');
        boot_dz      = abs(boot_means ./ boot_stds);
    else
        boot_dz_per_time = zeros(T, n_boots);
        for t = 1:T
            diff_t = differences(:, t);
            boot_samples_t = diff_t(boot_indices);
            boot_means = mean(boot_samples_t, 1, 'omitnan');
            boot_stds  = std(boot_samples_t, 0, 1, 'omitnan');
            boot_dz_per_time(t, :) = boot_means ./ boot_stds;
        end
        boot_dz = abs(mean(boot_dz_per_time, 1, 'omitnan'));
    end
    boot_dz = boot_dz(:);
end

function [boot_dakp] = bootDependentAKP(data1, data2, boot_indices)
    differences = data1 - data2;
    n_boots = size(boot_indices, 2);
    T = size(differences, 2);

    if T == 1
        boot_dakp = zeros(n_boots, 1);
        n = size(differences, 1);
        tr = 0.20;
        g = floor(tr * n);
        z_tr = norminv(1 - tr);
        phi_z = normpdf(z_tr);
        cterm = sqrt((erf(z_tr / sqrt(2)) - 2 * z_tr * phi_z) + 2 * (z_tr^2) * tr);

        for b = 1:n_boots
            bd = differences(boot_indices(:, b));
            sbd = sort(bd);
            win = bd;
            win(win <= sbd(g + 1)) = sbd(g + 1);
            win(win >= sbd(end - g)) = sbd(end - g);
            sw = std(win);
            if sw > 0
                boot_dakp(b) = abs(cterm * trimmean(bd, 2 * tr * 100) / sw);
            else
                boot_dakp(b) = NaN;
            end
        end
    else
        boot_dakp = bootCohenDz(data1, data2, boot_indices);
    end
    boot_dakp = boot_dakp(:);
end
