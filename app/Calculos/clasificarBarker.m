function resultado = classificarBarker(a, b, c, d)
% =========================================================================
% classificarBarker  Clasifica el mecanismo de 4 barras según Barker
% =========================================================================
% Convención:
%   a = entrada (manivela)
%   b = acoplador
%   c = salida (balancín)
%   d = base (fijo)
%
% Basado en Tabla 2-4 (Barker, Norton 2004)
% =========================================================================

    %% Ordenar longitudes
    L = sort([a b c d]);  % [S, P, Q, L]
    S = L(1); Lmax = L(4);
    P = L(2); Q = L(3);
    
    %% Condición de Grashof
    if S + Lmax < P + Q
        tipo_grashof = "Grashof";
        clase_base = "I";
    elseif S + Lmax == P + Q
        tipo_grashof = "Caso especial";
        clase_base = "III";
    else
        tipo_grashof = "No Grashof";
        clase_base = "II";
    end

    %% Identificar el eslabón más corto
    [~, idxS] = min([a b c d]);
    etiquetas = ["a (entrada)","b (acoplador)","c (salida)","d (base)"];
    eslabon_corto = etiquetas(idxS);

    %% Clasificación según Barker ajustada a la convención (a,b,c,d)
    switch clase_base
        case "I"  % --------- GRASHOF -------------
            switch idxS
                case 4
                    tipo = 1; codigo = "GCCC";
                    nombre = "Doble manivela de Grashof";
                case 1
                    tipo = 2; codigo = "GCRR";
                    nombre = "Manivela–balancín de Grashof";
                case 2
                    tipo = 3; codigo = "GRCR";
                    nombre = "Doble balancín de Grashof";
                case 3
                    tipo = 4; codigo = "GRRC";
                    nombre = "Balancín–manivela de Grashof";
            end

 case "II" % No Grashof (S+L > P+Q)
    % Índice del eslabón más largo en el orden [a b c d] = [entrada, acoplador, salida, bancada]
    [~, idxL] = max([a b c d]);

    switch idxL
        case 4   % d = bancada
            tipo = 5; codigo = "RRR1";
            nombre = "Triple balancín (L más largo = bancada)";
        case 1   % a = entrada
            tipo = 6; codigo = "RRR2";
            nombre = "Triple balancín (L más largo = entrada)";
        case 2   % b = acoplador
            tipo = 7; codigo = "RRR3";
            nombre = "Triple balancín (L más largo = acoplador)";
        case 3   % c = salida
            tipo = 8; codigo = "RRR4";
            nombre = "Triple balancín (L más largo = salida)";
    end


        case "III" % -------- CASOS ESPECIALES ----
            if abs(a-b)<1e-6 && abs(b-c)<1e-6 && abs(c-d)<1e-6
                tipo = 14; codigo = "S3X";
                nombre = "Cuadrado (caso especial)";
            elseif abs(a-c)<1e-6 && abs(b-d)<1e-6
                tipo = 13; codigo = "S2X";
                nombre = "Paralelogramo o deltoide";
            else
                switch idxS
                    case 4, tipo=9;  codigo="SCCC"; nombre="Doble manivela SC";
                    case 1, tipo=10; codigo="SCRR"; nombre="Manivela–balancín SC";
                    case 2, tipo=11; codigo="SRCR"; nombre="Doble balancín SC";
                    case 3, tipo=12; codigo="SRRC"; nombre="Balancín–manivela SC";
                end
            end
    end

    %% Resultado final
    resultado = struct( ...
        'tipo', tipo, ...
        'clase', clase_base, ...
        'codigo', codigo, ...
        'nombre', nombre, ...
        'descripcion', sprintf('%s (%s, eslabón más corto = %s)', ...
                               nombre, tipo_grashof, eslabon_corto) );
end

