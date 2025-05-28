# Matlab Hardware Modelling Example

This repo shows the different levels of modelling options available to model a hardware block in Matlab. The hardware block used in this example is a Multiply and Accumulate (MAC) block. A diagram is shown below.

![image](https://github.com/user-attachments/assets/f3387cb6-7157-4c3a-82db-34c7cfbd57d5)

This block takes in two 4 element vectors, does an element wise multiply and accumulates with the previous rounds result using an adder tree. Since we work at 4 elements at a time, the parellelism factor is 4. We have 4 delay blocks so our latency is also 4.

## Simple Matlab Model

The simpliest way to model this in Matlab, is just a element wise multimply and sum function:

```
ml_simple_acc = sum(a .* b);
```

## Simple Hardware Matlab Model

We can add the concept of parallelism by looping over 4 samples at a time, but still using our the element wise multiply and sum function.

```
parallelism = 4;
ml_simple_hw_acc = 0;
            
for out_index = 1:parallelism:length(a)
    % Take parallelism samples at a time
    ml_simple_hw_acc(end+1) = ml_simple_hw_acc(end) + sum(a(out_index:out_index+parallelism-1) .* b(out_index:out_index+parallelism-1)); %#ok
end
```

## Exact Hardware Matlab Model

Finally to match exactly, we can add in the latency and adder tree. This should solve any precision differences when comparing the binary output of the actual hardware to the matlab model. To model the delays, fifos are used to store values in a buffer for the next round of the loop.

## Example:

When you run the test_mac.m file, you should see the following output showing if the various MAC implementations match eachother. Mismatches between the Simple Matlab Model, Simple Hardware Matlab Model, and Exact Matlab Model are expected due to their different internal architectures; however, the Exact Hardware Matlab Model and the Simulink should match exactly:

```
IEEE 754 Double Precision Binary:
Simple Matlab Result:           22.592022 -> 0 10000000011 0110100101111000111010111010111010010101000100100101
Simple Hardware Matlab Result:  22.592022 -> 0 10000000011 0110100101111000111010111010111010010101000100100011
Exact Hardware Matlab Result:   22.592022 -> 0 10000000011 0110100101111000111010111010111010010101000100100010
Simulink Result:                22.592022 -> 0 10000000011 0110100101111000111010111010111010010101000100100010
✗ Simple Matlab and Simple Hardware DO NOT match exactly
✗ Simple Hardware and Exact Hardware DO NOT match exactly
✓ Exact Hardware and Simulink match exactly
```
