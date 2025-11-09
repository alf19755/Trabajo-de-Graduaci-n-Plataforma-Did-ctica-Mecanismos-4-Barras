%% LIMPIAR PUERTOS
clear all
instrreset

delete(instrfindall)
clear s


%% CODIGO PARA REVISAR COM (TENER CERRADO IDE)
serialportlist("available")

%% REVISAR VALORES
COM_SELECTED= "COM5";
s = serialport(COM_SELECTED,115200);
configureTerminator(s,"LF");
flush(s);
while true
    if s.NumBytesAvailable > 0
        disp(readline(s))
    end
end
