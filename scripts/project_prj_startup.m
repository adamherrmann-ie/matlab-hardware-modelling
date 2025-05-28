disp("[INFO] Turning warning backtrace off")
warning('backtrace','off');

disp("[INFO] Checking Matlab environment")

required_toolboxes = {'Fixed-Point Designer', ...             
                        'MATLAB', ...
                        'Simulink'};
required_version = 'R2024b';
check_matlab_environment(required_toolboxes, required_version);

disp("[INFO] Environment check complete!")