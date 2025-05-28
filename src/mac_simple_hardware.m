function ml_simple_hw_acc = mac_simple_hardware(a, b, parallelism)

ml_simple_hw_acc = 0;

for out_index = 1:parallelism:length(a)
    % Take parallelism samples at a time
    ml_simple_hw_acc(end+1) = ml_simple_hw_acc(end) + sum(a(out_index:out_index+parallelism-1) .* b(out_index:out_index+parallelism-1)); %#ok
end

end