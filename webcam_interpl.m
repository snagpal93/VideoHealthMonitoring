function [Rs, Gs, Bs] = webcam_interpl(R, G, B, w_timestemp, start, fin, resample_size)

    % interpolate all the colors
    Rs = interp1(w_timestemp(start:fin), R(start:fin), resample_size);
    Gs = interp1(w_timestemp(start:fin), G(start:fin), resample_size);
    Bs = interp1(w_timestemp(start:fin), B(start:fin), resample_size);
    
    % maybe use better mode, e.g. spline, or use detrend after?

end