# Matlab Hardware Modelling Example

This repo shows the different levels of modelling options available to model a hardware block in Matlab. The hardware block used in this example is a Multiply and Accumulate (MAC) block. A diagram is shown below.


This block takes in two 4 element vectors, does an element wise multiply and accumulates with the previous rounds result using an adder tree. Since we work at 4 elements at a time, the parellelism factor is 4. We have 4 delay blocks so our latency is also 4.