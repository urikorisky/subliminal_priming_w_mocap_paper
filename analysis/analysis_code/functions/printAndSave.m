function [] = printAndSave(final_fig_handles, full_stats_tables, analysisParameters) %#ok<INUSL>
%PRINTANDSAVE Directly produces the final consolidated master figures
% (.fig, .png, .pdf, .svg + Fig_S1f DOCX) in analysis/figures/ and
% All_Statistics.mat + 16-sheet All_Statistics.xlsx in analysis/statistics/,
% without generating or archiving any intermediate files.

    if nargin == 2
        analysisParameters = full_stats_tables;
        full_stats_tables = final_fig_handles;
    elseif nargin < 2
        error('printAndSave requires at least full_stats_tables and analysisParameters');
    end

    if ~isfield(analysisParameters, 'targetFigs_allAnalysesCombined') || isempty(analysisParameters.targetFigs_allAnalysesCombined)
        baseFigsFldr = '../figures';
    else
        baseFigsFldr = analysisParameters.targetFigs_allAnalysesCombined;
    end
    if ~exist(baseFigsFldr, 'dir'), mkdir(baseFigsFldr); end

    if ~isfield(analysisParameters, 'targetStats_allAnalysesCombined') || isempty(analysisParameters.targetStats_allAnalysesCombined)
        statsFldr = '../statistics';
    else
        statsFldr = analysisParameters.targetStats_allAnalysesCombined;
    end
    if ~exist(statsFldr, 'dir'), mkdir(statsFldr); end

    if isfield(analysisParameters, 'fromRawData') && analysisParameters.fromRawData && ...
            isfield(analysisParameters, 'targetPreProcData_TrajNorm_noStandardization_folder')
        procRoot = fileparts(regexprep(analysisParameters.targetPreProcData_TrajNorm_noStandardization_folder, '[\\/]+$', ''));
    elseif isfield(analysisParameters, 'readyPreProcData_TrajNorm_noStandardization_folder')
        procRoot = fileparts(regexprep(analysisParameters.readyPreProcData_TrajNorm_noStandardization_folder, '[\\/]+$', ''));
    else
        procRoot = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'processed_data');
    end

    % 1. Directly generate final master figures (.fig, .png, .pdf, .svg + Fig_S1f DOCX)
    fprintf('=== Generating Final Master Figures in %s ===\n', baseFigsFldr);
    generate_master_figures_part1(baseFigsFldr, full_stats_tables, procRoot);
    temporal_dynamics_struct = generate_master_figures_part2(baseFigsFldr, full_stats_tables, procRoot);
    full_stats_tables.Temporal_Dynamics = temporal_dynamics_struct;

    % 2. Save All_Statistics.mat in statistics folder
    matFile = fullfile(statsFldr, 'All_Statistics.mat');
    save(matFile, 'full_stats_tables');
    fprintf('Successfully saved master statistics struct to: %s\n', matFile);

    % 3. Directly build consolidated 16-sheet All_Statistics.xlsx
    xlsxFile = fullfile(statsFldr, 'All_Statistics.xlsx');
    try
        generate_master_all_statistics_xlsx(xlsxFile, full_stats_tables, procRoot, temporal_dynamics_struct);
        fprintf('Successfully exported consolidated 16-sheet workbook to: %s\n', xlsxFile);
    catch ME
        warning('Failed writing to %s (%s). Attempting fallback to All_Statistics_Consolidated.xlsx...', xlsxFile, ME.message);
        fallbackFile = fullfile(statsFldr, 'All_Statistics_Consolidated.xlsx');
        generate_master_all_statistics_xlsx(fallbackFile, full_stats_tables, procRoot, temporal_dynamics_struct);
        fprintf('Successfully exported consolidated workbook to fallback: %s\n', fallbackFile);
    end
end
