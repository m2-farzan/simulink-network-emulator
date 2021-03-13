function [IsDisonnected, NewState] = GILossModel(State, LossParams)
    P = TransitionProbabilities(LossParams);
    NewState = find(cumsum(P(State, :)) > rand(), 1, 'first');
    IsDisonnected = (NewState == 3) || (NewState == 4);
end

function p = TransitionProbabilities(LossParams)
    p = zeros(4);

    P_loss = LossParams(1);
    E_B = LossParams(2);
    rho = LossParams(3);
    P_isol = LossParams(4);
    E_GB = LossParams(5);

    p(3, 1) = 1 / (E_B * rho);
    p(1, 3) = (P_loss - P_isol)/(E_B * (1 - P_isol) * (rho - P_loss));
    p(2, 3) = 1 / (E_GB);
    p(3, 2) = (1 - rho) / (rho * E_GB);
    p(1, 4) = P_isol / (1 - P_isol);
    p(4, 1) = 1.0;
    p(1, 1) = 1 - p(1, 3) - p(1, 4);
    p(2, 2) = 1 - p(2, 3);
    p(3, 3) = 1 - p(3, 1) - p(3, 2);
    p(4, 4) = 0;
end
