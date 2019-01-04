function [TrackerInit,TrackInitFlag] = InitTracker

    TrackerInit.kernel_type = 'gaussian';
    TrackerInit.feature_type = 'gray';

    % parameters according to the paper. at this point we can override
    % parameters based on the chosen kernel or feature type
    TrackerInit.kernel.type = TrackerInit.kernel_type;

    TrackerInit.features.gray = false;
    TrackerInit.features.hog = false;

    TrackerInit.padding = 1;%1.5;  % extra area surrounding the target
    TrackerInit.lambda = 1e-2; %1e-4;  % regularization
    TrackerInit.output_sigma_factor = 1/16;%0.1;  % spatial bandwidth (proportional to target)

    switch TrackerInit.feature_type
        case 'gray',
        TrackerInit.interp_factor = 0.045;%0.075;  % linear interpolation factor for adaptation

        TrackerInit.kernel.sigma = 0.2;  % gaussian kernel bandwidth

        TrackerInit.kernel.poly_a = 1;  % polynomial kernel additive term
        TrackerInit.kernel.poly_b = 7;  % polynomial kernel exponent

        TrackerInit.features.gray = true;
        TrackerInit.cell_size = 1;

        case 'hog',
        TrackerInit.interp_factor = 0.02;

        TrackerInit.kernel.sigma = 0.5;

        TrackerInit.kernel.poly_a = 1;
        TrackerInit.kernel.poly_b = 9;

        TrackerInit.features.hog = true;
        TrackerInit.features.hog_orientations = 9;
        TrackerInit.cell_size = 4;

        otherwise
        error('Unknown feature.')
    end


    assert(any(strcmp(TrackerInit.kernel_type, {'linear', 'polynomial', 'gaussian'})), 'Unknown kernel.')	
    
    TrackInitFlag = true;

end