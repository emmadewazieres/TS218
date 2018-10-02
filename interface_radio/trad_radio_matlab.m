function [vec] = trad_radio_matlab(filename)
%%Help:
%Fonction ayant pour but de traduire un fichier contenant un signal recu
%par la radio en un vecteur matlab.
%%In:
%filename : fichier ou est stocke le signal recu par la radio.
%%Out:
%vec : vecteur resultant du fichier pris en entree

file = fopen(filename);

data = fread(file,2560000,'single');
if isempty(data)
  warning('Erreur le fichier est vide');
end

vec = data(1:2:end) + 1i*data(2:2:end);
fclose(file);
end

