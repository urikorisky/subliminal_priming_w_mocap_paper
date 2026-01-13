function final_table = extract_relevant_statistics(full_stats_tables, config_file)
% EXTRACT_RELEVANT_STATISTICS merges stats from specified Analysis Types.
%
%   Assumes 'full_stats_tables' contains fields that are MATLAB Tables 
%   (e.g., full_stats_tables.noTrajNorm_noStandardization is a Table).
%
%   Input Config CSV Columns:
%   - Statistic
%   - Descriptive_Type
%   - Comparative_Type

    % 1. Load Configuration
    if nargin < 2
        config_file = 'stats_config.csv';
    end
    
    if ~isfile(config_file)
        error('Configuration file "%s" not found.', config_file);
    end
    
    opts = detectImportOptions(config_file);
    opts.VariableTypes = {'string', 'string', 'string'}; 
    config = readtable(config_file, opts);
    
    required_cols = {'Statistic', 'Descriptive_Type', 'Comparative_Type'};
    if ~all(ismember(required_cols, config.Properties.VariableNames))
        error('CSV must contain columns: Statistic, Descriptive_Type, Comparative_Type');
    end

    % 2. Define Comparative Fields to Overwrite
    % We take these values from the Comparative table, overwriting the Descriptive table values.
    comp_fields_to_overwrite = {'tVal', 'pVal', 'df', ...
                                't_SD', 'cohens_d_z', 'diff_relative_std'};

    final_table = table();

    % 3. Iterate through config rows
    for i = 1:height(config)
        stat_name = config.Statistic(i);
        desc_type = config.Descriptive_Type(i);
        comp_type = config.Comparative_Type(i);
        
        % Validate that the tables exist in the struct
        if ~isfield(full_stats_tables, desc_type)
            warning('Descriptive table "%s" not found in data.', desc_type);
            continue;
        end
        if ~isfield(full_stats_tables, comp_type)
            warning('Comparative table "%s" not found in data.', comp_type);
            continue;
        end
        
        % --- Step A: Get Descriptive Base Row ---
        desc_table = full_stats_tables.(desc_type);
        
        % Find the row index where 'name' matches the statistic
        % ismember is robust for both string arrays and cell arrays of chars
        idx_desc = find(ismember(desc_table.name, stat_name), 1);
        
        if isempty(idx_desc)
            warning('Statistic "%s" not found in table "%s".', stat_name, desc_type);
            continue;
        end
        
        % Extract the base row (keeps all original columns like con_avg, incon_avg)
        row_table = desc_table(idx_desc, :);
        
        
        % --- Step B: Get Comparative Data & Overwrite ---
        comp_table = full_stats_tables.(comp_type);
        idx_comp = find(ismember(comp_table.name, stat_name), 1);
        
        if ~isempty(idx_comp)
            comp_row = comp_table(idx_comp, :);
            
            % Overwrite specific statistical columns in row_table
            for f = 1:length(comp_fields_to_overwrite)
                col_name = comp_fields_to_overwrite{f};
                
                % Only copy if the column actually exists in both tables
                if ismember(col_name, comp_row.Properties.VariableNames) && ...
                   ismember(col_name, row_table.Properties.VariableNames)
                    
                    row_table.(col_name) = comp_row.(col_name);
                end
            end
        else
            warning('Statistic "%s" found in Descriptive but missing in Comparative table "%s".', stat_name, comp_type);
        end

        % --- Step C: Add Metadata Columns ---
        % Convert to string to ensure consistent column types
        row_table.Descriptive_Type = string(desc_type);
        row_table.Comparative_Type = string(comp_type);
        
        % Boolean Flags (derived from the COMPARATIVE source)
        row_table.Trajectory_Normalized = ~contains(comp_type, 'noTrajNorm', 'IgnoreCase', true);
        row_table.Within_Participant_Standardization = ~contains(comp_type, 'noStandardization', 'IgnoreCase', true);
        
        % Append to final table
        % (MATLAB tables handle appending rows with matching columns automatically)
        if isempty(final_table)
            final_table = row_table;
        else
            final_table = [final_table; row_table]; %#ok<AGROW>
        end
    end
    
    % Reorder columns for readability (Descriptive info first)
    if ~isempty(final_table)
        desired_order = {'name', 'Descriptive_Type', 'Comparative_Type', ...
                         'Trajectory_Normalized', 'Within_Participant_Standardization', ...
                         'con_avg', 'con_std', 'incon_avg', 'incon_std', ...
                         'diff_avg', 'tVal', 'pVal', 'cohens_d_z'};
                     
        existing_cols = intersect(desired_order, final_table.Properties.VariableNames, 'stable');
        final_table = movevars(final_table, existing_cols, 'Before', 1);
    end

end