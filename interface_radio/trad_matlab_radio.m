function [] = trad_matlab_radio( filename,signal)
%%HELP
% Fonction ayant pour but de stocker dans un fichier binaire le signal
% module que l'on souhaite emettre à l'aide de la radio. 
%%IN:
%filename: nom du fichier dans lequel va etre stocke les valeurs du signal.
%Utiliser chemin absolu du fichier. Le fichier doit etre un fichier du type
%".bin".
%signal : signal modulé que l'on souhaite emettre avec la radio.
file = fopen(filename,'w');
vect  = [];

for i=1:length(signal)
    pr=real(signal(i));
    pi=imag(signal(i));
    vect = [vect pr pi];
end

count = fwrite(file,vect,'single');
fclose(file);

if (length(vect)~=count)
    warning('Erreur decriture dans le fichier.')
end
end

