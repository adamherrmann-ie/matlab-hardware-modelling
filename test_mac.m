classdef test_mac < matlab.unittest.TestCase
% Test script for comparing the different ways of implementing an multiply
% and accumulate.
%
% Our intput are two vectors, a and b. Our multiply and accumulate block
% shall multiply each element of a with each element of b and sum the
% result.
    properties (TestParameter)
        seed = num2cell(1:10);
        debug = {false};
    end

    methods (Test)
        function level0(testCase, seed, debug)

            rng(seed);

            vector_length = 100;
            
            a = rand(vector_length,1);
            b = rand(vector_length,1);
            
            %% Simple Matlab
            %  ============
            % For simple matlab, we can just use the following command to multiply two
            % vectors, a and b, together and accumulate the result:
            
            ml_simple_acc = sum(a .* b);
            
            if (debug)
                fprintf("Simple Matlab Result:\t\t\t");
                fprintf('%d ', ml_simple_acc);
                fprintf('\n');
            end
            
            %% Simple Hardware Matlab
            %  ============
            % In hardware to achieve performace, we will parallelize the operation.
            % This will enable us to match the intermediate results; however, we may
            % have mismatches due to the actual hardware implementing an adder tree
            % instead of a straight summation.
            
            parallelism = 4;
            ml_simple_hw_acc = 0;
            
            for out_index = 1:parallelism:length(a)
                % Take parallelism samples at a time
                ml_simple_hw_acc(end+1) = ml_simple_hw_acc(end) + sum(a(out_index:out_index+parallelism-1) .* b(out_index:out_index+parallelism-1)); %#ok
            end
            
            if (debug)
                fprintf("Simple Hardware Matlab Result:\t");
                fprintf('%d ', ml_simple_hw_acc);
                fprintf('\n');
            end
            
            %% Exact Hardware Matlab
            %  =====================
            %  We will now add in the adder tree and delays to match the hardware implementation exactly
            
            sim_length = 40;
            parallelism = 4;
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
            
            if (debug)
                fprintf("Exact Hardware Matlab Result:\t");
                fprintf('%d ', ml_exact_hw_acc);
                fprintf('\n');
            end
            
            %% Simulink
            %  ========
            % Use the below to setup the environment to run the simulink model which is
            % the exact hardware implementation above
            
            sl_latency = 4;
            
            a_parallel = reshape(a,parallelism,[])';
            b_parallel = reshape(b,parallelism,[])';
            
            a_padded = [a_parallel; zeros(sl_latency,parallelism)];
            b_padded = [b_parallel; zeros(sl_latency,parallelism)];
            
            sl_a.signals.values     = a_padded;
            sl_a.time               = 0:1:length(a_padded)-1;
            sl_a.signals.dimensions = parallelism;
            
            sl_b.signals.values     = b_padded;
            sl_b.time               = 0:1:length(b_padded)-1;
            sl_b.signals.dimensions = parallelism;
            
            simOut = sim('mac','FastRestart','off','SrcWorkspace','current','ReturnWorkspaceOutputs','on', 'StopTime', sprintf('%d',sim_length - 1));
            
            if (debug)
                fprintf("Simulink Result:\t\t\t\t");
                fprintf('%d ', simOut.sl_acc.Data);
                fprintf('\n');
            end
            
            %% Final Result Comparison in IEEE 754 Representation
            %  ==================================================
            %  Lets compare the outputs to check if we are getting any
            %  precision errors
            
            fprintf("\nIEEE 754 Double Precision Binary:\n");
            
            [sign,exponent,mantissa_simple_ml] = ieee754(ml_simple_acc);
            fprintf("Simple Matlab Result:\t\t\t%.6f -> %s %s %s\n", ml_simple_acc, sign, exponent, mantissa_simple_ml);
            
            [sign,exponent,mantissa_simple_hw] = ieee754(ml_simple_hw_acc(end));
            fprintf("Simple Hardware Matlab Result:\t%.6f -> %s %s %s\n", ml_simple_hw_acc(end), sign, exponent, mantissa_simple_hw);
            
            [sign,exponent,mantissa_exact_hw] = ieee754(ml_exact_hw_acc(end));
            fprintf("Exact Hardware Matlab Result:\t%.6f -> %s %s %s\n", ml_exact_hw_acc(end), sign, exponent, mantissa_exact_hw);
            
            [sign,exponent,mantissa_sl] = ieee754(simOut.sl_acc.Data(end));
            fprintf("Simulink Result:\t\t\t\t%.6f -> %s %s %s\n", simOut.sl_acc.Data(end), sign, exponent, mantissa_sl);
            
            if (mantissa_simple_ml == mantissa_simple_hw)
                fprintf('✓ Simple Matlab and Simple Hardware match exactly\n');
            else
                fprintf('✗ Simple Matlab and Simple Hardware DO NOT match exactly\n');
            end
            
            if (mantissa_simple_hw == mantissa_exact_hw)
                fprintf('✓ Simple Hardware and Exact Hardware match exactly\n');
            else
                fprintf('✗ Simple Hardware and Exact Hardware DO NOT match exactly\n');
            end
            
            if (mantissa_exact_hw == mantissa_sl)
                fprintf('✓ Exact Hardware and Simulink match exactly\n');
            else
                fprintf('✗ Exact Hardware and Simulink DO NOT match exactly\n');
            end

            %testCase.verifyEqual(mantissa_simple_ml,mantissa_simple_hw);
            %testCase.verifyEqual(mantissa_simple_hw,mantissa_exact_hw);
            testCase.verifyEqual(mantissa_exact_hw,mantissa_sl);
        end
    end
end