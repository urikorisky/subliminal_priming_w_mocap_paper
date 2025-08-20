function s = vect2rangestr(v)
    v = sort(v(:)');               % ensure row vector
    d = [true, diff(v) > 1, true]; % boundaries of runs
    idx = find(d);                 % run boundaries
    s = cell(1, numel(idx)-1);

    for k = 1:numel(idx)-1
        run = v(idx(k):idx(k+1)-1);
        if isscalar(run)
            s{k} = sprintf('%d', run);
        else
            s{k} = sprintf('%d-%d', run(1), run(end));
        end
    end

    s = strjoin(s, '_');
end
