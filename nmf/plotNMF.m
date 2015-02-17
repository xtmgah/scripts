function plotNMF( prefix, nmfDir, minNumSig, maxNumSig )
% run NMF 
addpath(strcat(nmfDir, '/source/'));
addpath(strcat(nmfDir, '/plotting/'));
mkdir('temp');

for totalSignatures = minNumSig : maxNumSig
    inputFile = strcat(prefix, '_ts', num2str(totalSignatures), '.mat');
    load(inputFile);
    plotSignaturesToFile(prefix, processes, input, allProcesses, idx, processStabAvg, processNames);
end

quit
end
    
