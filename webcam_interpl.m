function [Rs, Gs, Bs] = webcam_interpl(R, G, B, w_timestemp, first, last, update_Fs)

    resample = w_timestap(first):update_Fs:w_timestap(last);

    % interpolate all the colors
    Rs = interp1(w_timestemp(first:last), R(first:last), resample);
    Gs = interp1(w_timestemp(first:last), G(first:last), resample);
    Bs = interp1(w_timestemp(first:last), B(first:last), resample);
    
    % maybe use better mode, e.g. spline, or use detrend after?

end