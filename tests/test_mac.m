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

            vector_length = 500;
            
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
            
            ml_simple_hw_acc = mac_simple_hardware(a, b, parallelism);
            
            if (debug)
                fprintf("Simple Hardware Matlab Result:\t");
                fprintf('%d ', ml_simple_hw_acc);
                fprintf('\n');
            end
            
            %% Exact Hardware Matlab
            %  =====================
            %  We will now add in the adder tree and delays to match the hardware implementation exactly
            
            sim_length = 40;
            
            ml_exact_hw_acc = mac_exact_hardware(a, b, parallelism, sim_length);
            
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
            sl_a.signals.dimensions = parallelism;              %# ok
            
            sl_b.signals.values     = b_padded;
            sl_b.time               = 0:1:length(b_padded)-1;
            sl_b.signals.dimensions = parallelism;              %# ok

            sl_valid.signals.values     = true(length(a_padded),1);
            sl_valid.time               = 0:1:length(a_padded)-1;
            sl_valid.signals.dimensions = 1;                    %# ok
            
            simOut = sim('mac_simulink','FastRestart','off','SrcWorkspace','current','ReturnWorkspaceOutputs','on', 'StopTime', sprintf('%d',sim_length - 1));
            
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
            fprintf("Simple Matlab Result:\t\t%.6f -> %s %s %s\n", ml_simple_acc, sign, exponent, mantissa_simple_ml);
            
            [sign,exponent,mantissa_simple_hw] = ieee754(ml_simple_hw_acc(end));
            fprintf("Simple Hardware Matlab Result:\t%.6f -> %s %s %s\n", ml_simple_hw_acc(end), sign, exponent, mantissa_simple_hw);
            
            [sign,exponent,mantissa_exact_hw] = ieee754(ml_exact_hw_acc(end));
            fprintf("Exact Hardware Matlab Result:\t%.6f -> %s %s %s\n", ml_exact_hw_acc(end), sign, exponent, mantissa_exact_hw);
            
            [sign,exponent,mantissa_sl] = ieee754(simOut.sl_acc.Data(end));
            fprintf("Simulink Result:\t\t%.6f -> %s %s %s\n", simOut.sl_acc.Data(end), sign, exponent, mantissa_sl);
            
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

            testCase.verifyEqual(mantissa_exact_hw,mantissa_sl);
        end
    end
end