%% chrome method function                         

function s_chrom = chrom_method(ACDC_R, ACDC_G, ACDC_B, a_filter, b_filter)
                %%%%% normalized skin tone
                Rc=1.00*ACDC_R;
                Gc=0.66667*ACDC_G;
                Bc=0.50*ACDC_B;
                %%%%% chrominance signals
                X_CHROM=(Rc-Gc);
                Y_CHROM=(Rc+Gc-2*Bc);
                %%%%% prefiltering X, Y to optimize for the relevant band (40-220BPM)
                Xf = filtfilt(b_filter,a_filter, X_CHROM);
                Yf = filtfilt(b_filter,a_filter, Y_CHROM);
                Nx=std(Xf);
                Ny=std(Yf);
                alpha_CHROM = Nx/Ny;
                s_chrom = Xf- alpha_CHROM*Yf;    
end