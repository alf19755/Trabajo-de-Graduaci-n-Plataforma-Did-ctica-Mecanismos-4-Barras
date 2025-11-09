function [theta3_1, theta3_2, x_1, x_2] = calcManivelaCorredera(a, b, c, theta2, units)
% calcSliderCrank  Cinemática de posición para manivela–corredera con descentrado.
%
% ENTRADAS
%   a      : longitud de la manivela (O2–A)
%   b      : longitud de la biela (A–B)
%   c      : descentrado (distancia vertical desde O2 al eje de la corredera; + arriba)
%   theta2 : ángulo de la manivela
%   units  : 'deg' (por defecto) o 'rad'
%
% SALIDAS
%   theta3_1, theta3_2 : ángulos de la biela (dos configuraciones)
%   x_1, x_2           : posición del deslizador para cada configuración
%
% Modelo (signos como en tus láminas):
%   sin(theta3) = (a*sin(theta2) - c)/b
%   x = a*cos(theta2) - b*cos(theta3)

    if nargin < 5 || isempty(units), units = 'deg'; end
    useDeg = strcmpi(units,'deg');

    th2 = theta2;
    if useDeg, th2 = deg2rad(theta2); end

    % --- Chequeo de factibilidad geométrica
    s = (a*sin(th2) - c)/b;
    if abs(s) > 1 + 1e-12
        % fuera del rango: no hay solución real
        theta3_1 = NaN; theta3_2 = NaN;
        x_1 = NaN; x_2 = NaN;
        warning('No hay solución: |(a*sin(theta2)-c)/b| = %.6f > 1',abs(s));
        return;
    end
    % Limitar a [-1,1] por errores numéricos
    s = max(min(s,1),-1);

    % --- Dos configuraciones
    th3_1 = asin(s);                 % codo-arriba (convención)
    th3_2 = asin(-s) + pi;           % codo-abajo (según tu fórmula)

    % --- Posición del deslizador
    x_1 = a*cos(th2) - b*cos(th3_1);
    x_2 = a*cos(th2) - b*cos(th3_2);

    % Salida en grados si se pidió así
    if useDeg
        theta3_1 = rad2deg(th3_1);
        theta3_2 = rad2deg(th3_2);
    else
        theta3_1 = th3_1;
        theta3_2 = th3_2;
    end
end
