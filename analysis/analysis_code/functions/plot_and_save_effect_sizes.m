function plot_and_save_effect_sizes(effects_tbl, within_tbl, cross_tbl)
    %% Generate Horizontal Whisker Plots and Save Data
    
    out_dir_stats = '../statistics/';
    out_dir_figs = fullfile('../figures/', 'Effect_Sizes');
    if ~exist(out_dir_stats, 'dir'), mkdir(out_dir_stats); end
    if ~exist(out_dir_figs, 'dir'), mkdir(out_dir_figs); end
    
    % Define human-readable names
    readable_names = containers.Map(...
        {'rt', 'react', 'mt', 'mad', 'com', 'tot_dist', 'auc', 'max_vel', 'ra', 'kb_rt', 'head_angle', 'iep', 'traj', 'x_std', 'vel'}, ...
        {'Reaction Time', 'Reach RT', 'Movement Time', 'Maximum Absolute Deviation (MAD)', 'Change of Mind (COM)', ...
         'Total Distance', 'Area Under Curve (AUC)', 'Maximum Velocity', 'Reach Area', 'Keyboard RT', ...
         'Head Angle', 'IEP', 'Trajectory', 'X-axis STD', 'Velocity'});
    
    flavors = unique(effects_tbl.Flavor);
    
    %% Plot 1: Effect sizes per flavor
    for iF = 1:length(flavors)
        f = string(flavors(iF));
        idx = effects_tbl.Flavor == f;
        sub_tbl = effects_tbl(idx, :);
        
        fig = figure('Name', sprintf('Effect Sizes for %s', f), 'Position', [100 100 800 600]);
        hold on;
        
        y = 1:height(sub_tbl);
        vars = sub_tbl.Effect;
        
        % Map to readable names
        readable_vars = strings(length(vars), 1);
        for v = 1:length(vars)
            if isKey(readable_names, char(vars(v)))
                readable_vars(v) = readable_names(char(vars(v)));
            else
                readable_vars(v) = strrep(char(vars(v)), '_', ' ');
            end
        end
        
        err_neg = sub_tbl.Reported_Effect_Size - sub_tbl.CI_Lower;
        err_pos = sub_tbl.CI_Upper - sub_tbl.Reported_Effect_Size;
        
        errorbar(sub_tbl.Reported_Effect_Size, y, err_neg, err_pos, 'horizontal', 'o', ...
            'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'CapSize', 10);
        
        set(gca, 'YTick', y, 'YTickLabel', readable_vars, 'FontSize', 12);
        xlabel('Standardized Effect Size (d_z / Dependent AKP)', 'FontSize', 14);
        
        title_str = strrep(f, '_', ' ');
        title(sprintf('Standardized Effect Sizes - %s', title_str), 'FontSize', 16, 'Interpreter', 'none');
        
        % Add text labels
        for j = 1:length(y)
            % Format without 0 for values > 1 or <-1
            val_str = sprintf('%.2f', sub_tbl.Reported_Effect_Size(j));
            low_str = sprintf('%.2f', sub_tbl.CI_Lower(j));
            up_str = sprintf('%.2f', sub_tbl.CI_Upper(j));
            
            val_str = strrep(val_str, '0.', '.'); val_str = strrep(val_str, '-0.', '-.');
            low_str = strrep(low_str, '0.', '.'); low_str = strrep(low_str, '-0.', '-.');
            up_str = strrep(up_str, '0.', '.'); up_str = strrep(up_str, '-0.', '-.');
            
            txt = sprintf('%s [%s, %s]', val_str, low_str, up_str);
            text(sub_tbl.CI_Upper(j) + 0.05, y(j), txt, 'VerticalAlignment', 'middle', 'FontSize', 10);
        end
        grid on;
        
        % Save Plot 1
        saveas(fig, fullfile(out_dir_figs, sprintf('Effect_Sizes_%s.fig', f)));
        saveas(fig, fullfile(out_dir_figs, sprintf('Effect_Sizes_%s.png', f)));
        saveas(fig, fullfile(out_dir_figs, sprintf('Effect_Sizes_%s.svg', f)));
    end
    
    %% Plot 2: Effect Size difference vs KB_RT across ALL flavors
    kb_idx = contains(within_tbl.Comparison, 'kb_rt');
    kb_tbl = within_tbl(kb_idx, :);
    
    fig2 = figure('Name', 'Effect Size Differences vs KB_RT', 'Position', [100 100 1200 800]);
    hold on;
    y = 1:height(kb_tbl); % fallback for limits if needed
    
    flavors_kb = unique(kb_tbl.Flavor, 'stable');
    
    actual_diff_array = zeros(height(kb_tbl), 1);
    ci_lower_array = zeros(height(kb_tbl), 1);
    ci_upper_array = zeros(height(kb_tbl), 1);
    y_positions = zeros(height(kb_tbl), 1);
    y_labels = cell(height(kb_tbl), 1);
    p_values_array = zeros(height(kb_tbl), 1);
    
    bg_colors = [0.95 0.95 0.95; 0.9 0.95 1; 0.95 1 0.95; 1 0.95 0.9];
    
    y_current = 0;
    
    for iF = length(flavors_kb):-1:1
        f = string(flavors_kb(iF));
        idx = find(kb_tbl.Flavor == f);
        
        y_current = y_current + 1;
        y_bottom = y_current - 0.5;
        
        y_positions(idx) = (y_current + length(idx) - 1) : -1 : y_current;
        y_current = y_current + length(idx) - 1;
        
        y_top = y_current + 0.5;
        
        patch([-10 10 10 -10], [y_bottom y_bottom y_top y_top], bg_colors(mod(iF-1, size(bg_colors,1))+1, :), 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        
        y_current = y_current + 1;
        title_y = y_current;
        
        flav_clean = strrep(f, '_', ' ');
        text(0, title_y, flav_clean, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);
        
        y_current = y_current + 0.5;
    end
    
    for j = 1:height(kb_tbl)
        comp_parts = split(kb_tbl.Comparison(j), '_minus_');
        if strcmp(comp_parts{1}, 'kb_rt')
            var_name = comp_parts{2};
            actual_diff_array(j) = -kb_tbl.Effect_Size_Diff(j);
            ci_lower_array(j) = -kb_tbl.CI_Upper(j);
            ci_upper_array(j) = -kb_tbl.CI_Lower(j);
        else
            var_name = comp_parts{1};
            actual_diff_array(j) = kb_tbl.Effect_Size_Diff(j);
            ci_lower_array(j) = kb_tbl.CI_Lower(j);
            ci_upper_array(j) = kb_tbl.CI_Upper(j);
        end
        p_values_array(j) = kb_tbl.P_Value(j);
        
        if isKey(readable_names, char(var_name))
            var_clean = readable_names(char(var_name));
        else
            var_clean = strrep(char(var_name), '_', ' ');
        end
        y_labels{j} = char(var_clean);
    end
    
    err_neg = actual_diff_array - ci_lower_array;
    err_pos = ci_upper_array - actual_diff_array;
    
    errorbar(actual_diff_array, y_positions, err_neg, err_pos, 'horizontal', 'o', ...
        'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'Color', 'r', 'CapSize', 10);
    
    [sorted_y, sort_idx] = sort(y_positions);
    sorted_labels = y_labels(sort_idx);
    set(gca, 'YTick', sorted_y, 'YTickLabel', sorted_labels, 'FontSize', 10);
    ylim([0 y_current]);
    xlabel('\Delta Standardized Effect Size (Variable - KB RT)', 'FontSize', 14);
    title('Effect Size Differences Compared to KB RT', 'FontSize', 16);
    xline(0, 'k--', 'LineWidth', 1.5);
    
    for j = 1:height(kb_tbl)
        val_str = sprintf('%.2f', actual_diff_array(j));
        low_str = sprintf('%.2f', ci_lower_array(j));
        up_str = sprintf('%.2f', ci_upper_array(j));
        
        val_str = strrep(val_str, '0.', '.'); val_str = strrep(val_str, '-0.', '-.');
        low_str = strrep(low_str, '0.', '.'); low_str = strrep(low_str, '-0.', '-.');
        up_str = strrep(up_str, '0.', '.'); up_str = strrep(up_str, '-0.', '-.');
        
        p_val_str = sprintf('p=%.3f', p_values_array(j));
        p_val_str = strrep(p_val_str, 'p=0.', 'p=.');
        
        txt = sprintf('%s [%s, %s], %s', val_str, low_str, up_str, p_val_str);
        
        % Always place text to the right of the CI
        text(ci_upper_array(j) + 0.05, y_positions(j), txt, 'VerticalAlignment', 'middle', 'FontSize', 10);
    end
    grid on;
    
    % Adjust X-axis limits to tightly fit the data and text (while ignoring NaNs)
    min_x = min(ci_lower_array, [], 'omitnan') - 0.2;
    max_x = max(ci_upper_array, [], 'omitnan') + 1.4;
    xlim([min_x, max_x]);
    
    % Save Plot 2
    saveas(fig2, fullfile(out_dir_figs, 'dz_Differences_vs_KB_RT.fig'));
    saveas(fig2, fullfile(out_dir_figs, 'dz_Differences_vs_KB_RT.png'));
    saveas(fig2, fullfile(out_dir_figs, 'dz_Differences_vs_KB_RT.svg'));
    
    %% Save Tables
    writetable(effects_tbl, fullfile(out_dir_stats, 'Effect_Sizes_Table.csv'));
    writetable(within_tbl, fullfile(out_dir_stats, 'Within_Flavor_Comparisons.csv'));
    writetable(cross_tbl, fullfile(out_dir_stats, 'Cross_Flavor_Comparisons.csv'));
    
    writetable(effects_tbl, fullfile(out_dir_stats, 'Effect_Sizes_Table.xlsx'));
    writetable(within_tbl, fullfile(out_dir_stats, 'Within_Flavor_Comparisons.xlsx'));
    writetable(cross_tbl, fullfile(out_dir_stats, 'Cross_Flavor_Comparisons.xlsx'));
    
    save(fullfile(out_dir_stats, 'Bootstrap_Stats_Tables.mat'), 'effects_tbl', 'within_tbl', 'cross_tbl');
    disp('All plots and tables successfully saved!');
end