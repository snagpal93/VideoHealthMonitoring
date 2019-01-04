function F = Spec_RT(P,fps)

    Pdim = size(P);
    if Pdim(1) > Pdim; P = P'; end
    if size(P,1)~=1; display('Invalid input: data should by of dimension 1x#samples'); end    

	stride = fps*20;
    
    S = zeros(size(P,2)-stride+1,stride);
    
    for idx = 1:size(P,2)-stride+1
        p = P(1,idx:idx+stride-1);
        S(idx,:) = (p-mean(p))/(eps+std(p));
    end
    
    S = S .* repmat(hann(stride)',[size(S,1),1]);
    H = abs(fft(S,fps*60,2));
    F = H(:,1:fps*60/2)';

end