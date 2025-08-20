function outTable = agg_and_split_table(srcTable,aggFields,splitFields)
%AGG_AND_SPLIT_TABLE A function to aggregate variables in a table using
%other variables

% Out stats - a table with: <number of agg fields> + <number of split
% fields> + [average*<number of agg fields>, numOccurences, table with
% list of trials in this split and only the aggFields for each]
outTable = table();

tableVars = aggAndSplitRec(srcTable,aggFields,splitFields);

tableVarNames = [splitFields,{'numOccur'},aggFields,{'allTrialsTable'}];

for i=1:size(tableVars,2)
    cVar = tableVars(:,i);
    % cVarIsNumeric = all(cellfun(@(x) isnumeric(x),cVar));
    % if(cVarIsNumeric)
    %     outTable.
    % else
    % end
    outTable.(tableVarNames{i}) = cVar;
end

end

function outCell = aggAndSplitRec(srcTable,aggFields,splitFields)
    if(isempty(splitFields))
        outCell{1} = size(srcTable,1); % numOccur
        for aggField_cell = aggFields
            aggField = aggField_cell{1};
            outCell{end+1} = mean(srcTable.(aggField)); % mean of each aggField
        end
        addFieldsIdxs_cell = cellfun(@(x) ismember(srcTable.Properties.VariableNames,x),[{'iTrial'},aggFields],'UniformOutput',false);
        addFieldsIdxs = cellfun(@(x) find(x),addFieldsIdxs_cell);
        outCell{end+1} = srcTable(:,addFieldsIdxs);
        return;
    end

    splitField = splitFields{1};
    splitFields(1) = [];

    uniqueSplitVals = unique(srcTable.(splitField))';

    if(isnumeric(uniqueSplitVals))
        nullSplitLabel = nan();
    else
        nullSplitLabel = {'<IGNORED>'};
    end

    uniqueSplitVals = [nullSplitLabel, uniqueSplitVals];
    if(isnumeric(uniqueSplitVals))
        uniqueSplitVals = num2cell(uniqueSplitVals);
    end

    %outCell = cell([],size(splitFields,2)+1+numel(aggFields));

    for iSplitVal = 1:numel(uniqueSplitVals)
        %outCell(end+1,1) = uniqueSplitVals(iSplitVal);
        splitVal = uniqueSplitVals{iSplitVal};
        if (iSplitVal ==1)
            tableFiltToSplitVal = srcTable;
            currChunk = aggAndSplitRec(tableFiltToSplitVal,aggFields,splitFields);
            outCell = [repmat({splitVal},size(currChunk,1),1) currChunk];
        else
            tableFiltToSplitVal = srcTable((srcTable.(splitField) == splitVal),:);
            currChunk = aggAndSplitRec(tableFiltToSplitVal,aggFields,splitFields);
            currChunk = [repmat({splitVal},size(currChunk,1),1) currChunk];
            outCell = [outCell; currChunk];
        end
        
    end
end