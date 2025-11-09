function [theta2_1, theta2_2, theta3_1, theta3_2, mu_1, mu_2] = calcCorrederaManivela(a,b,c,d,units)
% calcCorrederaManivela  Cinemática de posición para corredera–manivela con descentrado.
%
% ENTRADAS
%   a      : longitud de la manivela (O2–A)
%   b      : longitud de la biela (A–B)
%   c      : descentrado (distancia vertical desde O2 al eje de la corredera; + arriba)
%   d      : posición de la corredera (entrada)
%   units  : 'deg' (por defecto) o 'rad'
%
% SALIDAS
%   theta2_1, theta2_2 : ángulos de la manivela (dos configuraciones)
%   theta3_1, theta3_2 : ángulos de la biela correspondientes
%
% Modelo inverso del mecanismo Manivela–Corredera:
%   (a*cosθ2 - x)^2 + (a*sinθ2 - c)^2 = b^2
%   sinθ3 = (a*sinθ2 - c)/b

    if nargin < 5 || isempty(units), units = 'deg'; end
    useDeg = strcmpi(units,'deg');

    % --- Cálculos intermedios
    K1 = a^2 - b^2 + c^2 + d^2;
    K2 = -2*a*c;
    K3 = -2*a*d;

    A = K1 - K3;
    B = 2*K2;
    C = K1 + K3;

    % --- Chequeo de factibilidad
    disc = B.^2 - 4*A.*C;
    if any(disc < 0)
        theta2_1 = NaN; theta2_2 = NaN;
        theta3_1 = NaN; theta3_2 = NaN;
        warning('No hay solución real: discriminante negativo (B^2 - 4AC < 0)');
        return;
    end

    % --- Dos soluciones para theta2
    th2_1 = 2*atan((-B + sqrt(disc))./(2*A));
    th2_2 = 2*atan((-B - sqrt(disc))./(2*A));

    % --- Ángulos de la biela
    s1 = (-(a*sin(th2_1) - c)/b);
    s2 = (-(a*sin(th2_2) - c)/b);

    % Limitar dominio
    s1 = max(min(s1,1),-1);
    s2 = max(min(s2,1),-1);

    th3_1 = asin(s1)+pi;
    th3_2 = asin(s2)+pi;

    % --- Salida en grados si se pidió
    if useDeg
        theta2_1 = rad2deg(th2_1);
        theta2_2 = rad2deg(th2_2);
        theta3_1 = rad2deg(th3_1);
        theta3_2 = rad2deg(th3_2);
    else
        theta2_1 = th2_1;
        theta2_2 = th2_2;
        theta3_1 = th3_1;
        theta3_2 = th3_2;
    end


    %% ÁNGULO DE TRANSMISIÓN (Slider–Crank)
% µ = ángulo agudo entre la biela y la horizontal
mu_1 = abs(theta3_1);
mu_2 = abs(theta3_2);

if mu_1 > 90
    mu_1 = 180 - mu_1;
end
if mu_2 > 90
    mu_2 = 180 - mu_2;
end





end
