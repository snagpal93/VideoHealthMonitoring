function [hr] = calcHR(ppg)
%CALCHR Summary of this function goes here
%   Detailed explanation goes here
    n = size(ppg,1);
    
    if(n==1)
        n = size(ppg,2);
    end
    
    hr =[];
    for i= 1:1:n-300
       ppg_seg = ppg(i:i+299);
       inst_hr = calcHR300(ppg_seg);
       hr = [hr inst_hr];
    end

end

