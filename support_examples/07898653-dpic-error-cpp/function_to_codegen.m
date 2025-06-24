function [data_0,  data_1, data_2, data_3, data_4, data_5, data_6] = function_to_codegen(...
                seed, payloads_to_send)

    % Init the random number generator
    rng(seed);

    % Create data
    data_3 = rand(1000,1);
    data_4 = rand(1000,1);
    data_5 = rand(1000,1);
    data_6 = rand(1000,1);
    data_1 = rand(1000,1);
    data_2 = rand(1000,1);
    
    data_0 = zeros(payloads_to_send,1);
end
