%returns the best value representation for the block of agc data
%input:
%   agc_block: a vector of doubles of agc data
%   threshold: threshold for the standard deviation
%output:
%   eval: the best represenation of the agc data
%           -the mean of the data block if the standard deviation of the
%           agc_block is less than the threshold
%           -the min or max value from agc_block if the standard deviation
%           is greater than the threshold
function eval = check_stdev(agc_block, threshold)

    if std(agc_block) > threshold;
        top = max(agc_block);
        bot = min(agc_block);
        avg = mean(agc_block);
        if( abs(top-avg) > abs(bot-avg) )
            eval = top;
        else 
            eval = bot;
        end
    else
        eval = mean(agc_block);
    end

end