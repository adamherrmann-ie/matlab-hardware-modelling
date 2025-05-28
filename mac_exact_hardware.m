function ml_exact_hw_acc = mac_exact_hardware(a, b, parallelism, sim_length)

ml_exact_hw_acc = zeros(sim_length,1);
            
prod_1_buffer = zeros(2,1);
prod_2_buffer = zeros(2,1);
prod_3_buffer = zeros(2,1);
prod_4_buffer = zeros(2,1);

sum_1_buffer = zeros(2,1);
sum_2_buffer = zeros(2,1);
sum_3_buffer = zeros(2,1);

output_buffer = zeros(2,1);

in_index = 1;

for out_index = 1:sim_length
    % Products
    if (in_index > length(a))
        prod_1 = 0; prod_2 = 0; prod_3 = 0; prod_4 = 0;
    else
        prod_1 = a(in_index) * b(in_index);
        prod_2 = a(in_index + 1) * b(in_index + 1);
        prod_3 = a(in_index + 2) * b(in_index + 2);
        prod_4 = a(in_index + 3) * b(in_index + 3);
        in_index = in_index + parallelism;
    end

    % Delay
    prod_1_buffer = fifo_push(prod_1_buffer,prod_1);
    prod_2_buffer = fifo_push(prod_2_buffer,prod_2);
    prod_3_buffer = fifo_push(prod_3_buffer,prod_3);
    prod_4_buffer = fifo_push(prod_4_buffer,prod_4);

    % Sum
    sum_1 = (prod_1_buffer(end) + prod_2_buffer(end));
    sum_2 = (prod_3_buffer(end) + prod_4_buffer(end));
    
    % Delay
    sum_1_buffer = fifo_push(sum_1_buffer,sum_1);
    sum_2_buffer = fifo_push(sum_2_buffer,sum_2);

    % Sum
    sum_3 = sum_1_buffer(end) + sum_2_buffer(end);

    % Delay
    sum_3_buffer = fifo_push(sum_3_buffer,sum_3);

    % Sum
    sum_4 = output_buffer(1) + sum_3_buffer(end);
    
    % Delay
    output_buffer = fifo_push(output_buffer,sum_4);
    ml_exact_hw_acc(out_index) = output_buffer(end);
end
end