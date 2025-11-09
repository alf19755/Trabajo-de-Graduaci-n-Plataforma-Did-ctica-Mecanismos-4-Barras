function resultado = calcGrashof(a, b, c, d)

    %GRASHOF
    % calcGrashof - Determina si un mecanismo de cuatro barras es Grashof
    %
    % Entradas:
    %   a, b, c, d       Longitudes de los eslabones
    %
    % Salidas (struct):
    %   resultado.class   Clasificación Grashof (string)
    %   resultado.S      Longitud del eslabón más corto
    %   resultado.L      Longitud del eslabón más largo
    %   resultado.PQ     Suma de los otros dos eslabones
    % Verificar que sean positivos
    if any([a, b, c, d] <= 0)
        error('Las longitudes de los eslabones deben ser positivas.');
    end

    S = min([a, b, c, d]); % mas corto
    L = max([a, b, c, d]); % Lmas largo
    P = sum([a, b, c, d]) - S - L; % Sum of other two links
    Q = sum([a, b, c, d]) - S - L - P; % Remaining link
    S_plus_L = S + L;
    P_plus_Q = P + Q;
    
    % Grashof condition with special case
    if S_plus_L < P_plus_Q
        grashof_class = 'Grashof (Clase I: Grashof: Revolución)';
    elseif S_plus_L == P_plus_Q
        grashof_class = 'Grashof (Clase III: Especial de Grashof)';
    else
        grashof_class = 'No Grashof (Clase II: No Grashof)';
    end




   %BARKER











   %RESULTADOS


    resultado.class = grashof_class;
    resultado.S = S;
    resultado.L = L;
    resultado.P = P;
    resultado.P = Q;
end