function GILossModelValidate(LossParams)
    P_loss = LossParams(1);
    E_B = LossParams(2);
    rho = LossParams(3);
    P_isol = LossParams(4);
    E_GB = LossParams(5);

    assert(E_B >= 1 / rho, 'E_B must be >= 1/rho');
    assert(P_isol <= P_loss, 'P_isol must be <= P_loss');
    assert(P_loss < rho, 'P_loss must be <= rho');
    assert(P_loss - P_isol <= E_B * (1.0 - P_isol) * (rho - P_loss), ...
        '(P_loss - P_isol) must be <= E_B * (1.0 - P_isol) * (rho - P_loss)');
    assert(E_GB >= 1, 'E_GB must be >= 1');
    assert(P_isol <= 1/2, 'P_isol must be <= 1/2');
end
