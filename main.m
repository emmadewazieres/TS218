clear
close all
clc

%% Parametres des objets participant a l'emetteur
% Parametre du flux TS
% -------------------------------------------------------------------------
tx_vid_fname   = 'tx_stream.ts';  % Fichier contenant le message ï¿½ transmettre
rx_vid_prefix  = 'rx_stream';  % Fichier contenant le message ï¿½ transmettre
msg_oct_sz     = 188;
msg_bit_sz     = msg_oct_sz*8; % Taille de la payload des paquets en bits
pckt_per_frame = 8;
frame_oct_sz   = pckt_per_frame * msg_oct_sz;
frame_bit_sz   = 8*frame_oct_sz; % Une trame = 8 paquets
store_rx_vid   = false;
% -------------------------------------------------------------------------

%% Création des structures de paramètres
waveform_params        = configure_waveform(1e6,0.25e6,0.25e6); % Les parametres de la mise en forme
channel_params         = configure_channel(0:10,0,0,1,0); % Les paramètres du canal
[tx_filter, rx_filter] = build_flt(waveform_params); % La couche de mise en forme

%% Création des objets
[mod_psk, demod_psk]                   = build_mdm(waveform_params); % Construction des modems
dvb_scramble                           = build_dvb_scramble(); %Construction du scrambler
[awgn_channel, doppler, channel_delay] = build_channel(channel_params, waveform_params); % Blocs du canal
stat_erreur                            = comm.ErrorRate('ReceiveDelay', frame_bit_sz,'ComputationDelay',frame_bit_sz); % Calcul du nombre d'erreur et du BER
mac_sync_delay                         = dsp.VariableIntegerDelay('MaximumDelay', frame_bit_sz*2);

% Conversions octet <-> bits
o2b = OctToBit();
b2o = BitToOct();

% Lecture octet par octet du fichier vidéo d'entree
message_source = BinaryFileReader(...
    'Filename', tx_vid_fname,...
    'SamplesPerFrame', msg_oct_sz*pckt_per_frame,...
    'DataType', 'uint8');

% Ecriture octet par octet du fichier vidéo de sortie
message_destination = BinaryFileWriter('DataType','uint8');

%%
ber = zeros(1,length(channel_params.EbN0dB));
Pe = qfunc(sqrt(2*channel_params.EbN0));
tx_rx_flt_delay = frame_bit_sz - waveform_params.rxflt.FilterSpanInSymbols*waveform_params.mod.ModulationBPS;

figure(1)
semilogy(channel_params.EbN0dB,Pe);
hold all
h_ber = semilogy(channel_params.EbN0dB,ber,'XDataSource','channel_params.EbN0dB', 'YDataSource','ber');
grid on
xlabel('$\frac{E_b}{N_0}$ en dB','Interpreter', 'latex', 'FontSize',14)
ylabel('$P_b$, TEB','Interpreter', 'latex', 'FontSize',14)
legend({'$P_b$ (Th\''eorique)', 'TEB (Exp\''erimentale)'}, 'Interpreter', 'latex', 'FontSize',14);

for i_snr = 1:length(channel_params.EbN0dB)
	if store_rx_vid
		message_destination.release;
		message_destination.Filename = [rx_vid_prefix, num2str(channel_params.EbN0dB(i_snr)),'dB.ts'];
	end
	
	awgn_channel.EbNo=channel_params.EbN0dB(i_snr);% Mise à jour du EbN0 pour le canal
	
	stat_erreur.reset; % reset du compteur d'erreur
	err_stat = [0 0 0];
	while (err_stat(2) < 100 && err_stat(3) < 1e9)
		message_source.reset;
		while(~message_source.isDone)
			%% Emetteur
			tx_oct     = step(message_source); % Lire une trame
			tx_scr_oct = bitxor(tx_oct,dvb_scramble); % scrambler
			tx_scr_bit = step(o2b,tx_scr_oct); % Octets -> Bits
			tx_sym     = step(mod_psk,  tx_scr_bit); % Modulation QPSK
            tx_spls    = step(tx_filter,tx_sym);
			
			%% Canal
			tx_sps_dpl = step(doppler, tx_spls); % Simulation d'un effet Doppler
			rx_sps_del = step(channel_delay, tx_sps_dpl, channel_params.Delai); % Ajout d'un retard de propagation
			rx_sps     = step(awgn_channel,channel_params.Gain * rx_sps_del); % Ajout d'un bruit gaussien
			
			%% Recepteur
            rx_sym      = step(rx_filter,rx_sps);
			rx_scr_llr  = step(demod_psk,rx_sym);% Ce bloc nous renvoie des LLR (meilleur si on va interface avec du codage)
			rx_scr_bit  = rx_scr_llr<0; % Bits
            rx_scr_sync = step(mac_sync_delay, rx_scr_bit, tx_rx_flt_delay); % synchronisation couche accès.
			rx_scr_oct  = step(b2o,rx_scr_sync); % Conversion en octet pour le scrambler
			rx_oct      = bitxor(rx_scr_oct,dvb_scramble); % descrambler

			%% Compate des erreurs binaires
			tx_bit     = step(o2b,tx_oct);
			rx_bit     = step(o2b,rx_oct);
			err_stat   = step(stat_erreur, tx_bit, rx_bit);
			
			%% Destination
			if store_rx_vid
				step(message_destination, rx_oct); % Ecriture du fichier
			end
		end
	end
	ber(i_snr) = err_stat(1);
    refreshdata(h_ber);
	drawnow limitrate
end



