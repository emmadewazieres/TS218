clear
close all
clc

%% Parametres des objets participant � l'emetteur
bool_store_rec_video = true;

waveform_params = configure_waveform();
channel_params  = configure_channel(0:10);

[mod_psk, demod_psk]           = build_mdm(waveform_params);
dvb_scramble                   = build_dvb_scramble();
[awgn_channel, doppler, delay] = build_channel(channel_params, waveform_params);

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
rx_vid_prefix = 'rx_stream';  % Fichier contenant le message � transmettre
message_source = BinaryFileReader('Filename', tx_vid_fname, 'SamplesPerFrame', msg_oct_sz*pckt_per_frame, 'DataType', 'uint8');
message_destination = BinaryFileWriter('DataType','uint8');
% ------------------------------------------------------------------------

%%
o2b = OctToBit();
b2o = BitToOct();
%%
ber = zeros(1,length(channel_params.EbN0dB));
Pe = qfunc(sqrt(2*channel_params.EbN0));

for i_snr = 1:length(channel_params.EbN0dB)
	message_source.reset;
	if bool_store_rec_video
		message_destination.release;
		message_destination.Filename = [rx_vid_prefix, num2str(channel_params.EbN0dB(i_snr)),'dB.ts'];
	end
	awgn_channel.EbNo=channel_params.EbN0dB(i_snr);
	n_trame = 0;
	n_erreur = 0;
	message_source.reset();
	while(~message_source.isDone)
		%% Emetteur
		tx_oct     = step(message_source); % Lire une trame
		tx_scr_oct = bitxor(tx_oct,dvb_scramble); % scrambler
		tx_scr_bit = step(o2b,tx_scr_oct); % Octets -> Bits
		tx_sym     = step(mod_psk,  tx_scr_bit); % Modulation QPSK
		
		%% Canal
		tx_sps_dpl = step(doppler, tx_sym); % Simulation d'un effet Doppler
		rx_sps_del = step(delay, tx_sps_dpl, channel_params.Delai); % Ajout d'un retard de propagation
		rx_sps     = step(awgn_channel,channel_params.Gain * rx_sps_del); % Ajout d'un bruit gaussien
		
		%% Recepteur
		rx_bit = step(demod_psk,rx_sps);
		rx_scr_oct = step(b2o,rx_bit<0);
		rx_oct = bitxor(rx_scr_oct,dvb_scramble); % scrambler
		n_erreur = n_erreur + biterr(tx_oct,rx_oct);
		n_trame = n_trame + 1;
		
		%% Destination
		if bool_store_rec_video
			step(message_destination,rx_oct);
		end
	end
	ber(i_snr) = n_erreur/(n_trame*frame_bit_sz);
	semilogy(channel_params.EbN0dB,ber);
	drawnow
end
hold all
semilogy(channel_params.EbN0dB,Pe);



