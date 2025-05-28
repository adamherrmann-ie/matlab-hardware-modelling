function [sign,exponent,mantissa] = ieee754(input_value)
% Function to convert the input value into the IEEE754 representation

% Convert double to uint64 to access raw bits
bits = typecast(input_value, 'uint64');
binary_str = dec2bin(bits, 64);

% Format with spaces for readability (sign|exponent|mantissa)
sign = binary_str(1);
exponent = binary_str(2:12);
mantissa = binary_str(13:64);
end