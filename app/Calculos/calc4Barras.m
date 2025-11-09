function resultado = calc4Barras(a, b, c, d, theta2_deg)
    % calc4Barras - Cálculo  de síntesis de posición de un mecanismo de 4 barras
    % Detecta cuando las ecuaciones no tienen solución real y devuelve banderas de estado.
    
    %% Inicialización segura
    resultado = struct(...
        'tetha4_1', NaN, 'tetha4_2', NaN, ...
        'tetha3_1', NaN, 'tetha3_2', NaN, ...
        'agarrotamiento1', NaN, 'agarrotamiento2', NaN, ...
        'hay_solucion_theta3', false, ...
        'hay_solucion_theta4', false, ...
        'mensaje', '');

    try
        %% Conversión de ángulo
        theta2_rad = deg2rad(theta2_deg);

                %% -------------------------------------------------------------
        % CASO ESPECIAL: PARALELOGRAMO O DELTOIDE
        % -------------------------------------------------------------
        if abs(a-c) < 1e-3 && abs(b-d) < 1e-3
            resultado.tetha3_1 = theta2_deg;
            resultado.tetha3_2 = theta2_deg;
            resultado.tetha4_1 = theta2_deg;
            resultado.tetha4_2 = theta2_deg;


                %% -------------------------------------------------------------
        % CASO ESPECIAL: PARALELOGRAMO O CUADRADO
        % -------------------------------------------------------------
        if abs(a-c) < 1e-3 && abs(b-d) < 1e-3
            % Los ángulos opuestos son iguales y paralelos
            resultado.tetha3_1 = theta2_deg;
            resultado.tetha3_2 = theta2_deg;
            resultado.tetha4_1 = mod(theta2_deg + 180, 360);
            resultado.tetha4_2 = resultado.tetha4_1;

            % Marcar soluciones válidas
            resultado.hay_solucion_theta3 = true;
            resultado.hay_solucion_theta4 = true;

            % Transmisión ideal
            resultado.theta_transmision_1 = 90;
            resultado.theta_transmision_2 = 90;
            resultado.mu_1 = 90;
            resultado.mu_2 = 90;
            resultado.mu_extremo_min = 90;
            resultado.mu_extremo_max = 90;
            resultado.agarrotamiento1 = 0;
            resultado.agarrotamiento2 = 0;

            % Mensaje
            if abs(a-b) < 1e-3
                resultado.mensaje = 'Caso especial: mecanismo cuadrado (SC).';
            else
                resultado.mensaje = 'Caso especial: paralelogramo o deltoide (ángulos opuestos paralelos).';
            end

            %  Ajuste de coordenadas para visualización
            % Guardar un flag adicional para avisar al programa de dibujo
            resultado.es_paralelogramo = true;

            return;
        else
            resultado.es_paralelogramo = false;
        end






            
            resultado.hay_solucion_theta3 = true;
            resultado.hay_solucion_theta4 = true;

            % Ángulos teóricos
            resultado.theta_transmision_1 = 90;
            resultado.theta_transmision_2 = 90;
            resultado.mu_1 = 90;
            resultado.mu_2 = 90;
            resultado.mu_extremo_min = 90;
            resultado.mu_extremo_max = 90;
            resultado.agarrotamiento1 = 0;
            resultado.agarrotamiento2 = 0;

            resultado.mensaje = 'Caso especial: mecanismo paralelogramo o deltoide (ángulos equivalentes).';
            return;  
        end


        %% Coeficientes de posición
        K1 = d / a;
        K2 = d / c;
        K3 = (a^2 - b^2 + c^2 + d^2) / (2 * a * c);
        K4 = d / b;
        K5 = (c^2 - d^2 - a^2 - b^2) / (2 * a * b);

        % Ecuaciones A–F
        A = cos(theta2_rad) - K1 - K2 * cos(theta2_rad) + K3;
        B = -2 * sin(theta2_rad);
        C = K1 - (K2 + 1) * cos(theta2_rad) + K3;
        D = cos(theta2_rad) - K1 + K4 * cos(theta2_rad) + K5;
        E = -2 * sin(theta2_rad);
        F = K1 + (K4 - 1) * cos(theta2_rad) + K5;

        %% Discriminantes
        disc4 = B^2 - 4 * A * C;
        disc3 = E^2 - 4 * D * F;

        %% Cálculo de θ4
        if disc4 >= 0
            theta4_1 = 2 * atan(((-B) + sqrt(disc4)) / (2 * A));
            theta4_2 = 2 * atan(((-B) - sqrt(disc4)) / (2 * A));
            resultado.tetha4_1 = rad2deg(theta4_1);
            resultado.tetha4_2 = mod(rad2deg(theta4_2), 360);
            resultado.hay_solucion_theta4 = true;
        else
            resultado.mensaje = sprintf('No hay solución real para θ₄ (discriminante %.3f < 0).', disc4);
        end

        %% Cálculo de θ3
        if disc3 >= 0
            theta3_1 = 2 * atan((-E + sqrt(disc3)) / (2 * D));
            theta3_2 = 2 * atan((-E - sqrt(disc3)) / (2 * D));
            resultado.tetha3_1 = rad2deg(theta3_1);
            resultado.tetha3_2 = mod(rad2deg(theta3_2), 360);
            resultado.hay_solucion_theta3 = true;
        else
            if resultado.mensaje ~= ""
                resultado.mensaje = resultado.mensaje + " Además, no hay solución real para θ₃.";
            else
                resultado.mensaje = sprintf('No hay solución real para θ₃ (discriminante %.3f < 0).', disc3);
            end
        end

             %% Ángulo de transmisión (μ y θ_trans) con corrección geométrica
        if resultado.hay_solucion_theta3 && resultado.hay_solucion_theta4
            % Normalizar ángulos en [0, 360)
            t3_1 = mod(resultado.tetha3_1, 360);
            t3_2 = mod(resultado.tetha3_2, 360);
            t4_1 = mod(resultado.tetha4_1, 360);
            t4_2 = mod(resultado.tetha4_2, 360);

            % Diferencia angular absoluta
            theta_trans_1 = abs(t3_1 - t4_1);
            theta_trans_2 = abs(t3_2 - t4_2);

            % Llevar siempre al menor ángulo (0 a 180)
            if theta_trans_1 > 180
                theta_trans_1 = 360 - theta_trans_1;
            end
            if theta_trans_2 > 180
                theta_trans_2 = 360 - theta_trans_2;
            end

            % Aplicar criterio teórico: si > 90°, usar 180 - θ_trans
            if theta_trans_1 > 90
                mu1 = 180 - theta_trans_1;
            else
                mu1 = theta_trans_1;
            end

            if theta_trans_2 > 90
                mu2 = 180 - theta_trans_2;
            else
                mu2 = theta_trans_2;
            end

            % Guardar resultados
            resultado.theta_transmision_1 = theta_trans_1;
            resultado.theta_transmision_2 = theta_trans_2;
            resultado.mu_1 = mu1;
            resultado.mu_2 = mu2;
        else
            resultado.theta_transmision_1 = NaN;
            resultado.theta_transmision_2 = NaN;
            resultado.mu_1 = NaN;
            resultado.mu_2 = NaN;
        end
        
                %% Ángulos extremos de transmisión (μ_min y μ_max)
        % μ1 -> posición de traslape (colineales y opuestos)
        % μ2 -> posición de extendido (colineales y extendidos)
        try
            arg_mu1 = (b^2 + c^2 - (d - a)^2) / (2 * b * c);
            arg_mu2 = (b^2 + c^2 - (d + a)^2) / (2 * b * c);

            % Limitar al dominio [-1, 1] para evitar NaN por redondeo
            arg_mu1 = max(min(arg_mu1, 1), -1);
            arg_mu2 = max(min(arg_mu2, 1), -1);

            mu_min = rad2deg(acos(arg_mu1));       % μ1 = γ1
            mu_max = rad2deg(acos(arg_mu2)); % μ2 = π - γ2

            resultado.mu_extremo_min = mu_min;
            resultado.mu_extremo_max = mu_max;
        catch
            resultado.mu_extremo_min = NaN;
            resultado.mu_extremo_max = NaN;
        end



        
        %% Ángulos de agarrotamiento
        num = a^2 + d^2 - b^2 - c^2;
        den = 2 * a * d;
        t1 = num / den;
        t2 = (b * c) / (a * d);
        arg1 = max(min(t1 + t2, 1), -1);
        arg2 = max(min(t1 - t2, 1), -1);
        resultado.agarrotamiento1 = rad2deg(acos(arg1));
        resultado.agarrotamiento2 = rad2deg(acos(arg2));

        %% Mensaje final coherente
        if resultado.hay_solucion_theta3 && resultado.hay_solucion_theta4
            resultado.mensaje = 'Las soluciones son reales y válidas.';
        elseif resultado.hay_solucion_theta3
            resultado.mensaje = 'Solo θ₃ tiene solución real.';
        elseif resultado.hay_solucion_theta4
            resultado.mensaje = 'Solo θ₄ tiene solución real.';
        elseif resultado.mensaje == ""
            resultado.mensaje = 'No existen soluciones reales para θ₃ ni θ₄.';
        end


        
    catch ME
        %% Manejo de errores inesperados
        resultado.mensaje = sprintf('Error inesperado: El mecanismo no existe en la configuracion y angulos deseada. Ingresar otro valor%s', ME.message);
    end
end

 