function fifo_buffer = fifo_push(fifo_buffer, new_value)
% Model the push into a fifo. To access the oldest value, use
% fifo_buffer(end). The size of the buffer depends on the size of
% fifo_buffer declared outside of the function
    fifo_buffer = circshift(fifo_buffer, 1);
    fifo_buffer(1) = new_value;
end