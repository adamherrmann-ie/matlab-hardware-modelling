function [missing_toolboxes, version_compatable] = check_matlab_environment(required_toolboxes, required_version)
% CHECKMATLABENVIROMENT Check if required MATLAB version and toolboxes are installed
%   [missingToolboxes, versionCompatible] = checkMatlabEnvironment(requiredToolboxes, requiredVersion)
%   checks if the current MATLAB version meets or exceeds the required version
%   and if the toolboxes listed in the cell array requiredToolboxes are installed.
%
%   Inputs:
%       requiredToolboxes - Cell array of toolbox names
%       requiredVersion  - String with minimum required MATLAB version (e.g., '9.10' for R2021a)
%                          or release name (e.g., 'R2021a')
%
%   Outputs:
%       missingToolboxes  - Cell array of missing toolboxes
%       versionCompatible - Boolean indicating if version requirement is met
%
%   Example:
%       [missing, versionOK] = checkMatlabEnvironment({'Signal Processing Toolbox'}, 'R2021b');
%       if ~versionOK
%           warning('Your MATLAB version is older than required.');
%       end

    % Check MATLAB version
    currentVersion = version;
    version_compatable = true;

    % Convert release name to version number if needed
    if startsWith(required_version, 'R')
        % Map from release names to version numbers
        releaseMap = containers.Map(...
            {'R2023b', 'R2024a', 'R2024b', 'R2025a'}, ...
            {'23.2', '24.1', '24.2', '25.1'});

        if isKey(releaseMap, required_version)
            required_version = releaseMap(required_version);
        else
            warning('Unknown release name: %s. Version check may not be accurate.', required_version);
        end
    end

    % Extract major and minor version numbers for comparison
    currentParts = regexp(currentVersion, '(\d+)\.(\d+)', 'tokens');
    requiredParts = regexp(required_version, '(\d+)\.(\d+)', 'tokens');

    if ~isempty(currentParts) && ~isempty(requiredParts)
        currentMajor = str2double(currentParts{1}{1});
        currentMinor = str2double(currentParts{1}{2});
        requiredMajor = str2double(requiredParts{1}{1});
        requiredMinor = str2double(requiredParts{1}{2});

        if currentMajor < requiredMajor || (currentMajor == requiredMajor && currentMinor < requiredMinor)
            version_compatable = false;
        end
    else
        warning('Could not parse version numbers. Version check may not be accurate.');
    end

    % Check toolboxes
    missing_toolboxes = {};
    if ~isempty(required_toolboxes)
        if ~iscell(required_toolboxes)
            error('Toolbox list must be a cell array of toolbox names.');
        end

        % Get installed toolboxes
        installedToolboxes = ver;
        installedNames = {installedToolboxes.Name};

        % Check each required toolbox
        for i = 1:length(required_toolboxes)
            if ~any(strcmp(installedNames, required_toolboxes{i}))
                missing_toolboxes{end+1} = required_toolboxes{i};
            end
        end
    end

    % Display results if no output arguments
    if nargout == 0
        % Version check results
        fprintf('[INFO] Current MATLAB version: %s\n', currentVersion);
        fprintf('[INFO] Required MATLAB version: %s\n', required_version);
        if version_compatable
            fprintf('[PASS] ✓ Version requirement met.\n');
        else
            error('[ERROR] ✗ Version requirement NOT met. Please update MATLAB.\n');
        end

        % Toolbox check results
        if isempty(missing_toolboxes)
            fprintf('[PASS] ✓ All required toolboxes are installed.\n');
        else
            warning('[WARN] ✗ Missing toolboxes:\n');
            for i = 1:length(missing_toolboxes)
                fprintf('  - %s\n', missing_toolboxes{i});
            end
        end
    end
end
