function [Rs, Gs, Bs] = webcam_interpl(R, G, B, timestemp, start, end, resample_size)

    % interpolate all the colors
    Rs = interp1(w_timestep(), R(), resample_size);
    Gs = interp1(w_timestep(), G(), resample_size);
    Bs = interp1(w_timestep(), B(), resample_size);

end