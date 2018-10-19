function [awgn_channel, doppler, delay] = build_channel(channel_params, waveform_params)
delay = dsp.VariableFractionalDelay;
doppler = comm.PhaseFrequencyOffset(...
    'FrequencyOffset',channel_params.FrequencyOffset,...
    'PhaseOffset',    channel_params.PhaseOffset,...
    'SampleRate',     waveform_params.sim.Fe);

awgn_channel = comm.AWGNChannel(...
    'NoiseMethod', 'Signal to noise ratio (Es/No)',...
    'EsNo',channel_params.EbN0dB(1),...
    'SignalPower',channel_params.Gain^2);
    %'BitsPerSymbol',waveform_params.mod.ModulationBPS,...
    

