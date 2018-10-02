clear
close all
clc

%% Parametres des objets participant � l'emetteur
waveform_params = configure_waveform();

[mod_psk, demod_psk] = build_mdm(waveform_params);
dvb_scramble         = build_dvb_scramble();

% Parametre du flux TS
% -------------------------------------------------------------------------
msg_oct_sz     = 188;
msg_bit_sz     = msg_oct_sz*8; % Taille de la payload des paquets en bits
pckt_per_frame = 8;
frame_oct_sz   = pckt_per_frame * msg_oct_sz;
frame_bit_sz   = 8*frame_oct_sz; % Une trame = 8 paquets

% -------------------------------------------------------------------------

% Parametres fichiers
% -------------------------------------------------------------------------
tx_vid_fname = 'tx_stream.ts';  % Fichier contenant le message � transmettre
message_source = BinaryFileReader('Filename', tx_vid_fname, 'SamplesPerFrame', msg_oct_sz*pckt_per_frame);
% ------------------------------------------------------------------------


%%
Delta_f = 0;
Phi0 = 0;
alpha = 1;
del_val = 0;
list_EbN0_dB = 0:10;
list_EbN0 = 10.^(list_EbN0_dB/10);
delay = dsp.VariableFractionalDelay('MaximumDelay',8000);
doppler = comm.PhaseFrequencyOffset(...
    'FrequencyOffset',Delta_f,...
    'PhaseOffset',Phi0,...
    'SampleRate',waveform_params.sim.Fe);

awgn_channel = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (Eb/No)','EbNo',list_EbN0_dB(1),'BitsPerSymbol',2,'SignalPower',alpha^2);


%%
o2b = OctToBit();
b2o = BitToOct();
%%
ber = zeros(1,length(list_EbN0_dB));

Pe = qfunc(sqrt(2*list_EbN0));

for i_snr = 1:length(list_EbN0_dB)
    message_source.reset;
    awgn_channel.EbNo=list_EbN0_dB(i_snr);
    n_trame = 0;
    n_erreur = 0;
    while(n_erreur < 100 && n_trame < 100)
        %% Emetteur
        tx_oct     = step(message_source); % Lire une trame
        tx_scr_oct = bitxor(tx_oct,dvb_scramble); % scrambler
        tx_scr_bit = step(o2b,tx_scr_oct); % Octets -> Bits
        tx_sym     = step(mod_psk,  tx_scr_bit); % Modulation QPSK
        
        %% Canal
        tx_sps_dpl = step(doppler,tx_sym); % Simulation d'un effet Doppler
        rx_sps_del = step(delay,tx_sps_dpl,del_val); % Ajout d'un retard de propagation
        rx_sps     = step(awgn_channel,alpha*rx_sps_del); % Ajout d'un bruit gaussien
        
        %% Recepteur
        rx_bit = step(demod_psk,rx_sps);
        rx_scr_oct = step(b2o,rx_bit<0);
        rx_oct = bitxor(rx_scr_oct,dvb_scramble); % scrambler
        n_erreur = n_erreur + biterr(tx_oct,rx_oct);
        n_trame = n_trame + 1;
    end
    ber(i_snr) = n_erreur/(n_trame*frame_bit_sz);
    semilogy(list_EbN0_dB,ber);
    drawnow
end
hold all
semilogy(list_EbN0_dB,Pe);



