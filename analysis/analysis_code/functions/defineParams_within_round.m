% Some parameters might change between running the exp and analyzing its results.
% This function loads the parameters values that were set when the exp was run and adjusts some of them for the analysis to work.
function p = defineParams_within_round(p, iSub)
    NORMALIZE_WITHIN_SUB = p.NORMALIZE_WITHIN_SUB;
    NORM_TRAJ = p.NORM_TRAJ;
    MIN_SAMP_LEN = p.MIN_SAMP_LEN;
    MIN_TRIM_FRAMES = p.MIN_TRIM_FRAMES;
    SUBS = p.SUBS;
    ORIG_SUBS = p.ORIG_SUBS;
    DAY = p.DAY;
    PROC_DATA_FOLDER = p.PROC_DATA_FOLDER;
    DATA_FOLDER = p.DATA_FOLDER;

    p.NORMALIZE_WITHIN_SUB = NORMALIZE_WITHIN_SUB;
    p.NORM_TRAJ = NORM_TRAJ;
    p.MIN_SAMP_LEN = MIN_SAMP_LEN;
    p.MIN_TRIM_FRAMES = MIN_TRIM_FRAMES;
    % Paths.
    curr_path = replace(pwd, '\', '/');
    p.EXP_FOLDER = [curr_path '/../../experiment/RUN_ME/code'];
    p.STIM_FOLDER = [p.EXP_FOLDER '/../stimuli/'];

    p.PROC_DATA_FOLDER = PROC_DATA_FOLDER;
    p.DATA_FOLDER = DATA_FOLDER;

    p.TRIALS_FOLDER = [p.STIM_FOLDER '/trial_lists/'];
    p.DATA_FOLDER_WIN = replace(p.DATA_FOLDER, '/', '\');
    p.TESTS_FOLDER = [p.EXP_FOLDER '/./tests/test_results/'];
    p.SUBS = SUBS;
    p.ORIG_SUBS = ORIG_SUBS;
    p.SUBS_STRING = vect2rangestr(p.SUBS);
    p.DAY = DAY;
    p.N_SUBS = length(p.SUBS);
    p.MAX_SUB = max(p.SUBS);
    % Normalization params.
    p.TRAJ_FILT_ORDER = 2;
    p.TRAJ_FILT_CUTOFF = 8;% in Hz.
    p.VEL_FILTER_ORDER = 2;
    p.VEL_FILTER_CUTOFF = 10;% in Hz.
    p.NORM_FRAMES = 200; % length of normalized trajs.
    p.NORM_TYPE = 4; % 1=to time, 2=to x, 3=to y, 4=to z.

    p.SCREEN_DIST = 0.35;
    p.RECOG_CAP_LENGTH_SEC = 7;
    p.CATEGOR_CAP_LENGTH_SEC = 0.74;
    p.MIN_REACH_DIST = p.SCREEN_DIST - p.MAX_DIST_FROM_SCREEN;
    % Distances.
    p.DIST_BETWEEN_TARGETS = 0.20; % In meter.
    p.TARGET_MISS_RANGE = 0.12; % In meter.

    % Recording length.
    p.RECOG_CAP_LENGTH = p.RECOG_CAP_LENGTH_SEC * p.REF_RATE_HZ; % Trajectory capture length (num of samples).
    p.CATEGOR_CAP_LENGTH = p.CATEGOR_CAP_LENGTH_SEC * p.REF_RATE_HZ;
    p.MAX_CAP_LENGTH = max(p.RECOG_CAP_LENGTH, p.CATEGOR_CAP_LENGTH);
    

    p.NUM_TRIALS = p.NUM_BLOCKS * p.BLOCK_SIZE;
    p.MIN_AMNT_TRIALS_IN_COND = 25; % sub with less good trials in each condition (same/diff) is disqualified.
    p.MIN_GOOD_TRIALS = p.MIN_AMNT_TRIALS_IN_COND * 2; % Total, regardless of condition.
    p.MAX_BAD_TRIALS = p.NUM_TRIALS - p.MIN_GOOD_TRIALS; % sub with more bad trials is disqualified.

    % Conditions.
    p.CONDS = ["con" "incon"];
    p.N_CONDS = length(p.CONDS); % Conditions: Same/Diff.

    % Hypothesis testing.
    p.SIG_PVAL = 0.05;

    p.EXP = 'exp4_1';
end