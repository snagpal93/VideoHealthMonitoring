%=========================%=========================
%=========================%=========================

%% VHM Final assingment

% Students:
% Michel van Lier 0961263

%=========================%=========================
%=========================%=========================

% tbs clear matlab
clear all
close all

%% Source selection input %%

Fs = 20;

while true
    disp(' ')
    prompt = 'Select input: webcam[w]/existing recording[v]/quit[q]: ';
    choise = input(prompt,'s');

    while ((choise~='w') && (choise~='v') && (choise~='q'))
        disp('Wrong input selected, please slelect correct:')
        prompt = 'Select input: webcam[w]/existing recording[v]/quit[q]: ';
        choise = input(prompt,'s');
    end

    disp(' ')
    disp('You selected the correct input:')
    if choise == 'w'
        disp('- Webcam')
        % call here  webcam function
        Pt = webcam_ppg(Fs);
        PR_reference = 0;
    elseif choise == 'v'
        disp('- Existing recording')
        % call here recording function
        [Pt, PR_reference] = video_ppg();
    else
        disp('- Quit Framework')
        return
    end

    % evaluation of the framework
    if length(Pt) > 1
        disp('- Framework work is now going to evaluated')
        disp(' ')
        fw_evaluation(choise, Pt, Fs, PR_reference);
    end 
end

