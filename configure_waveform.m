function waveform_params = configure_waveform(varargin)
% CONFIGURE_WAVEFORM cree une structure de parametres de la parte mise en
% forme du signal (TX et RX)
%
% WAVEFORM_PARAMS = CONFIGURE_WAVEFORM(FE, M, PHI0)
% construit WAVEFORM_PARAMS a partir des parametres suivants :
% FE : frequence d'echantillonnage (canal) - DEFAUT 1e6
% M : Ordre de la PSK (2, 4 ou 8) - DEFAUT 4
% PHI0 : Phase initiale de la PSK  - DEFAUT pi/4


if nargin < 1
    Fe = 1e6;
else
    Fe = varargin{1};
end

if nargin < 2
    M=4;
else
    M = varargin{6};
end

if nargin < 3
    phi0=pi/4;
else
    phi0 = varargin{7};
end

waveform_params.sim.Fe = Fe;        % Frequence d'echantillonnage
waveform_params.sim.Ds = Fe; % Sampling frequency (Hz)

Fse = floor(waveform_params.sim.Fe/waveform_params.sim.Ds);

waveform_params.sim.Fse = Fse;   % sapn du filtre de mise en forme

switch M
    case 2
        waveform_params.mod.Name = 'BPSK';
    case 4
        waveform_params.mod.Name = 'QPSK';
    case 8
        waveform_params.mod.Name = '8PSK';
    otherwise
        error('Ce code ne fonctionne que pour des BPSK, QPSK, et 8PSK');
end
waveform_params.demod.Name = waveform_params.mod.Name;

% Parametres de la modulation numérique
% -------------------------------------------------------------------------
waveform_params.mod.ModulationOrder = M; % Taille de la modulation
waveform_params.mod.ModulationBPS   = log2(waveform_params.mod.ModulationOrder); % Nombre de bits par symboles
waveform_params.mod.PhaseOffset     = phi0; % Phase initiale nulle
waveform_params.mod.SymbolMapping   = 'Gray'; % Mapping de Gray
waveform_params.mod.BitInput        = true;
% -------------------------------------------------------------------------


% Parametres de la modulation numérique
% -------------------------------------------------------------------------
waveform_params.demod.ModulationOrder = M; % Taille de la modulation
waveform_params.demod.ModulationBPS   = log2(waveform_params.demod.ModulationOrder); % Nombre de bits par symboles
waveform_params.demod.PhaseOffset     = phi0; % Phase initiale nulle
waveform_params.demod.SymbolMapping   = 'Gray'; % Mapping de Gray
waveform_params.demod.BitOutput        = true;
waveform_params.demod.DecisionMethod  = 'Log-likelihood ratio';
waveform_params.demod.Variance        = 1;
% -------------------------------------------------------------------------

